# Auto-generated client for Runscope API v1.0.0
# Source: https://api.apis.guru/v2/specs/runscope.com/1.0.0/swagger.json
# Auth: --token flag or $env.RUNSCOPE_API_TOKEN

const BASE_URL = "https://api.runscope.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o RUNSCOPE_API_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.runscope.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<email: string, id: string, name: string, teams: list<record>>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record, tests_url: string, trigger_url: string, verify_ssl: bool>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new bucket
#
# POST /buckets
export def "buckets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of this bucket
  team_id: string # Unique identifier for the team to create this bucket for.
]: any -> record<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record<id: string, name: string>, tests_url: string, trigger_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets" $auth.query)
  let req_body = {"name": $name, "team_id": $team_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a single bucket resource.
#
# DELETE /buckets/{bucketKey}
export def "buckets delete" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns a single bucket resource.
#
# GET /buckets/{bucketKey}
export def "buckets get" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_token: string, collections_url: string, default: bool, key: string, messages_url: string, name: string, team: record<id: string, name: string>, tests_url: string, trigger_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of shared environments for a specified bucket.
#
# GET /buckets/{bucketKey}/environments
export def "buckets-environments get" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/environments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new shared environment.
#
# POST /buckets/{bucketKey}/environments
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-environments create" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --regions: list<string> # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list<string> # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/environments") $auth.query)
  let req_body = {"auth": $body_auth, "client_certificate": $client_certificate, "emails": $emails, "exported_at": $exported_at, "headers": $headers, "id": $id, "initial_script_hash": $initial_script_hash, "initial_variables": $initial_variables, "integrations": $integrations, "name": $name, "parent_environment_id": $parent_environment_id, "preserve_cookies": $preserve_cookies, "regions": $regions, "remote_agents": $remote_agents, "retry_on_failure": $retry_on_failure, "script": $script, "script_library": $script_library, "stop_on_failure": $stop_on_failure, "test_id": $test_id, "verify_ssl": $verify_ssl, "version": $version, "webhooks": $webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update the details of a shared environment.
#
# PUT /buckets/{bucketKey}/environments/{environmentId}
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-environments update" [
  bucket_key: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --regions: list<string> # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list<string> # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($environment_id | is-empty) { error make --unspanned { msg: "path parameter 'environmentId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), environment_id: (encode-path-segment $environment_id)} | format pattern "/buckets/{bucket_key}/environments/{environment_id}") $auth.query)
  let req_body = {"auth": $body_auth, "client_certificate": $client_certificate, "emails": $emails, "exported_at": $exported_at, "headers": $headers, "id": $id, "initial_script_hash": $initial_script_hash, "initial_variables": $initial_variables, "integrations": $integrations, "name": $name, "parent_environment_id": $parent_environment_id, "preserve_cookies": $preserve_cookies, "regions": $regions, "remote_agents": $remote_agents, "retry_on_failure": $retry_on_failure, "script": $script, "script_library": $script_library, "stop_on_failure": $stop_on_failure, "test_id": $test_id, "verify_ssl": $verify_ssl, "version": $version, "webhooks": $webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a list of error messages in a bucket
#
# GET /buckets/{bucketKey}/errors
export def "buckets-errors get" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Maxiumum number of messages to return. Default 50, max 1000.
  --since: int # Only return messages after the given Unix timestamp
  --before: int # Only return messages before the given Unix timestamp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/errors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "since": $since, "before": $before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Clear a bucket (remove all messages).
#
# DELETE /buckets/{bucketKey}/messages
export def "buckets-messages delete" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/messages") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve a list of messages in a bucket
#
# GET /buckets/{bucketKey}/messages
export def "buckets-messages list" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Maxiumum number of messages to return. Default 50, max 1000.
  --since: int # Only return messages after the given Unix timestamp
  --before: int # Only return messages before the given Unix timestamp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/messages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "since": $since, "before": $before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a message
#
# POST /buckets/{bucketKey}/messages
# --request shape: {body?: string, body_encoding?: string, form?: string, headers?: string, method?: string, timestamp?: float, url?: string}
# --response shape: {body?: string, body_encoding?: string, headers?: string, reason?: string, response_time?: float, status?: int, timestamp?: float}
export def "buckets-messages create" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request: record # shape: {body?: string, body_encoding?: string, form?: string, headers?: string, method?: string, timestamp?: float, url?: string}
  --response: record # shape: {body?: string, body_encoding?: string, headers?: string, reason?: string, response_time?: float, status?: int, timestamp?: float}
]: any -> record<data: table<error: record, status: string, unique_identifier: string, uuid: string, warning: record>, meta: record<error_count: int, succcess_count: int, warning_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/messages") $auth.query)
  let req_body = {"request": $request, "response": $response} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve the details for a single message.
#
# GET /buckets/{bucketKey}/messages/{messageId}
export def "buckets-messages get" [
  bucket_key: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), message_id: (encode-path-segment $message_id)} | format pattern "/buckets/{bucket_key}/messages/{message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of tests.
#
# GET /buckets/{bucketKey}/tests
export def "buckets-tests list" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created_at: int, created_by: record, default_environment_id: string, description: string, id: string, last_run: record, name: string, trigger_url: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/tests") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a test.
#
# POST /buckets/{bucketKey}/tests
# --created_by shape: {email?: string, id?: string, name?: string}
export def "buckets-tests create" [
  bucket_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key)} | format pattern "/buckets/{bucket_key}/tests") $auth.query)
  let req_body = {"created_at": $created_at, "created_by": $created_by, "default_environment_id": $default_environment_id, "description": $description, "id": $id, "last_run": $last_run, "name": $name, "trigger_url": $trigger_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a test, including all steps, schedules, test-specific environments and results.
#
# DELETE /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests delete" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve the details of a given test by ID.
#
# GET /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests get" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: record<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list<record>, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list<string>, remote_agents: list<record>, retry_on_failure: bool, script: string, script_library: list<string>, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, exported_at: int, last_run: record, schedules: table<environment_id: string, exported_at: int, id: string, interval: string, note: string, version: string>, steps: list<record>, version: string, created_at: int, created_by: record<email: string, id: string, name: string>, default_environment_id: string, description: string, id: string, name: string, trigger_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modify a test's name, description, default environment and its steps. To modify other individual properties of a test, make requests to the steps, environments, and schedules subresources of the test.
#
# PUT /buckets/{bucketKey}/tests/{testId}
export def "buckets-tests update" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: record<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list<record>, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list<string>, remote_agents: list<record>, retry_on_failure: bool, script: string, script_library: list<string>, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, exported_at: int, last_run: record, schedules: table<environment_id: string, exported_at: int, id: string, interval: string, note: string, version: string>, steps: list<record>, version: string, created_at: int, created_by: record<email: string, id: string, name: string>, default_environment_id: string, description: string, id: string, name: string, trigger_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Return details of the test's environments (only those that belong to the specified test)
#
# GET /buckets/{bucketKey}/tests/{testId}/environments
export def "buckets-tests-environments get" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<auth: string, client_certificate: string, emails: record, exported_at: int, headers: record, id: string, initial_script_hash: string, initial_variables: record, integrations: list, name: string, parent_environment_id: string, preserve_cookies: bool, regions: list, remote_agents: list, retry_on_failure: bool, script: string, script_library: list, stop_on_failure: bool, test_id: string, verify_ssl: bool, version: string, webhooks: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/environments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new test environment.
#
# POST /buckets/{bucketKey}/tests/{testId}/environments
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-tests-environments create" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --regions: list<string> # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list<string> # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --body-test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/environments") $auth.query)
  let req_body = {"auth": $body_auth, "client_certificate": $client_certificate, "emails": $emails, "exported_at": $exported_at, "headers": $headers, "id": $id, "initial_script_hash": $initial_script_hash, "initial_variables": $initial_variables, "integrations": $integrations, "name": $name, "parent_environment_id": $parent_environment_id, "preserve_cookies": $preserve_cookies, "regions": $regions, "remote_agents": $remote_agents, "retry_on_failure": $retry_on_failure, "script": $script, "script_library": $script_library, "stop_on_failure": $stop_on_failure, "test_id": $body_test_id, "verify_ssl": $verify_ssl, "version": $version, "webhooks": $webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update the details of a test environment.
#
# PUT /buckets/{bucketKey}/tests/{testId}/environments/{environmentId}
# --integrations item shape: {description?: string, id?: string, type?: string, uuid?: string}
# --remote_agents item shape: {agent_id?: string, name?: string, version?: string}
export def "buckets-tests-environments update" [
  bucket_key: string
  test_id: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --regions: list<string> # An array of the region codes that this environment is using.
  --remote-agents: list # item shape: {agent_id?: string, name?: string, version?: string}
  --retry-on-failure: oneof<nothing, bool>
  --script: string
  --script-library: list<string> # The list of ids for scripts, part of the script libraries, being used for this environment.
  --stop-on-failure: oneof<nothing, bool> # Stop executing the test after the first failed step.
  --body-test-id: string # The unique identifier for this test.
  --verify-ssl: oneof<nothing, bool> # Validate all SSL certificates on any HTTPS connections.
  --version: string
  --webhooks: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  if ($environment_id | is-empty) { error make --unspanned { msg: "path parameter 'environmentId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id), environment_id: (encode-path-segment $environment_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/environments/{environment_id}") $auth.query)
  let req_body = {"auth": $body_auth, "client_certificate": $client_certificate, "emails": $emails, "exported_at": $exported_at, "headers": $headers, "id": $id, "initial_script_hash": $initial_script_hash, "initial_variables": $initial_variables, "integrations": $integrations, "name": $name, "parent_environment_id": $parent_environment_id, "preserve_cookies": $preserve_cookies, "regions": $regions, "remote_agents": $remote_agents, "retry_on_failure": $retry_on_failure, "script": $script, "script_library": $script_library, "stop_on_failure": $stop_on_failure, "test_id": $body_test_id, "verify_ssl": $verify_ssl, "version": $version, "webhooks": $webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Return details of the test metrics for the specified timeframe.
#
# GET /buckets/{bucketKey}/tests/{testId}/metrics
export def "buckets-tests-metrics get" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes_from_last_period: record, environment_uuid: string, region: string, response_times: table<avg_response_time_ms: int, success_ratio: int, timestamp: int>, this_time_period: record, timeframe: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/metrics") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List test steps for a test.
#
# GET /buckets/{bucketKey}/tests/{testId}/steps
export def "buckets-tests-steps get" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/steps") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add new test step.
#
# POST /buckets/{bucketKey}/tests/{testId}/steps
export def "buckets-tests-steps create" [
  bucket_key: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-type: string # Type of test step -- request, pause, condition, ghost-inspector, or subtest.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/steps") $auth.query)
  let req_body = {"step_type": $step_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a step from a test.
#
# DELETE /buckets/{bucketKey}/tests/{testId}/steps/{stepId}
export def "buckets-tests-steps delete" [
  bucket_key: string
  test_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  if ($step_id | is-empty) { error make --unspanned { msg: "path parameter 'stepId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id), step_id: (encode-path-segment $step_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/steps/{step_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update the details of a single test step.
#
# PUT /buckets/{bucketKey}/tests/{testId}/steps/{stepId}
export def "buckets-tests-steps update" [
  bucket_key: string
  test_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-type: string # Type of test step -- request, pause, condition, ghost-inspector, or subtest.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_key | is-empty) { error make --unspanned { msg: "path parameter 'bucketKey' must be non-empty" } }
  if ($test_id | is-empty) { error make --unspanned { msg: "path parameter 'testId' must be non-empty" } }
  if ($step_id | is-empty) { error make --unspanned { msg: "path parameter 'stepId' must be non-empty" } }
  let full_url = (build-url $base ({bucket_key: (encode-path-segment $bucket_key), test_id: (encode-path-segment $test_id), step_id: (encode-path-segment $step_id)} | format pattern "/buckets/{bucket_key}/tests/{test_id}/steps/{step_id}") $auth.query)
  let req_body = {"step_type": $step_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Team agents list
#
# GET /teams/{teamId}/agents
export def "teams-agents get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agent_id: string, name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}/agents") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Team integrations list
#
# GET /teams/{teamId}/integrations
export def "teams-integrations get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<description: string, id: string, type: string, uuid: string>, meta: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}/integrations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Teams Resource
#
# GET /teams/{teamId}/people
export def "teams-people get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<email: string, id: string, name: string, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}/people") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
