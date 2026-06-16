# Auto-generated client for Netlify's API documentation v2.15.0
# Source: https://api.apis.guru/v2/specs/netlify.com/2.15.0/swagger.json
# Auth: --token flag or $env.NETLIFY_S_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.netlify.com/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETLIFY_S_API_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.netlify.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def period-completer [] { ["monthly" "yearly"] }
def context-name-completer [] { ["all" "branch-deploy" "deploy-preview" "dev" "production"] }
def scope-completer [] { ["builds" "functions" "post-processing" "runtime"] }
def context-completer [] { ["branch-deploy" "deploy-preview" "dev" "production"] }
def filter-completer [] { ["all" "guest" "owner"] }
def state-completer [] { ["accepted" "building" "enqueued" "error" "new" "pending_review" "prepared" "preparing" "processing" "ready" "rejected" "retrying" "uploaded" "uploading"] }
def role-completer [] { ["Collaborator" "Controller" "Owner"] }
def site-access-completer [] { ["all" "none" "selected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts listAccountsForUser" } } | get name | first)
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

# GET /accounts
#
# operationId: listAccountsForUser
export def "accounts listAccountsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /accounts
#
# operationId: createAccount
export def "accounts createAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extra-seats-block: int
  name: string
  --payment-method-id: string
  --period: string@period-completer
  type_id: string
]: any -> record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {extra_seats_block: $extra_seats_block, name: $name, payment_method_id: $payment_method_id, period: $period, type_id: $type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /accounts/types
#
# operationId: listAccountTypesForUser
export def "accounts-types listAccountTypesForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<capabilities: record, description: string, id: string, monthly_dollar_price: int, monthly_seats_addon_dollar_price: int, name: string, yearly_dollar_price: int, yearly_seats_addon_dollar_price: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /accounts/{account_id}
#
# operationId: cancelAccount
export def "accounts cancelAccount" [
  account_id: string
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
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /accounts/{account_id}
#
# operationId: getAccount
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /accounts/{account_id}
#
# operationId: updateAccount
export def "accounts updateAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-details: string
  --billing-email: string
  --billing-name: string
  --extra-seats-block: int
  --name: string
  --slug: string
  --type-id: string
]: any -> record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let body = {billing_details: $billing_details, billing_email: $billing_email, billing_name: $billing_name, extra_seats_block: $extra_seats_block, name: $name, slug: $slug, type_id: $type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /accounts/{account_id}/audit
#
# operationId: listAccountAuditEvents
export def "accounts-audit listAccountAuditEvents" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --log-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<account_id: string, id: string, payload: record<action: string, actor_email: string, actor_id: string, actor_name: string, log_type: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "log_type" $log_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all environment variables for an account or site. An account corresponds to a team in the Netlify UI. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env
# operationId: getEnvVars
export def "accounts-env list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer # Filter by scope
  --site-id: string # If specified, only return environment variables set on this site
]: nothing -> table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context_name" $context_name "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new environment variables. Granular scopes are available on Pro plans and above.  To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# POST /accounts/{account_id}/env
# operationId: createEnvVars
export def "accounts-env createEnvVars" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, create an environment variable on the site level, not the account level
  --body: record
]: any -> table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an environment variable. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}
# operationId: deleteEnvVar
export def "accounts-env delete" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, delete the environment variable from this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an individual environment variable. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env/{key}
# operationId: getEnvVar
export def "accounts-env get" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, return the environment variable for a specific site (no merging is performed)
]: nothing -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates a new value for an existing environment variable. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# PATCH /accounts/{account_id}/env/{key}
# operationId: setEnvVarValue
export def "accounts-env setEnvVarValue" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --context: string@context-completer # The deploy context in which this value will be used. `dev` refers to local development when running `netlify dev`.
  --value: string # The environment variable's unencrypted value
]: any -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let body = {context: $context, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing environment variable and all of its values. Existing values will be replaced by values provided. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# PUT /accounts/{account_id}/env/{key}
# operationId: updateEnvVar
# --values item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
export def "accounts-env updateEnvVar" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --body-key: string # The existing or new name of the key, if you wish to rename it (case-sensitive)
  --scopes: list # The scopes that this environment variable is set to (Pro plans and above)
  --values: list # item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
]: any -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let body = {key: $body_key, scopes: $scopes, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific environment variable value. To use this endpoint, your site must no longer be using the <a href="https://docs.netlify.com/environment-variables/classic-experience/">classic environment variables experience</a>.  Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}/value/{id}
# operationId: deleteEnvVarValue
export def "accounts-env-value delete" [
  account_id: string
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, delete the value from an environment variable on this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)/value/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /billing/payment_methods
#
# operationId: listPaymentMethodsForUser
export def "billing-payment-methods listPaymentMethodsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, data: record<card_type: string, email: string, last4: string>, id: string, method_name: string, state: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/payment_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /builds/{build_id}
#
# operationId: getSiteBuild
export def "builds get" [
  build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/builds/($build_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /builds/{build_id}/log
#
# operationId: updateSiteBuildLog
export def "builds-log updateSiteBuildLog" [
  build_id: string
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
  let full_url = (build-url $base $"/builds/($build_id)/log")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /builds/{build_id}/start
#
# operationId: notifyBuildStart
export def "builds-start notifyBuildStart" [
  build_id: string
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
  let full_url = (build-url $base $"/builds/($build_id)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /deploy_keys
#
# operationId: listDeployKeys
export def "deploy-keys listDeployKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /deploy_keys
#
# operationId: createDeployKey
export def "deploy-keys createDeployKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /deploy_keys/{key_id}
#
# operationId: deleteDeployKey
export def "deploy-keys delete" [
  key_id: string
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
  let full_url = (build-url $base $"/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /deploy_keys/{key_id}
#
# operationId: getDeployKey
export def "deploy-keys get" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /deploys/{deploy_id}
#
# operationId: deleteDeploy
export def "deploys delete" [
  deploy_id: string
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
  let full_url = (build-url $base $"/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /deploys/{deploy_id}
#
# operationId: getDeploy
export def "deploys get" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /deploys/{deploy_id}/cancel
#
# operationId: cancelSiteDeploy
export def "deploys-cancel cancelSiteDeploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /deploys/{deploy_id}/files/{path}
#
# operationId: uploadDeployFile
export def "deploys-files uploadDeployFile" [
  deploy_id: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: int
  --body: record
]: any -> record<id: string, mime_type: string, path: string, sha: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploys/($deploy_id)/files/($path)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /deploys/{deploy_id}/functions/{name}
#
# operationId: uploadDeployFunction
export def "deploys-functions uploadDeployFunction" [
  deploy_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runtime: string
  --size: int
  --X-Nf-Retry-Count: int
  --body: record
]: any -> record<id: string, name: string, sha: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runtime" $runtime "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploys/($deploy_id)/functions/($name)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nf-Retry-Count": $X_Nf_Retry_Count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /deploys/{deploy_id}/lock
#
# operationId: lockDeploy
export def "deploys-lock lockDeploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is an internal-only endpoint.
#
# POST /deploys/{deploy_id}/plugin_runs
# operationId: createPluginRun
export def "deploys-plugin-runs createPluginRun" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string
  --reporting-event: string
  --state: string
  --summary: string
  --text: string
  --title: string
  --version: string
]: any -> record<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/plugin_runs")
  let body = {package: $package, reporting_event: $reporting_event, state: $state, summary: $summary, text: $text, title: $title, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /deploys/{deploy_id}/unlock
#
# operationId: unlockDeploy
export def "deploys-unlock unlockDeploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dns_zones
#
# operationId: getDnsZones
export def "dns-zones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_slug" $account_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dns_zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dns_zones
#
# operationId: createDnsZone
export def "dns-zones createDnsZone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
  --name: string
  --site-id: string
]: any -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns_zones")
  let body = {account_slug: $account_slug, name: $name, site_id: $site_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /dns_zones/{zone_id}
#
# operationId: deleteDnsZone
export def "dns-zones delete" [
  zone_id: string
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
  let full_url = (build-url $base $"/dns_zones/($zone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dns_zones/{zone_id}
#
# operationId: getDnsZone
export def "dns-zones get" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dns_zones/{zone_id}/dns_records
#
# operationId: getDnsRecords
export def "dns-zones-dns-records list" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dns_zones/{zone_id}/dns_records
#
# operationId: createDnsRecord
export def "dns-zones-dns-records createDnsRecord" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flag: int # format: int64
  --hostname: string
  --port: int # format: int64
  --priority: int # format: int64
  --tag: string
  --ttl: int # format: int64
  --type: string
  --value: string
  --weight: int # format: int64
]: any -> record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records")
  let body = {flag: $flag, hostname: $hostname, port: $port, priority: $priority, tag: $tag, ttl: $ttl, type: $type, value: $value, weight: $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: deleteDnsRecord
export def "dns-zones-dns-records delete" [
  zone_id: string
  dns_record_id: string
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
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records/($dns_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: getIndividualDnsRecord
export def "dns-zones-dns-records get" [
  zone_id: string
  dns_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records/($dns_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /dns_zones/{zone_id}/transfer
#
# operationId: transferDnsZone
export def "dns-zones-transfer transferDnsZone" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # the account of the dns zone
  --transfer-account-id: string # the account you want to transfer the dns zone to
  --transfer-user-id: string # the user you want to transfer the dns zone to
]: nothing -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "transfer_account_id" $transfer_account_id "scalar") (serialize-qp "transfer_user_id" $transfer_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dns_zones/($zone_id)/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /forms/{form_id}/submissions
#
# operationId: listFormSubmissions
export def "forms-submissions listFormSubmissions" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/forms/($form_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /hooks
#
# operationId: listHooksBySiteId
export def "hooks listHooksBySiteId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string
]: nothing -> table<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /hooks
#
# operationId: createHookBySiteId
export def "hooks createHookBySiteId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id: string
  --type: string
  --updated-at: string # format: dateTime
]: any -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let body = {created_at: $created_at, data: $data, disabled: $disabled, event: $event, id: $id, site_id: $site_id, type: $type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /hooks/types
#
# operationId: listHookTypes
export def "hooks-types listHookTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<events: list<string>, fields: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /hooks/{hook_id}
#
# operationId: deleteHook
export def "hooks delete" [
  hook_id: string
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
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /hooks/{hook_id}
#
# operationId: getHook
export def "hooks get" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /hooks/{hook_id}
#
# operationId: updateHook
export def "hooks updateHook" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id: string
  --type: string
  --updated-at: string # format: dateTime
]: any -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let body = {created_at: $created_at, data: $data, disabled: $disabled, event: $event, id: $id, site_id: $site_id, type: $type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /hooks/{hook_id}/enable
#
# operationId: enableHook
export def "hooks-enable enableHook" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /oauth/tickets
#
# operationId: createTicket
export def "oauth-tickets createTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
]: nothing -> record<authorized: bool, client_id: string, created_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /oauth/tickets/{ticket_id}
#
# operationId: showTicket
export def "oauth-tickets showTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorized: bool, client_id: string, created_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /oauth/tickets/{ticket_id}/exchange
#
# operationId: exchangeTicket
export def "oauth-tickets-exchange exchangeTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_token: string, created_at: string, id: string, user_email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/tickets/($ticket_id)/exchange")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /services/
#
# operationId: getServices
export def "services get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> table<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /services/{addonName}
#
# operationId: showService
export def "services showService" [
  addonName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($addonName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /services/{addonName}/manifest
#
# operationId: showServiceManifest
export def "services-manifest showServiceManifest" [
  addonName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($addonName)/manifest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites
# operationId: listSites
export def "sites listSites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --filter: string@filter-completer
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /sites
# operationId: createSite
# --build_settings shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
# --repo shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites createSite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --body-url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let body = {account_name: $account_name, account_slug: $account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $body_url, user_id: $user_id, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}
#
# operationId: deleteSite
export def "sites delete" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites/{site_id}
# operationId: getSite
export def "sites get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [updateEnvVar](#tag/environmentVariables/operation/updateEnvVar) to update a site's environment variables.
#
# PATCH /sites/{site_id}
# operationId: updateSite
# --build_settings shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
# --repo shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites updateSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --body-url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let body = {account_name: $account_name, account_slug: $account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $body_url, user_id: $user_id, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/assets
#
# operationId: listSiteAssets
export def "sites-assets listSiteAssets" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/assets
#
# operationId: createSiteAsset
export def "sites-assets createSiteAsset" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --size: int # format: int64
  --content-type: string
  --visibility: string
]: nothing -> record<asset: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, form: record<fields: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /sites/{site_id}/assets/{asset_id}
#
# operationId: deleteSiteAsset
export def "sites-assets delete" [
  site_id: string
  asset_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/assets/{asset_id}
#
# operationId: getSiteAssetInfo
export def "sites-assets get" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/assets/{asset_id}
#
# operationId: updateSiteAsset
export def "sites-assets updateSiteAsset" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string
]: nothing -> record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/assets/{asset_id}/public_signature
#
# operationId: getSiteAssetPublicSignature
export def "sites-assets-public-signature get" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)/public_signature")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/build_hooks
#
# operationId: listSiteBuildHooks
export def "sites-build-hooks listSiteBuildHooks" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/build_hooks
#
# operationId: createSiteBuildHook
export def "sites-build-hooks createSiteBuildHook" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string
  --title: string
]: any -> record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks")
  let body = {branch: $branch, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}/build_hooks/{id}
#
# operationId: deleteSiteBuildHook
export def "sites-build-hooks delete" [
  site_id: string
  id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/build_hooks/{id}
#
# operationId: getSiteBuildHook
export def "sites-build-hooks get" [
  site_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/build_hooks/{id}
#
# operationId: updateSiteBuildHook
export def "sites-build-hooks updateSiteBuildHook" [
  site_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let body = {branch: $branch, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/builds
#
# operationId: listSiteBuilds
export def "sites-builds listSiteBuilds" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/builds
#
# operationId: createSiteBuild
export def "sites-builds createSiteBuild" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-cache: oneof<nothing, bool>
  --image: string
]: any -> record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/builds")
  let body = {clear_cache: $clear_cache, image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/deployed-branches
#
# operationId: listSiteDeployedBranches
export def "sites-deployed-branches listSiteDeployedBranches" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deploy_id: string, id: string, name: string, slug: string, ssl_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deployed-branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/deploys
#
# operationId: listSiteDeploys
export def "sites-deploys listSiteDeploys" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/deploys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/deploys
#
# operationId: createSiteDeploy
# --function_schedules item shape: {cron?: string, name?: string}
export def "sites-deploys createSiteDeploy" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --title: string
  --async: oneof<nothing, bool>
  --branch: string
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/deploys" $qp)
  let body = {async: $async, branch: $branch, draft: $draft, files: $files, framework: $framework, function_schedules: $function_schedules, functions: $functions, functions_config: $functions_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}/deploys/{deploy_id}
#
# operationId: deleteSiteDeploy
export def "sites-deploys delete" [
  deploy_id: string
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/deploys/{deploy_id}
#
# operationId: getSiteDeploy
export def "sites-deploys get" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/deploys/{deploy_id}
#
# operationId: updateSiteDeploy
# --function_schedules item shape: {cron?: string, name?: string}
export def "sites-deploys updateSiteDeploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --branch: string
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)")
  let body = {async: $async, branch: $branch, draft: $draft, files: $files, framework: $framework, function_schedules: $function_schedules, functions: $functions, functions_config: $functions_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /sites/{site_id}/deploys/{deploy_id}/restore
#
# operationId: restoreSiteDeploy
export def "sites-deploys-restore restoreSiteDeploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/dns
#
# operationId: getDNSForSite
export def "sites-dns get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/dns
#
# operationId: configureDNSForSite
export def "sites-dns configureDNSForSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/files
#
# operationId: listSiteFiles
export def "sites-files listSiteFiles" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, mime_type: string, path: string, sha: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/files/{file_path}
#
# operationId: getSiteFileByPathName
export def "sites-files get" [
  site_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, mime_type: string, path: string, sha: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/files/($file_path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/forms
#
# operationId: listSiteForms
export def "sites-forms listSiteForms" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, fields: list<record>, id: string, name: string, paths: list<string>, site_id: string, submission_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/forms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /sites/{site_id}/forms/{form_id}
#
# operationId: deleteSiteForm
export def "sites-forms delete" [
  site_id: string
  form_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/forms/($form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/metadata
#
# operationId: getSiteMetadata
export def "sites-metadata get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/metadata
#
# operationId: updateSiteMetadata
export def "sites-metadata updateSiteMetadata" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This is an internal-only endpoint.
#
# GET /sites/{site_id}/plugin_runs/latest
# operationId: getLatestPluginRuns
export def "sites-plugin-runs-latest get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --packages: list
  --state: string
]: nothing -> table<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packages" $packages "csv") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/plugin_runs/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is an internal-only endpoint.
#
# PUT /sites/{site_id}/plugins/{package}
# operationId: updatePlugin
export def "sites-plugins updatePlugin" [
  site_id: string
  package: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pinned-version: string
]: any -> record<package: string, pinned_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/plugins/($package)")
  let body = {pinned_version: $pinned_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /sites/{site_id}/rollback
#
# operationId: rollbackSiteDeploy
export def "sites-rollback rollbackSiteDeploy" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/rollback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/service-instances
#
# operationId: listServiceInstancesForSite
export def "sites-service-instances listServiceInstancesForSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/service-instances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/services/{addon}/instances
#
# operationId: createServiceInstance
export def "sites-services-instances createServiceInstance" [
  site_id: string
  addon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: deleteServiceInstance
export def "sites-services-instances delete" [
  site_id: string
  addon: string
  instance_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: showServiceInstance
export def "sites-services-instances showServiceInstance" [
  site_id: string
  addon: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: updateServiceInstance
export def "sites-services-instances updateServiceInstance" [
  site_id: string
  addon: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/snippets
#
# operationId: listSiteSnippets
export def "sites-snippets listSiteSnippets" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/snippets
#
# operationId: createSiteSnippet
export def "sites-snippets createSiteSnippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string
  --title: string
]: any -> record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets")
  let body = {general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position, id: $id, site_id: $body_site_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}/snippets/{snippet_id}
#
# operationId: deleteSiteSnippet
export def "sites-snippets delete" [
  site_id: string
  snippet_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/snippets/{snippet_id}
#
# operationId: getSiteSnippet
export def "sites-snippets get" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/snippets/{snippet_id}
#
# operationId: updateSiteSnippet
export def "sites-snippets updateSiteSnippet" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let body = {general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position, id: $id, site_id: $body_site_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/ssl
#
# operationId: showSiteTLSCertificate
export def "sites-ssl showSiteTLSCertificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/ssl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/ssl
#
# operationId: provisionSiteTLSCertificate
export def "sites-ssl provisionSiteTLSCertificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string
  --key: string
  --ca-certificates: string
]: nothing -> record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certificate" $certificate "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ca_certificates" $ca_certificates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/ssl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/submissions
#
# operationId: listSiteSubmissions
export def "sites-submissions listSiteSubmissions" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/traffic_splits
#
# operationId: getSplitTests
export def "sites-traffic-splits list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/traffic_splits
#
# operationId: createSplitTest
export def "sites-traffic-splits createSplitTest" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits")
  let body = {branch_tests: $branch_tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/traffic_splits/{split_test_id}
#
# operationId: getSplitTest
export def "sites-traffic-splits get" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/traffic_splits/{split_test_id}
#
# operationId: updateSplitTest
export def "sites-traffic-splits updateSplitTest" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)")
  let body = {branch_tests: $branch_tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/publish
#
# operationId: enableSplitTest
export def "sites-traffic-splits-publish enableSplitTest" [
  site_id: string
  split_test_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/unpublish
#
# operationId: disableSplitTest
export def "sites-traffic-splits-unpublish disableSplitTest" [
  site_id: string
  split_test_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)/unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Unlinks the repo from the site.  This action will also: - Delete associated deploy keys - Delete outgoing webhooks for the repo - Delete the site's build hooks
#
# PUT /sites/{site_id}/unlink_repo
# operationId: unlinkSiteRepo
export def "sites-unlink-repo unlinkSiteRepo" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/unlink_repo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /submissions/{submission_id}
#
# operationId: deleteSubmission
export def "submissions delete" [
  submission_id: string
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
  let full_url = (build-url $base $"/submissions/($submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /submissions/{submission_id}
#
# operationId: listFormSubmission
export def "submissions listFormSubmission" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/submissions/($submission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /user
#
# operationId: getCurrentUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<affiliate_id: string, avatar_url: string, created_at: string, email: string, full_name: string, id: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>, site_count: int, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{account_id}/builds/status
#
# operationId: getAccountBuildStatus
export def "builds-status get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: int, build_count: int, enqueued: int, minutes: record<current: int, current_average_sec: int, included_minutes: string, included_minutes_with_packs: string, last_updated_at: string, period_end_date: string, period_start_date: string, previous: int>, pending_concurrency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_id)/builds/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{account_slug}/members
#
# operationId: listMembersForAccount
export def "members listMembersForAccount" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatar: string, email: string, full_name: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{account_slug}/members
#
# operationId: addMemberToAccount
export def "members addMemberToAccount" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --role: string@role-completer
]: any -> table<avatar: string, email: string, full_name: string, id: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members")
  let body = {email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /{account_slug}/members/{member_id}
#
# operationId: removeAccountMember
export def "members removeAccountMember" [
  account_slug: string
  member_id: string
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
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{account_slug}/members/{member_id}
#
# operationId: getAccountMember
export def "members get" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, email: string, full_name: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{account_slug}/members/{member_id}
#
# operationId: updateAccountMember
export def "members updateAccountMember" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer
  --site-access: string@site-access-completer
  --site-ids: list
]: any -> record<avatar: string, email: string, full_name: string, id: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let body = {role: $role, site_access: $site_access, site_ids: $site_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /{account_slug}/sites
# operationId: listSitesForAccount
export def "sites listSitesForAccount" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($account_slug)/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /{account_slug}/sites
# operationId: createSiteInTeam
# --build_settings shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
# --repo shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites createSiteInTeam" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --body-account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list, required_functions?: list, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, site_id?: string, skipped?: bool, ssl_url?: string, state?: string, title?: string, updated_at?: string, url?: string, user_id?: string}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --body-url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($account_slug)/sites" $qp)
  let body = {account_name: $account_name, account_slug: $body_account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $body_url, user_id: $user_id, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
