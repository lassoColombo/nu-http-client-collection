# Auto-generated client for Netlify's API documentation v2.15.0
# Source: https://api.apis.guru/v2/specs/netlify.com/2.15.0/swagger.json
# Auth: --token flag or $env.NETLIFY_S_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.netlify.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETLIFY_S_API_DOCUMENTATION_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list-for-user" } } | get name | first)
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
export def "accounts list-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /accounts
#
# operationId: createAccount
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"extra_seats_block": $extra_seats_block, "name": $name, "payment_method_id": $payment_method_id, "period": $period, "type_id": $type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /accounts/types
#
# operationId: listAccountTypesForUser
export def "accounts-types list-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<capabilities: record, description: string, id: string, monthly_dollar_price: int, monthly_seats_addon_dollar_price: int, name: string, yearly_dollar_price: int, yearly_seats_addon_dollar_price: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /accounts/{account_id}
#
# operationId: cancelAccount
export def "accounts cancel" [
  account_id: string
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
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /accounts/{account_id}
#
# operationId: updateAccount
export def "accounts update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let req_body = {"billing_details": $billing_details, "billing_email": $billing_email, "billing_name": $billing_name, "extra_seats_block": $extra_seats_block, "name": $name, "slug": $slug, "type_id": $type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /accounts/{account_id}/audit
#
# operationId: listAccountAuditEvents
export def "accounts-audit list-events" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --log-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<account_id: string, id: string, payload: record<action: string, actor_email: string, actor_id: string, actor_name: string, log_type: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "log_type" $log_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/audit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "log_type": $log_type, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Returns all environment variables for an account or site. An account corresponds to a team in the Netlify UI. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env
# operationId: getEnvVars
export def "accounts-env get-vars" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer # Filter by scope
  --site-id: string # If specified, only return environment variables set on this site
]: nothing -> table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "context_name" $context_name "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/env") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"context_name": $context_name, "scope": $scope, "site_id": $site_id} | compact), body: null}
}

# Creates new environment variables. Granular scopes are available on Pro plans and above. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# POST /accounts/{account_id}/env
# operationId: createEnvVars
export def "accounts-env create-vars" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, create an environment variable on the site level, not the account level
  --body: list
]: any -> table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/env") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"site_id": $site_id} | compact), body: $req_body}
}

# Deletes an environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}
# operationId: deleteEnvVar
export def "accounts-env delete-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, delete the environment variable from this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"site_id": $site_id} | compact), body: null}
}

# Returns an individual environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env/{key}
# operationId: getEnvVar
export def "accounts-env get-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, return the environment variable for a specific site (no merging is performed)
]: nothing -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"site_id": $site_id} | compact), body: null}
}

# Updates or creates a new value for an existing environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PATCH /accounts/{account_id}/env/{key}
# operationId: setEnvVarValue
export def "accounts-env update-var-value" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --context: string@context-completer # The deploy context in which this value will be used. `dev` refers to local development when running `netlify dev`.
  --value: string # The environment variable's unencrypted value
]: any -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp)
  let req_body = {"context": $context, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"site_id": $site_id} | compact), body: $req_body}
}

# Updates an existing environment variable and all of its values. Existing values will be replaced by values provided. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PUT /accounts/{account_id}/env/{key}
# operationId: updateEnvVar
# --values item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
export def "accounts-env update-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --body-key: string # The existing or new name of the key, if you wish to rename it (case-sensitive)
  --scopes: list<string> # The scopes that this environment variable is set to (Pro plans and above)
  --values: list # item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
]: any -> record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp)
  let req_body = {"key": $body_key, "scopes": $scopes, "values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"site_id": $site_id} | compact), body: $req_body}
}

# Deletes a specific environment variable value. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}/value/{id}
# operationId: deleteEnvVarValue
export def "accounts-env-value delete-var" [
  account_id: string
  key: string
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
  --site-id: string # If provided, delete the value from an environment variable on this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key), id: (encode-path-segment $id)} | format pattern "/accounts/{account_id}/env/{key}/value/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"site_id": $site_id} | compact), body: null}
}

# GET /billing/payment_methods
#
# operationId: listPaymentMethodsForUser
export def "billing-payment-methods list-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, data: record<card_type: string, email: string, last4: string>, id: string, method_name: string, state: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/payment_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /builds/{build_id}
#
# operationId: getSiteBuild
export def "builds get-site" [
  build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /builds/{build_id}/log
#
# operationId: updateSiteBuildLog
export def "builds-log update-site" [
  build_id: string
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
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}/log"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /builds/{build_id}/start
#
# operationId: notifyBuildStart
export def "builds-start notify" [
  build_id: string
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
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /deploy_keys
#
# operationId: listDeployKeys
export def "deploy-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /deploy_keys
#
# operationId: createDeployKey
export def "deploy-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/deploy_keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/deploy_keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /deploys/{deploy_id}/cancel
#
# operationId: cancelSiteDeploy
export def "deploys-cancel cancel-site" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /deploys/{deploy_id}/files/{path}
#
# operationId: uploadDeployFile
export def "deploys-files upload" [
  deploy_id: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: int
  --body: string
]: any -> record<id: string, mime_type: string, path: string, sha: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id), path: (encode-path-segment $path)} | format pattern "/deploys/{deploy_id}/files/{path}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"size": $size} | compact), body: $req_body}
}

# PUT /deploys/{deploy_id}/functions/{name}
#
# operationId: uploadDeployFunction
export def "deploys-functions upload" [
  deploy_id: string
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
  --runtime: string
  --size: int
  --x-nf-retry-count: int
  --body: string
]: any -> record<id: string, name: string, sha: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "runtime" $runtime "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id), name: (encode-path-segment $name)} | format pattern "/deploys/{deploy_id}/functions/{name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Nf-Retry-Count": $x_nf_retry_count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"runtime": $runtime, "size": $size} | compact), body: $req_body}
}

# POST /deploys/{deploy_id}/lock
#
# operationId: lockDeploy
export def "deploys-lock lock" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/lock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This is an internal-only endpoint.
#
# POST /deploys/{deploy_id}/plugin_runs
# operationId: createPluginRun
export def "deploys-plugin-runs create" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/plugin_runs"))
  let req_body = {"package": $package, "reporting_event": $reporting_event, "state": $state, "summary": $summary, "text": $text, "title": $title, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /deploys/{deploy_id}/unlock
#
# operationId: unlockDeploy
export def "deploys-unlock unlock" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/unlock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_slug" $account_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dns_zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"account_slug": $account_slug} | compact), body: null}
}

# POST /dns_zones
#
# operationId: createDnsZone
export def "dns-zones create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
  --name: string
  --site-id: string
]: any -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns_zones")
  let req_body = {"account_slug": $account_slug, "name": $name, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /dns_zones/{zone_id}/dns_records
#
# operationId: getDnsRecords
export def "dns-zones-dns-records get" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/dns_records"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /dns_zones/{zone_id}/dns_records
#
# operationId: createDnsRecord
export def "dns-zones-dns-records create" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/dns_records"))
  let req_body = {"flag": $flag, "hostname": $hostname, "port": $port, "priority": $priority, "tag": $tag, "ttl": $ttl, "type": $type, "value": $value, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($dns_record_id | is-empty) { error make --unspanned { msg: "path parameter 'dns_record_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id), dns_record_id: (encode-path-segment $dns_record_id)} | format pattern "/dns_zones/{zone_id}/dns_records/{dns_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: getIndividualDnsRecord
export def "dns-zones-dns-records get-individual" [
  zone_id: string
  dns_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($dns_record_id | is-empty) { error make --unspanned { msg: "path parameter 'dns_record_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id), dns_record_id: (encode-path-segment $dns_record_id)} | format pattern "/dns_zones/{zone_id}/dns_records/{dns_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /dns_zones/{zone_id}/transfer
#
# operationId: transferDnsZone
export def "dns-zones-transfer update" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # the account of the dns zone
  --transfer-account-id: string # the account you want to transfer the dns zone to
  --transfer-user-id: string # the user you want to transfer the dns zone to
]: nothing -> record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "transfer_account_id" $transfer_account_id "scalar") (serialize-qp "transfer_user_id" $transfer_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/transfer") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"account_id": $account_id, "transfer_account_id": $transfer_account_id, "transfer_user_id": $transfer_user_id} | compact), body: null}
}

# GET /forms/{form_id}/submissions
#
# operationId: listFormSubmissions
export def "forms-submissions list" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/{form_id}/submissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# GET /hooks
#
# operationId: listHooksBySiteId
export def "hooks list-by-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string
]: nothing -> table<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"site_id": $site_id} | compact), body: null}
}

# POST /hooks
#
# operationId: createHookBySiteId
export def "hooks create-by-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id-body: string #  (body field)
  --type: string
  --updated-at: string # format: dateTime
]: any -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let req_body = {"created_at": $created_at, "data": $data, "disabled": $disabled, "event": $event, "id": $id, "site_id": $site_id_body, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"site_id": $site_id} | compact), body: $req_body}
}

# GET /hooks/types
#
# operationId: listHookTypes
export def "hooks-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<events: list<string>, fields: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /hooks/{hook_id}
#
# operationId: updateHook
export def "hooks update" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}"))
  let req_body = {"created_at": $created_at, "data": $data, "disabled": $disabled, "event": $event, "id": $id, "site_id": $site_id, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /hooks/{hook_id}/enable
#
# operationId: enableHook
export def "hooks-enable enable" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /oauth/tickets
#
# operationId: createTicket
export def "oauth-tickets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
]: nothing -> record<authorized: bool, client_id: string, created_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"client_id": $client_id} | compact), body: null}
}

# GET /oauth/tickets/{ticket_id}
#
# operationId: showTicket
export def "oauth-tickets get-show" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorized: bool, client_id: string, created_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/oauth/tickets/{ticket_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /oauth/tickets/{ticket_id}/exchange
#
# operationId: exchangeTicket
export def "oauth-tickets-exchange create" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_token: string, created_at: string, id: string, user_email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/oauth/tickets/{ticket_id}/exchange"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> table<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search} | compact), body: null}
}

# GET /services/{addonName}
#
# operationId: showService
export def "services get-show" [
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($addon_name | is-empty) { error make --unspanned { msg: "path parameter 'addonName' must be non-empty" } }
  let full_url = (build-url $base ({addon_name: (encode-path-segment $addon_name)} | format pattern "/services/{addon_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /services/{addonName}/manifest
#
# operationId: showServiceManifest
export def "services-manifest get-show" [
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($addon_name | is-empty) { error make --unspanned { msg: "path parameter 'addonName' must be non-empty" } }
  let full_url = (build-url $base ({addon_name: (encode-path-segment $addon_name)} | format pattern "/services/{addon_name}/manifest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites
# operationId: listSites
export def "sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /sites
# operationId: createSite
# --build_settings shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
# --repo shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
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
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let req_body = {"account_name": $account_name, "account_slug": $account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"configure_dns": $configure_dns} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [updateEnvVar](#tag/environmentVariables/operation/updateEnvVar) to update a site's environment variables.
#
# PATCH /sites/{site_id}
# operationId: updateSite
# --build_settings shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
# --repo shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites update" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
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
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let req_body = {"account_name": $account_name, "account_slug": $account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sites/{site_id}/assets
#
# operationId: listSiteAssets
export def "sites-assets list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/assets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/assets
#
# operationId: createSiteAsset
export def "sites-assets create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --size: int # format: int64
  --content-type: string
  --visibility: string
]: nothing -> record<asset: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, form: record<fields: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/assets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "size": $size, "content_type": $content_type, "visibility": $visibility} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/assets/{asset_id}
#
# operationId: updateSiteAsset
export def "sites-assets update" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string
]: nothing -> record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}/public_signature"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/build_hooks
#
# operationId: listSiteBuildHooks
export def "sites-build-hooks list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/build_hooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/build_hooks
#
# operationId: createSiteBuildHook
export def "sites-build-hooks create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string
  --title: string
]: any -> record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/build_hooks"))
  let req_body = {"branch": $branch, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/build_hooks/{id}
#
# operationId: updateSiteBuildHook
export def "sites-build-hooks update" [
  site_id: string
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
  --branch: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}"))
  let req_body = {"branch": $branch, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sites/{site_id}/builds
#
# operationId: listSiteBuilds
export def "sites-builds list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# POST /sites/{site_id}/builds
#
# operationId: createSiteBuild
export def "sites-builds create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-cache: oneof<nothing, bool>
  --image: string
]: any -> record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/builds"))
  let req_body = {"clear_cache": $clear_cache, "image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sites/{site_id}/deployed-branches
#
# operationId: listSiteDeployedBranches
export def "sites-deployed-branches list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deploy_id: string, id: string, name: string, slug: string, ssl_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deployed-branches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/deploys
#
# operationId: listSiteDeploys
export def "sites-deploys list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deploys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deploy-previews": $deploy_previews, "production": $production, "state": $state, "branch": $branch, "latest-published": $latest_published, "page": $page, "per_page": $per_page} | compact), body: null}
}

# POST /sites/{site_id}/deploys
#
# operationId: createSiteDeploy
# --function_schedules item shape: {cron?: string, name?: string}
export def "sites-deploys create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --title: string
  --async: oneof<nothing, bool>
  --branch-body: string #  (body field)
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deploys") $qp)
  let req_body = {"async": $async, "branch": $branch_body, "draft": $draft, "files": $files, "framework": $framework, "function_schedules": $function_schedules, "functions": $functions, "functions_config": $functions_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"deploy-previews": $deploy_previews, "production": $production, "state": $state, "branch": $branch, "latest-published": $latest_published, "title": $title} | compact), body: $req_body}
}

# DELETE /sites/{site_id}/deploys/{deploy_id}
#
# operationId: deleteSiteDeploy
export def "sites-deploys delete" [
  site_id: string
  deploy_id: string
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/deploys/{deploy_id}
#
# operationId: updateSiteDeploy
# --function_schedules item shape: {cron?: string, name?: string}
export def "sites-deploys update" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}"))
  let req_body = {"async": $async, "branch": $branch, "draft": $draft, "files": $files, "framework": $framework, "function_schedules": $function_schedules, "functions": $functions, "functions_config": $functions_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /sites/{site_id}/deploys/{deploy_id}/restore
#
# operationId: restoreSiteDeploy
export def "sites-deploys-restore create" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/dns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/dns
#
# operationId: configureDNSForSite
export def "sites-dns update-configure" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/dns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/files
#
# operationId: listSiteFiles
export def "sites-files list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, mime_type: string, path: string, sha: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/files/{file_path}
#
# operationId: getSiteFileByPathName
export def "sites-files get-by-name" [
  site_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, mime_type: string, path: string, sha: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'file_path' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), file_path: (encode-path-segment $file_path)} | format pattern "/sites/{site_id}/files/{file_path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/forms
#
# operationId: listSiteForms
export def "sites-forms list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, fields: list<record>, id: string, name: string, paths: list<string>, site_id: string, submission_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/forms"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), form_id: (encode-path-segment $form_id)} | format pattern "/sites/{site_id}/forms/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/metadata
#
# operationId: updateSiteMetadata
export def "sites-metadata update" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/metadata"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --packages: list<string>
  --state: string
]: nothing -> table<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "packages" $packages "csv") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/plugin_runs/latest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"packages": $packages, "state": $state} | compact), body: null}
}

# This is an internal-only endpoint.
#
# PUT /sites/{site_id}/plugins/{package}
# operationId: updatePlugin
export def "sites-plugins update" [
  site_id: string
  package: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pinned-version: string
]: any -> record<package: string, pinned_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($package | is-empty) { error make --unspanned { msg: "path parameter 'package' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), package: (encode-path-segment $package)} | format pattern "/sites/{site_id}/plugins/{package}"))
  let req_body = {"pinned_version": $pinned_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT /sites/{site_id}/rollback
#
# operationId: rollbackSiteDeploy
export def "sites-rollback update-deploy" [
  site_id: string
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/rollback"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/service-instances
#
# operationId: listServiceInstancesForSite
export def "sites-service-instances list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/service-instances"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/services/{addon}/instances
#
# operationId: createServiceInstance
export def "sites-services-instances create" [
  site_id: string
  addon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon)} | format pattern "/sites/{site_id}/services/{addon}/instances"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: showServiceInstance
export def "sites-services-instances get-show" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: updateServiceInstance
export def "sites-services-instances update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sites/{site_id}/snippets
#
# operationId: listSiteSnippets
export def "sites-snippets list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/snippets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/snippets
#
# operationId: createSiteSnippet
export def "sites-snippets create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/snippets"))
  let req_body = {"general": $general, "general_position": $general_position, "goal": $goal, "goal_position": $goal_position, "id": $id, "site_id": $body_site_id, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/snippets/{snippet_id}
#
# operationId: updateSiteSnippet
export def "sites-snippets update" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}"))
  let req_body = {"general": $general, "general_position": $general_position, "goal": $goal, "goal_position": $goal_position, "id": $id, "site_id": $body_site_id, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sites/{site_id}/ssl
#
# operationId: showSiteTLSCertificate
export def "sites-ssl get-show-tls-certificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/ssl
#
# operationId: provisionSiteTLSCertificate
export def "sites-ssl create-provision-tls-certificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string
  --key: string
  --ca-certificates: string
]: nothing -> record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "certificate" $certificate "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ca_certificates" $ca_certificates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/ssl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"certificate": $certificate, "key": $key, "ca_certificates": $ca_certificates} | compact), body: null}
}

# GET /sites/{site_id}/submissions
#
# operationId: listSiteSubmissions
export def "sites-submissions list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/submissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# GET /sites/{site_id}/traffic_splits
#
# operationId: getSplitTests
export def "sites-traffic-splits get-tests" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/traffic_splits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/traffic_splits
#
# operationId: createSplitTest
export def "sites-traffic-splits create-test" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/traffic_splits"))
  let req_body = {"branch_tests": $branch_tests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /sites/{site_id}/traffic_splits/{split_test_id}
#
# operationId: updateSplitTest
export def "sites-traffic-splits update" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}"))
  let req_body = {"branch_tests": $branch_tests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/publish
#
# operationId: enableSplitTest
export def "sites-traffic-splits-publish enable" [
  site_id: string
  split_test_id: string
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/unpublish
#
# operationId: disableSplitTest
export def "sites-traffic-splits-unpublish disable" [
  site_id: string
  split_test_id: string
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}/unpublish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# [Beta] Unlinks the repo from the site. This action will also: - Delete associated deploy keys - Delete outgoing webhooks for the repo - Delete the site's build hooks
#
# PUT /sites/{site_id}/unlink_repo
# operationId: unlinkSiteRepo
export def "sites-unlink-repo update" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/unlink_repo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /submissions/{submission_id}
#
# operationId: listFormSubmission
export def "submissions list-form" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "page": $page, "per_page": $per_page} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<affiliate_id: string, avatar_url: string, created_at: string, email: string, full_name: string, id: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>, site_count: int, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: int, build_count: int, enqueued: int, minutes: record<current: int, current_average_sec: int, included_minutes: string, included_minutes_with_packs: string, last_updated_at: string, period_end_date: string, period_start_date: string, previous: int>, pending_concurrency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/builds/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /{account_slug}/members
#
# operationId: listMembersForAccount
export def "members list" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatar: string, email: string, full_name: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{account_slug}/members
#
# operationId: addMemberToAccount
export def "members create" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --role: string@role-completer
]: any -> table<avatar: string, email: string, full_name: string, id: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/members"))
  let req_body = {"email": $email, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE /{account_slug}/members/{member_id}
#
# operationId: removeAccountMember
export def "members delete" [
  account_slug: string
  member_id: string
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
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, email: string, full_name: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{account_slug}/members/{member_id}
#
# operationId: updateAccountMember
export def "members update" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer
  --site-access: string@site-access-completer
  --site-ids: list<string>
]: any -> record<avatar: string, email: string, full_name: string, id: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}"))
  let req_body = {"role": $role, "site_access": $site_access, "site_ids": $site_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /{account_slug}/sites
# operationId: listSitesForAccount
export def "sites list-1" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/sites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "page": $page, "per_page": $per_page} | compact), body: null}
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /{account_slug}/sites
# operationId: createSiteInTeam
# --build_settings shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --processing_settings shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
# --published_deploy shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
# --repo shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
export def "sites create-in-team" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --body-account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
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
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/sites") $qp)
  let req_body = {"account_name": $account_name, "account_slug": $body_account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"configure_dns": $configure_dns} | compact), body: $req_body}
}
