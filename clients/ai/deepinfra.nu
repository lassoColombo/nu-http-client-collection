# Auto-generated client for DeepInfra API v1.0.0
# Source: https://api.deepinfra.com/openapi.json
# Auth: --token flag or $env.DEEPINFRA_API_TOKEN

const BASE_URL = "https://api.deepinfra.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEEPINFRA_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.deepinfra.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def provider-completer [] { ["cnt" "deepinfra" "huggingface"] }
def gpu-completer [] { ["A100-80GB" "B200-180GB" "B300-270GB" "H100-80GB" "H200-141GB" "L4-24GB" "L40S-48GB" "RTXPRO6000-96GB" "other"] }
def response-format-completer [] { ["flac" "mp3" "opus" "pcm" "wav"] }
def output-format-completer [] { ["flac" "mp3" "opus" "pcm" "wav"] }
def state-completer [] { ["active" "inactive"] }
def encoding-format-completer [] { ["base64" "float"] }
def endpoint-completer [] { ["/v1/chat/completions" "/v1/completions" "/v1/embeddings"] }
def state-completer-1 [] { ["active" "all" "inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "metrics-live get" } } | get name | first)
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

# Get Live Metrics
#
# GET /v1/metrics/live
# operationId: get_live_metrics_v1_metrics_live_get
export def "metrics-live get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tokens_per_second: any, time_to_first_token: any, requests_per_second: any, total_tflops: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metrics/live")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cli Version
#
# GET /cli/version
# operationId: cli_version_cli_version_get
export def "cli-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cli/version" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Me
#
# GET /v1/me
# operationId: me_v1_me_get
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --checklist: oneof<nothing, bool> # default: false
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<uid: string, email: any, email_verified: bool, account_setup: bool, require_email_verified: bool, display_name: string, provider: string, picture: any, is_admin: bool, can_access_agents: bool, name: string, first_name: string, last_name: string, country: string, is_business_account: bool, company: string, website: string, title: string, is_team_account: bool, is_team_owner: bool, team_role: any, team_display_name: any, is_team_upgrade_enabled: bool, vercel_connection: any, checklist: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checklist" $checklist "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Account
#
# DELETE /v1/me
# operationId: delete_account_v1_me_delete
export def "me delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<uid: string, email: any, email_verified: bool, account_setup: bool, require_email_verified: bool, display_name: string, provider: string, picture: any, is_admin: bool, can_access_agents: bool, name: string, first_name: string, last_name: string, country: string, is_business_account: bool, company: string, website: string, title: string, is_team_account: bool, is_team_owner: bool, team_role: any, team_display_name: any, is_team_upgrade_enabled: bool, vercel_connection: any, checklist: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Update Details
#
# PATCH /v1/me
# operationId: account_update_details_v1_me_patch
export def "me patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --name: any # Personal name
  --first-name: any # First name of the user
  --last-name: any # Last name of the user
  --country: any # Country of the user
  --email: any
  --is-business-account: any
  --company: any # Company name
  --website: any # Company website address
  --title: any # Job title of the user, e.g. 'Software Engineer'
  --display-name: any # String with length between 1 and 39 characters. Only alphanumeric characters and dashes allowed. Must contain no leading, trailing or consecutive dashes.
  --use-case: any # Short description of the use case for the account
  --attribution: any # Short description of how the user found out about DeepInfra
  --marketing-emails: any # Set to false to opt out of marketing emails
  --country-code: any # ISO 3166-1 alpha-2 country code of the user selected country
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let body = {name: $name, first_name: $first_name, last_name: $last_name, country: $country, email: $email, is_business_account: $is_business_account, company: $company, website: $website, title: $title, display_name: $display_name, use_case: $use_case, attribution: $attribution, marketing_emails: $marketing_emails, country_code: $country_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Account Email Values
#
# GET /v1/me/emails
# operationId: account_email_values_v1_me_emails_get
export def "me-emails get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<emails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/emails")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Team Set Display Name
#
# POST /v1/me/team_display_name
# operationId: team_set_display_name_v1_me_team_display_name_post
export def "me-team-display-name post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  display_name: string # String with length between 1 and 39 characters. Only alphanumeric characters and dashes allowed. Must contain no leading, trailing or consecutive dashes.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/team_display_name")
  let body = {display_name: $display_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Account Rate Limit
#
# GET /v1/me/rate_limit
# operationId: account_rate_limit_v1_me_rate_limit_get
export def "me-rate-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<rate_limit: int, tpm_rate_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/rate_limit")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Rate Limit Increase
#
# POST /v1/me/rate_limit/request
# operationId: request_rate_limit_increase_v1_me_rate_limit_request_post
export def "me-rate-limit-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  rate_limit: int
  --tpm-rate-limit: any
  reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/rate_limit/request")
  let body = {rate_limit: $rate_limit, tpm_rate_limit: $tpm_rate_limit, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy Create
#
# POST /v1/deploy
# operationId: deploy_create_v1_deploy_post
export def "deploy post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --provider: string@provider-completer
  model_name: string # model name in specified provider
  --version: any # A specific revision, if left empty uses the last one
]: any -> record<deploy_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deploy")
  let body = {provider: $provider, model_name: $model_name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Account Gpu Limit
#
# GET /v1/me/gpu_limit
# operationId: account_gpu_limit_v1_me_gpu_limit_get
export def "me-gpu-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<limits: record, pending_requests: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/gpu_limit")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Gpu Limit Increase
#
# POST /v1/me/gpu_limit/request
# operationId: request_gpu_limit_increase_v1_me_gpu_limit_request_post
export def "me-gpu-limit-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  gpu_type: string
  requested_limit: int
  reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/gpu_limit/request")
  let body = {gpu_type: $gpu_type, requested_limit: $requested_limit, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy Create Hf
#
# POST /deploy/hf/
# operationId: deploy_create_hf_deploy_hf__post
export def "deploy-hf post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model_name: string # Model Id from huggingface
  --task: any # Task
]: any -> record<deploy_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy/hf/")
  let body = {model_name: $model_name, task: $task} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy Gpu Availability
#
# GET /deploy/llm/gpu_availability
# operationId: deploy_gpu_availability_deploy_llm_gpu_availability_get
export def "deploy-llm-gpu-availability get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # default: 
  --base-model: string # default: 
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<gpus: table<gpu_config: string, usd_per_hour: float, available: bool, recommended: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "base_model" $base_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/llm/gpu_availability" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Llm Suggest Name
#
# GET /deploy/llm/suggest_name
# operationId: deploy_llm_suggest_name_deploy_llm_suggest_name_get
export def "deploy-llm-suggest-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model-name: string
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<model_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model_name" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/llm/suggest_name" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Llm Standard Args
#
# GET /deploy/llm/standard_args
# operationId: deploy_llm_standard_args_deploy_llm_standard_args_get
export def "deploy-llm-standard-args get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --engine: string # default: vllm
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engine" $engine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/llm/standard_args" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Create Llm
#
# POST /deploy/llm
# operationId: deploy_create_llm_deploy_llm_post
export def "deploy-llm post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model_name: string # model name for deepinfra (username/mode-name format)
  gpu: string@gpu-completer
  --num-gpus: int # Number of GPUs used by one instance (default: 1)
  --max-batch-size: int # Maximum number of concurrent requests (default: 96)
  --hf: any
  --base-model: any # Base public model
  --container-image: any # Docker image for the deployment (e.g. vllm/vllm-openai:v0.8.4)
  --settings: any
  --extra-args: any # Extra command line arguments for custom deployments
  --standard-args: any # Engine tuning knobs. Values are validated on submission; unsupported or out-of-range values are rejected.
]: any -> record<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy/llm")
  let body = {model_name: $model_name, gpu: $gpu, num_gpus: $num_gpus, max_batch_size: $max_batch_size, hf: $hf, base_model: $base_model, container_image: $container_image, settings: $settings, extra_args: $extra_args, standard_args: $standard_args} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy List
#
# GET /deploy/list/
# DEPRECATED
# operationId: deploy_list_deploy_list__get
@deprecated
export def "deploy-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # A list of statuses that should be returned, separated by comma. Allowed values in the list are: initializing,downloading,deploying,running,stopped,failed,deleted
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/list/" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy List
#
# GET /deploy/list
# operationId: deploy_list_deploy_list_get
export def "deploy-list get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # A list of statuses that should be returned, separated by comma. Allowed values in the list are: initializing,downloading,deploying,running,stopped,failed,deleted
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/list" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deployment Stats
#
# GET /deploy/stats
# operationId: deployment_stats_deploy_stats_get
export def "deploy-stats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period, unix ts or 'now-5h', supported units s(ec), m(min), h(our), d(ay), w(eek), M(onth)
  --qp-to: string # end of period, unix ts or now-relative, check from, defaults to now (default: now)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<model_name: string, requests: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploy/stats" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Status
#
# GET /deploy/{deploy_id}
# operationId: deploy_status_deploy__deploy_id__get
export def "deploy get" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy/($deploy_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Update
#
# PUT /deploy/{deploy_id}
# operationId: deploy_update_deploy__deploy_id__put
export def "deploy put" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --settings: any
  --standard-args: any # Engine tuning knobs. Replaces the whole set; omitted knobs are cleared.
  --extra-args: any # Extra engine-specific command-line args (custom-weight deploys only). Replaces the whole list; omitted args are cleared.
]: any -> record<deploy_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy/($deploy_id)")
  let body = {settings: $settings, standard_args: $standard_args, extra_args: $extra_args} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy Delete
#
# DELETE /deploy/{deploy_id}
# operationId: deploy_delete_deploy__deploy_id__delete
export def "deploy delete" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<deploy_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy/($deploy_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Stats
#
# GET /deploy/{deploy_id}/stats
# operationId: deploy_stats_deploy__deploy_id__stats_get
export def "deploy-stats get" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period, unix ts or 'now-5h', supported units s(ec), m(min), h(our), d(ay), w(eek), M(onth)
  --qp-to: string # end of period, unix ts or now-relative, check from, defaults to now (default: now)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<requests: int, total_time: int, total_tokens: int, input_tokens: int, output_tokens: int, total_amount: int, avg_time: float, avg95_time: float, errors: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploy/($deploy_id)/stats" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Detailed Stats
#
# GET /deploy/{deploy_id}/stats2
# operationId: deploy_detailed_stats_deploy__deploy_id__stats2_get
export def "deploy-stats2 get" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period, unix ts or 'now-5h', supported units s, m, h, d, w
  --qp-to: string # end of period, unix ts or now-relative, check from, defaults to now (default: now)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<llm: any, embeddings: any, time: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deploy/($deploy_id)/stats2" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Stop
#
# POST /deploy/{deploy_id}/stop
# operationId: deploy_stop_deploy__deploy_id__stop_post
export def "deploy-stop post" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<deploy_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy/($deploy_id)/stop")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy Start
#
# POST /deploy/{deploy_id}/start
# operationId: deploy_start_deploy__deploy_id__start_post
export def "deploy-start post" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<deploy_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy/($deploy_id)/start")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Private Models List
#
# GET /models/private/list
# operationId: private_models_list_models_private_list_get
export def "models-private-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<model_name: string, type: string, reported_type: string, description: string, cover_img_url: string, tags: list<string>, pricing: any, max_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, create_ts: any, private: int, is_partner: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models/private/list")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Lora Model
#
# POST /lora-model
# operationId: upload_lora_model_lora_model_post
export def "lora-model post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  hf_model_name: string
  --hf-token: any
  lora_model_name: string
  --base-model-name: any
]: any -> record<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lora-model")
  let body = {hf_model_name: $hf_model_name, hf_token: $hf_token, lora_model_name: $lora_model_name, base_model_name: $base_model_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Lora Model
#
# DELETE /lora-model/{lora_model_name}
# operationId: delete_lora_model_lora_model__lora_model_name__delete
export def "lora-model delete" [
  lora_model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lora-model/($lora_model_name)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Model Families Names
#
# GET /model-families/names
# operationId: model_families_names_model_families_names_get
export def "model-families-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/model-families/names")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Model Family
#
# GET /model-families/{family_name}
# operationId: model_family_model_families__family_name__get
export def "model-families get" [
  family_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, title: string, description: string, developer: string, meta_title: any, meta_description: any, featured_models: list<string>, pp_sections_out: table<section_id: string, ptype: string, title: string, description: string, mf_description: string, entries: list>, faq_entries: table<faq_id: string, question: string, answer: string, order: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/model-families/($family_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Models List
#
# GET /models/list
# operationId: models_list_models_list_get
export def "models-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<model_name: string, type: string, reported_type: string, description: string, cover_img_url: string, tags: list<string>, pricing: any, max_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, create_ts: any, private: int, is_partner: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Models Deployment List
#
# GET /models/deployment/list
# operationId: models_deployment_list_models_deployment_list_get
export def "models-deployment-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<model_name: string, type: string, reported_type: string, description: string, cover_img_url: string, tags: list<string>, pricing: any, max_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, create_ts: any, private: int, is_partner: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models/deployment/list")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Models Lora List
#
# GET /models/lora/list
# operationId: models_lora_list_models_lora_list_get
export def "models-lora-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<model_name: string, type: string, reported_type: string, description: string, cover_img_url: string, tags: list<string>, pricing: any, max_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, create_ts: any, private: int, is_partner: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models/lora/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openrouter Models
#
# GET /openrouter/models
# operationId: openrouter_models_openrouter_models_get
export def "openrouter-models get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, hugging_face_id: string, name: string, created: int, input_modalities: list, output_modalities: list, quantization: string, context_length: int, max_output_length: int, pricing: record, supported_sampling_parameters: list, supported_features: list, description: any, deprecation_date: any, openrouter: any, datacenters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openrouter/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Model Versions
#
# GET /models/{model_name}/versions
# operationId: model_versions_models__model_name__versions_get
export def "models-versions get" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<model_name: string, version: string, uploaded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_name)/versions")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Model Publicity
#
# POST /models/{model_name}/publicity
# operationId: model_publicity_models__model_name__publicity_post
export def "models-publicity post" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --public: oneof<nothing, bool> # whether to make the model public of private
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_name)/publicity")
  let body = {public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Model Meta Update
#
# POST /models/{model_name}/meta
# operationId: model_meta_update_models__model_name__meta_post
export def "models-meta post" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --description: any # short model description in plain text
  --github-url: any # source code project link (empty to delete)
  --paper-url: any # paper/research link (empty to delete)
  --license-url: any # usage license link (empty to delete)
  --readme: any # markdown flavored model readme
  --cover-img-url: any # dataurl or regular url to cover image (empty to delete)
  --reported-type: any # model type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_name)/meta")
  let body = {description: $description, github_url: $github_url, paper_url: $paper_url, license_url: $license_url, readme: $readme, cover_img_url: $cover_img_url, reported_type: $reported_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Model Delete
#
# DELETE /models/{model_name}
# operationId: model_delete_models__model_name__delete
export def "models delete" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # delete a particular version, pass 'ALL' to wipe everything
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/models/($model_name)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Models Info
#
# GET /models/{model_name}
# operationId: models_info_models__model_name__get
export def "models get" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<model_name: string, type: string, tags: list<string>, reported_type: string, version: string, description: any, mf_description: any, featured: bool, owner: bool, public: bool, curl_inv: string, cmdline_inv: string, txt_docs: string, out_example: string, out_docs: string, in_schema: any, out_schema: any, in_fields: any, pricing: any, doc_blocks: any, short_doc_block: any, schemas: table<key: string, url: string>, meta: record, max_tokens: any, max_output_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, import_time: any, is_partner: bool, is_custom_deployable: bool, mf_name: any, mf_title: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/models/($model_name)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Models Featured
#
# GET /models/featured
# operationId: models_featured_models_featured_get
export def "models-featured get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<model_name: string, type: string, reported_type: string, description: string, cover_img_url: string, tags: list<string>, pricing: any, max_tokens: any, replaced_by: any, deprecated: any, quantization: any, mmlu: any, expected: any, create_ts: any, private: int, is_partner: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models/featured")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Model Schema
#
# GET /models/{model_name}/schema/{variantKey}
# operationId: model_schema_models__model_name__schema__variantKey__get
export def "models-schema get" [
  model_name: string
  variantKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<variant: record<key: string, url: string>, schema_in: any, schema_out: any, schema_stream: any, fields_in: table<name: string, parent: any, ftype: string, description: any, allowed: any, default: any, examples: list, minimum: any, exclusiveMinimum: any, maximum: any, exclusiveMaximum: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/models/($model_name)/schema/($variantKey)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inference Deploy
#
# POST /v1/inference/deploy/{deploy_id}
# operationId: inference_deploy_v1_inference_deploy__deploy_id__post
export def "inference-deploy post" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/inference/deploy/($deploy_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inference Model
#
# POST /v1/inference/{model_name}
# operationId: inference_model_v1_inference__model_name__post
export def "inference post" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # model version to run inference against
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/inference/($model_name)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokenize
#
# POST /v1/tokenize
# operationId: tokenize_v1_tokenize_post
export def "tokenize post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model: string # model name
  --prompt: any # text to tokenize (completion form)
  --messages: any # chat messages to tokenize (chat form)
  --return-token-strs: any # also return the per-token strings (vLLM)
]: any -> record<count: int, max_model_len: int, tokens: list<int>, token_strs: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokenize")
  let body = {model: $model, prompt: $prompt, messages: $messages, return_token_strs: $return_token_strs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detokenize
#
# POST /v1/detokenize
# operationId: detokenize_v1_detokenize_post
export def "detokenize post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model: string # model name
  --tokens: list # token ids to detokenize
]: any -> record<prompt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/detokenize")
  let body = {model: $model, tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Anthropic Messages
#
# POST /anthropic/v1/messages
# operationId: anthropic_messages_anthropic_v1_messages_post
export def "anthropic-messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  model: string
  --max-tokens: any
  messages: list
  --system: any
  --stop-sequences: any
  --stream: any # default: false
  --temperature: any # default: 1.0
  --top-p: any
  --top-k: any
  --metadata: any
  --tools: any
  --tool-choice: any
  --thinking: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/anthropic/v1/messages")
  let body = {model: $model, max_tokens: $max_tokens, messages: $messages, system: $system, stop_sequences: $stop_sequences, stream: $stream, temperature: $temperature, top_p: $top_p, top_k: $top_k, metadata: $metadata, tools: $tools, tool_choice: $tool_choice, thinking: $thinking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta, "x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Anthropic Messages Count Tokens
#
# POST /anthropic/v1/messages/count_tokens
# operationId: anthropic_messages_count_tokens_anthropic_v1_messages_count_tokens_post
export def "anthropic-messages-count-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model: string
  messages: list
  --system: any
  --tools: any
  --thinking: any
  --tool-choice: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/anthropic/v1/messages/count_tokens")
  let body = {model: $model, messages: $messages, system: $system, tools: $tools, thinking: $thinking, tool_choice: $tool_choice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Models
#
# GET /v1/models
# operationId: openai_models_v1_models_get
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string
  --filter: string
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<object: string, data: table<id: string, object: string, created: int, owned_by: string, root: string, parent: any, metadata: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openai Images Generations
#
# POST /v1/images/generations
# operationId: openai_images_generations_v1_images_generations_post
export def "images-generations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  model: string # The model to use for image generation.
  --n: int # The number of images to generate. (default: 1)
  --response-format: any # The format in which the generated images are returned. Currently only b64_json is supported. (default: b64_json)
  --size: string # The size of the generated images. Available sizes depend on the model. (default: 1024x1024)
  --user: any # A unique identifier representing your end-user, which can help to monitor and detect abuse.
  prompt: string # A text description of desired image(s).
  --quality: any # The quality of the image that will be generated.
  --style: any # The style of the generated images.
]: any -> record<created: int, data: table<b64_json: any, revised_prompt: any, url: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/images/generations")
  let body = {model: $model, n: $n, response_format: $response_format, size: $size, user: $user, prompt: $prompt, quality: $quality, style: $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Images Variations
#
# POST /v1/images/variations
# operationId: openai_images_variations_v1_images_variations_post
export def "images-variations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  image: string # format: binary
  --inp: any
  model: string
]: any -> record<created: int, data: table<b64_json: any, revised_prompt: any, url: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/images/variations")
  let body = {image: $image, inp: $inp, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Openai Images Edits
#
# POST /v1/images/edits
# operationId: openai_images_edits_v1_images_edits_post
export def "images-edits post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  image: string # format: binary
  --inp: any
  prompt: string
  model: string
]: any -> record<created: int, data: table<b64_json: any, revised_prompt: any, url: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/images/edits")
  let body = {image: $image, inp: $inp, prompt: $prompt, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Submit Feedback
#
# POST /v1/feedback
# operationId: submit_feedback_v1_feedback_post
export def "feedback post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  message: string # The message you'd like to send to deepinfra team
  --contact-email: any # Optional contact email to reach you back
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/feedback")
  let body = {message: $message, contact_email: $contact_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Audio Speech
#
# POST /v1/audio/speech
# operationId: openai_audio_speech_v1_audio_speech_post
export def "audio-speech post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  --service-tier: any # The service tier used for processing the request. When set to 'priority', the request will be processed with higher priority (only applies to models that support it).
  model: string # model name
  input: string # Text to convert to speech
  --voice: any # Preset voices to use for the speech.
  --response-format: string@response-format-completer # Select the desired format for the speech output. Supported formats include mp3, opus, flac, wav, and pcm. (default: wav)
  --speed: float # speed of the speech (default: 1.0)
  --extra-body: any # Extra body parameters for the model.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/speech")
  let body = {service_tier: $service_tier, model: $model, input: $input, voice: $voice, response_format: $response_format, speed: $speed, extra_body: $extra_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Audio Transcriptions
#
# POST /v1/audio/transcriptions
# operationId: openai_audio_transcriptions_v1_audio_transcriptions_post
export def "audio-transcriptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  file: string # format: binary
  model: string
  --language: any
  --prompt: any
  --response-format: any # default: json
  --temperature: any # default: 0
  --timestamp-granularities: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/transcriptions")
  let body = {file: $file, model: $model, language: $language, prompt: $prompt, response_format: $response_format, temperature: $temperature, timestamp_granularities: $timestamp_granularities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Openai Audio Translations
#
# POST /v1/audio/translations
# operationId: openai_audio_translations_v1_audio_translations_post
export def "audio-translations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  file: string # format: binary
  model: string
  --prompt: any
  --response-format: any # default: json
  --temperature: any # default: 0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/translations")
  let body = {file: $file, model: $model, prompt: $prompt, response_format: $response_format, temperature: $temperature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Logs Query
#
# GET /v1/logs/query
# operationId: logs_query_v1_logs_query_get
export def "logs-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deploy-id: string # the deploy id to get the logs from
  --qp-from: string # start of period, in fractional seconds since unix epoch (inclusive)
  --qp-to: string # end of period, in fractional seconds since unix epoch (exclusive)
  --limit: int # how many items to return at most (default 100, in [1, 1000]) (default: 100)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<entries: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy_id" $deploy_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logs/query" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deployment Logs Query
#
# GET /v1/deployment_logs/query
# operationId: deployment_logs_query_v1_deployment_logs_query_get
export def "deployment-logs-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deploy-id: string # the deploy id to get the logs from
  --pod-name: string # the pod name to get the logs from
  --qp-from: string # start of period, in fractional seconds since unix epoch (inclusive)
  --qp-to: string # end of period, in fractional seconds since unix epoch (exclusive)
  --limit: int # how many items to return at most (default 100, in [1, 1000]) (default: 100)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<entries: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploy_id" $deploy_id "scalar") (serialize-qp "pod_name" $pod_name "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deployment_logs/query" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Voices
#
# GET /v1/voices
# operationId: get_voices_v1_voices_get
export def "voices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<voices: table<user_id: string, voice_id: string, name: string, description: string, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/voices")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Text To Speech Stream
#
# POST /v1/text-to-speech/{voice_id}/stream
# operationId: text_to_speech_stream_v1_text_to_speech__voice_id__stream_post
export def "text-to-speech-stream post" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string # e.g. wav
  --xi-api-key: string
  --x-api-key: string
  text: string # Text to convert to speech
  --model-id: string # Model ID to use for the conversion (default: hexgrad/Kokoro-82M)
  --output-format: string@output-format-completer # Select the desired format for the speech output. Supported formats include mp3, opus, flac, wav, and pcm. (default: wav)
  --language-code: any # ISO 639-1, 2 letter language code
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)/stream" $qp)
  let body = {text: $text, model_id: $model_id, output_format: $output_format, language_code: $language_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Speech
#
# POST /v1/text-to-speech/{voice_id}
# operationId: text_to_speech_v1_text_to_speech__voice_id__post
export def "text-to-speech post" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string # e.g. wav
  --xi-api-key: string
  --x-api-key: string
  text: string # Text to convert to speech
  --model-id: string # Model ID to use for the conversion (default: hexgrad/Kokoro-82M)
  --output-format: string@output-format-completer # Select the desired format for the speech output. Supported formats include mp3, opus, flac, wav, and pcm. (default: wav)
  --language-code: any # ISO 639-1, 2 letter language code
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)" $qp)
  let body = {text: $text, model_id: $model_id, output_format: $output_format, language_code: $language_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Voice
#
# GET /v1/voices/{voice_id}
# operationId: get_voice_v1_voices__voice_id__get
export def "voices get" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<user_id: string, voice_id: string, name: string, description: string, created_at: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Voice
#
# DELETE /v1/voices/{voice_id}
# operationId: delete_voice_v1_voices__voice_id__delete
export def "voices delete" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Voice
#
# POST /v1/voices/add
# operationId: create_voice_v1_voices_add_post
export def "voices-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string
  description: string
  files: list
]: any -> record<user_id: string, voice_id: string, name: string, description: string, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/voices/add")
  let body = {name: $name, description: $description, files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update Voice
#
# POST /v1/voices/{voice_id}/edit
# operationId: update_voice_v1_voices__voice_id__edit_post
export def "voices-edit post" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string
  description: string
]: any -> record<user_id: string, voice_id: string, name: string, description: string, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/edit")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Lora
#
# POST /v1/lora/create
# operationId: create_lora_v1_lora_create_post
# --source shape: {type: "civitai", civit_url?: any}
export def "lora-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  base_model: string
  lora_name: string
  --body-source: record # shape: {type: "civitai", civit_url?: any}
  --private: oneof<nothing, bool>
  --description: any # default: 
]: any -> record<type: string, deploy_id: string, model_name: string, version: string, task: string, status: string, fail_reason: string, created_at: string, updated_at: string, instances: any, config: any, settings: any, standard_args: any, extra_args: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/lora/create")
  let body = {base_model: $base_model, lora_name: $lora_name, source: $body_source, private: $private, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Lora Status
#
# GET /v1/lora/{lora_name}/status
# operationId: get_lora_status_v1_lora__lora_name__status_get
export def "lora-status get" [
  lora_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lora/($lora_name)/status")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Lora
#
# GET /v1/lora/{lora_name}
# operationId: get_lora_v1_lora__lora_name__get
export def "lora get" [
  lora_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lora/($lora_name)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Lora
#
# PATCH /v1/lora/{lora_name}
# operationId: update_lora_v1_lora__lora_name__patch
export def "lora patch" [
  lora_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  --private: any
  --description: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lora/($lora_name)")
  let body = {private: $private, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Lora
#
# DELETE /v1/lora/{lora_name}
# operationId: delete_lora_v1_lora__lora_name__delete
export def "lora delete" [
  lora_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lora/($lora_name)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model Loras
#
# GET /v1/model/{model_name}/loras
# operationId: get_model_loras_v1_model__model_name__loras_get
export def "model-loras get" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/model/($model_name)/loras")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Loras
#
# GET /v1/user/loras
# operationId: get_user_loras_v1_user_loras_get
export def "user-loras get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user/loras")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Container Rentals Get Params
#
# GET /v1/containers/params
# operationId: container_rentals_get_params_v1_containers_params_get
export def "containers-params get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/containers/params")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rent Gpu Availability
#
# GET /v1/containers/gpu_availability
# operationId: rent_gpu_availability_v1_containers_gpu_availability_get
export def "containers-gpu-availability get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # default: 
  --base-model: string # default: 
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<gpus: table<gpu_config: string, usd_per_hour: float, available: bool, recommended: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "base_model" $base_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/containers/gpu_availability" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Container Rentals Start
#
# POST /v1/containers
# operationId: container_rentals_start_v1_containers_post
export def "containers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string # Container Name
  gpu_config: string # GPU config
  container_image: string # Container Image
  cloud_init_user_data: string # Cloud Init User Data
]: any -> record<container_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/containers")
  let body = {name: $name, gpu_config: $gpu_config, container_image: $container_image, cloud_init_user_data: $cloud_init_user_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Container Rentals List
#
# GET /v1/containers
# operationId: container_rentals_list_v1_containers_get
export def "containers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # whether to return active or inactive containers (default: active)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<id: string, name: string, state: string, start_ts: int, state_ts: int, stop_ts: any, ip: any, gpu_config: string, price_per_hour: float, container_image: string, fail_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/containers" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Container Rentals Get
#
# GET /v1/containers/{container_id}
# operationId: container_rentals_get_v1_containers__container_id__get
export def "containers get" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<id: string, name: string, state: string, start_ts: int, state_ts: int, stop_ts: any, ip: any, gpu_config: string, price_per_hour: float, container_image: string, fail_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/containers/($container_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Container Rentals Update
#
# PATCH /v1/containers/{container_id}
# operationId: container_rentals_update_v1_containers__container_id__patch
export def "containers patch" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string # Container Name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/containers/($container_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Container Rentals Delete
#
# DELETE /v1/containers/{container_id}
# operationId: container_rentals_delete_v1_containers__container_id__delete
export def "containers delete" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/containers/($container_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Request Costs
#
# POST /v1/request-costs
# operationId: get_request_costs_v1_request_costs_post
export def "request-costs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  requestIds: list
]: any -> record<requests: table<requestId: string, costNanoUsd: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/request-costs")
  let body = {requestIds: $requestIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Hardware
#
# GET /v2/hardware
# operationId: get_hardware_v2_hardware_get
export def "hardware get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string # Model name (NVIDIA NemoClaw format)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<hardware: table<id: string, name: string, type: string, pricing: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/hardware" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openai Completions
#
# POST /v1/completions
# operationId: openai_completions_v1_completions_post
export def "completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  --service-tier: any # The service tier used for processing the request. When set to 'priority', the request will be processed with higher priority (only applies to models that support it).
  model: string # model name
  prompt: any # input prompt - a single string is currently supported
  --max-tokens: any # The maximum number of tokens to generate in the completion.  The total length of input tokens and generated tokens is limited by the model's context length.If explicitly set to None it will be the model's max context length minus input length or 16384, whichever is smaller.
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic (default: 1.0)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. (default: 1.0)
  --min-p: float # Float that represents the minimum probability for a token to be considered, relative to the probability of the most likely token. Must be in [0, 1]. Set to 0 to disable this. (default: 0.0)
  --top-k: int # Sample from the best k (number of) tokens. 0 means off (default: 0)
  --n: int # number of sequences to return (default: 1)
  --stream: oneof<nothing, bool> # whether to stream the output via SSE or return the full response (default: false)
  --logprobs: any # return top tokens and their log-probabilities
  --echo: any # return prompt as part of the respons
  --stop: any # up to 16 sequences where the API will stop generating further tokens
  --presence-penalty: float # Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (default: 0)
  --frequency-penalty: float # Positive values penalize new tokens based on how many times they appear in the text so far, increasing the model's likelihood to talk about new topics. (default: 0)
  --response-format: any # The format of the response. Currently, only json is supported.
  --repetition-penalty: float # Alternative penalty for repetition, but multiplicative instead of additive (> 1 penalize, < 1 encourage) (default: 1)
  --user: any # A unique identifier representing your end-user, which can help  monitor and detect abuse. Avoid sending us any identifying information. We recommend hashing user identifiers.
  --seed: any # Seed for random number generator. If not provided, a random seed is used. Determinism is not guaranteed.
  --stream-options: any # streaming options
  --stop-token-ids: any # Up to 16 token IDs where the API will stop generating further tokens. Merged with the model's built-in stop tokens. Intended for private deployments.
  --return-tokens-as-token-ids: any # return tokens as token ids
  --prompt-cache-key: any # A key to identify prompt cache for reuse across requests. If provided, the prompt will be cached and can be reused in subsequent requests with the same key.
  --data: any # Optional multi-modal data to pass alongside the prompt. Only supported for a small number of non-chat-native vision models. Images must be base64 data URIs (e.g. 'data:image/png;base64,...').
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/completions")
  let body = {service_tier: $service_tier, model: $model, prompt: $prompt, max_tokens: $max_tokens, temperature: $temperature, top_p: $top_p, min_p: $min_p, top_k: $top_k, n: $n, stream: $stream, logprobs: $logprobs, echo: $echo, stop: $stop, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, response_format: $response_format, repetition_penalty: $repetition_penalty, user: $user, seed: $seed, stream_options: $stream_options, stop_token_ids: $stop_token_ids, return_tokens_as_token_ids: $return_tokens_as_token_ids, prompt_cache_key: $prompt_cache_key, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Chat Completions
#
# POST /v1/chat/completions
# operationId: openai_chat_completions_v1_chat_completions_post
export def "chat-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --xi-api-key: string
  --x-api-key: string
  --service-tier: any # The service tier used for processing the request. When set to 'priority', the request will be processed with higher priority (only applies to models that support it).
  model: string # model name
  messages: list # conversation messages: (user,assistant,tool)*,user including one system message anywhere
  --stream: oneof<nothing, bool> # whether to stream the output via SSE or return the full response (default: false)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic (default: 1.0)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. (default: 1.0)
  --min-p: float # Float that represents the minimum probability for a token to be considered, relative to the probability of the most likely token. Must be in [0, 1]. Set to 0 to disable this. (default: 0.0)
  --top-k: int # Sample from the best k (number of) tokens. 0 means off (default: 0)
  --max-tokens: any # The maximum number of tokens to generate in the chat completion.  The total length of input tokens and generated tokens is limited by the model's context length. If explicitly set to None it will be the model's max context length minus input length or 16384, whichever is smaller.
  --stop: any # up to 16 sequences where the API will stop generating further tokens
  --stop-token-ids: any # Up to 16 token IDs where the API will stop generating further tokens. Merged with the model's built-in stop tokens. Intended for private deployments.
  --n: int # number of sequences to return (default: 1)
  --presence-penalty: float # Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (default: 0)
  --frequency-penalty: float # Positive values penalize new tokens based on how many times they appear in the text so far, increasing the model's likelihood to talk about new topics. (default: 0)
  --tools: any # A list of tools the model may call. Currently, only functions are supported as a tool.
  --tool-choice: any # Controls which (if any) function is called by the model. none means the model will not call a function and instead generates a message. auto means the model can pick between generating a message or calling a function. required means the model must call a function. defined tool means the model must call that specific tool. none is the default when no functions are present. auto is the default if functions are present.
  --response-format: any # The format of the response. Currently, only json is supported.
  --repetition-penalty: float # Alternative penalty for repetition, but multiplicative instead of additive (> 1 penalize, < 1 encourage) (default: 1)
  --user: any # A unique identifier representing your end-user, which can help monitor and detect abuse. Avoid sending us any identifying information. We recommend hashing user identifiers.
  --seed: any # Seed for random number generator. If not provided, a random seed is used. Determinism is not guaranteed.
  --logprobs: any # Whether to return log probabilities of the output tokens or not.If true, returns the log probabilities of each output token returned in the `content` of `message`.
  --stream-options: any # streaming options
  --reasoning-effort: any # Constrains effort on reasoning for reasoning models. Currently supported values are none, low, medium, high, and xhigh. Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response. Setting to none disables reasoning entirely if the model supports.
  --reasoning: any # Reasoning configuration.
  --prompt-cache-key: any # A key to identify prompt cache for reuse across requests. If provided, the prompt will be cached and can be reused in subsequent requests with the same key.
  --chat-template-kwargs: any # Chat template kwargs.
  --continue-final-message: any # If set, the final assistant message is used as a prefix for the model to continue generating from, rather than starting a new turn. Only applicable when the last message in the conversation is an assistant message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/completions")
  let body = {service_tier: $service_tier, model: $model, messages: $messages, stream: $stream, temperature: $temperature, top_p: $top_p, min_p: $min_p, top_k: $top_k, max_tokens: $max_tokens, stop: $stop, stop_token_ids: $stop_token_ids, n: $n, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, tools: $tools, tool_choice: $tool_choice, response_format: $response_format, repetition_penalty: $repetition_penalty, user: $user, seed: $seed, logprobs: $logprobs, stream_options: $stream_options, reasoning_effort: $reasoning_effort, reasoning: $reasoning, prompt_cache_key: $prompt_cache_key, chat_template_kwargs: $chat_template_kwargs, continue_final_message: $continue_final_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openai Embeddings
#
# POST /v1/embeddings
# operationId: openai_embeddings_v1_embeddings_post
export def "embeddings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-deepinfra-source: string
  --user-agent: string
  --xi-api-key: string
  --x-api-key: string
  --service-tier: any # The service tier used for processing the request. When set to 'priority', the request will be processed with higher priority (only applies to models that support it).
  model: string # model name
  input: any # sequences to embed
  --encoding-format: string@encoding-format-completer # format used when encoding (default: float)
  --dimensions: any # The number of dimensions in the embedding. If not provided, the model's default will be used.If provided bigger than model's default, the embedding will be padded with zeros.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embeddings")
  let body = {service_tier: $service_tier, model: $model, input: $input, encoding_format: $encoding_format, dimensions: $dimensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-deepinfra-source": $x_deepinfra_source, "user-agent": $user_agent, "xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Github Login
#
# GET /github/login
# operationId: github_login_github_login_get
export def "github-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login-id: string
  --origin: string
  --deal: string
  --ti-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login_id" $login_id "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "deal" $deal "scalar") (serialize-qp "ti_token" $ti_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/github/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Okta Login
#
# GET /okta/login
# operationId: okta_login_okta_login_get
export def "okta-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string
  --origin: string
  --login-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "login_id" $login_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/okta/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Github Cli Login
#
# GET /github/cli/login
# operationId: github_cli_login_github_cli_login_get
export def "github-cli-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login_id" $login_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/github/cli/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Api Tokens
#
# GET /v1/api-tokens
# operationId: get_api_tokens_v1_api_tokens_get
export def "api-tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<token: string, created_at: int, name: string, token_id: any, allowed_ips: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api-tokens")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Api Token
#
# POST /v1/api-tokens
# operationId: create_api_token_v1_api_tokens_post
export def "api-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string
]: any -> record<token: string, created_at: int, name: string, token_id: any, allowed_ips: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api-tokens")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Api Token
#
# GET /v1/api-tokens/{api_token}
# operationId: get_api_token_v1_api_tokens__api_token__get
export def "api-tokens get" [
  api_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<token: string, created_at: int, name: string, token_id: any, allowed_ips: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api-tokens/($api_token)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Api Token
#
# DELETE /v1/api-tokens/{api_token}
# operationId: delete_api_token_v1_api_tokens__api_token__delete
export def "api-tokens delete" [
  api_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api-tokens/($api_token)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Api Token To Vercel
#
# POST /v1/api-tokens/{api_token}/vercel_export
# operationId: export_api_token_to_vercel_v1_api_tokens__api_token__vercel_export_post
export def "api-tokens-vercel-export post" [
  api_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  project_id_or_name: string
  --is-sensitive: oneof<nothing, bool>
  --env-development: oneof<nothing, bool>
  --env-preview: oneof<nothing, bool>
  --env-production: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api-tokens/($api_token)/vercel_export")
  let body = {project_id_or_name: $project_id_or_name, is_sensitive: $is_sensitive, env_development: $env_development, env_preview: $env_preview, env_production: $env_production} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Create Scoped Jwt
#
# POST /v1/scoped-jwt
# operationId: _create_scoped_jwt_v1_scoped_jwt_post
export def "scoped-jwt post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  api_key_name: string
  --models: any # allow inference only to the specified model names
  --expires-delta: any # how many seconds in the future should the token be valid for
  --expires-at: any # unix timestamp when the token should expire
  --spending-limit: any # only allow spending that much USD until the token becomes invalid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped-jwt")
  let body = {api_key_name: $api_key_name, models: $models, expires_delta: $expires_delta, expires_at: $expires_at, spending_limit: $spending_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Inspect Scoped Jwt
#
# GET /v1/scoped-jwt
# operationId: inspect_scoped_jwt_v1_scoped_jwt_get
export def "scoped-jwt get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --jwtoken: string
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<expires_at: int, models: any, spending_limit: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwtoken" $jwtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scoped-jwt" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Ssh Keys
#
# GET /v1/ssh_keys
# operationId: get_ssh_keys_v1_ssh_keys_get
export def "ssh-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<id: string, name: string, key: string, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ssh_keys")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ssh Key
#
# POST /v1/ssh_keys
# operationId: create_ssh_key_v1_ssh_keys_post
export def "ssh-keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string # SSH Key name
  key: string # SSH Key content
]: any -> record<id: string, name: string, key: string, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ssh_keys")
  let body = {name: $name, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ssh Key
#
# DELETE /v1/ssh_keys/{ssh_key_id}
# operationId: delete_ssh_key_v1_ssh_keys__ssh_key_id__delete
export def "ssh-keys delete" [
  ssh_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ssh_keys/($ssh_key_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Files
#
# GET /v1/files
# operationId: list_files_v1_files_get
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string
  --purpose: string
  --order: string
  --limit: int # default: 100
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "purpose" $purpose "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/files" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openai Files
#
# POST /v1/files
# operationId: openai_files_v1_files_post
export def "files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  purpose: string
  file: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/files")
  let body = {purpose: $purpose, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get File
#
# GET /v1/files/{file_id}
# operationId: get_file_v1_files__file_id__get
export def "files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<id: string, object: string, created_at: int, filename: string, bytes: int, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete File
#
# DELETE /v1/files/{file_id}
# operationId: delete_file_v1_files__file_id__delete
export def "files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get File Content
#
# GET /v1/files/{file_id}/content
# operationId: get_file_content_v1_files__file_id__content_get
export def "files-content get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)/content")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Openai Batches
#
# GET /v1/batches
# operationId: retrieve_openai_batches_v1_batches_get
export def "batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string
  --limit: int # default: 20
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Openai Batch
#
# POST /v1/batches
# operationId: create_openai_batch_v1_batches_post
export def "batches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  input_file_id: string # The ID of an uploaded file that contains requests for the new batch.
  endpoint: string@endpoint-completer # The endpoint to be used for all requests in the batch. Currently /v1/chat/completions, /v1/completions, /v1/embeddings are supported.
  completion_window: string # The time frame within which the batch should be processed. Currently only 24h is supported.
  --metadata: any # Optional metadata to be stored with the batch.
]: any -> record<id: string, object: string, endpoint: string, errors: any, input_file_id: string, completion_window: string, status: string, output_file_id: any, error_file_id: any, created_at: int, in_progress_at: any, expires_at: int, finalizing_at: any, completed_at: any, failed_at: any, expired_at: any, cancelling_at: any, cancelled_at: any, request_counts: any, metadata: any, model: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches")
  let body = {input_file_id: $input_file_id, endpoint: $endpoint, completion_window: $completion_window, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Openai Batch
#
# GET /v1/batches/{batch_id}
# operationId: retrieve_openai_batch_v1_batches__batch_id__get
export def "batches get" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<id: string, object: string, endpoint: string, errors: any, input_file_id: string, completion_window: string, status: string, output_file_id: any, error_file_id: any, created_at: int, in_progress_at: any, expires_at: int, finalizing_at: any, completed_at: any, failed_at: any, expired_at: any, cancelling_at: any, cancelled_at: any, request_counts: any, metadata: any, model: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Openai Batch
#
# POST /v1/batches/{batch_id}/cancel
# operationId: cancel_openai_batch_v1_batches__batch_id__cancel_post
export def "batches-cancel post" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<id: string, object: string, endpoint: string, errors: any, input_file_id: string, completion_window: string, status: string, output_file_id: any, error_file_id: any, created_at: int, in_progress_at: any, expires_at: int, finalizing_at: any, completed_at: any, failed_at: any, expired_at: any, cancelling_at: any, cancelled_at: any, request_counts: any, metadata: any, model: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)/cancel")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Create
#
# POST /v1/agents
# operationId: openclaw_create_v1_agents_post
export def "agents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string # Instance name
  --agent-type-id: string # Agent type identifier (default: openclaw)
  --plan-id: string # Plan identifier (default: standard)
]: any -> record<instance_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agents")
  let body = {name: $name, agent_type_id: $agent_type_id, plan_id: $plan_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openclaw List
#
# GET /v1/agents
# operationId: openclaw_list_v1_agents_get
export def "agents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-1 # Which instances to return: active, inactive, or all (both) (default: active)
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<id: string, name: string, state: string, start_ts: int, state_ts: int, stop_ts: any, price_per_hour: float, region: string, last_backup_ts: any, ssh_port: int, fail_reason: any, public_ip: any, version: any, agent_type: string, ssh_user: string, plan_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/agents" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Catalog
#
# GET /v1/agents/catalog
# operationId: openclaw_catalog_v1_agents_catalog_get
export def "agents-catalog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agents/catalog")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Get
#
# GET /v1/agents/{instance_id}
# operationId: openclaw_get_v1_agents__instance_id__get
export def "agents get" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<id: string, name: string, state: string, start_ts: int, state_ts: int, stop_ts: any, price_per_hour: float, region: string, last_backup_ts: any, ssh_port: int, fail_reason: any, public_ip: any, version: any, agent_type: string, ssh_user: string, plan_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Update
#
# PATCH /v1/agents/{instance_id}
# operationId: openclaw_update_v1_agents__instance_id__patch
export def "agents patch" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
  name: string # Instance name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Openclaw Delete
#
# DELETE /v1/agents/{instance_id}
# operationId: openclaw_delete_v1_agents__instance_id__delete
export def "agents delete" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Launch Token
#
# POST /v1/agents/{instance_id}/launch_token
# operationId: openclaw_launch_token_v1_agents__instance_id__launch_token_post
export def "agents-launch-token post" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> record<dashboard_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/launch_token")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Stop
#
# POST /v1/agents/{instance_id}/stop
# operationId: openclaw_stop_v1_agents__instance_id__stop_post
export def "agents-stop post" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/stop")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Start
#
# POST /v1/agents/{instance_id}/start
# operationId: openclaw_start_v1_agents__instance_id__start_post
export def "agents-start post" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/start")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Update Version
#
# POST /v1/agents/{instance_id}/update
# operationId: openclaw_update_version_v1_agents__instance_id__update_post
export def "agents-update post" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/update")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw List Backups
#
# GET /v1/agents/{instance_id}/backups
# operationId: openclaw_list_backups_v1_agents__instance_id__backups_get
export def "agents-backups get" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> table<snapshot_name: string, size_in_gb: int, state: string, created_at_unix: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/backups")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Trigger Backup
#
# POST /v1/agents/{instance_id}/backup
# operationId: openclaw_trigger_backup_v1_agents__instance_id__backup_post
export def "agents-backup post" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/backup")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Openclaw Restore Backup
#
# POST /v1/agents/{instance_id}/backups/{backup_id}/restore
# operationId: openclaw_restore_backup_v1_agents__instance_id__backups__backup_id__restore_post
export def "agents-backups-restore post" [
  instance_id: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string
  --x-api-key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($instance_id)/backups/($backup_id)/restore")
  let extra_headers = {"xi-api-key": $xi_api_key, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Checklist
#
# GET /payment/checklist
# operationId: get_checklist_payment_checklist_get
export def "payment-checklist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compute-owed: oneof<nothing, bool> # default: false
  --session: any
]: nothing -> record<email: bool, billing_address: bool, billing_address_info: any, payment_method: bool, payment_method_info: any, suspended: bool, overdue_invoices: float, last_checked: int, stripe_balance: float, recent: float, limit: any, suspend_reason: any, topup: bool, topup_amount: int, topup_threshold: int, topup_failed: bool, billing_type: any, intermediate_invoicing_threshold: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compute_owed" $compute_owed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/checklist" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Config
#
# GET /payment/config
# operationId: get_config_payment_config_get
export def "payment-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session: any
]: nothing -> record<limit: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/config")
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Config
#
# POST /payment/config
# operationId: set_config_payment_config_post
export def "payment-config post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session: any
  --limit: any # Set usage limit (in USD). Negative means no limit.null/not-set means don't change it
]: any -> record<limit: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/config")
  let body = {limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Billing Portal
#
# GET /payment/billing-portal
# operationId: billing_portal_payment_billing_portal_get
export def "payment-billing-portal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-url: string
  --session: any
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_url" $return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/billing-portal" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Invoices
#
# GET /payment/invoices
# operationId: list_invoices_payment_invoices_get
export def "payment-invoices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 10
  --starting-after: string
  --invoice-type: string
  --session: any
]: nothing -> record<invoices: table<id: string, status: string, total: int, amount_due: int, created: int, due_date: any, period: any, invoice_type: any, hosted_invoice_url: any, invoice_pdf: any>, has_more: bool, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "invoice_type" $invoice_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/invoices" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage
#
# GET /payment/usage
# operationId: usage_payment_usage_get
export def "payment-usage list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period in YYYY.MM, current(-N), unix_timestamp (in seconds, UTC) format
  --qp-to: string # end of period (if missing a single month marked by from is return), same format as from
  --session: any
]: nothing -> record<months: table<period: string, interval: record, items: list, total_cost: int, invoice_id: string>, initial_month: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/usage" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage Tokens
#
# GET /payment/usage/tokens
# operationId: usage_tokens_payment_usage_tokens_get
export def "payment-usage-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period in YYYY.MM, current(-N), unix_timestamp (in seconds, UTC) format
  --qp-to: string # end of period (if missing a single month marked by from is return), same format as from
  --session: any
]: nothing -> record<months: table<period: string, interval: record, items: list, total_cost: int, invoice_id: string>, initial_month: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/usage/tokens" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage Rent
#
# GET /payment/usage/rent
# operationId: usage_rent_payment_usage_rent_get
export def "payment-usage-rent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # start of period, in seconds since unix epoch
  --qp-to: string # end of period, in seconds since unix epoch
  --session: any
]: nothing -> record<id_to_duration: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/usage/rent" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage Api Token
#
# GET /payment/usage/{api_token}
# operationId: usage_api_token_payment_usage__api_token__get
export def "payment-usage get" [
  api_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # start of period in YYYY.MM, current(-N), unix_timestamp (in seconds, UTC) format
  --qp-to: string # end of period (if missing a single month marked by from is return), same format as from
  --session: any
]: nothing -> record<months: table<period: string, interval: record, items: list, total_cost: int, invoice_id: string>, initial_month: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payment/usage/($api_token)" $qp)
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deepstart Apply
#
# POST /payment/deepstart/application
# operationId: deepstart_apply_payment_deepstart_application_post
export def "payment-deepstart-application post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session: any
  --id: string
  --uid: any
  company: string
  ceo: string
  funding: string
  founded_on: string
  website: string
  --created-at: int
  --status: string # default: pending
  --deal: any
]: any -> record<id: string, uid: any, company: string, ceo: string, funding: string, founded_on: string, website: string, created_at: int, status: string, deal: any, email: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/deepstart/application")
  let body = {id: $id, uid: $uid, company: $company, ceo: $ceo, funding: $funding, founded_on: $founded_on, website: $website, created_at: $created_at, status: $status, deal: $deal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Funds
#
# POST /payment/funds
# operationId: add_funds_payment_funds_post
export def "payment-funds post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-checkout: oneof<nothing, bool> # default: false
  --session: any
  amount: int # Amount to add in cents
]: any -> record<checkout_url: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_checkout" $use_checkout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment/funds" $qp)
  let body = {amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Setup Topup
#
# POST /payment/topup
# operationId: setup_topup_payment_topup_post
export def "payment-topup post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session: any
  --amount: int # Amount to top up in cents (default: 0)
  --threshold: int # Top up threshold in cents, if balance goes below this value, top up will be triggered (default: 0)
  --enabled: oneof<nothing, bool> # If true, top up will be triggered when balance goes below threshold (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/topup")
  let body = {amount: $amount, threshold: $threshold, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let cookie_str = {session: $session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
