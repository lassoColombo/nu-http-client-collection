# Auto-generated client for Anchore Engine API Server v0.1.20
# Source: https://raw.githubusercontent.com/anchore/anchore-engine/master/anchore_engine/services/apiext/swagger/swagger.yaml
# Auth: --token flag or $env.ANCHORE_ENGINE_API_SERVER_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ANCHORE_ENGINE_API_SERVER_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost" "https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def image-status-completer [] { ["active" "all" "deleting"] }
def analysis-status-completer [] { ["analysis_failed" "analyzed" "analyzing" "not_analyzed"] }
def severity-completer [] { ["Critical" "High" "Low" "Medium" "Negligible" "Unknown"] }
def state-completer [] { ["deleting" "disabled" "enabled"] }
def state-completer-1 [] { ["disabled" "enabled"] }
def type-completer [] { ["password"] }
def credential-type-completer [] { ["password"] }
def transition-completer [] { ["archive" "delete"] }
def notification-type-completer [] { ["analysis_update" "policy_eval" "tag_update" "vuln_update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api ping" } } | get name | first)
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

# Simple status check
#
# GET /
# operationId: ping
export def "api ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Health check, returns 200 and no body if service is running
#
# GET /health
# operationId: health_check
export def "health check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the version object for the service, including db schema version info
#
# GET /version
# operationId: version_check
export def "version check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service: record<version: string>, api: record<version: string>, db: record<schema_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List policies
#
# GET /policies
# operationId: list_policies
export def "policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_updated: string, policyId: string, active: bool, userId: string, policy_source: string, policybundle: record<id: string, name: string, comment: string, version: string, whitelists: list, policies: list, mappings: list, whitelisted_images: list, blacklisted_images: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/policies" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new policy
#
# POST /policies
# operationId: add_policy
# --whitelists item shape: {id: string, name?: string, version: string, comment?: string, items?: list}
# --policies item shape: {id: string, name?: string, comment?: string, version: string, rules?: list}
# --mappings item shape: {id?: string, name: string, whitelist_ids?: list, policy_id?: string, policy_ids?: list, registry: string, repository: string, image: record}
# --whitelisted_images item shape: {id?: string, name: string, registry: string, repository: string, image: record}
# --blacklisted_images item shape: {id?: string, name: string, registry: string, repository: string, image: record}
export def "policies policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  id: string # Id of the bundle
  --name: string # Human readable name for the bundle
  --comment: string # Description of the bundle, human readable
  version: string # Version id for this bundle format
  --whitelists: list # Whitelists which define which policy matches to disregard explicitly in the final policy decision — item shape: {id: string, name?: string, version: string, comment?: string, items?: list}
  policies: list # Policies which define the go/stop/warn status of an image using rule matches on image properties — item shape: {id: string, name?: string, comment?: string, version: string, rules?: list}
  mappings: list # Mapping rules for defining which policy and whitelist(s) to apply to an image based on a match of the image tag or id. Evaluated in order. — item shape: {id?: string, name: string, whitelist_ids?: list, policy_id?: string, policy_ids?: list, registry: string, repository: string, image: record}
  --whitelisted-images: list # List of mapping rules that define which images should always be passed (unless also on the blacklist), regardless of policy result. — item shape: {id?: string, name: string, registry: string, repository: string, image: record}
  --blacklisted-images: list # List of mapping rules that define which images should always result in a STOP/FAIL policy result regardless of policy content or presence in whitelisted_images — item shape: {id?: string, name: string, registry: string, repository: string, image: record}
]: any -> record<created_at: string, last_updated: string, policyId: string, active: bool, userId: string, policy_source: string, policybundle: record<id: string, name: string, comment: string, version: string, whitelists: list<record>, policies: list<record>, mappings: list<record>, whitelisted_images: list<record>, blacklisted_images: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies")
  let body = {id: $id, name: $name, comment: $comment, version: $version, whitelists: $whitelists, policies: $policies, mappings: $mappings, whitelisted_images: $whitelisted_images, blacklisted_images: $blacklisted_images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get specific policy
#
# GET /policies/{policyId}
# operationId: get_policy
export def "policies policy-by-policyId" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_updated: string, policyId: string, active: bool, userId: string, policy_source: string, policybundle: record<id: string, name: string, comment: string, version: string, whitelists: list, policies: list, mappings: list, whitelisted_images: list, blacklisted_images: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policies/($policyId)" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update policy
#
# PUT /policies/{policyId}
# operationId: update_policy
# --policybundle shape: {id: string, name?: string, comment?: string, version: string, whitelists?: list, policies: list, mappings: list, whitelisted_images?: list, blacklisted_images?: list}
export def "policies policy-by-policyId-1" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Mark policy as active
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --created-at: string # format: date-time
  --last-updated: string # format: date-time
  --body-policyId: string # The bundle's identifier
  --active: oneof<nothing, bool> # True if the bundle is currently defined to be used automatically
  --userId: string # UserId of the user that owns the bundle
  --policy-source: string # Source location of where the policy bundle originated
  --policybundle: record # A bundle containing a set of policies, whitelists, and rules for mapping them to specific images — shape: {id: string, name?: string, comment?: string, version: string, whitelists?: list, policies: list, mappings: list, whitelisted_images?: list, blacklisted_images?: list}
]: any -> table<created_at: string, last_updated: string, policyId: string, active: bool, userId: string, policy_source: string, policybundle: record<id: string, name: string, comment: string, version: string, whitelists: list, policies: list, mappings: list, whitelisted_images: list, blacklisted_images: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policies/($policyId)" $qp)
  let body = {created_at: $created_at, last_updated: $last_updated, policyId: $body_policyId, active: $active, userId: $userId, policy_source: $policy_source, policybundle: $policybundle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete policy
#
# DELETE /policies/{policyId}
# operationId: delete_policy
export def "policies policy-by-policyId-2" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/policies/($policyId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all subscriptions
#
# GET /subscriptions
# operationId: list_subscriptions
export def "subscriptions subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-key: string # filter only subscriptions matching key
  --subscription-type: string # filter only subscriptions matching type
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<subscription_key: string, subscription_type: string, subscription_value: string, userId: string, active: bool, subscription_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_key" $subscription_key "scalar") (serialize-qp "subscription_type" $subscription_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a subscription of a specific type
#
# POST /subscriptions
# operationId: add_subscription
export def "subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --subscription-key: string
  --subscription-value: string
  --subscription-type: string
]: any -> table<subscription_key: string, subscription_type: string, subscription_value: string, userId: string, active: bool, subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let body = {subscription_key: $subscription_key, subscription_value: $subscription_value, subscription_type: $subscription_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific subscription set
#
# GET /subscriptions/{subscriptionId}
# operationId: get_subscription
export def "subscriptions subscription-by-subscriptionId" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<subscription_key: string, subscription_type: string, subscription_value: string, userId: string, active: bool, subscription_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing and specific subscription
#
# PUT /subscriptions/{subscriptionId}
# operationId: update_subscription
export def "subscriptions subscription-by-subscriptionId-1" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --subscription-value: string # The new subscription value, e.g. the new tag to be subscribed to
  --active: oneof<nothing, bool> # Toggle the subscription processing on or off
]: any -> table<subscription_key: string, subscription_type: string, subscription_value: string, userId: string, active: bool, subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)")
  let body = {subscription_value: $subscription_value, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete subscriptions of a specific type
#
# DELETE /subscriptions/{subscriptionId}
# operationId: delete_subscription
export def "subscriptions subscription-by-subscriptionId-2" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all visible image digests and tags
#
# GET /summaries/imagetags
# operationId: list_imagetags
export def "summaries-imagetags imagetags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-status: list # Filter images in one or more states such as active, deleting. Defaults to active images only if unspecified (default: [active])
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<imageDigest: string, parentDigest: string, imageId: string, analysis_status: string, fulltag: string, created_at: int, analyzed_at: int, tag_detected_at: int, image_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_status" $image_status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/summaries/imagetags" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a new image for analysis by the engine
#
# POST /images
# operationId: add_image
# --source shape: {tag?: record, digest?: record, archive?: record, import?: record}
export def "images image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Override any existing entry in the system
  --autosubscribe: oneof<nothing, bool> # Instruct engine to automatically begin watching the added tag for updates from registry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --dockerfile: string # Base64 encoded content of the dockerfile for the image, if available. Deprecated in favor of the 'source' field.
  --digest: string # A digest string for an image, maybe a pull string or just a digest. e.g. nginx@sha256:123 or sha256:abc123. If a pull string, it must have same regisry/repo as the tag field. Deprecated in favor of the 'source' field
  --tag: string # Full pullable tag reference for image. e.g. docker.io/nginx:latest. Deprecated in favor of the 'source' field
  --created-at: string # Optional override of the image creation time, only honored when both tag and digest are also supplied  e.g. 2018-10-17T18:14:00Z. Deprecated in favor of the 'source' field (format: date-time)
  --image-type: string # Optional. The type of image this is adding, defaults to "docker". This can be ommitted until multiple image types are supported.
  --annotations: record # Annotations to be associated with the added image in key/value form
  --body-source: record # A set of analysis source types. Only one may be set in any given request. — shape: {tag?: record, digest?: record, archive?: record, import?: record}
]: any -> table<image_content: record, image_detail: list<record>, last_updated: string, created_at: string, imageDigest: string, userId: string, annotations: record, image_status: string, analysis_status: string, record_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "autosubscribe" $autosubscribe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let body = {dockerfile: $dockerfile, digest: $digest, tag: $tag, created_at: $created_at, image_type: $image_type, annotations: $annotations, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all visible images
#
# GET /images
# operationId: list_images
export def "images images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --history: oneof<nothing, bool> # Include image history in the response
  --fulltag: string # Full docker-pull string to filter results by (e.g. docker.io/library/nginx:latest, or myhost.com:5000/testimages:v1.1.1)
  --image-status: string@image-status-completer # Filter by image_status value on the record. Default if omitted is 'active'. (default: active)
  --analysis-status: string@analysis-status-completer # Filter by analysis_status value on the record.
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<image_content: record, image_detail: list<record>, last_updated: string, created_at: string, imageDigest: string, userId: string, annotations: record, image_status: string, analysis_status: string, record_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "fulltag" $fulltag "scalar") (serialize-qp "image_status" $image_status "scalar") (serialize-qp "analysis_status" $analysis_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk mark images for deletion
#
# DELETE /images
# operationId: delete_images_async
export def "images async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --imageDigests: list
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<digest: string, status: string, detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageDigests" $imageDigests "csv") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import an anchore image tar.gz archive file. This is a deprecated API replaced by the "/imports/images" route
#
# POST /import/images
# operationId: import_image_archive
export def "import-images archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  archive_file: path # anchore image tar archive.
]: any -> table<image_content: record, image_detail: list<record>, last_updated: string, created_at: string, imageDigest: string, userId: string, annotations: record, image_status: string, analysis_status: string, record_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/import/images")
  let body = {archive_file: $archive_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($archive_file | is-not-empty) { $body | upsert archive_file (open -r $archive_file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get image metadata
#
# GET /images/{imageDigest}
# operationId: get_image
export def "images image-by-imageDigest" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<image_content: record, image_detail: list<record>, last_updated: string, created_at: string, imageDigest: string, userId: string, annotations: record, image_status: string, analysis_status: string, record_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an image analysis
#
# DELETE /images/{imageDigest}
# operationId: delete_image
export def "images image-by-imageDigest-1" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<digest: string, status: string, detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($imageDigest)" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lookup image by docker imageId
#
# GET /images/by_id/{imageId}
# operationId: get_image_by_imageId
export def "images-by-id imageId-by-imageId" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<image_content: record, image_detail: list<record>, last_updated: string, created_at: string, imageDigest: string, userId: string, annotations: record, image_status: string, analysis_status: string, record_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete image by docker imageId
#
# DELETE /images/by_id/{imageId}
# operationId: delete_image_by_imageId
export def "images-by-id imageId-by-imageId-1" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<digest: string, status: string, detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/by_id/($imageId)" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check policy evaluation status for image
#
# GET /images/{imageDigest}/check
# operationId: get_image_policy_check
export def "images-check check" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policyId: string
  --tag: string
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --interactive: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyId" $policyId "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "history" $history "scalar") (serialize-qp "interactive" $interactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($imageDigest)/check" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check policy evaluation status for image
#
# GET /images/by_id/{imageId}/check
# operationId: get_image_policy_check_by_imageId
export def "images-by-id-check imageId" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policyId: string
  --tag: string
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyId" $policyId "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "history" $history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/by_id/($imageId)/check" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vulnerability types
#
# GET /images/{imageDigest}/vuln
# operationId: get_image_vulnerability_types
export def "images-vuln types" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/vuln")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vulnerabilities by type
#
# GET /images/{imageDigest}/vuln/{vtype}
# operationId: get_image_vulnerabilities_by_type
export def "images-vuln type" [
  imageDigest: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-refresh: oneof<nothing, bool>
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data. When set to true, it will filter out all vulnerabilities where `will_not_fix` is False. If false all vulnerabilities are returned regardless of `will_not_fix`
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, vulnerability_type: string, vulnerabilities: table<vuln: string, fix: string, severity: string, package: string, url: string, feed: string, feed_group: string, package_name: string, package_version: string, package_type: string, package_cpe: string, package_path: string, will_not_fix: bool, nvd_data: list, vendor_data: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_refresh" $force_refresh "scalar") (serialize-qp "vendor_only" $vendor_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($imageDigest)/vuln/($vtype)" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vulnerability types
#
# GET /images/by_id/{imageId}/vuln
# operationId: get_image_vulnerability_types_by_imageId
export def "images-by-id-vuln list" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/vuln")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vulnerabilities by type
#
# GET /images/by_id/{imageId}/vuln/{vtype}
# operationId: get_image_vulnerabilities_by_type_imageId
export def "images-by-id-vuln imageId" [
  imageId: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, vulnerability_type: string, vulnerabilities: table<vuln: string, fix: string, severity: string, package: string, url: string, feed: string, feed_group: string, package_name: string, package_version: string, package_type: string, package_cpe: string, package_path: string, will_not_fix: bool, nvd_data: list, vendor_data: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/vuln/($vtype)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List image content types
#
# GET /images/{imageDigest}/content
# operationId: list_image_content
export def "images-content content" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/content")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List image content types
#
# GET /images/by_id/{imageId}/content
# operationId: list_image_content_by_imageid
export def "images-by-id-content imageid" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/content")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type
#
# GET /images/{imageDigest}/content/{ctype}
# operationId: get_image_content_by_type
export def "images-content type" [
  imageDigest: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<package: string, version: string, size: string, type: string, origin: string, license: string, licenses: list, location: string, cpes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/content/($ctype)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type files
#
# GET /images/{imageDigest}/content/files
# operationId: get_image_content_by_type_files
export def "images-content-files files" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/content/files")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type java
#
# GET /images/{imageDigest}/content/java
# operationId: get_image_content_by_type_javapackage
export def "images-content-java javapackage" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<package: string, implementation_version: string, specification_version: string, maven_version: string, location: string, type: string, origin: string, cpes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/content/java")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type malware
#
# GET /images/{imageDigest}/content/malware
# operationId: get_image_content_by_type_malware
export def "images-content-malware malware" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<enabled: bool, scanner: string, metadata: record, findings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/content/malware")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type
#
# GET /images/by_id/{imageId}/content/{ctype}
# operationId: get_image_content_by_type_imageId
export def "images-by-id-content imageId" [
  imageId: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<package: string, version: string, size: string, type: string, origin: string, license: string, licenses: list, location: string, cpes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/content/($ctype)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type files
#
# GET /images/by_id/{imageId}/content/files
# operationId: get_image_content_by_type_imageId_files
export def "images-by-id-content-files files" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/content/files")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of an image by type java
#
# GET /images/by_id/{imageId}/content/java
# operationId: get_image_content_by_type_imageId_javapackage
export def "images-by-id-content-java javapackage" [
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, content_type: string, content: table<package: string, implementation_version: string, specification_version: string, maven_version: string, location: string, type: string, origin: string, cpes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/by_id/($imageId)/content/java")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/retrieved_files
# operationId: list_retrieved_files
export def "images-artifacts-retrieved-files files" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<path: string, b64_content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/artifacts/retrieved_files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/file_content_search
# operationId: list_file_content_search_results
export def "images-artifacts-file-content-search results" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<path: string, matches: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/artifacts/file_content_search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/secret_search
# operationId: list_secret_search_results
export def "images-artifacts-secret-search results" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<path: string, matches: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/artifacts/secret_search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List image metadata types
#
# GET /images/{imageDigest}/metadata
# operationId: list_image_metadata
export def "images-metadata metadata" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/metadata")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get image sbom in the native Anchore format
#
# GET /images/{imageDigest}/sboms/native
# operationId: get_image_sbom_native
export def "images-sboms-native native" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/sboms/native")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/gzip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the metadata of an image by type
#
# GET /images/{imageDigest}/metadata/{mtype}
# operationId: get_image_metadata_by_type
export def "images-metadata type" [
  imageDigest: string
  mtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, metadata_type: string, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($imageDigest)/metadata/($mtype)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add repository to watch
#
# POST /repositories
# operationId: add_repository
export def "repositories repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository: string # full repository to add e.g. docker.io/library/alpine
  --autosubscribe: oneof<nothing, bool> # flag to enable/disable auto tag_update activation when new images from a repo are added
  --dryrun: oneof<nothing, bool> # flag to return tags in the repository without actually watching the repository, default is false
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<subscription_key: string, subscription_type: string, subscription_value: string, userId: string, active: bool, subscription_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repository" $repository "scalar") (serialize-qp "autosubscribe" $autosubscribe "scalar") (serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List configured registries
#
# GET /registries
# operationId: list_registries
export def "registries registries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_upated: string, registry_user: string, registry_type: string, userId: string, registry: string, registry_name: string, registry_verify: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new registry
#
# POST /registries
# operationId: create_registry
export def "registries registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry add time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --registry-user: string # Username portion of credential to use for this registry
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository)
  --registry-name: string # human readable name associated with registry record
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> table<created_at: string, last_upated: string, registry_user: string, registry_type: string, userId: string, registry: string, registry_name: string, registry_verify: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate" $validate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registries" $qp)
  let body = {registry_user: $registry_user, registry_pass: $registry_pass, registry_type: $registry_type, registry: $registry, registry_name: $registry_name, registry_verify: $registry_verify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific registry configuration
#
# GET /registries/{registry}
# operationId: get_registry
export def "registries registry-by-registry" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_upated: string, registry_user: string, registry_type: string, userId: string, registry: string, registry_name: string, registry_verify: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($registry)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/replace a registry configuration
#
# PUT /registries/{registry}
# operationId: update_registry
export def "registries registry-by-registry-1" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry update time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --registry-user: string # Username portion of credential to use for this registry
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --body-registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository)
  --registry-name: string # human readable name associated with registry record
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> table<created_at: string, last_upated: string, registry_user: string, registry_type: string, userId: string, registry: string, registry_name: string, registry_verify: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate" $validate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/registries/($registry)" $qp)
  let body = {registry_user: $registry_user, registry_pass: $registry_pass, registry_type: $registry_type, registry: $body_registry, registry_name: $registry_name, registry_verify: $registry_verify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a registry configuration
#
# DELETE /registries/{registry}
# operationId: delete_registry
export def "registries registry-by-registry-2" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($registry)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service status
#
# GET /status
# operationId: get_status
export def "status status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool, busy: bool, up: bool, message: string, version: string, db_version: string, detail: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# System status
#
# GET /system
# operationId: get_service_detail
export def "system detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service_states: table<hostid: string, servicename: string, base_url: string, status_message: string, service_detail: record, status: bool, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# list feeds operations and information
#
# GET /system/feeds
# operationId: get_system_feeds
export def "system-feeds feeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, created_at: string, updated_at: string, groups: list<record>, last_full_sync: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/feeds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# trigger feeds operations
#
# POST /system/feeds
# operationId: post_system_feeds
export def "system-feeds feeds-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flush: oneof<nothing, bool> # instruct system to flush existing data feeds records from anchore-engine
  --sync: oneof<nothing, bool> # instruct system to re-sync data feeds
]: nothing -> table<feed: string, status: string, total_time_seconds: float, groups: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flush" $flush "scalar") (serialize-qp "sync" $sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable the feed so that it does not sync on subsequent sync operations
#
# PUT /system/feeds/{feed}
# operationId: toggle_feed_enabled
export def "system-feeds enabled-by-feed" [
  feed: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
]: nothing -> record<name: string, created_at: string, updated_at: string, groups: table<name: string, created_at: string, last_sync: string, record_count: int>, last_full_sync: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/system/feeds/($feed)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the groups and data for the feed and disable the feed itself
#
# DELETE /system/feeds/{feed}
# operationId: delete_feed
export def "system-feeds feed" [
  feed: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/feeds/($feed)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a specific group within a feed to not sync
#
# PUT /system/feeds/{feed}/{group}
# operationId: toggle_group_enabled
export def "system-feeds enabled-by-feed-group" [
  feed: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
]: nothing -> table<name: string, created_at: string, updated_at: string, groups: list<record>, last_full_sync: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/system/feeds/($feed)/($group)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the group data and disable the group itself
#
# DELETE /system/feeds/{feed}/{group}
# operationId: delete_feed_group
export def "system-feeds group" [
  feed: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/feeds/($feed)/($group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List system services
#
# GET /system/services
# operationId: list_services
export def "system-services services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<hostid: string, servicename: string, base_url: string, status_message: string, service_detail: record<available: bool, busy: bool, up: bool, message: string, version: string, db_version: string, detail: record>, status: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service configuration and state
#
# GET /system/services/{servicename}
# operationId: get_services_by_name
export def "system-services name" [
  servicename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<hostid: string, servicename: string, base_url: string, status_message: string, service_detail: record<available: bool, busy: bool, up: bool, message: string, version: string, db_version: string, detail: record>, status: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/services/($servicename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get service config for a specific host
#
# GET /system/services/{servicename}/{hostid}
# operationId: get_services_by_name_and_host
export def "system-services host" [
  servicename: string
  hostid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<hostid: string, servicename: string, base_url: string, status_message: string, service_detail: record<available: bool, busy: bool, up: bool, message: string, version: string, db_version: string, detail: record>, status: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/services/($servicename)/($hostid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the service config
#
# DELETE /system/services/{servicename}/{hostid}
# operationId: delete_service
export def "system-services service" [
  servicename: string
  hostid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/services/($servicename)/($hostid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describe the policy language spec implemented by this service.
#
# GET /system/policy_spec
# operationId: describe_policy
export def "system-policy-spec policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, description: string, state: string, superceded_by: string, triggers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/policy_spec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describe anchore engine error codes.
#
# GET /system/error_codes
# operationId: describe_error_codes
export def "system-error-codes codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/error_codes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Event Types
#
# GET /event_types
# operationId: list_event_types
export def "event-types types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, description: string, subcategories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Events
#
# GET /events
# operationId: list_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-servicename: string # Filter events by the originating service
  --source-hostid: string # Filter events by the originating host ID
  --event-type: string # Filter events by a prefix match on the event type (e.g. "user.image.")
  --resource-type: string # Filter events by the type of resource - tag, imageDigest, repository etc
  --resource-id: string # Filter events by the id of the resource
  --level: string # Filter events by the level - INFO or ERROR
  --since: string # Return events that occurred after the timestamp
  --before: string # Return events that occurred before the timestamp
  --page: int # Pagination controls - return the nth page of results. Defaults to first page if left empty (default: 1)
  --limit: int # Number of events in the result set. Defaults to 100 if left empty (default: 100)
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<results: table<generated_uuid: string, created_at: string, event: record>, next_page: bool, item_count: int, page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_servicename" $source_servicename "scalar") (serialize-qp "source_hostid" $source_hostid "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "level" $level "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Events
#
# DELETE /events
# operationId: delete_events
export def "events events-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Delete events that occurred before the timestamp
  --since: string # Delete events that occurred after the timestamp
  --level: string # Delete events that match the level - INFO or ERROR
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Event
#
# GET /events/{eventId}
# operationId: get_event
export def "events event-by-eventId" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<generated_uuid: string, created_at: string, event: record<source: record<servicename: string, hostid: string, base_url: string, request_id: string>, resource: record<user_id: string, id: string, type: string>, type: string, category: string, level: string, message: string, details: record, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($eventId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Event
#
# DELETE /events/{eventId}
# operationId: delete_event
export def "events event-by-eventId-1" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($eventId)")
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List images vulnerable to the specific vulnerability ID.
#
# GET /query/images/by_vulnerability
# operationId: query_images_by_vulnerability
export def "query-images-by-vulnerability vulnerability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --vulnerability-id: string # The ID of the vulnerability to search for within all images stored in anchore-engine (e.g. CVE-1999-0001)
  --namespace: string # Filter results to images within the given vulnerability namespace (e.g. debian:8, ubuntu:14.04)
  --affected-package: string # Filter results to images with vulnable packages with the given package name (e.g. libssl)
  --severity: string@severity-completer # Filter results to vulnerable package/vulnerability with the given severity
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data (default: true)
  --page: int # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<page: string, next_page: string, returned_count: int, images: table<image: record, affected_packages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vulnerability_id" $vulnerability_id "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "affected_package" $affected_package "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "vendor_only" $vendor_only "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query/images/by_vulnerability" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of images containing given package
#
# GET /query/images/by_package
# operationId: query_images_by_package
export def "query-images-by-package package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of package to search for (e.g. sed)
  --package-type: string # Type of package to filter on (e.g. dpkg)
  --version: string # Version of named package to filter on (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<page: string, next_page: string, returned_count: int, images: table<image: record, packages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "package_type" $package_type "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query/images/by_package" $qp)
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Listing information about given vulnerability
#
# GET /query/vulnerabilities
# operationId: query_vulnerabilities
export def "query-vulnerabilities vulnerabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # The ID of the vulnerability (e.g. CVE-1999-0001)
  --affected-package: string # Filter results by specified package name (e.g. sed)
  --affected-package-version: string # Filter results by specified package version (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1 (default: 1)
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --namespace: list # Namespace(s) to filter vulnerability records by
]: nothing -> record<page: string, next_page: string, returned_count: int, vulnerabilities: table<id: string, namespace: string, affected_packages: list, severity: string, link: string, nvd_data: list, vendor_data: list, description: string, references: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "affected_package" $affected_package "scalar") (serialize-qp "affected_package_version" $affected_package_version "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "namespace" $namespace "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/query/vulnerabilities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user summaries. Only available to the system admin user.
#
# GET /accounts
# operationId: list_accounts
export def "accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Filter accounts by state
]: nothing -> table<name: string, type: string, state: string, email: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user. Only avaialble to admin user.
#
# POST /accounts
# operationId: create_account
export def "accounts account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The account name to use. This will identify the account and must be globally unique in the system.
  --email: string # An optional email to associate with the account for contact purposes
]: any -> record<name: string, type: string, state: string, email: string, created_at: string, last_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {name: $name, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get info about an user. Only available to admin user. Uses the main user Id, not a username.
#
# GET /accounts/{accountname}
# operationId: get_account
export def "accounts account-by-accountname" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, type: string, state: string, email: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the specified account, only allowed if the account is in the disabled state. All users will be deleted along with the account and all resources will be garbage collected
#
# DELETE /accounts/{accountname}
# operationId: delete_account
export def "accounts account-by-accountname-1" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the state of an account to either enabled or disabled. For deletion use the DELETE route
#
# PUT /accounts/{accountname}/state
# operationId: update_account_state
export def "accounts-state state" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The status of the account
]: any -> record<state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/state")
  let body = {state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List accounts for the user
#
# GET /accounts/{accountname}/users
# operationId: list_users
export def "accounts-users users" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /accounts/{accountname}/users
# operationId: create_user
export def "accounts-users user-by-accountname" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string # The username to create
  password: string # The initial password for the user, must be at least 6 characters, up to 128
]: any -> record<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a specific user credential by username of the credential. Cannot be the credential used to authenticate the request.
#
# DELETE /accounts/{accountname}/users/{username}
# operationId: delete_user
export def "accounts-users user-by-accountname-username" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific user in the specified account
#
# GET /accounts/{accountname}/users/{username}
# operationId: get_account_user
export def "accounts-users user-by-accountname-username-1" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current credential summary
#
# GET /accounts/{accountname}/users/{username}/credentials
# operationId: list_user_credentials
export def "accounts-users-credentials credentials" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<type: string, value: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users/($username)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# add/replace credential
#
# POST /accounts/{accountname}/users/{username}/credentials
# operationId: create_user_credential
export def "accounts-users-credentials credential-by-accountname-username" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
  --created-at: string # The timestamp of creation of the credential
]: any -> record<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($accountname)/users/($username)/credentials")
  let body = {type: $type, value: $value, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a credential by type
#
# DELETE /accounts/{accountname}/users/{username}/credentials
# operationId: delete_user_credential
export def "accounts-users-credentials credential-by-accountname-username-1" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --credential-type: string@credential-type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "credential_type" $credential_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountname)/users/($username)/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the account for the authenticated user
#
# GET /account
# operationId: get_users_account
export def "account account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, type: string, state: string, email: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List authenticated user info
#
# GET /user
# operationId: get_user
export def "user user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current credential summary
#
# GET /user/credentials
# operationId: get_credentials
export def "user-credentials credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<type: string, value: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# add/replace credential
#
# POST /user/credentials
# operationId: add_credential
export def "user-credentials credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
  --created-at: string # The timestamp of creation of the credential
]: any -> record<username: string, type: string, source: string, created_at: string, last_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/credentials")
  let body = {type: $type, value: $value, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /archives
#
# operationId: list_archives
export def "archives archives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<images: record<total_image_count: int, total_tag_count: int, total_data_bytes: int, last_updated: string>, rules: record<count: int, last_updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /archives/rules
#
# operationId: list_analysis_archive_rules
export def "archives-rules rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --system-global: oneof<nothing, bool> # If true include system global rules (owned by admin) even for non-admin users. Defaults to true if not set. Can be set to false to exclude globals
]: nothing -> table<selector: record<registry: string, repository: string, tag: string>, rule_id: string, tag_versions_newer: int, analysis_age_days: int, transition: string, system_global: bool, created_at: string, last_updated: string, exclude: record<selector: record, expiration_days: int>, max_images_per_account: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "system_global" $system_global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archives/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /archives/rules
#
# operationId: create_analysis_archive_rule
# --selector shape: {registry?: string, repository?: string, tag?: string}
# --exclude shape: {selector?: record, expiration_days?: int}
export def "archives-rules rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --selector: record # A set of selection criteria to match an image by a tagged pullstring based on its components, with regex support in each field — shape: {registry?: string, repository?: string, tag?: string}
  --rule-id: string # Unique identifier for archive rule
  --tag-versions-newer: int # Number of images mapped to the tag that are newer
  --analysis-age-days: int # Matches if the analysis is strictly older than this number of days
  transition: string@transition-completer # The type of transition to make. If "archive", then archive an image from the working set and remove it from the working set. If "delete", then match against archived images and delete from the archive if match.
  --system-global: oneof<nothing, bool> # True if the rule applies to all accounts in the system. This is only available to admin users to update/modify, but all users with permission to list rules can see them
  --created-at: string # format: date-time
  --last-updated: string # format: date-time
  --exclude: record # Which Images to exclude from auto-archiving logic — shape: {selector?: record, expiration_days?: int}
  --max-images-per-account: int # This is the maximum number of image analyses an account can have. Can only be set on system_global rules
]: any -> record<selector: record<registry: string, repository: string, tag: string>, rule_id: string, tag_versions_newer: int, analysis_age_days: int, transition: string, system_global: bool, created_at: string, last_updated: string, exclude: record<selector: record<registry: string, repository: string, tag: string>, expiration_days: int>, max_images_per_account: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/rules")
  let body = {selector: $selector, rule_id: $rule_id, tag_versions_newer: $tag_versions_newer, analysis_age_days: $analysis_age_days, transition: $transition, system_global: $system_global, created_at: $created_at, last_updated: $last_updated, exclude: $exclude, max_images_per_account: $max_images_per_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /archives/rules/{ruleId}
#
# operationId: get_analysis_archive_rule
export def "archives-rules rule-by-ruleId" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<selector: record<registry: string, repository: string, tag: string>, rule_id: string, tag_versions_newer: int, analysis_age_days: int, transition: string, system_global: bool, created_at: string, last_updated: string, exclude: record<selector: record<registry: string, repository: string, tag: string>, expiration_days: int>, max_images_per_account: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/archives/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /archives/rules/{ruleId}
#
# operationId: delete_analysis_archive_rule
export def "archives-rules rule-by-ruleId-1" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/archives/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /archives/images
#
# operationId: list_analysis_archive
export def "archives-images archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<imageDigest: string, parentDigest: string, annotations: record, status: string, image_detail: list<record>, created_at: string, last_updated: string, analyzed_at: string, archive_size_bytes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /archives/images
#
# operationId: archive_image_analysis
export def "archives-images analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<digest: string, status: string, detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/images")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the archive metadata record identifying the image and tags for the analysis in the archive.
#
# GET /archives/images/{imageDigest}
# operationId: get_archived_analysis
export def "archives-images analysis-by-imageDigest" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imageDigest: string, parentDigest: string, annotations: record, status: string, image_detail: table<pullstring: string, registry: string, repository: string, tag: string, detected_at: string>, created_at: string, last_updated: string, analyzed_at: string, archive_size_bytes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/archives/images/($imageDigest)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs a synchronous archive deletion
#
# DELETE /archives/images/{imageDigest}
# operationId: delete_archived_analysis
export def "archives-images analysis-by-imageDigest-1" [
  imageDigest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/archives/images/($imageDigest)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a jwt token for subsequent operations, this request is authenticated with normal HTTP auth
#
# POST /oauth/token
# operationId: get_oauth_token
export def "oauth-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grant-type: string # OAuth Grant type for token
  --username: string # User to assign OAuth token to
  --password: string # Password for corresponding user
  --client-id: string # The type of client used for the OAuth token
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {grant_type: $grant_type, username: $username, password: $password, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Adds the capabilities to test a webhook delivery for the given notification type
#
# POST /system/webhooks/{webhook_type}/test
# operationId: test_webhook
export def "system-webhooks-test webhook" [
  webhook_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-type: string@notification-type-completer # What kind of Notification to send (default: tag_update)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification_type" $notification_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/system/webhooks/($webhook_type)/test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images
# operationId: create_operation
export def "imports-images operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uuid: string, status: string, expires_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists in-progress imports
#
# GET /imports/images
# operationId: list_operations
export def "imports-images operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<uuid: string, status: string, expires_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detail on a single import
#
# GET /imports/images/{operation_id}
# operationId: get_operation
export def "imports-images operation-by-operation_id" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uuid: string, status: string, expires_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invalidate operation ID so it can be garbage collected
#
# DELETE /imports/images/{operation_id}
# operationId: invalidate_operation
export def "imports-images operation-by-operation_id-1" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uuid: string, status: string, expires_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List uploaded package manifests
#
# GET /imports/images/{operation_id}/packages
# operationId: list_import_packages
export def "imports-images-packages packages-by-operation_id" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/packages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/packages
# operationId: import_image_packages
# --artifacts item shape: {id?: string, name: string, version: string, type: string, foundBy?: string, locations: list, licenses: list, language: string, cpes: list, purl?: string, metadataType: string, metadata?: record}
# --source shape: {type: string, target: any}
# --distro shape: {name: string, version: string, idLike: string}
# --descriptor shape: {name: string, version: string}
# --schema shape: {version: string, url: string}
# --artifactRelationships item shape: {parent: string, child: string, type: string, metadata?: record}
export def "imports-images-packages packages-by-operation_id-1" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  artifacts: list # item shape: {id?: string, name: string, version: string, type: string, foundBy?: string, locations: list, licenses: list, language: string, cpes: list, purl?: string, metadataType: string, metadata?: record}
  --body-source: record # shape: {type: string, target: any}
  distro: record # shape: {name: string, version: string, idLike: string}
  --descriptor: record # shape: {name: string, version: string}
  --schema: record # shape: {version: string, url: string}
  --artifactRelationships: list # item shape: {parent: string, child: string, type: string, metadata?: record}
]: any -> record<digest: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/packages")
  let body = {artifacts: $artifacts, source: $body_source, distro: $distro, descriptor: $descriptor, schema: $schema, artifactRelationships: $artifactRelationships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List uploaded dockerfiles
#
# GET /imports/images/{operation_id}/dockerfile
# operationId: list_import_dockerfiles
export def "imports-images-dockerfile dockerfiles" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/dockerfile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/dockerfile
# operationId: import_image_dockerfile
export def "imports-images-dockerfile dockerfile" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<digest: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/dockerfile")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List uploaded image manifests
#
# GET /imports/images/{operation_id}/manifest
# operationId: list_import_image_manifests
export def "imports-images-manifest manifests" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/manifest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a docker or OCI distribution manifest to associate with the image
#
# POST /imports/images/{operation_id}/manifest
# operationId: import_image_manifest
export def "imports-images-manifest manifest" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<digest: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/manifest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List uploaded parent manifests (manifest lists for a tag)
#
# GET /imports/images/{operation_id}/parent_manifest
# operationId: list_import_parent_manifests
export def "imports-images-parent-manifest manifests" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/parent_manifest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a docker or OCI distribution manifest list to associate with the image
#
# POST /imports/images/{operation_id}/parent_manifest
# operationId: import_image_parent_manifest
export def "imports-images-parent-manifest manifest" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<digest: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/parent_manifest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List uploaded image configs
#
# GET /imports/images/{operation_id}/image_config
# operationId: list_import_image_configs
export def "imports-images-image-config configs" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/image_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a docker or OCI image config to associate with the image
#
# POST /imports/images/{operation_id}/image_config
# operationId: import_image_config
export def "imports-images-image-config config" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<digest: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/images/($operation_id)/image_config")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
