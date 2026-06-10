# Auto-generated client for Netlify's API documentation v2.55.0
# Source: https://open-api.netlify.com/openapi.json
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
def base-url-completer [] { ["https://api.netlify.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def filter-completer [] { ["all" "guest" "owner"] }
def context-name-completer [] { ["all" "branch-deploy" "deploy-preview" "dev" "dev-server" "production"] }
def scope-completer [] { ["builds" "functions" "post-processing" "runtime"] }
def scope-completer-1 [] { ["builds" "functions" "post_processing" "runtime"] }
def context-completer [] { ["all" "branch" "branch-deploy" "deploy-preview" "dev" "dev-server" "production"] }
def state-completer [] { ["accepted" "building" "enqueued" "error" "new" "pending_review" "prepared" "preparing" "processed" "processing" "ready" "rejected" "retrying" "uploaded" "uploading"] }
def role-completer [] { ["Billing Admin" "Developer" "Owner" "Reviewer"] }
def site-access-completer [] { ["all" "none" "selected"] }
def period-completer [] { ["monthly" "yearly"] }
def state-completer-1 [] { ["error" "live"] }
def order-by-completer [] { ["asc" "desc"] }
def state-completer-2 [] { ["done" "error" "live" "starting"] }
def type-completer [] { ["content_refresh" "new_dev_server"] }
def role-completer-1 [] { ["netlifydb_owner" "netlifydb_readonly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sites listSites" } } | get name | first)
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

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
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
  --name: string
  --filter: string@filter-completer
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list, required_functions: list, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list, functions_region: string, functions_region_overrides: list>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /sites
# operationId: createSite
# --published_deploy shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
# --processing_settings shape: {html?: record}
# --build_settings shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --repo shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
export def "sites createSite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --configure-dns: string@bool-completer
  --id: string
  --state: string
  --plan: string
  --name: string
  --custom-domain: string
  --domain-aliases: list
  --branch-deploy-custom-domain: string
  --deploy-preview-custom-domain: string
  --password: string
  --notification-email: string
  --body-url: string
  --ssl-url: string
  --admin-url: string
  --screenshot-url: string
  --created-at: string # format: dateTime
  --updated-at: string # format: dateTime
  --user-id: string
  --session-id: string
  --ssl: string@bool-completer
  --force-ssl: string@bool-completer
  --managed-dns: string@bool-completer
  --deploy-url: string
  --published-deploy: record # shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
  --account-id: string
  --account-name: string
  --account-slug: string
  --git-provider: string
  --deploy-hook: string
  --capabilities: record
  --processing-settings: record # shape: {html?: record}
  --build-settings: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
  --id-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --build-image: string
  --prerender: string
  --functions-region: string
  --prevent-non-git-prod-deploys: string@bool-completer # default: false
  --repo: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
]: any -> record<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record<pretty_urls: bool>>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list<string>, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let body = {id: $id, state: $state, plan: $plan, name: $name, custom_domain: $custom_domain, domain_aliases: $domain_aliases, branch_deploy_custom_domain: $branch_deploy_custom_domain, deploy_preview_custom_domain: $deploy_preview_custom_domain, password: $password, notification_email: $notification_email, url: $body_url, ssl_url: $ssl_url, admin_url: $admin_url, screenshot_url: $screenshot_url, created_at: $created_at, updated_at: $updated_at, user_id: $user_id, session_id: $session_id, ssl: $ssl, force_ssl: $force_ssl, managed_dns: $managed_dns, deploy_url: $deploy_url, published_deploy: $published_deploy, account_id: $account_id, account_name: $account_name, account_slug: $account_slug, git_provider: $git_provider, deploy_hook: $deploy_hook, capabilities: $capabilities, processing_settings: $processing_settings, build_settings: $build_settings, id_domain: $id_domain, default_hooks_data: $default_hooks_data, build_image: $build_image, prerender: $prerender, functions_region: $functions_region, prevent_non_git_prod_deploys: $prevent_non_git_prod_deploys, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
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
]: nothing -> record<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record<pretty_urls: bool>>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list<string>, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [updateEnvVar](#tag/environmentVariables/operation/updateEnvVar) to update a site's environment variables.
#
# PATCH /sites/{site_id}
# operationId: updateSite
# --published_deploy shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
# --processing_settings shape: {html?: record}
# --build_settings shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --repo shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
export def "sites updateSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --state: string
  --plan: string
  --name: string
  --custom-domain: string
  --domain-aliases: list
  --branch-deploy-custom-domain: string
  --deploy-preview-custom-domain: string
  --password: string
  --notification-email: string
  --body-url: string
  --ssl-url: string
  --admin-url: string
  --screenshot-url: string
  --created-at: string # format: dateTime
  --updated-at: string # format: dateTime
  --user-id: string
  --session-id: string
  --ssl: string@bool-completer
  --force-ssl: string@bool-completer
  --managed-dns: string@bool-completer
  --deploy-url: string
  --published-deploy: record # shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
  --account-id: string
  --account-name: string
  --account-slug: string
  --git-provider: string
  --deploy-hook: string
  --capabilities: record
  --processing-settings: record # shape: {html?: record}
  --build-settings: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
  --id-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --build-image: string
  --prerender: string
  --functions-region: string
  --prevent-non-git-prod-deploys: string@bool-completer # default: false
  --repo: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
]: any -> record<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record<pretty_urls: bool>>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list<string>, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let body = {id: $id, state: $state, plan: $plan, name: $name, custom_domain: $custom_domain, domain_aliases: $domain_aliases, branch_deploy_custom_domain: $branch_deploy_custom_domain, deploy_preview_custom_domain: $deploy_preview_custom_domain, password: $password, notification_email: $notification_email, url: $body_url, ssl_url: $ssl_url, admin_url: $admin_url, screenshot_url: $screenshot_url, created_at: $created_at, updated_at: $updated_at, user_id: $user_id, session_id: $session_id, ssl: $ssl, force_ssl: $force_ssl, managed_dns: $managed_dns, deploy_url: $deploy_url, published_deploy: $published_deploy, account_id: $account_id, account_name: $account_name, account_slug: $account_slug, git_provider: $git_provider, deploy_hook: $deploy_hook, capabilities: $capabilities, processing_settings: $processing_settings, build_settings: $build_settings, id_domain: $id_domain, default_hooks_data: $default_hooks_data, build_image: $build_image, prerender: $prerender, functions_region: $functions_region, prevent_non_git_prod_deploys: $prevent_non_git_prod_deploys, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provisions or updates a TLS certificate for the site.  **Creating a certificate (site has no certificate):** - Omit certificate params to initiate Let's Encrypt provisioning - Provide certificate, key, and ca_certificates to upload a custom certificate  **Updating a certificate (site already has a certificate):** - REQUIRES certificate, key, and ca_certificates to replace with a new custom certificate - Use POST /api/v1/sites/{site_id}/ssl/renew to renew an existing Let's Encrypt certificate
#
# POST /sites/{site_id}/ssl
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
  --certificate: string # PEM-encoded certificate. Required when updating an existing certificate.
  --key: string # PEM-encoded private key. Required when updating an existing certificate.
  --ca-certificates: string # PEM-encoded CA certificate chain. Required when updating an existing certificate.
]: nothing -> record<state: string, domains: list<string>, created_at: string, updated_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certificate" $certificate "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ca_certificates" $ca_certificates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/ssl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<state: string, domains: list<string>, created_at: string, updated_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/ssl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/ssl/certificates
#
# operationId: getAllCertificates
export def "sites-ssl-certificates get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string
]: nothing -> table<state: string, domains: list<string>, created_at: string, updated_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/ssl/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all environment variables for an account or site. An account corresponds to a team in the Netlify UI.
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
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer # Filter by scope
  --site-id: string # If specified, only return environment variables set on this site
]: nothing -> table<key: string, scopes: list<string>, values: list<record>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context_name" $context_name "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates new environment variables. Granular scopes are available on Pro plans and above.
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
  --site-id: string # If provided, create an environment variable on the site level, not the account level
  --body: record
]: any -> table<key: string, scopes: list<string>, values: list<record>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all environment variables for a site. This convenience method behaves the same as `getEnvVars` but doesn't require an `account_id` as input.
#
# GET /api/v1/sites/{site_id}/env
# operationId: getSiteEnvVars
export def "sites-env get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer-1 # Filter by scope
]: nothing -> table<key: string, scopes: list<string>, values: list<record>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context_name" $context_name "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sites/($site_id)/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns an individual environment variable.
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
  --site-id: string # If provided, return the environment variable for a specific site (no merging is performed)
]: nothing -> record<key: string, scopes: list<string>, values: table<id: string, value: string, context: string, context_parameter: string>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing environment variable and all of its values. Existing values will be replaced by values provided.
#
# PUT /accounts/{account_id}/env/{key}
# operationId: updateEnvVar
# --values item shape: {id?: string, value?: string, context?: "all"|"dev"|"dev-server"|"branch-deploy"|"deploy-preview"|"production"|"branch", context_parameter?: string}
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
  --site-id: string # If provided, update an environment variable set on this site
  --body-key: string # The existing or new name of the key, if you wish to rename it (case-sensitive)
  --scopes: list # The scopes that this environment variable is set to (Pro plans and above)
  --values: list # item shape: {id?: string, value?: string, context?: "all"|"dev"|"dev-server"|"branch-deploy"|"deploy-preview"|"production"|"branch", context_parameter?: string}
  --is-secret: string@bool-completer # Secret values are only readable by code running on Netlify's systems. With secrets, only the local development context values are readable from the UI, API, and CLI. By default, environment variable values are not secret.
]: any -> record<key: string, scopes: list<string>, values: table<id: string, value: string, context: string, context_parameter: string>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let body = {key: $body_key, scopes: $scopes, values: $values, is_secret: $is_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates or creates a new value for an existing environment variable.
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
  --site-id: string # If provided, update an environment variable set on this site
  --context: string@context-completer # The deploy context in which this value will be used. `dev` refers to local development when running `netlify dev`. `branch` must be provided with a value in `context_parameter`.
  --context-parameter: string # An additional parameter for custom branches. Currently, this is used for providing a branch name when `context=branch`.
  --value: string # The environment variable's unencrypted value
]: any -> record<key: string, scopes: list<string>, values: table<id: string, value: string, context: string, context_parameter: string>, is_secret: bool, updated_at: string, updated_by: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let body = {context: $context, context_parameter: $context_parameter, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an environment variable
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
  --site-id: string # If provided, delete the environment variable from this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specific environment variable value.
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
  --site-id: string # If provided, delete the value from an environment variable on this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/env/($key)/value/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/functions
#
# operationId: searchSiteFunctions
export def "sites-functions searchSiteFunctions" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string
]: nothing -> table<branch: string, created_at: string, functions: list<record>, id: string, log_type: string, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, site_id: string, name: string, paths: list<string>, submission_count: int, fields: list<record>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/forms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/forms/($form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, number: int, email: string, name: string, first_name: string, last_name: string, company: string, summary: string, body: string, data: record, created_at: string, site_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, path: string, sha: string, mime_type: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, site_id: string, creator_id: string, name: string, state: string, content_type: string, url: string, key: string, visibility: string, size: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --name: string
  --size: int # format: int64
  --content-type: string
  --visibility: string
]: nothing -> record<form: record<url: string, fields: record>, asset: record<id: string, site_id: string, creator_id: string, name: string, state: string, content_type: string, url: string, key: string, visibility: string, size: int, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, creator_id: string, name: string, state: string, content_type: string, url: string, key: string, visibility: string, size: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --state: string
]: nothing -> record<id: string, site_id: string, creator_id: string, name: string, state: string, content_type: string, url: string, key: string, visibility: string, size: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/assets/($asset_id)/public_signature")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, path: string, sha: string, mime_type: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/files/($file_path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purges cached content from Netlify's CDN. Supports purging by Cache-Tag.
#
# POST /purge
# operationId: purgeCache
export def "purge purgeCache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --site-id: string
  --site-slug: string
  --cache-tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/purge")
  let body = {site_id: $site_id, site_slug: $site_slug, cache_tags: $cache_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> table<id: int, site_id: string, title: string, general: string, general_position: string, goal: string, goal_position: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --id: int # format: int32
  --body-site-id: string
  --title: string
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
]: any -> record<id: int, site_id: string, title: string, general: string, general_position: string, goal: string, goal_position: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets")
  let body = {id: $id, site_id: $body_site_id, title: $title, general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: int, site_id: string, title: string, general: string, general_position: string, goal: string, goal_position: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --id: int # format: int32
  --body-site-id: string
  --title: string
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let body = {id: $id, site_id: $body_site_id, title: $title, general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> table<id: string, title: string, branch: string, url: string, site_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --title: string
  --branch: string
]: any -> record<id: string, title: string, branch: string, url: string, site_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks")
  let body = {title: $title, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, title: string, branch: string, url: string, site_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --title: string
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let body = {title: $title, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/build_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --deploy-previews: string@bool-completer
  --production: string@bool-completer
  --state: string@state-completer
  --branch: string
  --latest-published: string@bool-completer
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/deploys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/deploys
#
# operationId: createSiteDeploy
# --function_schedules item shape: {name?: string, cron?: string}
# --environment item shape: {key: string, value: string, is_secret: bool, scopes: list}
export def "sites-deploys createSiteDeploy" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deploy-previews: string@bool-completer
  --production: string@bool-completer
  --state: string@state-completer
  --branch: string
  --latest-published: string@bool-completer
  --title: string
  --files: record # A hash mapping file paths to SHA1 digests of the file contents.
  --zip: string # A zip file containing the site files to deploy. Alternative to 'files'. To use this field, set Content-Type to 'application/json' and include the zip content here. Alternatively, you can set Content-Type to 'application/zip' and send the zip as the raw request body (not as JSON).  (format: binary)
  --draft: string@bool-completer
  --async: string@bool-completer
  --functions: record
  --function-schedules: list # item shape: {name?: string, cron?: string}
  --functions-config: record
  --branch: string
  --framework: string
  --framework-version: string
  --environment: list # A list of deploy-specific environment variable data. Data specified this way applies only to this specific deploy and is merged into any existing environment variables set on the account and site.  Deploy-specific environment variable data takes precedence over account and site environment variable data: For example, a deploy-specific variable with the key `NODE_ENV` will take priority over any existing site- and account-level environment variable data with the key `NODE_ENV`.  Environment variable data may be provided at one of two times:  - When creating a new Deploy with deploy files (most common) - When finalizing an existing Deploy with deploy files  Once set, environment variables for a specific deploy cannot be modified. Subsequent attempts to modify environment variable data for a deploy will be ignored. — item shape: {key: string, value: string, is_secret: bool, scopes: list}
]: any -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/deploys" $qp)
  let body = {files: $files, zip: $zip, draft: $draft, async: $async, functions: $functions, function_schedules: $function_schedules, functions_config: $functions_config, branch: $branch, framework: $framework, framework_version: $framework_version, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/deploys/{deploy_id}
#
# operationId: updateSiteDeploy
# --function_schedules item shape: {name?: string, cron?: string}
# --environment item shape: {key: string, value: string, is_secret: bool, scopes: list}
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
  --commit-ref: string
  --files: record # A hash mapping file paths to SHA1 digests of the file contents.
  --zip: string # A zip file containing the site files to deploy. Alternative to 'files'. To use this field, set Content-Type to 'application/json' and include the zip content here. Alternatively, you can set Content-Type to 'application/zip' and send the zip as the raw request body (not as JSON).  (format: binary)
  --draft: string@bool-completer
  --async: string@bool-completer
  --functions: record
  --function-schedules: list # item shape: {name?: string, cron?: string}
  --functions-config: record
  --branch: string
  --framework: string
  --framework-version: string
  --environment: list # A list of deploy-specific environment variable data. Data specified this way applies only to this specific deploy and is merged into any existing environment variables set on the account and site.  Deploy-specific environment variable data takes precedence over account and site environment variable data: For example, a deploy-specific variable with the key `NODE_ENV` will take priority over any existing site- and account-level environment variable data with the key `NODE_ENV`.  Environment variable data may be provided at one of two times:  - When creating a new Deploy with deploy files (most common) - When finalizing an existing Deploy with deploy files  Once set, environment variables for a specific deploy cannot be modified. Subsequent attempts to modify environment variable data for a deploy will be ignored. — item shape: {key: string, value: string, is_secret: bool, scopes: list}
]: any -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "commit_ref" $commit_ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)" $qp)
  let body = {files: $files, zip: $zip, draft: $draft, async: $async, functions: $functions, function_schedules: $function_schedules, functions_config: $functions_config, branch: $branch, framework: $framework, framework_version: $framework_version, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deploys/($deploy_id)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, deploy_id: string, sha: string, done: bool, error: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Runs a build for a site. The build will be scheduled to run at the first opportunity, but it might not start immediately if insufficient account build capacity is available.  Files for build can be uploaded as a zipped site using one of these methods: 1. Set Content-Type to 'application/zip' and send the zip file as the raw request body 2. Set Content-Type to 'multipart/form-data' and include the zip file in the 'zip' field
#
# POST /sites/{site_id}/builds
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
  --branch: string # If no branch is specified, it is treated as a production deploy If a branch IS specified and matches the main branch, it is also production If a branch is specified and doesn't match the main branch, it is a branch deploy
  --clear-cache: string@bool-completer # Whether to clear the build cache before building
  --image: string # The build image tag to use for the build
  --template-id: string # The build template to use for the build
  --title: string # The title of the build
  --zip: string # A zip file containing the site files to build. Only used with Content-Type 'multipart/form-data'. Alternatively, set Content-Type to 'application/zip' and send the zip as the raw request body (no 'zip' parameter needed).  (format: binary)
]: any -> record<id: string, deploy_id: string, sha: string, done: bool, error: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "clear_cache" $clear_cache "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "template_id" $template_id "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/builds" $qp)
  let body = {zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
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
]: nothing -> table<id: string, deploy_id: string, name: string, slug: string, url: string, ssl_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/deployed-branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record<pretty_urls: bool>>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list<string>, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/unlink_repo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Re-enables a site that was previously disabled by the user. Sites that were disabled for usage exceeded or marked as spam cannot be re-enabled via this endpoint.
#
# PUT /sites/{site_id}/enable
# operationId: enableSite
export def "sites-enable enableSite" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disables a site, preventing it from serving content. The site can be re-enabled later using the enable endpoint.
#
# PUT /sites/{site_id}/disable
# operationId: disableSite
export def "sites-disable disableSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for disabling the site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, deploy_id: string, sha: string, done: bool, error: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/builds/($build_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/builds/($build_id)/log")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --buildbot-version: string
  --build-version: string
  --task-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "buildbot_version" $buildbot_version "scalar") (serialize-qp "build_version" $build_version "scalar") (serialize-qp "task_id" $task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/builds/($build_id)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<active: int, pending_concurrency: int, enqueued: int, build_count: int, minutes: record<current: int, current_average_sec: int, previous: int, period_start_date: string, period_end_date: string, last_updated_at: string, included_minutes: string, included_minutes_with_packs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_id)/builds/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: list<record>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: list<record>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/rollback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: table<name: string, cron: string>, functions_region: string, functions_region_overrides: table<name: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploys/($deploy_id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --size: int
  --body: record
]: any -> record<id: string, path: string, sha: string, mime_type: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploys/($deploy_id)/files/($path)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
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
  --runtime: string
  --invocation-mode: string
  --timeout: int
  --size: int
  --X-Nf-Retry-Count: int
  --body: record
]: any -> record<id: string, name: string, sha: string, region: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runtime" $runtime "scalar") (serialize-qp "invocation_mode" $invocation_mode "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploys/($deploy_id)/functions/($name)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nf-Retry-Count": $X_Nf_Retry_Count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
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
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, number: int, email: string, name: string, first_name: string, last_name: string, company: string, summary: string, body: string, data: record, created_at: string, site_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/forms/($form_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --site-id: string
]: nothing -> table<id: string, site_id: string, type: string, event: string, data: record, created_at: string, updated_at: string, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --site-id: string
  --id: string
  --site-id: string
  --type: string
  --event: string
  --data: record
  --created-at: string # format: dateTime
  --updated-at: string # format: dateTime
  --disabled: string@bool-completer
]: any -> record<id: string, site_id: string, type: string, event: string, data: record, created_at: string, updated_at: string, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let body = {id: $id, site_id: $site_id, type: $type, event: $event, data: $data, created_at: $created_at, updated_at: $updated_at, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, site_id: string, type: string, event: string, data: record, created_at: string, updated_at: string, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --id: string
  --site-id: string
  --type: string
  --event: string
  --data: record
  --created-at: string # format: dateTime
  --updated-at: string # format: dateTime
  --disabled: string@bool-completer
]: any -> record<id: string, site_id: string, type: string, event: string, data: record, created_at: string, updated_at: string, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let body = {id: $id, site_id: $site_id, type: $type, event: $event, data: $data, created_at: $created_at, updated_at: $updated_at, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, site_id: string, type: string, event: string, data: record, created_at: string, updated_at: string, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hook_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<name: string, events: list<string>, fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --client-id: string
  --message: string
]: any -> record<id: string, client_id: string, authorized: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/tickets" $qp)
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, client_id: string, authorized: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, access_token: string, user_id: string, user_email: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/tickets/($ticket_id)/exchange")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, public_key: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, public_key: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, public_key: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /{account_slug}/sites
# operationId: createSiteInTeam
# --published_deploy shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
# --processing_settings shape: {html?: record}
# --build_settings shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
# --default_hooks_data shape: {access_token?: string}
# --repo shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
export def "sites createSiteInTeam" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --configure-dns: string@bool-completer
  --id: string
  --state: string
  --plan: string
  --name: string
  --custom-domain: string
  --domain-aliases: list
  --branch-deploy-custom-domain: string
  --deploy-preview-custom-domain: string
  --password: string
  --notification-email: string
  --body-url: string
  --ssl-url: string
  --admin-url: string
  --screenshot-url: string
  --created-at: string # format: dateTime
  --updated-at: string # format: dateTime
  --user-id: string
  --session-id: string
  --ssl: string@bool-completer
  --force-ssl: string@bool-completer
  --managed-dns: string@bool-completer
  --deploy-url: string
  --published-deploy: record # shape: {id?: string, site_id?: string, user_id?: string, build_id?: string, state?: string, name?: string, url?: string, ssl_url?: string, admin_url?: string, deploy_url?: string, deploy_ssl_url?: string, screenshot_url?: string, review_id?: float, draft?: bool, required?: list, required_functions?: list, error_message?: string, branch?: string, commit_ref?: string, commit_url?: string, skipped?: bool, created_at?: string, updated_at?: string, published_at?: string, title?: string, context?: string, locked?: bool, review_url?: string, framework?: string, skew_protection_token?: string, function_schedules?: list, functions_region?: string, functions_region_overrides?: list}
  --account-id: string
  --account-name: string
  --body-account-slug: string
  --git-provider: string
  --deploy-hook: string
  --capabilities: record
  --processing-settings: record # shape: {html?: record}
  --build-settings: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
  --id-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --build-image: string
  --prerender: string
  --functions-region: string
  --prevent-non-git-prod-deploys: string@bool-completer # default: false
  --repo: record # shape: {id?: int, provider?: string, deploy_key_id?: string, repo_path?: string, repo_branch?: string, dir?: string, functions_dir?: string, cmd?: string, allowed_branches?: list, public_repo?: bool, private_logs?: bool, repo_url?: string, env?: record, installation_id?: int, stop_builds?: bool}
]: any -> record<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list<string>, required_functions: list<string>, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list<record>, functions_region: string, functions_region_overrides: list<record>>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record<pretty_urls: bool>>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list<string>, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($account_slug)/sites" $qp)
  let body = {id: $id, state: $state, plan: $plan, name: $name, custom_domain: $custom_domain, domain_aliases: $domain_aliases, branch_deploy_custom_domain: $branch_deploy_custom_domain, deploy_preview_custom_domain: $deploy_preview_custom_domain, password: $password, notification_email: $notification_email, url: $body_url, ssl_url: $ssl_url, admin_url: $admin_url, screenshot_url: $screenshot_url, created_at: $created_at, updated_at: $updated_at, user_id: $user_id, session_id: $session_id, ssl: $ssl, force_ssl: $force_ssl, managed_dns: $managed_dns, deploy_url: $deploy_url, published_deploy: $published_deploy, account_id: $account_id, account_name: $account_name, account_slug: $body_account_slug, git_provider: $git_provider, deploy_hook: $deploy_hook, capabilities: $capabilities, processing_settings: $processing_settings, build_settings: $build_settings, id_domain: $id_domain, default_hooks_data: $default_hooks_data, build_image: $build_image, prerender: $prerender, functions_region: $functions_region, prevent_non_git_prod_deploys: $prevent_non_git_prod_deploys, repo: $repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# **Note:** Environment variable keys and values have moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
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
  --name: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, state: string, plan: string, name: string, custom_domain: string, domain_aliases: list<string>, branch_deploy_custom_domain: string, deploy_preview_custom_domain: string, password: string, notification_email: string, url: string, ssl_url: string, admin_url: string, screenshot_url: string, created_at: string, updated_at: string, user_id: string, session_id: string, ssl: bool, force_ssl: bool, managed_dns: bool, deploy_url: string, published_deploy: record<id: string, site_id: string, user_id: string, build_id: string, state: string, name: string, url: string, ssl_url: string, admin_url: string, deploy_url: string, deploy_ssl_url: string, screenshot_url: string, review_id: float, draft: bool, required: list, required_functions: list, error_message: string, branch: string, commit_ref: string, commit_url: string, skipped: bool, created_at: string, updated_at: string, published_at: string, title: string, context: string, locked: bool, review_url: string, framework: string, skew_protection_token: string, function_schedules: list, functions_region: string, functions_region_overrides: list>, account_id: string, account_name: string, account_slug: string, git_provider: string, deploy_hook: string, capabilities: record, processing_settings: record<html: record>, build_settings: record<id: int, provider: string, deploy_key_id: string, repo_path: string, repo_branch: string, dir: string, functions_dir: string, cmd: string, allowed_branches: list, public_repo: bool, private_logs: bool, repo_url: string, env: record, installation_id: int, stop_builds: bool>, id_domain: string, default_hooks_data: record<access_token: string>, build_image: string, prerender: string, functions_region: string, prevent_non_git_prod_deploys: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($account_slug)/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, full_name: string, email: string, avatar: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --role: string@role-completer
  --email: string
]: any -> table<id: string, full_name: string, email: string, avatar: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members")
  let body = {role: $role, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, full_name: string, email: string, avatar: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --role: string@role-completer
  --site-access: string@site-access-completer
  --site-ids: list
]: any -> record<id: string, full_name: string, email: string, avatar: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let body = {role: $role, site_access: $site_access, site_ids: $site_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($account_slug)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, method_name: string, type: string, state: string, data: record<card_type: string, last4: string, email: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/payment_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, name: string, description: string, capabilities: record, monthly_dollar_price: int, yearly_dollar_price: int, monthly_seats_addon_dollar_price: int, yearly_seats_addon_dollar_price: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, name: string, slug: string, type: string, capabilities: record<sites: record, collaborators: record>, billing_name: string, billing_email: string, billing_details: string, billing_period: string, payment_method_id: string, type_name: string, type_id: string, owner_ids: list<string>, roles_allowed: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  name: string
  type_id: string
  --payment-method-id: string
  --period: string@period-completer
  --extra-seats-block: int
]: any -> record<id: string, name: string, slug: string, type: string, capabilities: record<sites: record<included: int, used: int>, collaborators: record<included: int, used: int>>, billing_name: string, billing_email: string, billing_details: string, billing_period: string, payment_method_id: string, type_name: string, type_id: string, owner_ids: list<string>, roles_allowed: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {name: $name, type_id: $type_id, payment_method_id: $payment_method_id, period: $period, extra_seats_block: $extra_seats_block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, name: string, slug: string, type: string, capabilities: record<sites: record<included: int, used: int>, collaborators: record<included: int, used: int>>, billing_name: string, billing_email: string, billing_details: string, billing_period: string, payment_method_id: string, type_name: string, type_id: string, owner_ids: list<string>, roles_allowed: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --name: string
  --slug: string
  --type-id: string
  --extra-seats-block: int
  --billing-name: string
  --billing-email: string
  --billing-details: string
]: any -> record<id: string, name: string, slug: string, type: string, capabilities: record<sites: record<included: int, used: int>, collaborators: record<included: int, used: int>>, billing_name: string, billing_email: string, billing_details: string, billing_period: string, payment_method_id: string, type_name: string, type_id: string, owner_ids: list<string>, roles_allowed: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let body = {name: $name, slug: $slug, type_id: $type_id, extra_seats_block: $extra_seats_block, billing_name: $billing_name, billing_email: $billing_email, billing_details: $billing_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-query: string
  --log-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, account_id: string, payload: record<actor_id: string, actor_name: string, actor_email: string, action: string, timestamp: string, log_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "log_type" $log_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /agent_runners
#
# operationId: listAgentRunners
export def "agent-runners listAgentRunners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string
  --site-id: string
  --page: int # format: int32
  --per-page: int # format: int32
  --state: string@state-completer-1
  --title: string
  --branch: string
  --result-branch: string
  --qp-from: int
  --qp-to: int
]: nothing -> table<id: string, site_id: string, parent_agent_runner_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, branch: string, result_branch: string, pr_url: string, pr_branch: string, pr_state: string, pr_number: int, pr_is_being_created: bool, pr_error: string, current_task: string, result_diff: string, sha: string, merge_commit_sha: string, merge_commit_error: string, merge_commit_is_being_created: bool, base_deploy_id: string, attached_file_keys: list<string>, active_session_created_at: string, latest_session_deploy_id: string, latest_session_deploy_url: string, user: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "result_branch" $result_branch "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/agent_runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /agent_runners
#
# operationId: createAgentRunner
export def "agent-runners createAgentRunner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --site-id: string
  --deploy-id: string
  --branch: string
  --prompt: string
  --agent: string
  --model: string
  --parent-agent-runner-id: string
  --dev-server-image: string
  --file-keys: list
]: nothing -> record<id: string, site_id: string, parent_agent_runner_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, branch: string, result_branch: string, pr_url: string, pr_branch: string, pr_state: string, pr_number: int, pr_is_being_created: bool, pr_error: string, current_task: string, result_diff: string, sha: string, merge_commit_sha: string, merge_commit_error: string, merge_commit_is_being_created: bool, base_deploy_id: string, attached_file_keys: list<string>, active_session_created_at: string, latest_session_deploy_id: string, latest_session_deploy_url: string, user: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar") (serialize-qp "deploy_id" $deploy_id "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "prompt" $prompt "scalar") (serialize-qp "agent" $agent "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "parent_agent_runner_id" $parent_agent_runner_id "scalar") (serialize-qp "dev_server_image" $dev_server_image "scalar") (serialize-qp "file_keys" $file_keys "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/agent_runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /agent_runners/{agent_runner_id}
#
# operationId: getAgentRunner
export def "agent-runners get" [
  agent_runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, site_id: string, parent_agent_runner_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, branch: string, result_branch: string, pr_url: string, pr_branch: string, pr_state: string, pr_number: int, pr_is_being_created: bool, pr_error: string, current_task: string, result_diff: string, sha: string, merge_commit_sha: string, merge_commit_error: string, merge_commit_is_being_created: bool, base_deploy_id: string, attached_file_keys: list<string>, active_session_created_at: string, latest_session_deploy_id: string, latest_session_deploy_url: string, user: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /agent_runners/{agent_runner_id}
#
# operationId: updateAgentRunner
export def "agent-runners updateAgentRunner" [
  agent_runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, site_id: string, parent_agent_runner_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, branch: string, result_branch: string, pr_url: string, pr_branch: string, pr_state: string, pr_number: int, pr_is_being_created: bool, pr_error: string, current_task: string, result_diff: string, sha: string, merge_commit_sha: string, merge_commit_error: string, merge_commit_is_being_created: bool, base_deploy_id: string, attached_file_keys: list<string>, active_session_created_at: string, latest_session_deploy_id: string, latest_session_deploy_url: string, user: record<id: string, full_name: string, email: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /agent_runners/{agent_runner_id}
#
# operationId: deleteAgentRunner
export def "agent-runners delete" [
  agent_runner_id: string
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
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /agent_runners/{agent_runner_id}/archive
#
# operationId: archiveAgentRunner
export def "agent-runners-archive archiveAgentRunner" [
  agent_runner_id: string
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
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /agent_runners/{agent_runner_id}/sessions
#
# operationId: listAgentRunnerSessions
export def "agent-runners-sessions listAgentRunnerSessions" [
  agent_runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32
  --per-page: int # format: int32
  --state: string@state-completer-1
  --qp-from: int
  --qp-to: int
  --order-by: string@order-by-completer
]: nothing -> table<id: string, agent_runner_id: string, dev_server_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, prompt: string, agent_config: record<agent: string, model: string>, result: string, result_diff: string, commit_sha: string, deploy_id: string, deploy_url: string, duration: int, steps: list<record>, user: record<id: string, full_name: string, email: string, avatar_url: string>, attached_file_keys: list<string>, result_zip_file_name: string, is_published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /agent_runners/{agent_runner_id}/sessions
#
# operationId: createAgentRunnerSession
export def "agent-runners-sessions createAgentRunnerSession" [
  agent_runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prompt: string
  --agent: string
  --model: string
  --file-keys: list
]: nothing -> record<id: string, agent_runner_id: string, dev_server_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, prompt: string, agent_config: record<agent: string, model: string>, result: string, result_diff: string, commit_sha: string, deploy_id: string, deploy_url: string, duration: int, steps: table<title: string, message: string>, user: record<id: string, full_name: string, email: string, avatar_url: string>, attached_file_keys: list<string>, result_zip_file_name: string, is_published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prompt" $prompt "scalar") (serialize-qp "agent" $agent "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "file_keys" $file_keys "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /agent_runners/{agent_runner_id}/sessions/{agent_runner_session_id}
#
# operationId: getAgentRunnerSession
export def "agent-runners-sessions get" [
  agent_runner_id: string
  agent_runner_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, agent_runner_id: string, dev_server_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, prompt: string, agent_config: record<agent: string, model: string>, result: string, result_diff: string, commit_sha: string, deploy_id: string, deploy_url: string, duration: int, steps: table<title: string, message: string>, user: record<id: string, full_name: string, email: string, avatar_url: string>, attached_file_keys: list<string>, result_zip_file_name: string, is_published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/sessions/($agent_runner_session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /agent_runners/{agent_runner_id}/sessions/{agent_runner_session_id}
#
# operationId: updateAgentRunnerSession
export def "agent-runners-sessions updateAgentRunnerSession" [
  agent_runner_id: string
  agent_runner_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-published: string@bool-completer
]: nothing -> record<id: string, agent_runner_id: string, dev_server_id: string, state: string, created_at: string, updated_at: string, done_at: string, title: string, prompt: string, agent_config: record<agent: string, model: string>, result: string, result_diff: string, commit_sha: string, deploy_id: string, deploy_url: string, duration: int, steps: table<title: string, message: string>, user: record<id: string, full_name: string, email: string, avatar_url: string>, attached_file_keys: list<string>, result_zip_file_name: string, is_published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_published" $is_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/sessions/($agent_runner_session_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /agent_runners/{agent_runner_id}/sessions/{agent_runner_session_id}
#
# operationId: deleteAgentRunnerSession
export def "agent-runners-sessions delete" [
  agent_runner_id: string
  agent_runner_session_id: string
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
  let full_url = (build-url $base $"/agent_runners/($agent_runner_id)/sessions/($agent_runner_session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, number: int, email: string, name: string, first_name: string, last_name: string, company: string, summary: string, body: string, data: record, created_at: string, site_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/submissions/($submission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submissions/($submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, url: string, config: record, external_attributes: record, service_slug: string, service_path: string, service_name: string, env: record, snippets: list<record>, auth_url: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/service-instances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --body: record
]: any -> record<id: string, url: string, config: record, external_attributes: record, service_slug: string, service_path: string, service_name: string, env: record, snippets: list<record>, auth_url: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, url: string, config: record, external_attributes: record, service_slug: string, service_path: string, service_name: string, env: record, snippets: list<record>, auth_url: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/services/($addon)/instances/($instance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --search: string
]: nothing -> table<id: string, name: string, slug: string, service_path: string, long_description: string, description: string, events: list<record>, tags: list<string>, icon: string, manifest_url: string, environments: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, name: string, slug: string, service_path: string, long_description: string, description: string, events: list<record>, tags: list<string>, icon: string, manifest_url: string, environments: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($addonName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($addonName)/manifest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, uid: string, full_name: string, avatar_url: string, email: string, affiliate_id: string, site_count: int, created_at: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --branch-tests: record
]: any -> record<id: string, site_id: string, name: string, path: string, branches: list<record>, active: bool, created_at: string, updated_at: string, unpublished_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits")
  let body = {branch_tests: $branch_tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> table<id: string, site_id: string, name: string, path: string, branches: list<record>, active: bool, created_at: string, updated_at: string, unpublished_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --branch-tests: record
]: any -> record<id: string, site_id: string, name: string, path: string, branches: list<record>, active: bool, created_at: string, updated_at: string, unpublished_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)")
  let body = {branch_tests: $branch_tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, site_id: string, name: string, path: string, branches: list<record>, active: bool, created_at: string, updated_at: string, unpublished_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/traffic_splits/($split_test_id)/unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --account-slug: string
  --site-id: string
  --name: string
]: any -> record<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: table<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns_zones")
  let body = {account_slug: $account_slug, site_id: $site_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --account-slug: string
]: nothing -> table<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: list<record>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_slug" $account_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dns_zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: table<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --account-id: string # the account of the dns zone
  --transfer-account-id: string # the account you want to transfer the dns zone to
  --transfer-user-id: string # the user you want to transfer the dns zone to
]: nothing -> record<id: string, name: string, errors: list<string>, supported_record_types: list<string>, user_id: string, created_at: string, updated_at: string, records: table<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool>, dns_servers: list<string>, account_id: string, site_id: string, account_slug: string, account_name: string, domain: string, ipv6_enabled: bool, dedicated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "transfer_account_id" $transfer_account_id "scalar") (serialize-qp "transfer_user_id" $transfer_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dns_zones/($zone_id)/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --type: string
  --hostname: string
  --value: string
  --ttl: int # format: int64
  --priority: int # format: int64
  --weight: int # format: int64
  --port: int # format: int64
  --flag: int # format: int64
  --tag: string
]: any -> record<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records")
  let body = {type: $type, hostname: $hostname, value: $value, ttl: $ttl, priority: $priority, weight: $weight, port: $port, flag: $flag, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, hostname: string, type: string, value: string, ttl: int, priority: int, dns_zone_id: string, site_id: string, flag: int, tag: string, managed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records/($dns_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns_zones/($zone_id)/dns_records/($dns_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/dev_servers
#
# operationId: listSiteDevServers
export def "sites-dev-servers listSiteDevServers" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<id: string, site_id: string, branch: string, url: string, state: string, created_at: string, updated_at: string, starting_at: string, error_at: string, live_at: string, done_at: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/dev_servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/dev_servers
#
# operationId: createSiteDevServer
export def "sites-dev-servers createSiteDevServer" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> table<id: string, site_id: string, branch: string, url: string, state: string, created_at: string, updated_at: string, starting_at: string, error_at: string, live_at: string, done_at: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/dev_servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /sites/{site_id}/dev_servers
#
# operationId: deleteSiteDevServers
export def "sites-dev-servers delete" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/dev_servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sites/{site_id}/dev_servers/{dev_server_id}
#
# operationId: getSiteDevServer
export def "sites-dev-servers get" [
  site_id: string
  dev_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, site_id: string, branch: string, url: string, state: string, created_at: string, updated_at: string, starting_at: string, error_at: string, live_at: string, done_at: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_servers/($dev_server_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/dev_servers/{dev_server_id}/state
#
# operationId: updateDevServerState
export def "sites-dev-servers-state updateDevServerState" [
  site_id: string
  dev_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  state: string@state-completer-2
  --task-id: string
  --body-error: string
]: any -> record<id: string, site_id: string, branch: string, url: string, state: string, created_at: string, updated_at: string, starting_at: string, error_at: string, live_at: string, done_at: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_servers/($dev_server_id)/state")
  let body = {state: $state, task_id: $task_id, error: $body_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/dev_server_hooks
#
# operationId: listSiteDevServerHooks
export def "sites-dev-server-hooks listSiteDevServerHooks" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, title: string, branch: string, url: string, site_id: string, created_at: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_server_hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /sites/{site_id}/dev_server_hooks
#
# operationId: createSiteDevServerHook
export def "sites-dev-server-hooks createSiteDevServerHook" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --branch: string
  --type: string@type-completer
]: any -> record<id: string, title: string, branch: string, url: string, site_id: string, created_at: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_server_hooks")
  let body = {title: $title, branch: $branch, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /sites/{site_id}/dev_server_hooks/{id}
#
# operationId: getSiteDevServerHook
export def "sites-dev-server-hooks get" [
  site_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, branch: string, url: string, site_id: string, created_at: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_server_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /sites/{site_id}/dev_server_hooks/{id}
#
# operationId: updateSiteDevServerHook
export def "sites-dev-server-hooks updateSiteDevServerHook" [
  site_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --branch: string
  --type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/dev_server_hooks/($id)")
  let body = {title: $title, branch: $branch, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /sites/{site_id}/dev_server_hooks/{id}
#
# operationId: deleteSiteDevServerHook
export def "sites-dev-server-hooks delete" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/dev_server_hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /ai-gateway/providers
#
# operationId: getAIGatewayProviders
export def "ai-gateway-providers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<providers: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai-gateway/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns an AI Gateway token for a specific site
#
# GET /sites/{site_id}/ai-gateway/token
# operationId: getAIGatewayToken
export def "sites-ai-gateway-token get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: string, url: string, expires_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/ai-gateway/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns an AI Gateway token scoped to an account
#
# GET /accounts/{account_id}/ai-gateway/token
# operationId: getAccountAIGatewayToken
export def "accounts-ai-gateway-token get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: string, url: string, expires_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/ai-gateway/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new database for the specified site. If a database already exists, returns the existing connection string. The database region defaults to the site's functions region if not specified.
#
# POST /sites/{site_id}/database
# operationId: createSiteDatabase
export def "sites-database createSiteDatabase" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # The region where the database should be created. Defaults to the site's functions region if not specified.
]: any -> record<connection_string: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database")
  let body = {region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the database connection string for the specified site.
#
# GET /sites/{site_id}/database
# operationId: getSiteDatabase
export def "sites-database get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # The database role to use for the connection string. Defaults to netlifydb_owner if not specified.
]: nothing -> record<connection_string: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/database" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the database and all associated branches and snapshots for the specified site.
#
# DELETE /sites/{site_id}/database
# operationId: deleteSiteDatabase
export def "sites-database delete" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/database")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new database branch. If a branch already exists for the specified branch ID, returns the existing connection string.
#
# POST /sites/{site_id}/database/branch
# operationId: createSiteDatabaseBranch
export def "sites-database-branch createSiteDatabaseBranch" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-branch-id: string # The ID of the parent branch to create the new branch from. Defaults to the production branch if not specified.
  branch_id: string # The branch identifier
  --metadata: record # Arbitrary metadata to associate with the branch
]: any -> record<connection_string: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/branch")
  let body = {parent_branch_id: $parent_branch_id, branch_id: $branch_id, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all branches for the site's database with compute status and metadata.
#
# GET /sites/{site_id}/database/branches
# operationId: listSiteDatabaseBranches
export def "sites-database-branches listSiteDatabaseBranches" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<branches: table<branch_id: string, name: string, connection_string: string, state: string, logical_size_bytes: int, created_at: string, updated_at: string, last_active_at: string, compute: record, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the database branch connection string for a specific branch.
#
# GET /sites/{site_id}/database/branch/{branch_id}
# operationId: getSiteDatabaseBranch
export def "sites-database-branch get" [
  site_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # The database role to use for the connection string. Defaults to netlifydb_owner if not specified.
]: nothing -> record<connection_string: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/database/branch/($branch_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a database branch.
#
# DELETE /sites/{site_id}/database/branch/{branch_id}
# operationId: deleteSiteDatabaseBranch
export def "sites-database-branch delete" [
  site_id: string
  branch_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/database/branch/($branch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resets a non-production database branch by re-forking it from a source branch (defaults to the production branch). If the target branch is already in sync with the source, returns the existing connection string without performing a reset, unless `force=true` is passed. The production branch cannot be reset.
#
# POST /sites/{site_id}/database/branch/{branch_id}/reset
# operationId: resetSiteDatabaseBranch
export def "sites-database-branch-reset resetSiteDatabaseBranch" [
  site_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # If true, resets the branch even when it is already in sync with the source.
  --role: string@role-completer-1 # The database role to use for the returned connection string. Defaults to netlifydb_owner if not specified.
  --source-branch-id: string # The ID of the branch to re-fork the target branch from. Defaults to "production" if not specified.
]: any -> record<reset: bool, connection_string: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/database/branch/($branch_id)/reset" $qp)
  let body = {source_branch_id: $source_branch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets compute settings for a specific database branch, overriding project-level settings. Requires a Pro or higher plan.
#
# PUT /sites/{site_id}/database/branch/{branch_id}/compute/settings
# operationId: setSiteDatabaseBranchComputeSettings
export def "sites-database-branch-compute-settings setSiteDatabaseBranchComputeSettings" [
  site_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-cu: float # Minimum compute units (0.25 to 16.0). Must be less than or equal to max_cu. (nullable, format: double)
  --max-cu: float # Maximum compute units (0.25 to 16.0). Must be greater than or equal to min_cu. max_cu - min_cu must not exceed 8.0. (nullable, format: double)
  --sleep-timeout-seconds: int # Seconds of inactivity before the compute endpoint is suspended. Use -1 for always on, or a non-negative value. (nullable, format: int64)
]: any -> record<min_cu: float, max_cu: float, sleep_timeout_seconds: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/branch/($branch_id)/compute/settings")
  let body = {min_cu: $min_cu, max_cu: $max_cu, sleep_timeout_seconds: $sleep_timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets project-level compute settings for the database. Applied to new branches. Can be overridden per-branch. Requires a Pro or higher plan.
#
# PUT /sites/{site_id}/database/compute/settings
# operationId: setSiteDatabaseComputeSettings
export def "sites-database-compute-settings setSiteDatabaseComputeSettings" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-cu: float # Minimum compute units (0.25 to 16.0). Must be less than or equal to max_cu. (nullable, format: double)
  --max-cu: float # Maximum compute units (0.25 to 16.0). Must be greater than or equal to min_cu. max_cu - min_cu must not exceed 8.0. (nullable, format: double)
  --sleep-timeout-seconds: int # Seconds of inactivity before the compute endpoint is suspended. Use -1 for always on, or a non-negative value. (nullable, format: int64)
]: any -> record<min_cu: float, max_cu: float, sleep_timeout_seconds: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/compute/settings")
  let body = {min_cu: $min_cu, max_cu: $max_cu, sleep_timeout_seconds: $sleep_timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the project-level compute settings for the database. Returns effective settings (custom or tier defaults). Requires a Pro or higher plan.
#
# GET /sites/{site_id}/database/compute/settings
# operationId: getSiteDatabaseComputeSettings
export def "sites-database-compute-settings get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<min_cu: float, max_cu: float, sleep_timeout_seconds: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/compute/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resets project-level compute settings to tier defaults. Requires a Pro or higher plan.
#
# DELETE /sites/{site_id}/database/compute/settings
# operationId: clearSiteDatabaseComputeSettings
export def "sites-database-compute-settings clearSiteDatabaseComputeSettings" [
  site_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/database/compute/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the list of migrations available for the specified branch, indicating which ones have been applied to the database.
#
# GET /sites/{site_id}/database/migrations
# operationId: listSiteDatabaseMigrations
export def "sites-database-migrations listSiteDatabaseMigrations" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # The branch ID to list migrations for. Defaults to "production" if not specified.
]: nothing -> record<migrations: table<version: int, name: string, path: string, applied: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/database/migrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the contents of a named migration for the specified branch.
#
# GET /sites/{site_id}/database/migrations/{name}
# operationId: getSiteDatabaseMigration
export def "sites-database-migrations get" [
  site_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # The branch ID to look up the migration on. Defaults to the currently published deploy's branch.
]: nothing -> record<version: int, name: string, path: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/database/migrations/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Runs database migrations for the specified deploy. Finds the deploy and determines the appropriate branch.
#
# POST /sites/{site_id}/database/migrations/{deploy_id}
# operationId: runSiteDatabaseMigrations
export def "sites-database-migrations runSiteDatabaseMigrations" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run: string@bool-completer # If true, validates migrations without applying them.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/migrations/($deploy_id)")
  let body = {dry_run: $dry_run} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a point-in-time snapshot of a database branch. Defaults to the production branch if no branch name is specified.
#
# POST /sites/{site_id}/database/snapshot
# operationId: createSiteDatabaseSnapshot
# --metadata shape: {deploy?: record, source?: string}
export def "sites-database-snapshot createSiteDatabaseSnapshot" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch-id: string # The ID of the branch to snapshot. Defaults to "production" if not specified.
  --name: string # A name for the snapshot
  --metadata: record # Metadata associated with a snapshot — shape: {deploy?: record, source?: string}
]: any -> record<id: string, source_branch_id: string, manual: bool, created_at: string, expires_at: string, timestamp: string, metadata: record<deploy: record, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/snapshot")
  let body = {branch_id: $branch_id, name: $name, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all snapshots for the site's database.
#
# GET /sites/{site_id}/database/snapshots
# operationId: listSiteDatabaseSnapshots
export def "sites-database-snapshots listSiteDatabaseSnapshots" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<snapshots: table<id: string, source_branch_id: string, manual: bool, created_at: string, expires_at: string, timestamp: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a database snapshot.
#
# DELETE /sites/{site_id}/database/snapshot/{snapshot_id}
# operationId: deleteSiteDatabaseSnapshot
export def "sites-database-snapshot delete" [
  site_id: string
  snapshot_id: string
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
  let full_url = (build-url $base $"/sites/($site_id)/database/snapshot/($snapshot_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores a snapshot to a database branch. Defaults to the production branch if no branch_name is specified.
#
# POST /sites/{site_id}/database/snapshot/{snapshot_id}/restore
# operationId: restoreSiteDatabaseSnapshot
export def "sites-database-snapshot-restore restoreSiteDatabaseSnapshot" [
  site_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch-id: string # The ID of the branch to restore the snapshot to. Defaults to "production" if not specified.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/database/snapshot/($snapshot_id)/restore")
  let body = {branch_id: $branch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
