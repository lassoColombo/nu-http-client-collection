# Auto-generated client for LaunchDarkly REST API v5.3.0
# Source: https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json
# Auth: --token flag or $env.LAUNCHDARKLY_REST_API_TOKEN

const BASE_URL = "https://app.launchdarkly.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LAUNCHDARKLY_REST_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://app.launchdarkly.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root get" } } | get name | first)
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

# You can issue a GET request to the root resource to find all of the resource categories supported by the API.
#
# GET /
# operationId: getRoot
export def "root get" [
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
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of relay proxy configurations in the account.
#
# GET /account/relay-auto-configs
# operationId: getRelayProxyConfigs
export def "account-relay-auto-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<_creator: record, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/relay-auto-configs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new relay proxy config.
#
# POST /account/relay-auto-configs
# operationId: postRelayAutoConfig
export def "account-relay-auto-configs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/relay-auto-configs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a relay proxy configuration by ID.
#
# DELETE /account/relay-auto-configs/{id}
# operationId: deleteRelayProxyConfig
export def "account-relay-auto-configs delete" [
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
  let full_url = (build-url $base $"/account/relay-auto-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single relay proxy configuration by ID.
#
# GET /account/relay-auto-configs/{id}
# operationId: getRelayProxyConfig
export def "account-relay-auto-configs get" [
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
  let full_url = (build-url $base $"/account/relay-auto-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a relay proxy configuration by ID.
#
# PATCH /account/relay-auto-configs/{id}
# operationId: patchRelayProxyConfig
export def "account-relay-auto-configs patch" [
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
  let full_url = (build-url $base $"/account/relay-auto-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a relay proxy configuration's secret key with an optional expiry time for the old key.
#
# POST /account/relay-auto-configs/{id}/reset
# operationId: resetRelayProxyConfig
export def "account-relay-auto-configs-reset resetRelayProxyConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiry: int # An expiration time for the old relay proxy configuration key, expressed as a Unix epoch time in milliseconds. By default, the relay proxy configuration will expire immediately (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/relay-auto-configs/($id)/reset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all audit log entries. The query parameters allow you to restrict the returned results by date ranges, resource specifiers, or a full-text search query.
#
# GET /auditlog
# operationId: getAuditLogEntries
export def "auditlog list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have before this timestamp. (format: int64)
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
  --q: string # Text to search for. You can search for the full or partial name of the resource involved or full or partial email address of the member who made the change.
  --limit: float # A limit on the number of audit log entries to be returned, between 1 and 20.
  --spec: string # A resource specifier, allowing you to filter audit log listings by resource.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, comment: string, date: int, description: string, kind: string, member: record, name: string, shortDescription: string, target: record, title: string, titleVerb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "spec" $spec "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auditlog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Use this endpoint to fetch a single audit log entry by its resouce ID.
#
# GET /auditlog/{resourceId}
# operationId: getAuditLogEntry
export def "auditlog get" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, comment: string, date: int, description: string, kind: string, member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, name: string, shortDescription: string, target: record<_links: record<next: record, self: record>, name: string, resources: list<string>>, title: string, titleVerb: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auditlog/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all data export destinations.
#
# GET /destinations
# operationId: getDestinations
export def "destinations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, config: record, kind: string, name: string, on: bool, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/destinations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new data export destination
#
# POST /destinations/{projectKey}/{environmentKey}
# operationId: postDestination
export def "destinations post" [
  projectKey: string
  environmentKey: string
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
  let full_url = (build-url $base $"/destinations/($projectKey)/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single data export destination by ID
#
# DELETE /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: deleteDestination
export def "destinations delete" [
  projectKey: string
  environmentKey: string
  destinationId: string
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
  let full_url = (build-url $base $"/destinations/($projectKey)/($environmentKey)/($destinationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single data export destination by ID
#
# GET /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: getDestination
export def "destinations get-by-projectKey-environmentKey-destinationId" [
  projectKey: string
  environmentKey: string
  destinationId: string
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
  let full_url = (build-url $base $"/destinations/($projectKey)/($environmentKey)/($destinationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform a partial update to a data export destination.
#
# PATCH /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: patchDestination
export def "destinations patch" [
  projectKey: string
  environmentKey: string
  destinationId: string
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
  let full_url = (build-url $base $"/destinations/($projectKey)/($environmentKey)/($destinationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status for a particular feature flag across environments
#
# GET /flag-status/{projectKey}/{featureFlagKey}
# operationId: getFeatureFlagStatusAcrossEnvironments
export def "flag-status get" [
  projectKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, environments: record, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flag-status/($projectKey)/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of statuses for all feature flags. The status includes the last time the feature flag was requested, as well as the state of the flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}
# operationId: getFeatureFlagStatuses
export def "flag-statuses list" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, default: record, lastRequested: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flag-statuses/($projectKey)/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status for a particular feature flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}/{featureFlagKey}
# operationId: getFeatureFlagStatus
export def "flag-statuses get" [
  projectKey: string
  environmentKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, default: record, lastRequested: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flag-statuses/($projectKey)/($environmentKey)/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all features in the given project.
#
# GET /flags/{projectKey}
# operationId: getFeatureFlags
export def "flags list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --env: list # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment.
  --summary: string@bool-completer # By default in api version >= 1, flags will _not_ include their list of prerequisites, targets or rules.  Set summary=0 to include these fields for each flag returned.
  --archived: string@bool-completer # When set to 1, only archived flags will be included in the list of flags returned.  By default, archived flags are not included in the list of flags.
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --qp-sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, _maintainer: record, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record, creationDate: int, customProperties: record, defaults: record, description: string, environments: record, goalIds: list, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list, temporary: bool, variations: list>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "env" $env "multi") (serialize-qp "summary" $summary "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flags/($projectKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new feature flag.
#
# POST /flags/{projectKey}
# operationId: postFeatureFlag
export def "flags post" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clone: string # The key of the feature flag to be cloned. The key identifies the flag in your code.  For example, setting clone=flagKey will copy the full targeting configuration for all environments (including on/off state) from the original flag to the new flag.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clone" $clone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flags/($projectKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dependent flags for the flag in the environment specified in path parameters
#
# GET /flags/{projectKey}/{environmentKey}/{featureFlagKey}/dependent-flags
export def "flags-dependent-flags get" [
  projectKey: string
  environmentKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($environmentKey)/($featureFlagKey)/dependent-flags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a feature flag in all environments. Be careful-- only delete feature flags that are no longer being used by your application.
#
# DELETE /flags/{projectKey}/{featureFlagKey}
# operationId: deleteFeatureFlag
export def "flags delete" [
  projectKey: string
  featureFlagKey: string
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
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single feature flag by key.
#
# GET /flags/{projectKey}/{featureFlagKey}
# operationId: getFeatureFlag
export def "flags get" [
  projectKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --env: list # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "env" $env "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform a partial update to a feature.
#
# PATCH /flags/{projectKey}/{featureFlagKey}
# operationId: patchFeatureFlag
export def "flags patch" [
  projectKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copies the feature flag configuration from one environment to the same feature flag in another environment.
#
# POST /flags/{projectKey}/{featureFlagKey}/copy
# operationId: copyFeatureFlag
export def "flags-copy copyFeatureFlag" [
  projectKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dependent flags across all environments for the flag specified in the path parameters
#
# GET /flags/{projectKey}/{featureFlagKey}/dependent-flags
export def "flags-dependent-flags list" [
  projectKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, environments: list, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)/dependent-flags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expiring user targets for feature flag
#
# GET /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargets
export def "flags-expiring-user-targets get" [
  projectKey: string
  environmentKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update, add, or delete expiring user targets on feature flag
#
# PATCH /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargets
export def "flags-expiring-user-targets patch" [
  projectKey: string
  environmentKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($projectKey)/($featureFlagKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all configured audit log event integrations associated with this account.
#
# GET /integrations
# operationId: getIntegrations
export def "integrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all configured integrations of a given kind.
#
# GET /integrations/{integrationKey}
# operationId: getIntegrationSubscriptions
export def "integrations get-by-integrationKey" [
  integrationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: record<href: string, type: string>>, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/($integrationKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new integration subscription of a given kind.
#
# POST /integrations/{integrationKey}
# operationId: postIntegrationSubscription
export def "integrations post" [
  integrationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/($integrationKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an integration subscription by ID.
#
# DELETE /integrations/{integrationKey}/{integrationId}
# operationId: deleteIntegrationSubscription
export def "integrations delete" [
  integrationKey: string
  integrationId: string
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
  let full_url = (build-url $base $"/integrations/($integrationKey)/($integrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single integration subscription by ID.
#
# GET /integrations/{integrationKey}/{integrationId}
# operationId: getIntegrationSubscription
export def "integrations get-by-integrationKey-integrationId" [
  integrationKey: string
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/($integrationKey)/($integrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify an integration subscription by ID.
#
# PATCH /integrations/{integrationKey}/{integrationId}
# operationId: patchIntegrationSubscription
export def "integrations patch" [
  integrationKey: string
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/($integrationKey)/($integrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all members in the account.
#
# GET /members
# operationId: getMembers
export def "members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --qp-sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite new members.
#
# POST /members
# operationId: postMembers
export def "members post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current team member associated with the token
#
# GET /members/me
# operationId: getMe
export def "members-me get" [
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
  let full_url = (build-url $base "/members/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team member by ID.
#
# DELETE /members/{memberId}
# operationId: deleteMember
export def "members delete" [
  memberId: string
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
  let full_url = (build-url $base $"/members/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single team member by ID.
#
# GET /members/{memberId}
# operationId: getMember
export def "members get" [
  memberId: string
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
  let full_url = (build-url $base $"/members/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a team member by ID.
#
# PATCH /members/{memberId}
# operationId: patchMember
export def "members patch" [
  memberId: string
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
  let full_url = (build-url $base $"/members/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all projects in the account.
#
# GET /projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, defaultClientSideAvailability: record, environments: list, includeInSnippetByDefault: bool, key: string, name: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project with the given key and name.
#
# POST /projects
# operationId: postProject
export def "projects post" [
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
  let full_url = (build-url $base "/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a project by key. Caution-- deleting a project will delete all associated environments and feature flags. You cannot delete the last project in an account.
#
# DELETE /projects/{projectKey}
# operationId: deleteProject
export def "projects delete" [
  projectKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single project by key.
#
# GET /projects/{projectKey}
# operationId: getProject
export def "projects get" [
  projectKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a project by ID.
#
# PATCH /projects/{projectKey}
# operationId: patchProject
export def "projects patch" [
  projectKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new environment in a specified project with a given name, key, and swatch color.
#
# POST /projects/{projectKey}/environments
# operationId: postEnvironment
export def "projects-environments post" [
  projectKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an environment in a specific project.
#
# DELETE /projects/{projectKey}/environments/{environmentKey}
# operationId: deleteEnvironment
export def "projects-environments delete" [
  projectKey: string
  environmentKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/environments/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an environment given a project and key.
#
# GET /projects/{projectKey}/environments/{environmentKey}
# operationId: getEnvironment
export def "projects-environments get" [
  projectKey: string
  environmentKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/environments/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify an environment by ID. If you try to patch the environment by setting both required and requiredApprovalTags, it will result in an error. Users can specify either required approvals for all flags in an environment or those with specific tags, but not both. Only customers on an Enterprise plan can require approval for flag updates with either mechanism.
#
# PATCH /projects/{projectKey}/environments/{environmentKey}
# operationId: patchEnvironment
export def "projects-environments patch" [
  projectKey: string
  environmentKey: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/environments/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset an environment's SDK key with an optional expiry time for the old key.
#
# POST /projects/{projectKey}/environments/{environmentKey}/apiKey
# operationId: resetEnvironmentSDKKey
export def "projects-environments-api-key resetEnvironmentSDKKey" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiry: int # An expiration time for the old environment SDK key, expressed as a Unix epoch time in milliseconds. By default, the key will expire immediately. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectKey)/environments/($environmentKey)/apiKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset an environment's mobile key. The optional expiry for the old key is deprecated for this endpoint, so the old key will always expire immediately.
#
# POST /projects/{projectKey}/environments/{environmentKey}/mobileKey
# operationId: resetEnvironmentMobileKey
export def "projects-environments-mobile-key resetEnvironmentMobileKey" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiry: int # The expiry parameter is deprecated for this endpoint, so the old mobile key will always expire immediately. This parameter will be removed in an upcoming major API client version. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectKey)/environments/($environmentKey)/mobileKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all approval requests for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests
# operationId: getApprovalRequests
export def "projects-flags-environments-approval-requests list" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an approval request for a feature flag config
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: deleteApprovalRequest
export def "projects-flags-environments-approval-requests delete" [
  projectKey: string
  environmentKey: string
  featureFlagKey: string
  approvalRequestId: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests/($approvalRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single approval request for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: getApprovalRequest
export def "projects-flags-environments-approval-requests get" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  approvalRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests/($approvalRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: postApprovalRequest
export def "projects-flags-environments-approval-requests post" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  approvalRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _version: int, allReviews: table<_id: string, creationDate: int, kind: string, memberId: string>, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: table<kind: string>, notifyMemberIds: list<string>, operatingOnId: string, requestorId: string, reviewStatus: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests/($approvalRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/apply
# operationId: postApplyApprovalRequest
export def "projects-flags-environments-approval-requests-apply post" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  approvalRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests/($approvalRequestId)/apply")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Review approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/review
# operationId: postReviewApprovalRequest
export def "projects-flags-environments-approval-requests-review post" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  approvalRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/approval-requests/($approvalRequestId)/review")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scheduled workflows for a feature flag by key.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# operationId: getFlagConfigScheduledChanges
export def "projects-flags-environments-scheduled-changes list" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, executionDate: int, instructions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new scheduled change for a feature flag.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# operationId: postFlagConfigScheduledChanges
export def "projects-flags-environments-scheduled-changes post" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists conflicts between the given instructions and any existing scheduled changes for the feature flag. The actual HTTP verb should be REPORT, not POST.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes-conflicts
# operationId: getFlagConfigScheduledChangesConflicts
export def "projects-flags-environments-scheduled-changes-conflicts post" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<instructions: table<conflicts: list, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes-conflicts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a scheduled change on a feature flag in an environment.
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: deleteFlagConfigScheduledChanges
export def "projects-flags-environments-scheduled-changes delete" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  scheduledChangeId: string
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
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes/($scheduledChangeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a scheduled change on a feature flag by id.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: getFlagConfigScheduledChange
export def "projects-flags-environments-scheduled-changes get" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  scheduledChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes/($scheduledChangeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing scheduled-change on a feature flag in an environment.
#
# PATCH /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: patchFlagConfigScheduledChange
export def "projects-flags-environments-scheduled-changes patch" [
  projectKey: string
  featureFlagKey: string
  environmentKey: string
  scheduledChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectKey)/flags/($featureFlagKey)/environments/($environmentKey)/scheduled-changes/($scheduledChangeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a complete list of custom roles.
#
# GET /roles
# operationId: getCustomRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, description: string, key: string, name: string, policy: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new custom role.
#
# POST /roles
# operationId: postCustomRole
export def "roles post" [
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
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a custom role by key.
#
# DELETE /roles/{customRoleKey}
# operationId: deleteCustomRole
export def "roles delete" [
  customRoleKey: string
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
  let full_url = (build-url $base $"/roles/($customRoleKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one custom role by key.
#
# GET /roles/{customRoleKey}
# operationId: getCustomRole
export def "roles get" [
  customRoleKey: string
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
  let full_url = (build-url $base $"/roles/($customRoleKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a custom role by key.
#
# PATCH /roles/{customRoleKey}
# operationId: patchCustomRole
export def "roles patch" [
  customRoleKey: string
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
  let full_url = (build-url $base $"/roles/($customRoleKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all user segments in the given project.
#
# GET /segments/{projectKey}/{environmentKey}
# operationId: getUserSegments
export def "segments list" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_flags: list, _links: record, creationDate: int, description: string, excluded: list, included: list, key: string, name: string, rules: list, tags: list, unbounded: bool, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new user segment.
#
# POST /segments/{projectKey}/{environmentKey}
# operationId: postUserSegment
export def "segments post" [
  projectKey: string
  environmentKey: string
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
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user segment.
#
# DELETE /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: deleteUserSegment
export def "segments delete" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
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
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)/($userSegmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single user segment by key.
#
# GET /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: getUserSegment
export def "segments get" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
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
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)/($userSegmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform a partial update to a user segment.
#
# PATCH /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: patchUserSegment
export def "segments patch" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
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
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)/($userSegmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update targets included or excluded in a big segment
#
# POST /segments/{projectKey}/{environmentKey}/{userSegmentKey}/users
# operationId: updateBigSegmentTargets
export def "segments-users updateBigSegmentTargets" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
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
  let full_url = (build-url $base $"/segments/($projectKey)/($environmentKey)/($userSegmentKey)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expiring user targets for user segment
#
# GET /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargetsOnSegment
export def "segments-expiring-user-targets get" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($projectKey)/($userSegmentKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update, add, or delete expiring user targets on user segment
#
# PATCH /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargetsOnSegment
export def "segments-expiring-user-targets patch" [
  projectKey: string
  environmentKey: string
  userSegmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($projectKey)/($userSegmentKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of tokens in the account.
#
# GET /tokens
# operationId: getTokens
export def "tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showAll: string@bool-completer # If set to true, and the authentication access token has the "Admin" role, personal access tokens for all members will be retrieved.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _member: record, creationDate: int, customRoleIds: list, defaultApiVersion: int, inlineRole: list, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showAll" $showAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new token.
#
# POST /tokens
# operationId: postToken
export def "tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an access token by ID.
#
# DELETE /tokens/{tokenId}
# operationId: deleteToken
export def "tokens delete" [
  tokenId: string
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
  let full_url = (build-url $base $"/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single access token by ID.
#
# GET /tokens/{tokenId}
# operationId: getToken
export def "tokens get" [
  tokenId: string
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
  let full_url = (build-url $base $"/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify an access token by ID.
#
# PATCH /tokens/{tokenId}
# operationId: patchToken
export def "tokens patch" [
  tokenId: string
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
  let full_url = (build-url $base $"/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset an access token's secret key with an optional expiry time for the old key.
#
# POST /tokens/{tokenId}/reset
# operationId: resetToken
export def "tokens-reset resetToken" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiry: int # An expiration time for the old token key, expressed as a Unix epoch time in milliseconds. By default, the token will expire immediately. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($tokenId)/reset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns of the usage endpoints available.
#
# GET /usage
# operationId: getUsage
export def "usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events usage by event id and the feature flag key.
#
# GET /usage/evaluations/{envId}/{flagKey}
# operationId: getEvaluations
export def "usage-evaluations get" [
  envId: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/evaluations/($envId)/($flagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events usage endpoints.
#
# GET /usage/events
# operationId: getEvents
export def "usage-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events usage by event type.
#
# GET /usage/events/{type}
# operationId: getEvent
export def "usage-events get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/events/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get monthly active user data.
#
# GET /usage/mau
# operationId: getMAU
export def "usage-mau get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/mau")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get monthly active user data by category.
#
# GET /usage/mau/bycategory
# operationId: getMAUByCategory
export def "usage-mau-bycategory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: list<record>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/mau/bycategory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all streams.
#
# GET /usage/streams
# operationId: getStreams
export def "usage-streams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/streams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a stream endpoint and return timeseries data.
#
# GET /usage/streams/{source}
# operationId: getStream
export def "usage-streams get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/streams/($source)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a stream timeseries data by source show sdk version metadata.
#
# GET /usage/streams/{source}/bysdkversion
# operationId: getStreamBySDK
export def "usage-streams-bysdkversion get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/streams/($source)/bysdkversion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a stream timeseries data by source and show all sdk version associated.
#
# GET /usage/streams/{source}/sdkversions
# operationId: getStreamSDKVersion
export def "usage-streams-sdkversions get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/streams/($source)/sdkversions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search users in LaunchDarkly based on their last active date, or a search query. It should not be used to enumerate all users in LaunchDarkly-- use the List users API resource.
#
# GET /user-search/{projectKey}/{environmentKey}
# operationId: getSearchUsers
export def "user-search get" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search query.
  --limit: int # Pagination limit.
  --offset: int # Specifies the first item to return in the collection.
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user-search/($projectKey)/($environmentKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users in the environment. Includes the total count of users. In each page, there will be up to 'limit' users returned (default 20). This is useful for exporting all users in the system for further analysis. Paginated collections will include a next link containing a URL with the next set of elements in the collection.
#
# GET /users/{projectKey}/{environmentKey}
# operationId: getUsers
export def "users list" [
  projectKey: string
  environmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Pagination limit.
  --h: string # This parameter is required when following "next" links.
  --scrollId: string # This parameter is required when following "next" links.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "h" $h "scalar") (serialize-qp "scrollId" $scrollId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user by ID.
#
# DELETE /users/{projectKey}/{environmentKey}/{userKey}
# operationId: deleteUser
export def "users delete" [
  projectKey: string
  environmentKey: string
  userKey: string
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
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)/($userKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}
# operationId: getUser
export def "users get" [
  projectKey: string
  environmentKey: string
  userKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record<anonymous: bool, avatar: string, country: string, custom: record, email: string, firstName: string, ip: string, key: string, lastName: string, name: string, secondary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)/($userKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags
# operationId: getUserFlagSettings
export def "users-flags list" [
  projectKey: string
  environmentKey: string
  userKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)/($userKey)/flags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# operationId: getUserFlagSetting
export def "users-flags get" [
  projectKey: string
  environmentKey: string
  userKey: string
  featureFlagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _value: bool, setting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)/($userKey)/flags/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Specifically enable or disable a feature flag for a user based on their key.
#
# PUT /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# operationId: putFlagSetting
export def "users-flags put" [
  projectKey: string
  environmentKey: string
  userKey: string
  featureFlagKey: string
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
  let full_url = (build-url $base $"/users/($projectKey)/($environmentKey)/($userKey)/flags/($featureFlagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expiring dates on flags for user
#
# GET /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargetsForUser
export def "users-expiring-user-targets get" [
  projectKey: string
  environmentKey: string
  userKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($projectKey)/($userKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update, add, or delete expiring user targets for a single user on all flags
#
# PATCH /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargetsForFlags
export def "users-expiring-user-targets patch" [
  projectKey: string
  environmentKey: string
  userKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($projectKey)/($userKey)/expiring-user-targets/($environmentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a list of all webhooks.
#
# GET /webhooks
# operationId: getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, name: string, on: bool, secret: string, statements: list, tags: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook.
#
# POST /webhooks
# operationId: postWebhook
export def "webhooks post" [
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
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook by ID.
#
# DELETE /webhooks/{resourceId}
# operationId: deleteWebhook
export def "webhooks delete" [
  resourceId: string
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
  let full_url = (build-url $base $"/webhooks/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook by ID.
#
# GET /webhooks/{resourceId}
# operationId: getWebhook
export def "webhooks get" [
  resourceId: string
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
  let full_url = (build-url $base $"/webhooks/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a webhook by ID.
#
# PATCH /webhooks/{resourceId}
# operationId: patchWebhook
export def "webhooks patch" [
  resourceId: string
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
  let full_url = (build-url $base $"/webhooks/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
