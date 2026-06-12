# Auto-generated client for Runscope API v1.0.0
# Source: https://api.apis.guru/v2/specs/runscope.com/1.0.0/swagger.json
# Auth: --token flag or $env.RUNSCOPE_API_TOKEN

const BASE_URL = "https://api.runscope.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RUNSCOPE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.runscope.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Account Resource
#
# GET /account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<email: string, id: string, name: string, teams: list<record>>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of buckets.
#
# GET /buckets
export def "buckets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record, tests_url: string, trigger_url: string, verify_ssl: bool>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new bucket
#
# POST /buckets
export def "buckets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of this bucket
  team_id: string # Unique identifier for the team to create this bucket for.
]: any -> record<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record<id: string, name: string>, tests_url: string, trigger_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets")
  let body = {name: $name, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single bucket resource.
#
# DELETE /buckets/{bucketKey}
export def "buckets delete" [
  bucketKey: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single bucket resource.
#
# GET /buckets/{bucketKey}
export def "buckets get" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record<id: string, name: string>, tests_url: string, trigger_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of shared environments for a specified bucket.
#
# GET /buckets/{bucketKey}/environments
export def "buckets-environments get" [
  bucketKey: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new shared environment.
#
# POST /buckets/{bucketKey}/environments
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-environments post" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: string
  --client-certificate: string
  --emails: record
  --exported-at: int
  --headers: record
  --id: string # The unique identifier for this environment.
  --initial-script-hash: string
  --initial-variables: record
  --integrations: list # The list of integrations for this environment. — item shape: {description?: string, id?: string, type?: string, uuid?: string}
  name: string # Name of this environment.
  --parent-environment-id: string
  --preserve-cookies: oneof<nothing, bool>
  --regions: list # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/environments")
  let body = {auth: $body_auth, client_certificate: $client_certificate, emails: $emails, exported_at: $exported_at, headers: $headers, id: $id, initial_script_hash: $initial_script_hash, initial_variables: $initial_variables, integrations: $integrations, name: $name, parent_environment_id: $parent_environment_id, preserve_cookies: $preserve_cookies, regions: $regions, remote_agents: $remote_agents, retry_on_failure: $retry_on_failure, script: $script, script_library: $script_library, stop_on_failure: $stop_on_failure, test_id: $test_id, verify_ssl: $verify_ssl, version: $version, webhooks: $webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the details of a shared environment.
#
# PUT /buckets/{bucketKey}/environments/{environmentId}
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-environments put" [
  bucketKey: string
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: string
  --client-certificate: string
  --emails: record
  --exported-at: int
  --headers: record
  --id: string # The unique identifier for this environment.
  --initial-script-hash: string
  --initial-variables: record
  --integrations: list # The list of integrations for this environment. — item shape: {description?: string, id?: string, type?: string, uuid?: string}
  name: string # Name of this environment.
  --parent-environment-id: string
  --preserve-cookies: oneof<nothing, bool>
  --regions: list # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/environments/($environmentId)")
  let body = {auth: $body_auth, client_certificate: $client_certificate, emails: $emails, exported_at: $exported_at, headers: $headers, id: $id, initial_script_hash: $initial_script_hash, initial_variables: $initial_variables, integrations: $integrations, name: $name, parent_environment_id: $parent_environment_id, preserve_cookies: $preserve_cookies, regions: $regions, remote_agents: $remote_agents, retry_on_failure: $retry_on_failure, script: $script, script_library: $script_library, stop_on_failure: $stop_on_failure, test_id: $test_id, verify_ssl: $verify_ssl, version: $version, webhooks: $webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of error messages in a bucket
#
# GET /buckets/{bucketKey}/errors
export def "buckets-errors get" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Maxiumum number of messages to return. Default 50, max 1000.
  --since: int # Only return messages after the given Unix timestamp
  --before: int # Only return messages before the given Unix timestamp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketKey)/errors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear a bucket (remove all messages).
#
# DELETE /buckets/{bucketKey}/messages
export def "buckets-messages delete" [
  bucketKey: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of messages in a bucket
#
# GET /buckets/{bucketKey}/messages
export def "buckets-messages list" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Maxiumum number of messages to return. Default 50, max 1000.
  --since: int # Only return messages after the given Unix timestamp
  --before: int # Only return messages before the given Unix timestamp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketKey)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a message
#
# POST /buckets/{bucketKey}/messages
# --request shape: {body?: string, body_encoding?: string, form?: string, headers?: string, method?: string, timestamp?: float, url?: string}
# --response shape: {body?: string, body_encoding?: string, headers?: string, reason?: string, response_time?: float, status?: int, timestamp?: float}
export def "buckets-messages post" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --request: record # shape: {body?: string, body_encoding?: string, form?: string, headers?: string, method?: string, timestamp?: float, url?: string}
  --response: record # shape: {body?: string, body_encoding?: string, headers?: string, reason?: string, response_time?: float, status?: int, timestamp?: float}
]: any -> record<data: table<error: record, status: string, unique_identifier: string, uuid: string, warning: record>, meta: record<error_count: int, succcess_count: int, warning_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/messages")
  let body = {request: $request, response: $response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the details for a single message.
#
# GET /buckets/{bucketKey}/messages/{messageId}
export def "buckets-messages get" [
  bucketKey: string
  messageId: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of tests.
#
# GET /buckets/{bucketKey}/tests
export def "buckets-tests list" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created_at: int, created_by: record, default_environment_id: string, description: string, id: string, last_run: record, name: string, trigger_url: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a test.
#
# POST /buckets/{bucketKey}/tests
# --created_by shape: {email?: string, id?: string, name?: string}
export def "buckets-tests post" [
  bucketKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: int # The date the test was created in seconds (Unix time stamp format).
  --created-by: record # shape: {email?: string, id?: string, name?: string}
  --default-environment-id: string
  --description: string # The description for the test.
  --id: string
  --last-run: record
  name: string # The name for the test.
  --trigger-url: string
]: any -> record<data: table<created_at: int, created_by: record, default_environment_id: string, description: string, id: string, last_run: record, name: string, trigger_url: string>, meta: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests")
  let body = {created_at: $created_at, created_by: $created_by, default_environment_id: $default_environment_id, description: $description, id: $id, last_run: $last_run, name: $name, trigger_url: $trigger_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a test, including all steps, schedules, test-specific environments and results.
#
# DELETE /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests delete" [
  bucketKey: string
  testId: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the details of a given test by ID.
#
# GET /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests get" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: record<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list<record>, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list<string>, remote_agents: list<record>, retry_on_failure: bool, script: string, script_library: list<string>, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, exported_at: int, last_run: record, schedules: table<environment_id: string, exported_at: int, id: string, interval: string, note: string, version: string>, steps: list<record>, version: string, created_at: int, created_by: record<email: string, id: string, name: string>, default_environment_id: string, description: string, id: string, name: string, trigger_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a test's name, description, default environment and its steps. To modify other individual properties of a test, make requests to the steps, environments, and schedules subresources of the test.
#
# PUT /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests put" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: record<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list<record>, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list<string>, remote_agents: list<record>, retry_on_failure: bool, script: string, script_library: list<string>, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, exported_at: int, last_run: record, schedules: table<environment_id: string, exported_at: int, id: string, interval: string, note: string, version: string>, steps: list<record>, version: string, created_at: int, created_by: record<email: string, id: string, name: string>, default_environment_id: string, description: string, id: string, name: string, trigger_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return details of the test's environments (only those that belong to the specified test)
#
# GET /buckets/{bucketKey}/tests/{testId}/environments
export def "buckets-tests-environments get" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list, remote_agents: list, retry_on_failure: bool, script: string, script_library: list, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new test environment.
#
# POST /buckets/{bucketKey}/tests/{testId}/environments
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-tests-environments post" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: string
  --client-certificate: string
  --emails: record
  --exported-at: int
  --headers: record
  --id: string # The unique identifier for this environment.
  --initial-script-hash: string
  --initial-variables: record
  --integrations: list # The list of integrations for this environment. — item shape: {description?: string, id?: string, type?: string, uuid?: string}
  name: string # Name of this environment.
  --parent-environment-id: string
  --preserve-cookies: oneof<nothing, bool>
  --regions: list # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/environments")
  let body = {auth: $body_auth, client_certificate: $client_certificate, emails: $emails, exported_at: $exported_at, headers: $headers, id: $id, initial_script_hash: $initial_script_hash, initial_variables: $initial_variables, integrations: $integrations, name: $name, parent_environment_id: $parent_environment_id, preserve_cookies: $preserve_cookies, regions: $regions, remote_agents: $remote_agents, retry_on_failure: $retry_on_failure, script: $script, script_library: $script_library, stop_on_failure: $stop_on_failure, test_id: $test_id, verify_ssl: $verify_ssl, version: $version, webhooks: $webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the details of a test environment.
#
# PUT /buckets/{bucketKey}/tests/{testId}/environments/{environmentId}
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-tests-environments put" [
  bucketKey: string
  testId: string
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: string
  --client-certificate: string
  --emails: record
  --exported-at: int
  --headers: record
  --id: string # The unique identifier for this environment.
  --initial-script-hash: string
  --initial-variables: record
  --integrations: list # The list of integrations for this environment. — item shape: {description?: string, id?: string, type?: string, uuid?: string}
  name: string # Name of this environment.
  --parent-environment-id: string
  --preserve-cookies: oneof<nothing, bool>
  --regions: list # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/environments/($environmentId)")
  let body = {auth: $body_auth, client_certificate: $client_certificate, emails: $emails, exported_at: $exported_at, headers: $headers, id: $id, initial_script_hash: $initial_script_hash, initial_variables: $initial_variables, integrations: $integrations, name: $name, parent_environment_id: $parent_environment_id, preserve_cookies: $preserve_cookies, regions: $regions, remote_agents: $remote_agents, retry_on_failure: $retry_on_failure, script: $script, script_library: $script_library, stop_on_failure: $stop_on_failure, test_id: $test_id, verify_ssl: $verify_ssl, version: $version, webhooks: $webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return details of the test metrics for the specified timeframe.
#
# GET /buckets/{bucketKey}/tests/{testId}/metrics
export def "buckets-tests-metrics get" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes_from_last_period: record, environment_uuid: string, region: string, response_times: table<avg_response_time_ms: int, success_ratio: int, timestamp: int>, this_time_period: record, timeframe: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List test steps for a test.
#
# GET /buckets/{bucketKey}/tests/{testId}/steps
export def "buckets-tests-steps get" [
  bucketKey: string
  testId: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/steps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new test step.
#
# POST /buckets/{bucketKey}/tests/{testId}/steps
export def "buckets-tests-steps post" [
  bucketKey: string
  testId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-type: string # Type of test step -- request, pause, condition, ghost-inspector, or subtest.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/steps")
  let body = {step_type: $step_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a step from a test.
#
# DELETE /buckets/{bucketKey}/tests/{testId}/steps/{stepId}
export def "buckets-tests-steps delete" [
  bucketKey: string
  testId: string
  stepId: string
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
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/steps/($stepId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the details of a single test step.
#
# PUT /buckets/{bucketKey}/tests/{testId}/steps/{stepId}
export def "buckets-tests-steps put" [
  bucketKey: string
  testId: string
  stepId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-type: string # Type of test step -- request, pause, condition, ghost-inspector, or subtest.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketKey)/tests/($testId)/steps/($stepId)")
  let body = {step_type: $step_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Team agents list
#
# GET /teams/{teamId}/agents
export def "teams-agents get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agent_id: string, name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team integrations list
#
# GET /teams/{teamId}/integrations
export def "teams-integrations get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<description: string, id: string, type: string, uuid: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Teams Resource
#
# GET /teams/{teamId}/people
export def "teams-people get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<email: string, id: string, name: string, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/people")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
