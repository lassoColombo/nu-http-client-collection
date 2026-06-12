# Auto-generated client for Gateway REST API v4.259.0
# Source: https://docs.fireworks.ai/merged.openapi.yaml
# Auth: --token flag or $env.GATEWAY_REST_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GATEWAY_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost" "https://api.fireworks.ai" "https://api.fireworks.ai/inference"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def usageType-completer [] { ["DEDICATED_DEPLOYMENT" "SERVERLESS" "USAGE_TYPE_UNSPECIFIED"] }
def state-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_COMPLETED" "JOB_STATE_CREATING" "JOB_STATE_CREATING_INPUT_DATASET" "JOB_STATE_DELETED" "JOB_STATE_DELETING" "JOB_STATE_DELETING_CLEANING_UP" "JOB_STATE_EARLY_STOPPED" "JOB_STATE_EXPIRED" "JOB_STATE_FAILED" "JOB_STATE_IDLE" "JOB_STATE_PAUSED" "JOB_STATE_PENDING" "JOB_STATE_RE_QUEUEING" "JOB_STATE_RUNNING" "JOB_STATE_UNSPECIFIED" "JOB_STATE_VALIDATING" "JOB_STATE_WRITING_RESULTS"] }
def precision-completer [] { ["BF16" "FP16" "FP4" "FP4_BLOCKSCALED_MM" "FP4_MX_MOE" "FP8" "FP8_AR" "FP8_KV" "FP8_MM" "FP8_MM_KV_ATTN" "FP8_MM_KV_ATTN_V2" "FP8_MM_V2" "FP8_V2" "NF4" "PRECISION_UNSPECIFIED"] }
def usageType-completer-1 [] { ["DEDICATED_DEPLOYMENT" "SERVERLESS" "TRAINING" "USAGE_TYPE_UNSPECIFIED"] }
def state-completer-1 [] { ["CREATING" "DELETING" "FAILED" "READY" "STATE_UNSPECIFIED"] }
def state-completer-2 [] { ["READY" "STATE_UNSPECIFIED" "UPLOADING"] }
def format-completer [] { ["CHAT" "COMPLETION" "FORMAT_UNSPECIFIED" "RL"] }
def state-completer-3 [] { ["DEPLOYED" "DEPLOYING" "STATE_UNSPECIFIED" "UNDEPLOYING" "UPDATING"] }
def acceleratorType-completer [] { ["ACCELERATOR_TYPE_UNSPECIFIED" "AMD_MI300X_192GB" "AMD_MI325X_256GB" "AMD_MI350X_288GB" "NVIDIA_A100_40GB" "NVIDIA_A100_80GB" "NVIDIA_A10G_24GB" "NVIDIA_B200_180GB" "NVIDIA_B300_288GB" "NVIDIA_H100_80GB" "NVIDIA_H200_141GB" "NVIDIA_L4_24GB"] }
def presetType-completer [] { ["AGENTIC_CODING" "CHAT" "FAST" "FULL_PRECISION" "MINIMAL" "PRESET_TYPE_UNSPECIFIED" "SUMMARIZATION" "THROUGHPUT"] }
def state-completer-4 [] { ["CREATING" "DELETED" "DELETING" "FAILED" "READY" "STATE_UNSPECIFIED" "UPDATING"] }
def directRouteType-completer [] { ["AWS_PRIVATELINK" "DIRECT_ROUTE_TYPE_UNSPECIFIED" "GCP_PRIVATE_SERVICE_CONNECT" "INTERNET"] }
def region-completer [] { ["AP_MALAYSIA_1" "AP_TOKYO_1" "AP_TOKYO_2" "EU_FRANKFURT_1" "EU_ICELAND_1" "EU_ICELAND_2" "EU_NETHERLANDS_1" "NA_BRITISHCOLUMBIA_1" "REGION_UNSPECIFIED" "US_ARIZONA_1" "US_CALIFORNIA_1" "US_CALIFORNIA_2" "US_GEORGIA_1" "US_GEORGIA_2" "US_GEORGIA_3" "US_GEORGIA_4" "US_ILLINOIS_1" "US_ILLINOIS_2" "US_IOWA_1" "US_MINNESOTA_1" "US_NEWYORK_1" "US_OHIO_1" "US_OHIO_2" "US_TEXAS_1" "US_TEXAS_2" "US_UTAH_1" "US_VIRGINIA_1" "US_VIRGINIA_2" "US_WASHINGTON_1" "US_WASHINGTON_2" "US_WASHINGTON_3" "US_WASHINGTON_4" "US_WASHINGTON_5"] }
def hotLoadBucketType-completer [] { ["BUCKET_TYPE_UNSPECIFIED" "FW_HOSTED" "MINIO" "NEBIUS" "S3"] }
def state-completer-5 [] { ["ACTIVE" "EXPIRED" "STATE_UNSPECIFIED"] }
def purpose-completer [] { ["PURPOSE_PILOT" "PURPOSE_UNSPECIFIED"] }
def state-completer-6 [] { ["ACTIVE" "BUILDING" "BUILD_FAILED" "STATE_UNSPECIFIED"] }
def state-completer-7 [] { ["CREATING" "DELETING" "READY" "STATE_UNSPECIFIED" "UPDATING"] }
def kind-completer [] { ["CUSTOM_MODEL" "DRAFT_ADDON" "EMBEDDING_MODEL" "FIRE_AGENT" "FLUMINA_ADDON" "FLUMINA_BASE_MODEL" "HF_BASE_MODEL" "HF_PEFT_ADDON" "HF_TEFT_ADDON" "KIND_UNSPECIFIED" "LIVE_MERGE" "SNAPSHOT_MODEL"] }
def snapshotType-completer [] { ["FULL_SNAPSHOT" "INCREMENTAL_SNAPSHOT"] }
def rolloutStrategy-completer [] { ["ROLLOUT_STRATEGY_HOT_RELOAD" "ROLLOUT_STRATEGY_STANDARD" "ROLLOUT_STRATEGY_UNSPECIFIED"] }
def state-completer-8 [] { ["FAILED" "READY" "TRAINING_SESSION_STATE_UNSPECIFIED"] }
def referenceState-completer [] { ["ADAPTER" "BASE" "TRAINING_SESSION_REFERENCE_STATE_UNSPECIFIED"] }
def trainerMode-completer [] { ["FORWARD_ONLY" "LORA_TRAINER" "POLICY_TRAINER" "TRAINER_MODE_UNSPECIFIED"] }
def baseModelWeightPrecision-completer [] { ["BFLOAT16" "FP4_FP8" "FP8" "INT8" "NF4" "WEIGHT_PRECISION_UNSPECIFIED"] }
def service-tier-completer [] { ["auto" "default" "flex" "priority"] }
def context-length-exceeded-behavior-completer [] { ["error" "truncate"] }
def accept-completer [] { ["application/json" "text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts ListAccounts" } } | get name | first)
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

# List Accounts
#
# GET /v1/accounts
# operationId: Gateway_ListAccounts
export def "accounts ListAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of accounts to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListAccounts call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListAccounts must match the call that provided the page token.
  --filter: string # Only accounts satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # Not supported. Accounts will be returned ordered by `name`.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<accounts: table<name: string, displayName: string, createTime: string, accountType: string, email: string, state: string, status: record, suspendState: string, updateTime: string, notificationSettings: record>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh a session JWT before expiry with a fresh TTL.
#
# POST /v1/auth/refresh
# operationId: Gateway_RefreshSessionToken
export def "auth-refresh RefreshSessionToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refreshToken: string # The refresh token used to mint a fresh access token.
]: any -> record<token: string, expireTime: string, refreshToken: string, refreshExpireTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base "/v1/auth/refresh")
  let body = {refreshToken: $refreshToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# APIs for credit codes. Redeem Credit Code
#
# POST /v1/creditCodes:redeem
# operationId: Gateway_RedeemCreditCode
export def "credit-codes-redeem RedeemCreditCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # The user-facing credit code string (e.g., "HACKATHON_2025").
  name: string # The resource name of the account redeeming the credit code.
]: any -> record<amount: record<currencyCode: string, units: string, nanos: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base "/v1/creditCodes:redeem")
  let body = {code: $code, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate Model Config
#
# POST /v1/validateModelConfig
# operationId: Gateway_ValidateModelConfig
export def "validate-model-config ValidateModelConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  configJson: string # The config JSON of the model.
  --tokenizerConfigJson: string # The tokenizer config JSON of the model.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base "/v1/validateModelConfig")
  let body = {configJson: $configJson, tokenizerConfigJson: $tokenizerConfigJson} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Account
#
# GET /v1/accounts/{account_id}
# operationId: Gateway_GetAccount
export def "accounts GetAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, accountType: string, email: string, state: string, status: record<code: string, message: string>, suspendState: string, updateTime: string, notificationSettings: record<monthlySpendThresholds: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Distinct filter values for an account/time range (serverless + dedicated; for FE, separate -yet mirrors GetAccountUsage).
#
# GET /v1/accounts/{account_id}/accountUsageFilterOptions
# operationId: Gateway_GetAccountUsageFilterOptions
export def "accounts-account-usage-filter-options GetAccountUsageFilterOptions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # format: date-time
  --endTime: string # format: date-time
  --usageType: string@usageType-completer # If not specified, loads filter options for both usage streams.   - SERVERLESS: Serverless filter dimensions only (model_name, api_key_id, annotations.*).  - DEDICATED_DEPLOYMENT: Dedicated deployment filter dimensions (deployment_name, annotations.team, .project, .environment). (default: USAGE_TYPE_UNSPECIFIED)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "usageType" $usageType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/accountUsageFilterOptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List User Audit Logs
#
# GET /v1/accounts/{account_id}/auditLogs
# operationId: Gateway_ListAuditLogs
export def "accounts-audit-logs ListAuditLogs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # Start time of the audit logs to retrieve. If unspecified, the default is 30 days before now. (format: date-time)
  --endTime: string # End time of the audit logs to retrieve. If unspecified, the default is the current time. (format: date-time)
  --email: string # Optional. Filter audit logs for user email associated with the account.
  --pageSize: int # The maximum number of audit logs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 10. (format: int32)
  --pageToken: string # A page token, received from a previous ListAuditLogs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListAuditLogs must match the call that provided the page token.
  --filter: string # Unused but required to use existing ListRequest functionality.
  --orderBy: string # Unused but required to use existing ListRequest functionality.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<auditLogs: table<id: string, method: string, principal: string, payload: record, status: record, timestamp: string, message: string, resource: string, isAdminAction: bool, userAgent: string, clientIp: string, apiKeyId: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/auditLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Batch Inference Jobs
#
# GET /v1/accounts/{account_id}/batchInferenceJobs
# operationId: Gateway_ListBatchInferenceJobs
export def "accounts-batch-inference-jobs ListBatchInferenceJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of batch inference jobs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListBatchInferenceJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListBatchInferenceJobs must match the call that provided the page token.
  --filter: string # Only jobs satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "created_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<batchInferenceJobs: table<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record, model: string, inputDatasetId: string, outputDatasetId: string, inferenceParameters: record, updateTime: string, precision: string, jobProgress: record, continuedFromJobName: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/batchInferenceJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Batch Inference Job
#
# POST /v1/accounts/{account_id}/batchInferenceJobs
# operationId: Gateway_CreateBatchInferenceJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --inferenceParameters shape: {maxTokens?: int, temperature?: float, topP?: float, n?: int, extraBody?: string, topK?: int}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
export def "accounts-batch-inference-jobs CreateBatchInferenceJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --batchInferenceJobId: string # ID of the batch inference job.
  --displayName: string
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --model: string # The name of the model to use for inference. This is required, except when continued_from_job_name is specified.
  --inputDatasetId: string # The name of the dataset used for inference. This is required, except when continued_from_job_name is specified.
  --outputDatasetId: string # The name of the dataset used for storing the results. This will also contain the error file.
  --inferenceParameters: record # shape: {maxTokens?: int, temperature?: float, topP?: float, n?: int, extraBody?: string, topK?: int}
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --continuedFromJobName: string # The resource name of the batch inference job that this job continues from. Used for lineage tracking to understand job continuation chains.
]: any -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, model: string, inputDatasetId: string, outputDatasetId: string, inferenceParameters: record<maxTokens: int, temperature: float, topP: float, n: int, extraBody: string, topK: int>, updateTime: string, precision: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, continuedFromJobName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "batchInferenceJobId" $batchInferenceJobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/batchInferenceJobs" $qp)
  let body = {displayName: $displayName, state: $state, status: $status, model: $model, inputDatasetId: $inputDatasetId, outputDatasetId: $outputDatasetId, inferenceParameters: $inferenceParameters, precision: $precision, jobProgress: $jobProgress, continuedFromJobName: $continuedFromJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Batch Inference Job
#
# GET /v1/accounts/{account_id}/batchInferenceJobs/{batch_inference_job_id}
# operationId: Gateway_GetBatchInferenceJob
export def "accounts-batch-inference-jobs GetBatchInferenceJob" [
  account_id: string
  batch_inference_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, model: string, inputDatasetId: string, outputDatasetId: string, inferenceParameters: record<maxTokens: int, temperature: float, topP: float, n: int, extraBody: string, topK: int>, updateTime: string, precision: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, continuedFromJobName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/batchInferenceJobs/($batch_inference_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Batch Inference Job
#
# DELETE /v1/accounts/{account_id}/batchInferenceJobs/{batch_inference_job_id}
# operationId: Gateway_DeleteBatchInferenceJob
export def "accounts-batch-inference-jobs DeleteBatchInferenceJob" [
  account_id: string
  batch_inference_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/batchInferenceJobs/($batch_inference_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get billing summary information for an account
#
# GET /v1/accounts/{account_id}/billing/summary
# operationId: Gateway_GetBillingSummary
export def "accounts-billing-summary GetBillingSummary" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # Start time for the billing period. Note: Costs are aggregated daily. Only the date portion (YYYY-MM-DD) is used; the time portion is ignored. For example, 2025-10-05T07:18:29Z and 2025-10-05T23:59:59Z are treated the same as 2025-10-05T00:00:00Z. (format: date-time)
  --endTime: string # End time for the billing period (exclusive). Note: Costs are aggregated daily. Only the date portion (YYYY-MM-DD) is used; the time portion is ignored. Costs for the end date are NOT included. For example, to get costs for Oct 5 and Oct 6, use:   start_time: 2025-10-05T00:00:00Z   end_time: 2025-10-07T00:00:00Z (Oct 7 is excluded) (format: date-time)
]: nothing -> record<lineItems: table<category: string, groupingKey: string, groupingValue: string, secondaryGroupingKey: string, secondaryGroupingValue: string, quantity: float, unitAmount: record, totalCost: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/billing/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account Usage
#
# GET /v1/accounts/{account_id}/billingUsage
# operationId: Gateway_GetAccountUsage
export def "accounts-billing-usage GetAccountUsage" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # Costs returned are inclusive of `start_time`. start_time must be before end_time. (format: date-time)
  --endTime: string # Costs returned are exclusive of `end_time`. end_time must not be more than 31 days after start_time. (format: date-time)
  --usageType: string@usageType-completer-1 # Usage type to query usage for. If not specified, returns all usage types (serverless, dedicated deployments, and training).   - USAGE_TYPE_UNSPECIFIED: Default value. When specified (or when usage_type field is not set), returns usage data for all deployment types: serverless requests, dedicated deployments, and training jobs.  - SERVERLESS: Returns only serverless usage data. Filters the response to include only usage from serverless API requests.  - DEDICATED_DEPLOYMENT: Returns only dedicated deployment usage data. Filters the response to include only usage from dedicated deployments.  - TRAINING: Returns only training job usage data (SFT/DPO token usage and RFT / service-mode trainer GPU-seconds usage). Inference deployments serving rollouts for RFT / online RL are reported under DEDICATED_DEPLOYMENT (not TRAINING) to avoid double counting GPU time. (default: USAGE_TYPE_UNSPECIFIED)
  --timezone: string # IANA timezone identifier for daily aggregation (e.g., "America/Los_Angeles", "Europe/London"). When specified, the returned data will be aggregated into daily buckets based on this timezone. If not specified or empty, defaults to "UTC". See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  --groupBy: list # Dimensions to group usage by (multiple values allowed; each is a separate GROUP BY column). Each returned bucket carries the requested dimension values in the `group` map on the response item. Serverless: "model_name", "api_key_id", "api_key_name", "annotations.team", "annotations.project", "annotations.environment". Dedicated: "deployment_name", "accelerator_type", and the same annotation keys. Training: "job_id", "job_type", "usage_type", "accelerator_type", "base_model", and the same annotation keys. When usage_type is unspecified, dimensions that apply only to one stream are ignored on the others (e.g. "deployment_name" is ignored for serverless and training; "model_name" / "api_key_id" / "api_key_name" are ignored for dedicated and training; "job_id" / "job_type" are ignored for serverless and dedicated). Example: ["annotations.team", "model_name"] or ["api_key_id", "api_key_name"]. If empty: serverless aggregates by model name; dedicated defaults to deployment and accelerator type; training aggregates by job_id, job_type, usage_type, accelerator_type and base_model.
  --filter: record # Filter usage by dimension. Map query parameter — encode each entry as `filter[<dimension>][values]=<value>`, repeating the same key to OR multiple values for a single dimension. Serverless: "model_name", "api_key_id", "api_key_name", "annotations.team", "annotations.project", "annotations.environment". Dedicated: "deployment_name", "accelerator_type", and the same annotation keys. Training: "job_id", "job_type", "usage_type", "accelerator_type", "base_model", and the same annotation keys. Example: `filter[api_key_name][values]=prod-key&filter[api_key_name][values]=staging-key`.
]: nothing -> record<serverlessCosts: table<modelName: string, promptTokens: string, completionTokens: string, startTime: string, endTime: string, audioInputSeconds: float, usageType: string, apiKeyId: string, group: record>, dedicatedCosts: table<deploymentId: string, acceleratorType: string, acceleratorSeconds: string, startTime: string, endTime: string, baseModel: string, usageType: string, placement: string, group: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "usageType" $usageType "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "groupBy" $groupBy "multi") (serialize-qp "filter" $filter "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/billingUsage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote a checkpoint to a model. The checkpoint is identified by account + snapshot ID; the trainer job ID is passed in the request body to resolve the GCS bucket.
#
# POST /v1/accounts/{account_id}/checkpoints/{checkpoint_id}:promote
# operationId: Gateway_PromoteCheckpoint
export def "accounts-checkpoints PromoteCheckpoint" [
  account_id: string
  checkpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  outputModel: string
  trainerJobId: string # The trainer job that wrote this checkpoint. Format: accounts/{account}/rlorTrainerJobs/{rlor_trainer_job} Used to construct the GCS path (trainer-keyed bucket) and as a source annotation on the promoted model.
  baseModel: string
  --hotLoadDeploymentId: string
]: any -> record<model: record<name: string, displayName: string, description: string, createTime: string, state: string, status: record<code: string, message: string>, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record<worldSize: int, checkpointFormat: string, huggingfaceFiles: list, parameterCount: string, moe: bool, tunable: bool, modelType: string, supportsFireattention: bool, defaultPrecision: string, supportsMtp: bool>, peftDetails: record<baseModel: string, r: int, targetModules: list, baseModelType: string, mergeAddonModelName: string>, teftDetails: record, public: bool, conversationConfig: record<style: string, system: string, template: string>, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: list<record>, cluster: string, deprecationDate: record<year: int, month: int, day: int>, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/checkpoints/($checkpoint_id):promote")
  let body = {outputModel: $outputModel, trainerJobId: $trainerJobId, baseModel: $baseModel, hotLoadDeploymentId: $hotLoadDeploymentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Clusters
#
# GET /v1/accounts/{account_id}/clusters
# operationId: Gateway_ListClusters
export def "accounts-clusters ListClusters" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of clusters to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListClusters call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListClusters must match the call that provided the page token.
  --filter: string # Only clusters satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<clusters: table<name: string, displayName: string, createTime: string, eksCluster: record, fakeCluster: record, state: string, status: record, updateTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Cluster
#
# POST /v1/accounts/{account_id}/clusters
# operationId: Gateway_CreateCluster
# --cluster shape: {displayName?: string, eksCluster?: record, fakeCluster?: record, state?: "STATE_UNSPECIFIED"|"CREATING"|"READY"|"DELETING"|"FAILED", status?: record}
export def "accounts-clusters CreateCluster" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster: record # shape: {displayName?: string, eksCluster?: record, fakeCluster?: record, state?: "STATE_UNSPECIFIED"|"CREATING"|"READY"|"DELETING"|"FAILED", status?: record}
  clusterId: string
]: any -> record<name: string, displayName: string, createTime: string, eksCluster: record<awsAccountId: string, fireworksManagerRole: string, region: string, clusterName: string, storageBucketName: string, metricWriterRole: string, loadBalancerControllerRole: string, workloadIdentityPoolProviderId: string, inferenceRole: string>, fakeCluster: record<projectId: string, location: string, clusterName: string>, state: string, status: record<code: string, message: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters")
  let body = {cluster: $cluster, clusterId: $clusterId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Cluster
#
# GET /v1/accounts/{account_id}/clusters/{cluster_id}
# operationId: Gateway_GetCluster
export def "accounts-clusters GetCluster" [
  account_id: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, eksCluster: record<awsAccountId: string, fireworksManagerRole: string, region: string, clusterName: string, storageBucketName: string, metricWriterRole: string, loadBalancerControllerRole: string, workloadIdentityPoolProviderId: string, inferenceRole: string>, fakeCluster: record<projectId: string, location: string, clusterName: string>, state: string, status: record<code: string, message: string>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters/($cluster_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Cluster
#
# PATCH /v1/accounts/{account_id}/clusters/{cluster_id}
# operationId: Gateway_UpdateCluster
# --eksCluster shape: {awsAccountId: string, fireworksManagerRole?: string, region: string, clusterName?: string, storageBucketName?: string, metricWriterRole?: string, loadBalancerControllerRole?: string, workloadIdentityPoolProviderId?: string, inferenceRole?: string}
# --fakeCluster shape: {projectId?: string, location?: string, clusterName?: string}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-clusters UpdateCluster" [
  account_id: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human-readable display name of the cluster. e.g. "My Cluster" Must be fewer than 64 characters long.
  --eksCluster: record # shape: {awsAccountId: string, fireworksManagerRole?: string, region: string, clusterName?: string, storageBucketName?: string, metricWriterRole?: string, loadBalancerControllerRole?: string, workloadIdentityPoolProviderId?: string, inferenceRole?: string}
  --fakeCluster: record # shape: {projectId?: string, location?: string, clusterName?: string}
  --state: string@state-completer-1 # - CREATING: The cluster is still being created.  - READY: The cluster is ready to be used.  - DELETING: The cluster is being deleted.  - FAILED: Cluster is not operational. Consult 'status' for detailed messaging. Cluster needs to be deleted and re-created. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
]: any -> record<name: string, displayName: string, createTime: string, eksCluster: record<awsAccountId: string, fireworksManagerRole: string, region: string, clusterName: string, storageBucketName: string, metricWriterRole: string, loadBalancerControllerRole: string, workloadIdentityPoolProviderId: string, inferenceRole: string>, fakeCluster: record<projectId: string, location: string, clusterName: string>, state: string, status: record<code: string, message: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters/($cluster_id)")
  let body = {displayName: $displayName, eksCluster: $eksCluster, fakeCluster: $fakeCluster, state: $state, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Cluster
#
# DELETE /v1/accounts/{account_id}/clusters/{cluster_id}
# operationId: Gateway_DeleteCluster
export def "accounts-clusters DeleteCluster" [
  account_id: string
  cluster_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Cluster Connection Info
#
# GET /v1/accounts/{account_id}/clusters/{cluster_id}:getConnectionInfo
# operationId: Gateway_GetClusterConnectionInfo
export def "accounts-clusters GetClusterConnectionInfo" [
  account_id: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<endpoint: string, caData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/clusters/($cluster_id):getConnectionInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Credit Redemptions
#
# GET /v1/accounts/{account_id}/creditRedemptions
# operationId: Gateway_ListCreditRedemptions
export def "accounts-credit-redemptions ListCreditRedemptions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of redemptions to return (format: int32)
  --pageToken: string # A page token, received from a previous ListCreditRedemptions call
  --filter: string # Filter string to filter redemptions
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar"
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<creditRedemptions: table<name: string, creditCode: string, createTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/creditRedemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Datasets
#
# GET /v1/accounts/{account_id}/datasets
# operationId: Gateway_ListDatasets
export def "accounts-datasets ListDatasets" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of datasets to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDatasets call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDatasets must match the call that provided the page token.
  --filter: string # Only model satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<datasets: table<name: string, displayName: string, createTime: string, state: string, status: record, exampleCount: string, userUploaded: record, evaluationResult: record, transformed: record, splitted: record, evalProtocol: record, externalUrl: string, format: string, createdBy: string, updateTime: string, sourceJobName: string, estimatedTokenCount: string, averageTurnCount: float>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Dataset
#
# POST /v1/accounts/{account_id}/datasets
# operationId: Gateway_CreateDataset
# --dataset shape: {displayName?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, exampleCount?: string, userUploaded?: record, evaluationResult?: record, transformed?: record, splitted?: record, evalProtocol?: record, externalUrl?: string, format?: "FORMAT_UNSPECIFIED"|"CHAT"|"COMPLETION"|"RL", sourceJobName?: string}
export def "accounts-datasets CreateDataset" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset: record # shape: {displayName?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, exampleCount?: string, userUploaded?: record, evaluationResult?: record, transformed?: record, splitted?: record, evalProtocol?: record, externalUrl?: string, format?: "FORMAT_UNSPECIFIED"|"CHAT"|"COMPLETION"|"RL", sourceJobName?: string}
  datasetId: string
  --sourceDatasetId: string
  --filter: string
]: any -> record<name: string, displayName: string, createTime: string, state: string, status: record<code: string, message: string>, exampleCount: string, userUploaded: record, evaluationResult: record<evaluationJobId: string>, transformed: record<sourceDatasetId: string, filter: string, originalFormat: string>, splitted: record<sourceDatasetId: string>, evalProtocol: record, externalUrl: string, format: string, createdBy: string, updateTime: string, sourceJobName: string, estimatedTokenCount: string, averageTurnCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets")
  let body = {dataset: $dataset, datasetId: $datasetId, sourceDatasetId: $sourceDatasetId, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Dataset
#
# GET /v1/accounts/{account_id}/datasets/{dataset_id}
# operationId: Gateway_GetDataset
export def "accounts-datasets GetDataset" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, state: string, status: record<code: string, message: string>, exampleCount: string, userUploaded: record, evaluationResult: record<evaluationJobId: string>, transformed: record<sourceDatasetId: string, filter: string, originalFormat: string>, splitted: record<sourceDatasetId: string>, evalProtocol: record, externalUrl: string, format: string, createdBy: string, updateTime: string, sourceJobName: string, estimatedTokenCount: string, averageTurnCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Dataset
#
# PATCH /v1/accounts/{account_id}/datasets/{dataset_id}
# operationId: Gateway_UpdateDataset
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --evaluationResult shape: {evaluationJobId: string}
# --transformed shape: {sourceDatasetId: string, filter?: string, originalFormat?: "FORMAT_UNSPECIFIED"|"CHAT"|"COMPLETION"|"RL"}
# --splitted shape: {sourceDatasetId: string}
export def "accounts-datasets UpdateDataset" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --state: string@state-completer-2 # default: STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --exampleCount: string # format: int64
  --userUploaded: record
  --evaluationResult: record # shape: {evaluationJobId: string}
  --transformed: record # shape: {sourceDatasetId: string, filter?: string, originalFormat?: "FORMAT_UNSPECIFIED"|"CHAT"|"COMPLETION"|"RL"}
  --splitted: record # shape: {sourceDatasetId: string}
  --evalProtocol: record
  --externalUrl: string
  --format: string@format-completer # default: FORMAT_UNSPECIFIED
  --sourceJobName: string # The resource name of the job that created this dataset (e.g., batch inference job). Used for lineage tracking to understand dataset provenance.
]: any -> record<name: string, displayName: string, createTime: string, state: string, status: record<code: string, message: string>, exampleCount: string, userUploaded: record, evaluationResult: record<evaluationJobId: string>, transformed: record<sourceDatasetId: string, filter: string, originalFormat: string>, splitted: record<sourceDatasetId: string>, evalProtocol: record, externalUrl: string, format: string, createdBy: string, updateTime: string, sourceJobName: string, estimatedTokenCount: string, averageTurnCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id)")
  let body = {displayName: $displayName, state: $state, status: $status, exampleCount: $exampleCount, userUploaded: $userUploaded, evaluationResult: $evaluationResult, transformed: $transformed, splitted: $splitted, evalProtocol: $evalProtocol, externalUrl: $externalUrl, format: $format, sourceJobName: $sourceJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Dataset
#
# DELETE /v1/accounts/{account_id}/datasets/{dataset_id}
# operationId: Gateway_DeleteDataset
export def "accounts-datasets DeleteDataset" [
  account_id: string
  dataset_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Dataset Download Endpoint
#
# GET /v1/accounts/{account_id}/datasets/{dataset_id}:getDownloadEndpoint
# operationId: Gateway_GetDatasetDownloadEndpoint
export def "accounts-datasets GetDatasetDownloadEndpoint" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
  --downloadLineage: oneof<nothing, bool> # If true, downloads entire lineage chain (all related datasets). Filenames will be prefixed with dataset IDs to avoid collisions.
]: nothing -> record<filenameToSignedUrls: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar") (serialize-qp "downloadLineage" $downloadLineage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id):getDownloadEndpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Dataset Upload Endpoint
#
# POST /v1/accounts/{account_id}/datasets/{dataset_id}:getUploadEndpoint
# operationId: Gateway_GetDatasetUploadEndpoint
export def "accounts-datasets GetDatasetUploadEndpoint" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filenameToSize: record # A mapping from the file name to its size in bytes.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: any -> record<filenameToSignedUrls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id):getUploadEndpoint")
  let body = {filenameToSize: $filenameToSize, readMask: $readMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/accounts/{account_id}/datasets/{dataset_id}:splitDataset
#
# operationId: Gateway_SplitDataset
export def "accounts-datasets SplitDataset" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chunkSize: int # format: int32
  --parent: string # The parent account ID of the requester.
]: any -> record<chunkDatasetNames: list<string>, chunksCreated: int, totalExamples: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id):splitDataset")
  let body = {chunkSize: $chunkSize, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate Dataset Upload
#
# POST /v1/accounts/{account_id}/datasets/{dataset_id}:validateUpload
# operationId: Gateway_ValidateDatasetUpload
export def "accounts-datasets ValidateDatasetUpload" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id):validateUpload")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List LoRAs
#
# GET /v1/accounts/{account_id}/deployedModels
# operationId: Gateway_ListDeployedModels
export def "accounts-deployed-models ListDeployedModels" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of deployed models to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDeployedModels call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDeployedModels must match the call that provided the page token.
  --filter: string # Only depoyed models satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<deployedModels: table<name: string, displayName: string, description: string, createTime: string, model: string, deployment: string, default: bool, state: string, serverless: bool, status: record, public: bool, updateTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployedModels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Load LoRA
#
# POST /v1/accounts/{account_id}/deployedModels
# operationId: Gateway_CreateDeployedModel
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-deployed-models CreateDeployedModel" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replaceMergedAddon: oneof<nothing, bool> # Merges new addon to the base model, while unmerging/deleting any existing addon in the deployment. Must be specified for hot reload deployments
  --displayName: string
  --description: string # Description of the resource.
  --model: string
  --deployment: string # The resource name of the base deployment the model is deployed to.
  --default: oneof<nothing, bool> # If true, this is the default target when querying this model without the `#<deployment>` suffix. The first deployment a model is deployed to will have this field set to true.
  --state: string@state-completer-3 # - UNDEPLOYING: The model is being undeployed.  - DEPLOYING: The model is being deployed.  - DEPLOYED: The model is deployed and ready for inference.  - UPDATING: there are updates happening with the deployed model (default: STATE_UNSPECIFIED)
  --serverless: oneof<nothing, bool>
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --public: oneof<nothing, bool> # If true, the deployed model will be publicly reachable.
]: any -> record<name: string, displayName: string, description: string, createTime: string, model: string, deployment: string, default: bool, state: string, serverless: bool, status: record<code: string, message: string>, public: bool, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "replaceMergedAddon" $replaceMergedAddon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployedModels" $qp)
  let body = {displayName: $displayName, description: $description, model: $model, deployment: $deployment, default: $default, state: $state, serverless: $serverless, status: $status, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get LoRA
#
# GET /v1/accounts/{account_id}/deployedModels/{deployed_model_id}
# operationId: Gateway_GetDeployedModel
export def "accounts-deployed-models GetDeployedModel" [
  account_id: string
  deployed_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, model: string, deployment: string, default: bool, state: string, serverless: bool, status: record<code: string, message: string>, public: bool, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployedModels/($deployed_model_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update LoRA
#
# PATCH /v1/accounts/{account_id}/deployedModels/{deployed_model_id}
# operationId: Gateway_UpdateDeployedModel
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-deployed-models UpdateDeployedModel" [
  account_id: string
  deployed_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --description: string # Description of the resource.
  --model: string
  --deployment: string # The resource name of the base deployment the model is deployed to.
  --default: oneof<nothing, bool> # If true, this is the default target when querying this model without the `#<deployment>` suffix. The first deployment a model is deployed to will have this field set to true.
  --state: string@state-completer-3 # - UNDEPLOYING: The model is being undeployed.  - DEPLOYING: The model is being deployed.  - DEPLOYED: The model is deployed and ready for inference.  - UPDATING: there are updates happening with the deployed model (default: STATE_UNSPECIFIED)
  --serverless: oneof<nothing, bool>
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --public: oneof<nothing, bool> # If true, the deployed model will be publicly reachable.
]: any -> record<name: string, displayName: string, description: string, createTime: string, model: string, deployment: string, default: bool, state: string, serverless: bool, status: record<code: string, message: string>, public: bool, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployedModels/($deployed_model_id)")
  let body = {displayName: $displayName, description: $description, model: $model, deployment: $deployment, default: $default, state: $state, serverless: $serverless, status: $status, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unload LoRA
#
# DELETE /v1/accounts/{account_id}/deployedModels/{deployed_model_id}
# operationId: Gateway_DeleteDeployedModel
export def "accounts-deployed-models DeleteDeployedModel" [
  account_id: string
  deployed_model_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployedModels/($deployed_model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployment Shapes
#
# GET /v1/accounts/{account_id}/deploymentShapes
# operationId: Gateway_ListDeploymentShapes
export def "accounts-deployment-shapes ListDeploymentShapes" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of deployments to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDeploymentShapes call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDeploymentShapes must match the call that provided the page token.
  --filter: string # Only deployment satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
  --targetModel: string # Target model that the returned deployment shapes should be compatible with.
]: nothing -> record<deploymentShapes: table<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar") (serialize-qp "targetModel" $targetModel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for deployment shape. Create Deployment Shape
#
# POST /v1/accounts/{account_id}/deploymentShapes
# operationId: Gateway_CreateDeploymentShape
export def "accounts-deployment-shapes CreateDeploymentShape" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentShapeId: string # The ID of the deployment shape. If not specified, a random ID will be generated.
  --displayName: string # Human-readable display name of the deployment shape. e.g. "My Deployment Shape" Must be fewer than 64 characters long.
  --description: string # The description of the deployment shape. Must be fewer than 1000 characters long.
  baseModel: string
  --acceleratorCount: int # The number of accelerators used per replica. If not specified, the default is the estimated minimum required by the base model. (format: int32)
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --disableDeploymentSizeValidation: oneof<nothing, bool> # If true, the deployment size validation is disabled.
  --enableAddons: oneof<nothing, bool> # If true, LORA addons are enabled for deployments created from this shape.
  --draftTokenCount: int # The number of candidate tokens to generate per step for speculative decoding. Default is the base model's draft_token_count. (format: int32)
  --draftModel: string # The draft model name for speculative decoding. e.g. accounts/fireworks/models/my-draft-model If empty, speculative decoding using a draft model is disabled. Default is the base model's default_draft_model. Deprecated: set default_draft_model on the base model instead.
  --ngramSpeculationLength: int # The length of previous input sequence to be considered for N-gram speculation. (format: int32)
  --disableSpeculativeDecoding: oneof<nothing, bool> # If true, speculative decoding is disabled for deployments created from this shape, even if the base model has default draft model settings.
  --enableSessionAffinity: oneof<nothing, bool> # Whether to apply sticky routing based on `user` field.
  --numLoraDeviceCached: int # format: int32
  --maxContextLength: int # The maximum context length supported by the model (context window). If set to 0 or not specified, the model's default maximum context length will be used. (format: int32)
  --presetType: string@presetType-completer # default: PRESET_TYPE_UNSPECIFIED
]: any -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "deploymentShapeId" $deploymentShapeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes" $qp)
  let body = {displayName: $displayName, description: $description, baseModel: $baseModel, acceleratorCount: $acceleratorCount, acceleratorType: $acceleratorType, precision: $precision, disableDeploymentSizeValidation: $disableDeploymentSizeValidation, enableAddons: $enableAddons, draftTokenCount: $draftTokenCount, draftModel: $draftModel, ngramSpeculationLength: $ngramSpeculationLength, disableSpeculativeDecoding: $disableSpeculativeDecoding, enableSessionAffinity: $enableSessionAffinity, numLoraDeviceCached: $numLoraDeviceCached, maxContextLength: $maxContextLength, presetType: $presetType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Deployment Shape
#
# GET /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}
# operationId: Gateway_GetDeploymentShape
export def "accounts-deployment-shapes GetDeploymentShape" [
  account_id: string
  deployment_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
  --skipShapeValidation: oneof<nothing, bool> # If true, returns the latest version regardless of validation status. By default, returns the latest validated version.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar") (serialize-qp "skipShapeValidation" $skipShapeValidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Deployment Shape
#
# PATCH /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}
# operationId: Gateway_UpdateDeploymentShape
export def "accounts-deployment-shapes UpdateDeploymentShape" [
  account_id: string
  deployment_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromLatestValidated: oneof<nothing, bool> # When true, the update will use the latest validated version snapshot as the base for fields not present in the update mask; otherwise, the current shape is used.
  --displayName: string # Human-readable display name of the deployment shape. e.g. "My Deployment Shape" Must be fewer than 64 characters long.
  --description: string # The description of the deployment shape. Must be fewer than 1000 characters long.
  baseModel: string
  --acceleratorCount: int # The number of accelerators used per replica. If not specified, the default is the estimated minimum required by the base model. (format: int32)
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --disableDeploymentSizeValidation: oneof<nothing, bool> # If true, the deployment size validation is disabled.
  --enableAddons: oneof<nothing, bool> # If true, LORA addons are enabled for deployments created from this shape.
  --draftTokenCount: int # The number of candidate tokens to generate per step for speculative decoding. Default is the base model's draft_token_count. (format: int32)
  --draftModel: string # The draft model name for speculative decoding. e.g. accounts/fireworks/models/my-draft-model If empty, speculative decoding using a draft model is disabled. Default is the base model's default_draft_model. Deprecated: set default_draft_model on the base model instead.
  --ngramSpeculationLength: int # The length of previous input sequence to be considered for N-gram speculation. (format: int32)
  --disableSpeculativeDecoding: oneof<nothing, bool> # If true, speculative decoding is disabled for deployments created from this shape, even if the base model has default draft model settings.
  --enableSessionAffinity: oneof<nothing, bool> # Whether to apply sticky routing based on `user` field.
  --numLoraDeviceCached: int # format: int32
  --maxContextLength: int # The maximum context length supported by the model (context window). If set to 0 or not specified, the model's default maximum context length will be used. (format: int32)
  --presetType: string@presetType-completer # default: PRESET_TYPE_UNSPECIFIED
]: any -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "fromLatestValidated" $fromLatestValidated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)" $qp)
  let body = {displayName: $displayName, description: $description, baseModel: $baseModel, acceleratorCount: $acceleratorCount, acceleratorType: $acceleratorType, precision: $precision, disableDeploymentSizeValidation: $disableDeploymentSizeValidation, enableAddons: $enableAddons, draftTokenCount: $draftTokenCount, draftModel: $draftModel, ngramSpeculationLength: $ngramSpeculationLength, disableSpeculativeDecoding: $disableSpeculativeDecoding, enableSessionAffinity: $enableSessionAffinity, numLoraDeviceCached: $numLoraDeviceCached, maxContextLength: $maxContextLength, presetType: $presetType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Deployment Shape
#
# DELETE /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}
# operationId: Gateway_DeleteDeploymentShape
export def "accounts-deployment-shapes DeleteDeploymentShape" [
  account_id: string
  deployment_shape_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployment Shapes Versions
#
# GET /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}/versions
# operationId: Gateway_ListDeploymentShapeVersions
export def "accounts-deployment-shapes-versions ListDeploymentShapeVersions" [
  account_id: string
  deployment_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of deployment shape versions to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDeploymentShapeVersions call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDeploymentShapeVersions must match the call that provided the page token.
  --filter: string # Only deployment shape versions satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<deploymentShapeVersions: table<name: string, createTime: string, snapshot: record, validated: bool, public: bool, latestValidated: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Deployment Shape Version
#
# GET /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}/versions/{version_id}
# operationId: Gateway_GetDeploymentShapeVersion
export def "accounts-deployment-shapes-versions GetDeploymentShapeVersion" [
  account_id: string
  deployment_shape_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, createTime: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string>, validated: bool, public: bool, latestValidated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)/versions/($version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Deployment Shape Version
#
# PATCH /v1/accounts/{account_id}/deploymentShapes/{deployment_shape_id}/versions/{version_id}
# operationId: Gateway_UpdateDeploymentShapeVersion
# --snapshot shape: {displayName?: string, description?: string, baseModel: string, acceleratorCount?: int, acceleratorType?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_A100_80GB"|"NVIDIA_H100_80GB"|"AMD_MI300X_192GB"|"NVIDIA_A10G_24GB"|"NVIDIA_A100_40GB"|"NVIDIA_L4_24GB"|"NVIDIA_H200_141GB"|"NVIDIA_B200_180GB"|"AMD_MI325X_256GB"|"AMD_MI350X_288GB"|"NVIDIA_B300_288GB", precision?: "PRECISION_UNSPECIFIED"|"FP16"|"FP8"|"FP8_MM"|"FP8_AR"|"FP8_MM_KV_ATTN"|"FP8_KV"|"FP8_MM_V2"|"FP8_V2"|"FP8_MM_KV_ATTN_V2"|"NF4"|"FP4"|"BF16"|"FP4_BLOCKSCALED_MM"|"FP4_MX_MOE", disableDeploymentSizeValidation?: bool, enableAddons?: bool, draftTokenCount?: int, draftModel?: string, ngramSpeculationLength?: int, disableSpeculativeDecoding?: bool, enableSessionAffinity?: bool, numLoraDeviceCached?: int, maxContextLength?: int, presetType?: "PRESET_TYPE_UNSPECIFIED"|"MINIMAL"|"FAST"|"THROUGHPUT"|"FULL_PRECISION"|"AGENTIC_CODING"|"CHAT"|"SUMMARIZATION"}
export def "accounts-deployment-shapes-versions UpdateDeploymentShapeVersion" [
  account_id: string
  deployment_shape_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot: record # shape: {displayName?: string, description?: string, baseModel: string, acceleratorCount?: int, acceleratorType?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_A100_80GB"|"NVIDIA_H100_80GB"|"AMD_MI300X_192GB"|"NVIDIA_A10G_24GB"|"NVIDIA_A100_40GB"|"NVIDIA_L4_24GB"|"NVIDIA_H200_141GB"|"NVIDIA_B200_180GB"|"AMD_MI325X_256GB"|"AMD_MI350X_288GB"|"NVIDIA_B300_288GB", precision?: "PRECISION_UNSPECIFIED"|"FP16"|"FP8"|"FP8_MM"|"FP8_AR"|"FP8_MM_KV_ATTN"|"FP8_KV"|"FP8_MM_V2"|"FP8_V2"|"FP8_MM_KV_ATTN_V2"|"NF4"|"FP4"|"BF16"|"FP4_BLOCKSCALED_MM"|"FP4_MX_MOE", disableDeploymentSizeValidation?: bool, enableAddons?: bool, draftTokenCount?: int, draftModel?: string, ngramSpeculationLength?: int, disableSpeculativeDecoding?: bool, enableSessionAffinity?: bool, numLoraDeviceCached?: int, maxContextLength?: int, presetType?: "PRESET_TYPE_UNSPECIFIED"|"MINIMAL"|"FAST"|"THROUGHPUT"|"FULL_PRECISION"|"AGENTIC_CODING"|"CHAT"|"SUMMARIZATION"}
  --validated: oneof<nothing, bool> # If true, this version has been validated.
  --public: oneof<nothing, bool> # If true, this version will be publicly readable.
]: any -> record<name: string, createTime: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, modelType: string, parameterCount: string, acceleratorCount: int, acceleratorType: string, precision: string, disableDeploymentSizeValidation: bool, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, disableSpeculativeDecoding: bool, enableSessionAffinity: bool, numLoraDeviceCached: int, maxContextLength: int, presetType: string>, validated: bool, public: bool, latestValidated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deploymentShapes/($deployment_shape_id)/versions/($version_id)")
  let body = {snapshot: $snapshot, validated: $validated, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Deployments
#
# GET /v1/accounts/{account_id}/deployments
# operationId: Gateway_ListDeployments
export def "accounts-deployments ListDeployments" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of deployments to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDeployments call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDeployments must match the call that provided the page token.
  --filter: string # Only deployment satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --showDeleted: oneof<nothing, bool> # If set, DELETED deployments will be included.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<deployments: table<name: string, displayName: string, description: string, createTime: string, expireTime: string, purgeTime: string, deleteTime: string, state: string, status: record, annotations: record, minReplicaCount: int, maxReplicaCount: int, maxWithRevocableReplicaCount: int, desiredReplicaCount: int, replicaCount: int, autoscalingPolicy: record, baseModel: string, acceleratorCount: int, acceleratorType: string, precision: string, cluster: string, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, enableSessionAffinity: bool, directRouteApiKeys: list, numPeftDeviceCached: int, directRouteType: string, directRouteHandle: string, deploymentTemplate: string, autoTune: record, placement: record, region: string, maxContextLength: int, updateTime: string, disableDeploymentSizeValidation: bool, enableHotLoad: bool, hotLoadBucketType: string, enableHotReloadLatestAddon: bool, deploymentShape: string, activeModelVersion: string, targetModelVersion: string, replicaStats: record, hotLoadBucketUrl: string, pricingPlanId: string, hotLoadTrainerJob: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "showDeleted" $showDeleted "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Deployment
#
# POST /v1/accounts/{account_id}/deployments
# operationId: Gateway_CreateDeployment
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --autoscalingPolicy shape: {scaleUpWindow?: string, scaleDownWindow?: string, scaleToZeroWindow?: string, loadTargets?: record, scalingSchedules?: record}
# --autoTune shape: {longPrompt?: bool}
# --placement shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
export def "accounts-deployments CreateDeployment" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disableAutoDeploy: oneof<nothing, bool> # By default, a deployment created with a currently undeployed base model will be deployed to this deployment. If true, this auto-deploy function is disabled.
  --disableSpeculativeDecoding: oneof<nothing, bool> # By default, a deployment will use the speculative decoding settings from the base model. If true, this will disable speculative decoding.
  --deploymentId: string # The ID of the deployment. If not specified, a random ID will be generated.
  --validateOnly: oneof<nothing, bool> # If true, this will not create the deployment, but will return the deployment that would be created.
  --skipShapeValidation: oneof<nothing, bool> # By default, a deployment will ensure the deployment shape provided is validated. If true, we will not require the deployment shape to be validated.
  --skipImageTagValidation: oneof<nothing, bool> # If true, skip the image tag policy validation that blocks certain image tags. This allows creating deployments with image tags that would otherwise be blocked.
  --displayName: string # Human-readable display name of the deployment. e.g. "My Deployment" Must be fewer than 64 characters long.
  --description: string # Description of the deployment.
  --expireTime: string # Deprecated: This field is deprecated and no longer causes auto-deletion. The time at which this deployment will automatically be deleted. (format: date-time)
  --state: string@state-completer-4 # - CREATING: The deployment is still being created.  - READY: The deployment is ready to be used.  - DELETING: The deployment is being deleted.  - FAILED: The deployment failed to be created. See the `status` field for additional details on why it failed.  - UPDATING: There are in-progress updates happening with the deployment.  - DELETED: The deployment is soft-deleted. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --annotations: record # Annotations to identify deployment properties. Key/value pairs may be used by external tools or other services. The "image-tag-reason" key is redacted from API responses for non-superuser principals.
  --minReplicaCount: int # The minimum number of replicas. If not specified, the default is 0. (format: int32)
  --maxReplicaCount: int # The maximum number of replicas. If not specified, the default is max(min_replica_count, 1). May be set to 0 to downscale the deployment to 0. (format: int32)
  --maxWithRevocableReplicaCount: int # max_with_revocable_replica_count is max replica count including revocable capacity. The max revocable capacity will be max_with_revocable_replica_count - max_replica_count. (format: int32)
  --autoscalingPolicy: record # shape: {scaleUpWindow?: string, scaleDownWindow?: string, scaleToZeroWindow?: string, loadTargets?: record, scalingSchedules?: record}
  baseModel: string
  --acceleratorCount: int # The number of accelerators used per replica. If not specified, the default is the estimated minimum required by the base model. (format: int32)
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --enableAddons: oneof<nothing, bool> # If true, PEFT addons are enabled for this deployment.
  --draftTokenCount: int # The number of candidate tokens to generate per step for speculative decoding. Default is the base model's draft_token_count. Set CreateDeploymentRequest.disable_speculative_decoding to false to disable this behavior. (format: int32)
  --draftModel: string # The draft model name for speculative decoding. e.g. accounts/fireworks/models/my-draft-model If empty, speculative decoding using a draft model is disabled. Default is the base model's default_draft_model. Set CreateDeploymentRequest.disable_speculative_decoding to false to disable this behavior.
  --ngramSpeculationLength: int # The length of previous input sequence to be considered for N-gram speculation. (format: int32)
  --enableSessionAffinity: oneof<nothing, bool> # Whether to apply sticky routing based on `user` field. Serverless will be set to true when creating deployment.
  --directRouteApiKeys: list # The set of API keys used to access the direct route deployment. If direct routing is not enabled, this field is unused.
  --numPeftDeviceCached: int # format: int32
  --directRouteType: string@directRouteType-completer # default: DIRECT_ROUTE_TYPE_UNSPECIFIED
  --deploymentTemplate: string # The name of the deployment template to use for this deployment. Only available to enterprise accounts.
  --autoTune: record # shape: {longPrompt?: bool}
  --placement: record # The desired geographic region where the deployment must be placed. Exactly one field will be specified. — shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
  --region: string@region-completer # default: REGION_UNSPECIFIED
  --maxContextLength: int # The maximum context length supported by the model (context window). If set to 0 or not specified, the model's default maximum context length will be used. (format: int32)
  --disableDeploymentSizeValidation: oneof<nothing, bool> # Whether the deployment size validation is disabled.
  --enableHotLoad: oneof<nothing, bool> # Whether to use hot load for this deployment.
  --hotLoadBucketType: string@hotLoadBucketType-completer # default: BUCKET_TYPE_UNSPECIFIED
  --enableHotReloadLatestAddon: oneof<nothing, bool> # Allows up to 1 addon at a time to be loaded, and will merge it into the base model.
  --deploymentShape: string # The name of the deployment shape that this deployment is using. On the server side, this will be replaced with the deployment shape version name.
  --activeModelVersion: string # The model version that is currently active and applied to running replicas of a deployment.
  --targetModelVersion: string # The target model version that is being rolled out to the deployment. In a ready steady state, the target model version is the same as the active model version.
  --replicaStats: record
  --hotLoadBucketUrl: string
  --pricingPlanId: string # Optional pricing plan ID for custom billing configuration. If set, this deployment will use the pricing plan's billing rules instead of default billing behavior.
  --hotLoadTrainerJob: string
]: any -> record<name: string, displayName: string, description: string, createTime: string, expireTime: string, purgeTime: string, deleteTime: string, state: string, status: record<code: string, message: string>, annotations: record, minReplicaCount: int, maxReplicaCount: int, maxWithRevocableReplicaCount: int, desiredReplicaCount: int, replicaCount: int, autoscalingPolicy: record<scaleUpWindow: string, scaleDownWindow: string, scaleToZeroWindow: string, loadTargets: record, scalingSchedules: record>, baseModel: string, acceleratorCount: int, acceleratorType: string, precision: string, cluster: string, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, enableSessionAffinity: bool, directRouteApiKeys: list<string>, numPeftDeviceCached: int, directRouteType: string, directRouteHandle: string, deploymentTemplate: string, autoTune: record<longPrompt: bool>, placement: record<region: string, multiRegion: string, regions: list<string>>, region: string, maxContextLength: int, updateTime: string, disableDeploymentSizeValidation: bool, enableHotLoad: bool, hotLoadBucketType: string, enableHotReloadLatestAddon: bool, deploymentShape: string, activeModelVersion: string, targetModelVersion: string, replicaStats: record<pendingSchedulingReplicaCount: int, downloadingModelReplicaCount: int, initializingReplicaCount: int, readyReplicaCount: int, revocableReplicaCount: int, partialReplicaCount: float>, hotLoadBucketUrl: string, pricingPlanId: string, hotLoadTrainerJob: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "disableAutoDeploy" $disableAutoDeploy "scalar") (serialize-qp "disableSpeculativeDecoding" $disableSpeculativeDecoding "scalar") (serialize-qp "deploymentId" $deploymentId "scalar") (serialize-qp "validateOnly" $validateOnly "scalar") (serialize-qp "skipShapeValidation" $skipShapeValidation "scalar") (serialize-qp "skipImageTagValidation" $skipImageTagValidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments" $qp)
  let body = {displayName: $displayName, description: $description, expireTime: $expireTime, state: $state, status: $status, annotations: $annotations, minReplicaCount: $minReplicaCount, maxReplicaCount: $maxReplicaCount, maxWithRevocableReplicaCount: $maxWithRevocableReplicaCount, autoscalingPolicy: $autoscalingPolicy, baseModel: $baseModel, acceleratorCount: $acceleratorCount, acceleratorType: $acceleratorType, precision: $precision, enableAddons: $enableAddons, draftTokenCount: $draftTokenCount, draftModel: $draftModel, ngramSpeculationLength: $ngramSpeculationLength, enableSessionAffinity: $enableSessionAffinity, directRouteApiKeys: $directRouteApiKeys, numPeftDeviceCached: $numPeftDeviceCached, directRouteType: $directRouteType, deploymentTemplate: $deploymentTemplate, autoTune: $autoTune, placement: $placement, region: $region, maxContextLength: $maxContextLength, disableDeploymentSizeValidation: $disableDeploymentSizeValidation, enableHotLoad: $enableHotLoad, hotLoadBucketType: $hotLoadBucketType, enableHotReloadLatestAddon: $enableHotReloadLatestAddon, deploymentShape: $deploymentShape, activeModelVersion: $activeModelVersion, targetModelVersion: $targetModelVersion, replicaStats: $replicaStats, hotLoadBucketUrl: $hotLoadBucketUrl, pricingPlanId: $pricingPlanId, hotLoadTrainerJob: $hotLoadTrainerJob} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Deployment
#
# GET /v1/accounts/{account_id}/deployments/{deployment_id}
# operationId: Gateway_GetDeployment
export def "accounts-deployments GetDeployment" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, expireTime: string, purgeTime: string, deleteTime: string, state: string, status: record<code: string, message: string>, annotations: record, minReplicaCount: int, maxReplicaCount: int, maxWithRevocableReplicaCount: int, desiredReplicaCount: int, replicaCount: int, autoscalingPolicy: record<scaleUpWindow: string, scaleDownWindow: string, scaleToZeroWindow: string, loadTargets: record, scalingSchedules: record>, baseModel: string, acceleratorCount: int, acceleratorType: string, precision: string, cluster: string, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, enableSessionAffinity: bool, directRouteApiKeys: list<string>, numPeftDeviceCached: int, directRouteType: string, directRouteHandle: string, deploymentTemplate: string, autoTune: record<longPrompt: bool>, placement: record<region: string, multiRegion: string, regions: list<string>>, region: string, maxContextLength: int, updateTime: string, disableDeploymentSizeValidation: bool, enableHotLoad: bool, hotLoadBucketType: string, enableHotReloadLatestAddon: bool, deploymentShape: string, activeModelVersion: string, targetModelVersion: string, replicaStats: record<pendingSchedulingReplicaCount: int, downloadingModelReplicaCount: int, initializingReplicaCount: int, readyReplicaCount: int, revocableReplicaCount: int, partialReplicaCount: float>, hotLoadBucketUrl: string, pricingPlanId: string, hotLoadTrainerJob: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Deployment
#
# PATCH /v1/accounts/{account_id}/deployments/{deployment_id}
# operationId: Gateway_UpdateDeployment
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --autoscalingPolicy shape: {scaleUpWindow?: string, scaleDownWindow?: string, scaleToZeroWindow?: string, loadTargets?: record, scalingSchedules?: record}
# --autoTune shape: {longPrompt?: bool}
# --placement shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
export def "accounts-deployments UpdateDeployment" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipShapeValidation: oneof<nothing, bool> # By default, updating a deployment shape will ensure the new deployment shape provided is validated. If true, we will not require the deployment shape to be validated.
  --displayName: string # Human-readable display name of the deployment. e.g. "My Deployment" Must be fewer than 64 characters long.
  --description: string # Description of the deployment.
  --expireTime: string # Deprecated: This field is deprecated and no longer causes auto-deletion. The time at which this deployment will automatically be deleted. (format: date-time)
  --state: string@state-completer-4 # - CREATING: The deployment is still being created.  - READY: The deployment is ready to be used.  - DELETING: The deployment is being deleted.  - FAILED: The deployment failed to be created. See the `status` field for additional details on why it failed.  - UPDATING: There are in-progress updates happening with the deployment.  - DELETED: The deployment is soft-deleted. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --annotations: record # Annotations to identify deployment properties. Key/value pairs may be used by external tools or other services. The "image-tag-reason" key is redacted from API responses for non-superuser principals.
  --minReplicaCount: int # The minimum number of replicas. If not specified, the default is 0. (format: int32)
  --maxReplicaCount: int # The maximum number of replicas. If not specified, the default is max(min_replica_count, 1). May be set to 0 to downscale the deployment to 0. (format: int32)
  --maxWithRevocableReplicaCount: int # max_with_revocable_replica_count is max replica count including revocable capacity. The max revocable capacity will be max_with_revocable_replica_count - max_replica_count. (format: int32)
  --autoscalingPolicy: record # shape: {scaleUpWindow?: string, scaleDownWindow?: string, scaleToZeroWindow?: string, loadTargets?: record, scalingSchedules?: record}
  baseModel: string
  --acceleratorCount: int # The number of accelerators used per replica. If not specified, the default is the estimated minimum required by the base model. (format: int32)
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --enableAddons: oneof<nothing, bool> # If true, PEFT addons are enabled for this deployment.
  --draftTokenCount: int # The number of candidate tokens to generate per step for speculative decoding. Default is the base model's draft_token_count. Set CreateDeploymentRequest.disable_speculative_decoding to false to disable this behavior. (format: int32)
  --draftModel: string # The draft model name for speculative decoding. e.g. accounts/fireworks/models/my-draft-model If empty, speculative decoding using a draft model is disabled. Default is the base model's default_draft_model. Set CreateDeploymentRequest.disable_speculative_decoding to false to disable this behavior.
  --ngramSpeculationLength: int # The length of previous input sequence to be considered for N-gram speculation. (format: int32)
  --enableSessionAffinity: oneof<nothing, bool> # Whether to apply sticky routing based on `user` field. Serverless will be set to true when creating deployment.
  --directRouteApiKeys: list # The set of API keys used to access the direct route deployment. If direct routing is not enabled, this field is unused.
  --numPeftDeviceCached: int # format: int32
  --directRouteType: string@directRouteType-completer # default: DIRECT_ROUTE_TYPE_UNSPECIFIED
  --deploymentTemplate: string # The name of the deployment template to use for this deployment. Only available to enterprise accounts.
  --autoTune: record # shape: {longPrompt?: bool}
  --placement: record # The desired geographic region where the deployment must be placed. Exactly one field will be specified. — shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
  --region: string@region-completer # default: REGION_UNSPECIFIED
  --maxContextLength: int # The maximum context length supported by the model (context window). If set to 0 or not specified, the model's default maximum context length will be used. (format: int32)
  --disableDeploymentSizeValidation: oneof<nothing, bool> # Whether the deployment size validation is disabled.
  --enableHotLoad: oneof<nothing, bool> # Whether to use hot load for this deployment.
  --hotLoadBucketType: string@hotLoadBucketType-completer # default: BUCKET_TYPE_UNSPECIFIED
  --enableHotReloadLatestAddon: oneof<nothing, bool> # Allows up to 1 addon at a time to be loaded, and will merge it into the base model.
  --deploymentShape: string # The name of the deployment shape that this deployment is using. On the server side, this will be replaced with the deployment shape version name.
  --activeModelVersion: string # The model version that is currently active and applied to running replicas of a deployment.
  --targetModelVersion: string # The target model version that is being rolled out to the deployment. In a ready steady state, the target model version is the same as the active model version.
  --replicaStats: record
  --hotLoadBucketUrl: string
  --pricingPlanId: string # Optional pricing plan ID for custom billing configuration. If set, this deployment will use the pricing plan's billing rules instead of default billing behavior.
  --hotLoadTrainerJob: string
]: any -> record<name: string, displayName: string, description: string, createTime: string, expireTime: string, purgeTime: string, deleteTime: string, state: string, status: record<code: string, message: string>, annotations: record, minReplicaCount: int, maxReplicaCount: int, maxWithRevocableReplicaCount: int, desiredReplicaCount: int, replicaCount: int, autoscalingPolicy: record<scaleUpWindow: string, scaleDownWindow: string, scaleToZeroWindow: string, loadTargets: record, scalingSchedules: record>, baseModel: string, acceleratorCount: int, acceleratorType: string, precision: string, cluster: string, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, enableSessionAffinity: bool, directRouteApiKeys: list<string>, numPeftDeviceCached: int, directRouteType: string, directRouteHandle: string, deploymentTemplate: string, autoTune: record<longPrompt: bool>, placement: record<region: string, multiRegion: string, regions: list<string>>, region: string, maxContextLength: int, updateTime: string, disableDeploymentSizeValidation: bool, enableHotLoad: bool, hotLoadBucketType: string, enableHotReloadLatestAddon: bool, deploymentShape: string, activeModelVersion: string, targetModelVersion: string, replicaStats: record<pendingSchedulingReplicaCount: int, downloadingModelReplicaCount: int, initializingReplicaCount: int, readyReplicaCount: int, revocableReplicaCount: int, partialReplicaCount: float>, hotLoadBucketUrl: string, pricingPlanId: string, hotLoadTrainerJob: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "skipShapeValidation" $skipShapeValidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)" $qp)
  let body = {displayName: $displayName, description: $description, expireTime: $expireTime, state: $state, status: $status, annotations: $annotations, minReplicaCount: $minReplicaCount, maxReplicaCount: $maxReplicaCount, maxWithRevocableReplicaCount: $maxWithRevocableReplicaCount, autoscalingPolicy: $autoscalingPolicy, baseModel: $baseModel, acceleratorCount: $acceleratorCount, acceleratorType: $acceleratorType, precision: $precision, enableAddons: $enableAddons, draftTokenCount: $draftTokenCount, draftModel: $draftModel, ngramSpeculationLength: $ngramSpeculationLength, enableSessionAffinity: $enableSessionAffinity, directRouteApiKeys: $directRouteApiKeys, numPeftDeviceCached: $numPeftDeviceCached, directRouteType: $directRouteType, deploymentTemplate: $deploymentTemplate, autoTune: $autoTune, placement: $placement, region: $region, maxContextLength: $maxContextLength, disableDeploymentSizeValidation: $disableDeploymentSizeValidation, enableHotLoad: $enableHotLoad, hotLoadBucketType: $hotLoadBucketType, enableHotReloadLatestAddon: $enableHotReloadLatestAddon, deploymentShape: $deploymentShape, activeModelVersion: $activeModelVersion, targetModelVersion: $targetModelVersion, replicaStats: $replicaStats, hotLoadBucketUrl: $hotLoadBucketUrl, pricingPlanId: $pricingPlanId, hotLoadTrainerJob: $hotLoadTrainerJob} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Deployment
#
# DELETE /v1/accounts/{account_id}/deployments/{deployment_id}
# operationId: Gateway_DeleteDeployment
export def "accounts-deployments DeleteDeployment" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: oneof<nothing, bool> # If true, this will perform a hard deletion.
  --ignoreChecks: oneof<nothing, bool> # If true, this will ignore checks and force the deletion of a deployment that is currently deployed and is in use.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "hard" $hard "scalar") (serialize-qp "ignoreChecks" $ignoreChecks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ledger
#
# GET /v1/accounts/{account_id}/deployments/{deployment_id}/ledger
# operationId: Gateway_GetLedger
export def "accounts-deployments-ledger GetLedger" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ledger: table<timestamp: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)/ledger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset ledger for hot load
#
# DELETE /v1/accounts/{account_id}/deployments/{deployment_id}/ledger
# operationId: Gateway_ResetLedger
export def "accounts-deployments-ledger ResetLedger" [
  account_id: string
  deployment_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)/ledger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployment Shards
#
# GET /v1/accounts/{account_id}/deployments/{deployment_id}/shards
# operationId: Gateway_ListDeploymentShards
export def "accounts-deployments-shards ListDeploymentShards" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of deployment shards to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDeploymentShards call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDeploymentShards must match the call that provided the page token.
  --filter: string # Only deployment shard satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<deploymentShards: table<name: string, createTime: string, updateTime: string, state: string, status: record, replicaStats: record>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)/shards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get termination message from deployment
#
# GET /v1/accounts/{account_id}/deployments/{deployment_id}/terminationMessage
# operationId: Gateway_GetTerminationMessage
export def "accounts-deployments-termination-message GetTerminationMessage" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id)/terminationMessage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Deployment Metrics (Deprecated)
#
# GET /v1/accounts/{account_id}/deployments/{deployment_id}:metrics
# operationId: Gateway_GetDeploymentMetrics
export def "accounts-deployments GetDeploymentMetrics" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeRange: string # The time range to fetch metrics for (e.g. "1m", "10m", "2h"). Defaults to 10m.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<metrics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "timeRange" $timeRange "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id):metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scale Deployment to a specific number of replicas or to zero
#
# PATCH /v1/accounts/{account_id}/deployments/{deployment_id}:scale
# operationId: Gateway_ScaleDeployment
export def "accounts-deployments ScaleDeployment" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replicaCount: int # The desired number of replicas. (format: int32)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id):scale")
  let body = {replicaCount: $replicaCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Undelete Deployment
#
# POST /v1/accounts/{account_id}/deployments/{deployment_id}:undelete
# operationId: Gateway_UndeleteDeployment
export def "accounts-deployments UndeleteDeployment" [
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, displayName: string, description: string, createTime: string, expireTime: string, purgeTime: string, deleteTime: string, state: string, status: record<code: string, message: string>, annotations: record, minReplicaCount: int, maxReplicaCount: int, maxWithRevocableReplicaCount: int, desiredReplicaCount: int, replicaCount: int, autoscalingPolicy: record<scaleUpWindow: string, scaleDownWindow: string, scaleToZeroWindow: string, loadTargets: record, scalingSchedules: record>, baseModel: string, acceleratorCount: int, acceleratorType: string, precision: string, cluster: string, enableAddons: bool, draftTokenCount: int, draftModel: string, ngramSpeculationLength: int, enableSessionAffinity: bool, directRouteApiKeys: list<string>, numPeftDeviceCached: int, directRouteType: string, directRouteHandle: string, deploymentTemplate: string, autoTune: record<longPrompt: bool>, placement: record<region: string, multiRegion: string, regions: list<string>>, region: string, maxContextLength: int, updateTime: string, disableDeploymentSizeValidation: bool, enableHotLoad: bool, hotLoadBucketType: string, enableHotReloadLatestAddon: bool, deploymentShape: string, activeModelVersion: string, targetModelVersion: string, replicaStats: record<pendingSchedulingReplicaCount: int, downloadingModelReplicaCount: int, initializingReplicaCount: int, readyReplicaCount: int, revocableReplicaCount: int, partialReplicaCount: float>, hotLoadBucketUrl: string, pricingPlanId: string, hotLoadTrainerJob: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/deployments/($deployment_id):undelete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Developer Passes
#
# GET /v1/accounts/{account_id}/developerPasses
# operationId: Gateway_ListDeveloperPasses
export def "accounts-developer-passes ListDeveloperPasses" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Maximum number of developer passes to return. (format: int32)
  --pageToken: string # Page token from a previous ListDeveloperPasses call.
  --filter: string # Filter expression (e.g., "state=ACTIVE")
  --orderBy: string # Order by expression (e.g., "create_time desc")
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<developerPasses: table<name: string, autoRenew: bool, endTime: string, createTime: string, updateTime: string, state: string, lastRenewTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/developerPasses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for developer passes. Create Developer Pass
#
# POST /v1/accounts/{account_id}/developerPasses
# operationId: Gateway_CreateDeveloperPass
export def "accounts-developer-passes CreateDeveloperPass" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoRenew: oneof<nothing, bool> # Whether the developer pass will automatically renew upon expiry.
  --state: string@state-completer-5 # default: STATE_UNSPECIFIED
]: any -> record<name: string, autoRenew: bool, endTime: string, createTime: string, updateTime: string, state: string, lastRenewTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/developerPasses")
  let body = {autoRenew: $autoRenew, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Developer Pass
#
# GET /v1/accounts/{account_id}/developerPasses/{developer_passe_id}
# operationId: Gateway_GetDeveloperPass
export def "accounts-developer-passes GetDeveloperPass" [
  account_id: string
  developer_passe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, autoRenew: bool, endTime: string, createTime: string, updateTime: string, state: string, lastRenewTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/developerPasses/($developer_passe_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Developer Pass
#
# PATCH /v1/accounts/{account_id}/developerPasses/{developer_passe_id}
# operationId: Gateway_UpdateDeveloperPass
export def "accounts-developer-passes UpdateDeveloperPass" [
  account_id: string
  developer_passe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoRenew: oneof<nothing, bool> # Whether the developer pass will automatically renew upon expiry.
  --state: string@state-completer-5 # default: STATE_UNSPECIFIED
]: any -> record<name: string, autoRenew: bool, endTime: string, createTime: string, updateTime: string, state: string, lastRenewTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/developerPasses/($developer_passe_id)")
  let body = {autoRenew: $autoRenew, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{account_id}/dpoJobs
#
# operationId: Gateway_ListDpoJobs
export def "accounts-dpo-jobs ListDpoJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of dpo jobs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListDpoJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDpoJobs must match the call that provided the page token.
  --filter: string # Filter criteria for the returned jobs. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<dpoJobs: table<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, state: string, status: record, createdBy: string, trainingConfig: record, wandbConfig: record, trainerLogsSignedUrl: string, lossConfig: record, awsS3Config: record, azureBlobStorageConfig: record, purpose: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/accounts/{account_id}/dpoJobs
#
# operationId: Gateway_CreateDpoJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --trainingConfig shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --lossConfig shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
export def "accounts-dpo-jobs CreateDpoJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dpoJobId: string # ID of the DPO job, a random ID will be generated if not specified.
  --displayName: string
  dataset: string # The name of the dataset used for training.
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --trainingConfig: record # shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --lossConfig: record # Loss method + hyperparameters for reinforcement-learning-style fine-tuning (e.g. RFT / RL trainers). For preference jobs (DPO API), the default loss method is GRPO when METHOD_UNSPECIFIED. — shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, trainerLogsSignedUrl: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "dpoJobId" $dpoJobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs" $qp)
  let body = {displayName: $displayName, dataset: $dataset, state: $state, status: $status, trainingConfig: $trainingConfig, wandbConfig: $wandbConfig, lossConfig: $lossConfig, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{account_id}/dpoJobs/{dpo_job_id}
#
# operationId: Gateway_GetDpoJob
export def "accounts-dpo-jobs GetDpoJob" [
  account_id: string
  dpo_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, trainerLogsSignedUrl: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs/($dpo_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/accounts/{account_id}/dpoJobs/{dpo_job_id}
#
# operationId: Gateway_DeleteDpoJob
export def "accounts-dpo-jobs DeleteDpoJob" [
  account_id: string
  dpo_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs/($dpo_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Dpo Job
#
# POST /v1/accounts/{account_id}/dpoJobs/{dpo_job_id}:cancel
# operationId: Gateway_CancelDpoJob
export def "accounts-dpo-jobs CancelDpoJob" [
  account_id: string
  dpo_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs/($dpo_job_id):cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{account_id}/dpoJobs/{dpo_job_id}:getMetricsFileEndpoint
#
# operationId: Gateway_GetDpoJobMetricsFileEndpoint
export def "accounts-dpo-jobs GetDpoJobMetricsFileEndpoint" [
  account_id: string
  dpo_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<signedUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs/($dpo_job_id):getMetricsFileEndpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume Dpo Job
#
# POST /v1/accounts/{account_id}/dpoJobs/{dpo_job_id}:resume
# operationId: Gateway_ResumeDpoJob
export def "accounts-dpo-jobs ResumeDpoJob" [
  account_id: string
  dpo_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, trainerLogsSignedUrl: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/dpoJobs/($dpo_job_id):resume")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Evaluation Jobs
#
# GET /v1/accounts/{account_id}/evaluationJobs
# operationId: Gateway_ListEvaluationJobs
export def "accounts-evaluation-jobs ListEvaluationJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<evaluationJobs: table<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record, evaluator: string, inputDataset: string, outputDataset: string, metrics: record, outputStats: string, updateTime: string, awsS3Config: record>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluationJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Evaluation Job
#
# POST /v1/accounts/{account_id}/evaluationJobs
# operationId: Gateway_CreateEvaluationJob
# --evaluationJob shape: {displayName?: string, state?: "JOB_STATE_UNSPECIFIED"|"JOB_STATE_CREATING"|"JOB_STATE_RUNNING"|"JOB_STATE_COMPLETED"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_DELETING"|"JOB_STATE_WRITING_RESULTS"|"JOB_STATE_VALIDATING"|"JOB_STATE_DELETING_CLEANING_UP"|"JOB_STATE_PENDING"|"JOB_STATE_EXPIRED"|"JOB_STATE_RE_QUEUEING"|"JOB_STATE_CREATING_INPUT_DATASET"|"JOB_STATE_IDLE"|"JOB_STATE_CANCELLING"|"JOB_STATE_EARLY_STOPPED"|"JOB_STATE_PAUSED"|"JOB_STATE_DELETED", status?: record, evaluator: string, inputDataset: string, outputDataset: string, outputStats?: string, awsS3Config?: record}
export def "accounts-evaluation-jobs CreateEvaluationJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluationJob: record # shape: {displayName?: string, state?: "JOB_STATE_UNSPECIFIED"|"JOB_STATE_CREATING"|"JOB_STATE_RUNNING"|"JOB_STATE_COMPLETED"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_DELETING"|"JOB_STATE_WRITING_RESULTS"|"JOB_STATE_VALIDATING"|"JOB_STATE_DELETING_CLEANING_UP"|"JOB_STATE_PENDING"|"JOB_STATE_EXPIRED"|"JOB_STATE_RE_QUEUEING"|"JOB_STATE_CREATING_INPUT_DATASET"|"JOB_STATE_IDLE"|"JOB_STATE_CANCELLING"|"JOB_STATE_EARLY_STOPPED"|"JOB_STATE_PAUSED"|"JOB_STATE_DELETED", status?: record, evaluator: string, inputDataset: string, outputDataset: string, outputStats?: string, awsS3Config?: record}
  --evaluationJobId: string
]: any -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, evaluator: string, inputDataset: string, outputDataset: string, metrics: record, outputStats: string, updateTime: string, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluationJobs")
  let body = {evaluationJob: $evaluationJob, evaluationJobId: $evaluationJobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Evaluation Job
#
# GET /v1/accounts/{account_id}/evaluationJobs/{evaluation_job_id}
# operationId: Gateway_GetEvaluationJob
export def "accounts-evaluation-jobs GetEvaluationJob" [
  account_id: string
  evaluation_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, evaluator: string, inputDataset: string, outputDataset: string, metrics: record, outputStats: string, updateTime: string, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluationJobs/($evaluation_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Evaluation Job
#
# DELETE /v1/accounts/{account_id}/evaluationJobs/{evaluation_job_id}
# operationId: Gateway_DeleteEvaluationJob
export def "accounts-evaluation-jobs DeleteEvaluationJob" [
  account_id: string
  evaluation_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluationJobs/($evaluation_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Evaluation Job execution logs (stream log endpoint + tracing IDs).
#
# GET /v1/accounts/{account_id}/evaluationJobs/{evaluation_job_id}:getExecutionLogEndpoint
# operationId: Gateway_GetEvaluationJobExecutionLogEndpoint
export def "accounts-evaluation-jobs GetEvaluationJobExecutionLogEndpoint" [
  account_id: string
  evaluation_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<executionLogSignedUri: string, contentType: string, expireTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluationJobs/($evaluation_job_id):getExecutionLogEndpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Evaluations
#
# GET /v1/accounts/{account_id}/evaluations
# operationId: Gateway_ListEvaluations
export def "accounts-evaluations ListEvaluations" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<evaluations: table<name: string, createTime: string, createdBy: string, status: record, evaluationType: string, description: string, providers: list, assertions: list, updateTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Evaluation
#
# POST /v1/accounts/{account_id}/evaluations
# operationId: Gateway_CreateEvaluation
# --evaluation shape: {status?: record, evaluationType: string, description?: string, providers: list, assertions: list}
export def "accounts-evaluations CreateEvaluation" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluation: record # shape: {status?: record, evaluationType: string, description?: string, providers: list, assertions: list}
  --evaluationId: string
]: any -> record<name: string, createTime: string, createdBy: string, status: record<code: string, message: string>, evaluationType: string, description: string, providers: table<id: string, config: record, label: string>, assertions: table<assertionType: string, llmAssertion: record, codeAssertion: record, metricName: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations")
  let body = {evaluation: $evaluation, evaluationId: $evaluationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Evaluation
#
# GET /v1/accounts/{account_id}/evaluations/{evaluation_id}
# operationId: Gateway_GetEvaluation
export def "accounts-evaluations GetEvaluation" [
  account_id: string
  evaluation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, createTime: string, createdBy: string, status: record<code: string, message: string>, evaluationType: string, description: string, providers: table<id: string, config: record, label: string>, assertions: table<assertionType: string, llmAssertion: record, codeAssertion: record, metricName: string>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations/($evaluation_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TODO: Add Update Evaluation Update Evaluation rpc UpdateEvaluation(UpdateEvaluationRequest) returns (Evaluation) {   option (google.api.http) = {     patch: "/v1/{evaluation.name=accounts/*/evaluations/*}"     body: "evaluation"   }; } Delete Evaluation
#
# DELETE /v1/accounts/{account_id}/evaluations/{evaluation_id}
# operationId: Gateway_DeleteEvaluation
export def "accounts-evaluations DeleteEvaluation" [
  account_id: string
  evaluation_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations/($evaluation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview an evaluation with sample data
#
# POST /v1/accounts/{account_id}/evaluations/{evaluation_id}:preview
# operationId: Gateway_PreviewEvaluation
export def "accounts-evaluations PreviewEvaluation" [
  account_id: string
  evaluation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sampleData: string
  --maxSamples: int # format: int32
]: any -> record<results: table<success: bool, reason: string, score: float, messages: list, metrics: record>, totalSamples: int, totalRuntimeMs: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations/($evaluation_id):preview")
  let body = {sampleData: $sampleData, maxSamples: $maxSamples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate evaluation assertions
#
# POST /v1/accounts/{account_id}/evaluations:validateAssertions
# operationId: Gateway_ValidateAssertions
# --assertions item shape: {assertionType: "ASSERTION_TYPE_UNSPECIFIED"|"ASSERTION_TYPE_LLM"|"ASSERTION_TYPE_CODE", llmAssertion?: record, codeAssertion?: record, metricName?: string}
export def "accounts-evaluations-validate-assertions ValidateAssertions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assertions: list # item shape: {assertionType: "ASSERTION_TYPE_UNSPECIFIED"|"ASSERTION_TYPE_LLM"|"ASSERTION_TYPE_CODE", llmAssertion?: record, codeAssertion?: record, metricName?: string}
]: any -> record<status: string, metricToErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluations:validateAssertions")
  let body = {assertions: $assertions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Evaluators
#
# GET /v1/accounts/{account_id}/evaluators
# operationId: Gateway_ListEvaluators
export def "accounts-evaluators ListEvaluators" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<evaluators: table<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: list, requirements: string, entryPoint: string, status: record, commitHash: string, source: record, defaultDataset: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Evaluator (Deprecated)
#
# POST /v1/accounts/{account_id}/evaluators
# operationId: Gateway_CreateEvaluator
# --evaluator shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
export def "accounts-evaluators CreateEvaluator" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluator: record # shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
  --evaluatorId: string
]: any -> record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: table<type: string, name: string, description: string, codeSnippets: record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators")
  let body = {evaluator: $evaluator, evaluatorId: $evaluatorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Evaluator
#
# GET /v1/accounts/{account_id}/evaluators/{evaluator_id}
# operationId: Gateway_GetEvaluator
export def "accounts-evaluators GetEvaluator" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: table<type: string, name: string, description: string, codeSnippets: record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Evaluator
#
# PATCH /v1/accounts/{account_id}/evaluators/{evaluator_id}
# operationId: Gateway_UpdateEvaluator
# --criteria item shape: {type?: "TYPE_UNSPECIFIED"|"CODE_SNIPPETS", name?: string, description?: string, codeSnippets?: record}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --source shape: {type?: "TYPE_UNSPECIFIED"|"TYPE_UPLOAD"|"TYPE_GITHUB"|"TYPE_TEMPORARY", githubRepositoryName?: string}
export def "accounts-evaluators UpdateEvaluator" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prepareCodeUpload: oneof<nothing, bool> # If true, prepare a new code upload/build attempt by transitioning the evaluator to BUILDING state. Can be used without update_mask.
  --displayName: string
  --description: string
  --state: string@state-completer-6 # default: STATE_UNSPECIFIED
  --criteria: list # item shape: {type?: "TYPE_UNSPECIFIED"|"CODE_SNIPPETS", name?: string, description?: string, codeSnippets?: record}
  --requirements: string
  --entryPoint: string
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --commitHash: string
  --body-source: record # shape: {type?: "TYPE_UNSPECIFIED"|"TYPE_UPLOAD"|"TYPE_GITHUB"|"TYPE_TEMPORARY", githubRepositoryName?: string}
  --defaultDataset: string
]: any -> record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: table<type: string, name: string, description: string, codeSnippets: record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "prepareCodeUpload" $prepareCodeUpload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)" $qp)
  let body = {displayName: $displayName, description: $description, state: $state, criteria: $criteria, requirements: $requirements, entryPoint: $entryPoint, status: $status, commitHash: $commitHash, source: $body_source, defaultDataset: $defaultDataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Evaluator
#
# DELETE /v1/accounts/{account_id}/evaluators/{evaluator_id}
# operationId: Gateway_DeleteEvaluator
export def "accounts-evaluators DeleteEvaluator" [
  account_id: string
  evaluator_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Evaluator Revisions
#
# GET /v1/accounts/{account_id}/evaluators/{evaluator_id}/versions
# operationId: Gateway_ListEvaluatorVersions
export def "accounts-evaluators-versions ListEvaluatorVersions" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string # Default order should be reverse chronological (newest first) per AIP-162.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<evaluatorVersions: table<name: string, snapshot: record, createTime: string, alternateIds: list>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for evaluator revisions (AIP-162). Get Evaluator Revision
#
# GET /v1/accounts/{account_id}/evaluators/{evaluator_id}/versions/{version_id}
# operationId: Gateway_GetEvaluatorVersion
export def "accounts-evaluators-versions GetEvaluatorVersion" [
  account_id: string
  evaluator_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: list<record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string>, createTime: string, alternateIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)/versions/($version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Evaluator Revision (deletes alias if name is an alias per AIP-162)
#
# DELETE /v1/accounts/{account_id}/evaluators/{evaluator_id}/versions/{version_id}
# operationId: Gateway_DeleteEvaluatorVersion
export def "accounts-evaluators-versions DeleteEvaluatorVersion" [
  account_id: string
  evaluator_id: string
  version_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Alias Evaluator Revision - assign or update a user-specified alias
#
# POST /v1/accounts/{account_id}/evaluators/{evaluator_id}/versions/{version_id}:alias
# operationId: Gateway_AliasEvaluatorVersion
export def "accounts-evaluators-versions AliasEvaluatorVersion" [
  account_id: string
  evaluator_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  aliasId: string # The alias ID (e.g., "current", a semver tag, etc.).
]: any -> record<name: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: list<record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string>, createTime: string, alternateIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)/versions/($version_id):alias")
  let body = {aliasId: $aliasId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rollback Evaluator to a specific revision
#
# POST /v1/accounts/{account_id}/evaluators/{evaluator_id}/versions/{version_id}:rollback
# operationId: Gateway_RollbackEvaluator
export def "accounts-evaluators-versions RollbackEvaluator" [
  account_id: string
  evaluator_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: list<record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string>, createTime: string, alternateIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id)/versions/($version_id):rollback")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Evaluator Build Log Endpoint
#
# GET /v1/accounts/{account_id}/evaluators/{evaluator_id}:getBuildLogEndpoint
# operationId: Gateway_GetEvaluatorBuildLogEndpoint
export def "accounts-evaluators GetEvaluatorBuildLogEndpoint" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<buildLogSignedUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id):getBuildLogEndpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Evaluator Source Code Endpoint
#
# GET /v1/accounts/{account_id}/evaluators/{evaluator_id}:getSourceCodeSignedUrl
# operationId: Gateway_GetEvaluatorSourceCodeEndpoint
export def "accounts-evaluators GetEvaluatorSourceCodeEndpoint" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<filenameToSignedUrls: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id):getSourceCodeSignedUrl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Evaluator Upload Endpoint
#
# POST /v1/accounts/{account_id}/evaluators/{evaluator_id}:getUploadEndpoint
# operationId: Gateway_GetEvaluatorUploadEndpoint
export def "accounts-evaluators GetEvaluatorUploadEndpoint" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filenameToSize: record
  --readMask: string
]: any -> record<filenameToSignedUrls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id):getUploadEndpoint")
  let body = {filenameToSize: $filenameToSize, readMask: $readMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate Evaluator Upload
#
# POST /v1/accounts/{account_id}/evaluators/{evaluator_id}:validateUpload
# operationId: Gateway_ValidateEvaluatorUpload
export def "accounts-evaluators ValidateEvaluatorUpload" [
  account_id: string
  evaluator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators/($evaluator_id):validateUpload")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/accounts/{account_id}/evaluators:previewEvaluator
#
# operationId: Gateway_PreviewEvaluator
# --evaluator shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
export def "accounts-evaluators-preview-evaluator PreviewEvaluator" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluator: record # shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
  sampleData: list
  --maxSamples: int # format: int32
]: any -> record<results: table<success: string, score: float, perMetricEvals: record, reason: string>, totalSamples: int, totalRuntimeMs: string, stdout: list<string>, stderr: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluators:previewEvaluator")
  let body = {evaluator: $evaluator, sampleData: $sampleData, maxSamples: $maxSamples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Evaluator
#
# POST /v1/accounts/{account_id}/evaluatorsV2
# operationId: Gateway_CreateEvaluatorV2
# --evaluator shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
export def "accounts-evaluators-v2 CreateEvaluatorV2" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluator: record # shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"ACTIVE"|"BUILDING"|"BUILD_FAILED", criteria?: list, requirements?: string, entryPoint?: string, status?: record, commitHash?: string, source?: record, defaultDataset?: string}
  --evaluatorId: string
]: any -> record<name: string, displayName: string, description: string, createTime: string, createdBy: string, updateTime: string, state: string, criteria: table<type: string, name: string, description: string, codeSnippets: record>, requirements: string, entryPoint: string, status: record<code: string, message: string>, commitHash: string, source: record<type: string, githubRepositoryName: string>, defaultDataset: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/evaluatorsV2")
  let body = {evaluator: $evaluator, evaluatorId: $evaluatorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the generic deployment types under an account
#
# GET /v1/accounts/{account_id}/genericDeploymentTypes
# operationId: Gateway_ListGenericDeploymentTypes
export def "accounts-generic-deployment-types ListGenericDeploymentTypes" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of generic deployment types to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListGenericDeploymentTypeRequest call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListGenericDeploymentTypeRequest must match the call that provided the page token.
  --filter: string # Only generic deployments satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<genericDeploymentTypes: table<name: string, createTime: string, updateTime: string, imageTag: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Generic Deployment Type
#
# POST /v1/accounts/{account_id}/genericDeploymentTypes
# operationId: Gateway_CreateGenericDeploymentType
export def "accounts-generic-deployment-types CreateGenericDeploymentType" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --genericDeploymentTypeId: string # The id of the generic deployment type
  --imageTag: string
]: any -> record<name: string, createTime: string, snapshot: record<name: string, createTime: string, updateTime: string, imageTag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "genericDeploymentTypeId" $genericDeploymentTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes" $qp)
  let body = {imageTag: $imageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all generic deployment type version
#
# GET /v1/accounts/{account_id}/genericDeploymentTypes/{generic_deployment_type_id}
# operationId: Gateway_ListGenericDeploymentTypeVersions
export def "accounts-generic-deployment-types ListGenericDeploymentTypeVersions" [
  account_id: string
  generic_deployment_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of generic deployment type versions to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListGenericDeploymentTypeVersionRequest call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListGenericDeploymentTypeVersionRequest must match the call that provided the page token.
  --filter: string # Only generic deployment type versions satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<genericDeploymentTypeVersions: table<name: string, createTime: string, snapshot: record>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes/($generic_deployment_type_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Generic Deployment Type
#
# PATCH /v1/accounts/{account_id}/genericDeploymentTypes/{generic_deployment_type_id}
# operationId: Gateway_UpdateGenericDeploymentType
export def "accounts-generic-deployment-types UpdateGenericDeploymentType" [
  account_id: string
  generic_deployment_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --imageTag: string
]: any -> record<name: string, createTime: string, snapshot: record<name: string, createTime: string, updateTime: string, imageTag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes/($generic_deployment_type_id)")
  let body = {imageTag: $imageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Generic Deployment Type
#
# DELETE /v1/accounts/{account_id}/genericDeploymentTypes/{generic_deployment_type_id}
# operationId: Gateway_DeleteGenericDeploymentType
export def "accounts-generic-deployment-types DeleteGenericDeploymentType" [
  account_id: string
  generic_deployment_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: oneof<nothing, bool> # If true, this will perform a hard deletion.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "hard" $hard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes/($generic_deployment_type_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get generic deployment type version
#
# GET /v1/accounts/{account_id}/genericDeploymentTypes/{generic_deployment_type_id}/versions/{version_id}
# operationId: Gateway_GetGenericDeploymentTypeVersion
export def "accounts-generic-deployment-types-versions GetGenericDeploymentTypeVersion" [
  account_id: string
  generic_deployment_type_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, createTime: string, snapshot: record<name: string, createTime: string, updateTime: string, imageTag: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes/($generic_deployment_type_id)/versions/($version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the generic deployment type version
#
# DELETE /v1/accounts/{account_id}/genericDeploymentTypes/{generic_deployment_type_id}/versions/{version_id}
# operationId: Gateway_DeleteGenericDeploymentTypeVersion
export def "accounts-generic-deployment-types-versions DeleteGenericDeploymentTypeVersion" [
  account_id: string
  generic_deployment_type_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: oneof<nothing, bool> # If true, this will perform a hard deletion.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "hard" $hard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeploymentTypes/($generic_deployment_type_id)/versions/($version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the generic deployments under an account
#
# GET /v1/accounts/{account_id}/genericDeployments
# operationId: Gateway_ListGenericDeployments
export def "accounts-generic-deployments ListGenericDeployments" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of generic deployments to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListGenericDeploymentRequest call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListGenericDeploymentRequest must match the call that provided the page token.
  --filter: string # Only generic deployments satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<genericDeployments: table<name: string, releaseValues: record, placement: record, createTime: string, updateTime: string, genericDeploymentType: string, state: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Generic Deployment
#
# POST /v1/accounts/{account_id}/genericDeployments
# operationId: Gateway_CreateGenericDeployment
# --placement shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
export def "accounts-generic-deployments CreateGenericDeployment" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --genericDeploymentId: string # The ID of the deployment. If not specified, a random ID will be generated.
  --validateOnly: oneof<nothing, bool> # If true, this will not create the deployment, but will return the deployment that would be created.
  releaseValues: record
  placement: record # The desired geographic region where the deployment must be placed. Exactly one field will be specified. — shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
  genericDeploymentType: string
  --state: string@state-completer-4 # - CREATING: The deployment is still being created.  - READY: The deployment is ready to be used.  - FAILED: The deployment failed to be created.  - UPDATING: There are in-progress updates happening with the deployment.  - DELETING: The deployment is being deleted  - DELETED: The deployment has been deleted. (default: STATE_UNSPECIFIED)
]: any -> record<name: string, releaseValues: record, placement: record<region: string, multiRegion: string, regions: list<string>>, createTime: string, updateTime: string, genericDeploymentType: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "genericDeploymentId" $genericDeploymentId "scalar") (serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeployments" $qp)
  let body = {releaseValues: $releaseValues, placement: $placement, genericDeploymentType: $genericDeploymentType, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Generic Deployment
#
# GET /v1/accounts/{account_id}/genericDeployments/{generic_deployment_id}
# operationId: Gateway_GetGenericDeployment
export def "accounts-generic-deployments GetGenericDeployment" [
  account_id: string
  generic_deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, releaseValues: record, placement: record<region: string, multiRegion: string, regions: list<string>>, createTime: string, updateTime: string, genericDeploymentType: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeployments/($generic_deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Generic Deployment
#
# PATCH /v1/accounts/{account_id}/genericDeployments/{generic_deployment_id}
# operationId: Gateway_UpdateGenericDeployment
# --placement shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
export def "accounts-generic-deployments UpdateGenericDeployment" [
  account_id: string
  generic_deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  releaseValues: record
  placement: record # The desired geographic region where the deployment must be placed. Exactly one field will be specified. — shape: {region?: "REGION_UNSPECIFIED"|"US_IOWA_1"|"US_VIRGINIA_1"|"US_VIRGINIA_2"|"US_ILLINOIS_1"|"AP_TOKYO_1"|"US_ARIZONA_1"|"US_TEXAS_1"|"US_ILLINOIS_2"|"EU_FRANKFURT_1"|"US_TEXAS_2"|"EU_ICELAND_1"|"EU_ICELAND_2"|"US_WASHINGTON_1"|"US_WASHINGTON_2"|"US_WASHINGTON_3"|"AP_TOKYO_2"|"US_CALIFORNIA_1"|"US_UTAH_1"|"US_GEORGIA_1"|"US_GEORGIA_2"|"US_WASHINGTON_4"|"US_GEORGIA_3"|"NA_BRITISHCOLUMBIA_1"|"US_GEORGIA_4"|"US_OHIO_1"|"US_NEWYORK_1"|"EU_NETHERLANDS_1"|"US_WASHINGTON_5"|"US_MINNESOTA_1"|"US_CALIFORNIA_2"|"AP_MALAYSIA_1"|"US_OHIO_2", multiRegion?: "MULTI_REGION_UNSPECIFIED"|"GLOBAL"|"US"|"EUROPE"|"APAC", regions?: list}
  genericDeploymentType: string
  --state: string@state-completer-4 # - CREATING: The deployment is still being created.  - READY: The deployment is ready to be used.  - FAILED: The deployment failed to be created.  - UPDATING: There are in-progress updates happening with the deployment.  - DELETING: The deployment is being deleted  - DELETED: The deployment has been deleted. (default: STATE_UNSPECIFIED)
]: any -> record<name: string, releaseValues: record, placement: record<region: string, multiRegion: string, regions: list<string>>, createTime: string, updateTime: string, genericDeploymentType: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeployments/($generic_deployment_id)")
  let body = {releaseValues: $releaseValues, placement: $placement, genericDeploymentType: $genericDeploymentType, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Generic Deployment
#
# DELETE /v1/accounts/{account_id}/genericDeployments/{generic_deployment_id}
# operationId: Gateway_DeleteGenericDeployment
export def "accounts-generic-deployments DeleteGenericDeployment" [
  account_id: string
  generic_deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: oneof<nothing, bool> # If true, this will perform a hard deletion.
  --ignoreChecks: oneof<nothing, bool> # If true, this will ignore checks and force the deletion of a deployment that is currently deployed and is in use.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "hard" $hard "scalar") (serialize-qp "ignoreChecks" $ignoreChecks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/genericDeployments/($generic_deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Identity Providers
#
# GET /v1/accounts/{account_id}/identityProviders
# operationId: Gateway_ListIdentityProviders
export def "accounts-identity-providers ListIdentityProviders" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Page size (format: int32)
  --pageToken: string # Page token
  --filter: string # Filter expression
  --orderBy: string # Order by
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<identityProviders: table<name: string, displayName: string, createTime: string, updateTime: string, samlConfig: record, oidcConfig: record, tenantDomains: list, state: string, status: record, domainUrl: string, issuerUrl: string, clientId: string, enableJitUserProvisioning: bool, jitDefaultRole: string, enforceSso: bool, enableIdpInitiatedSso: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/identityProviders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Identity Provider
#
# POST /v1/accounts/{account_id}/identityProviders
# operationId: Gateway_CreateIdentityProvider
# --samlConfig shape: {metadataUrl?: string, metadataXml?: string}
# --oidcConfig shape: {issuerUrl: string, clientId: string, clientSecret: string}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-identity-providers CreateIdentityProvider" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --samlConfig: record # SAML Configuration Exactly one of metadata_url or metadata_xml must be provided. — shape: {metadataUrl?: string, metadataXml?: string}
  --oidcConfig: record # shape: {issuerUrl: string, clientId: string, clientSecret: string}
  --tenantDomains: list
  --state: string@state-completer-7 # default: STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --enableJitUserProvisioning: oneof<nothing, bool> # Enable Just-In-Time (JIT) user provisioning. When enabled, users are automatically created in the account on first SSO login if they don't already exist. When disabled, users must be pre-provisioned before they can authenticate via SSO.
  --jitDefaultRole: string # Default role assigned to JIT-provisioned users. Valid values: "admin", "user", "contributor", "inference-user". Only applies when enable_jit_user_provisioning is true and RBAC V2 is enabled. If empty or unset, defaults to "inference-user" (least privilege). If RBAC V2 is not enabled for the account, JIT users always get "user" role.
  --enforceSso: oneof<nothing, bool>
  --enableIdpInitiatedSso: oneof<nothing, bool> # Enable IdP-initiated SAML (Security Assertion Markup Language) single sign-on. When enabled, users can start the login flow from their identity provider's portal (e.g., Okta app launcher) instead of from the Fireworks login page. Only supported for SAML identity providers.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, samlConfig: record<metadataUrl: string, metadataXml: string>, oidcConfig: record<issuerUrl: string, clientId: string, clientSecret: string>, tenantDomains: list<string>, state: string, status: record<code: string, message: string>, domainUrl: string, issuerUrl: string, clientId: string, enableJitUserProvisioning: bool, jitDefaultRole: string, enforceSso: bool, enableIdpInitiatedSso: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/identityProviders")
  let body = {displayName: $displayName, samlConfig: $samlConfig, oidcConfig: $oidcConfig, tenantDomains: $tenantDomains, state: $state, status: $status, enableJitUserProvisioning: $enableJitUserProvisioning, jitDefaultRole: $jitDefaultRole, enforceSso: $enforceSso, enableIdpInitiatedSso: $enableIdpInitiatedSso} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Identity Provider
#
# GET /v1/accounts/{account_id}/identityProviders/{identity_provider_id}
# operationId: Gateway_GetIdentityProvider
export def "accounts-identity-providers GetIdentityProvider" [
  account_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, updateTime: string, samlConfig: record<metadataUrl: string, metadataXml: string>, oidcConfig: record<issuerUrl: string, clientId: string, clientSecret: string>, tenantDomains: list<string>, state: string, status: record<code: string, message: string>, domainUrl: string, issuerUrl: string, clientId: string, enableJitUserProvisioning: bool, jitDefaultRole: string, enforceSso: bool, enableIdpInitiatedSso: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/identityProviders/($identity_provider_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Identity Provider
#
# PATCH /v1/accounts/{account_id}/identityProviders/{identity_provider_id}
# operationId: Gateway_UpdateIdentityProvider
# --samlConfig shape: {metadataUrl?: string, metadataXml?: string}
# --oidcConfig shape: {issuerUrl: string, clientId: string, clientSecret: string}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-identity-providers UpdateIdentityProvider" [
  account_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --samlConfig: record # SAML Configuration Exactly one of metadata_url or metadata_xml must be provided. — shape: {metadataUrl?: string, metadataXml?: string}
  --oidcConfig: record # shape: {issuerUrl: string, clientId: string, clientSecret: string}
  --tenantDomains: list
  --state: string@state-completer-7 # default: STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --enableJitUserProvisioning: oneof<nothing, bool> # Enable Just-In-Time (JIT) user provisioning. When enabled, users are automatically created in the account on first SSO login if they don't already exist. When disabled, users must be pre-provisioned before they can authenticate via SSO.
  --jitDefaultRole: string # Default role assigned to JIT-provisioned users. Valid values: "admin", "user", "contributor", "inference-user". Only applies when enable_jit_user_provisioning is true and RBAC V2 is enabled. If empty or unset, defaults to "inference-user" (least privilege). If RBAC V2 is not enabled for the account, JIT users always get "user" role.
  --enforceSso: oneof<nothing, bool>
  --enableIdpInitiatedSso: oneof<nothing, bool> # Enable IdP-initiated SAML (Security Assertion Markup Language) single sign-on. When enabled, users can start the login flow from their identity provider's portal (e.g., Okta app launcher) instead of from the Fireworks login page. Only supported for SAML identity providers.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, samlConfig: record<metadataUrl: string, metadataXml: string>, oidcConfig: record<issuerUrl: string, clientId: string, clientSecret: string>, tenantDomains: list<string>, state: string, status: record<code: string, message: string>, domainUrl: string, issuerUrl: string, clientId: string, enableJitUserProvisioning: bool, jitDefaultRole: string, enforceSso: bool, enableIdpInitiatedSso: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/identityProviders/($identity_provider_id)")
  let body = {displayName: $displayName, samlConfig: $samlConfig, oidcConfig: $oidcConfig, tenantDomains: $tenantDomains, state: $state, status: $status, enableJitUserProvisioning: $enableJitUserProvisioning, jitDefaultRole: $jitDefaultRole, enforceSso: $enforceSso, enableIdpInitiatedSso: $enableIdpInitiatedSso} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Identity Provider
#
# DELETE /v1/accounts/{account_id}/identityProviders/{identity_provider_id}
# operationId: Gateway_DeleteIdentityProvider
export def "accounts-identity-providers DeleteIdentityProvider" [
  account_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/identityProviders/($identity_provider_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Models
#
# GET /v1/accounts/{account_id}/models
# operationId: Gateway_ListModels
export def "accounts-models ListModels" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of models to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListModels call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListModels must match the call that provided the page token.
  --filter: string # Only model satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<models: table<name: string, displayName: string, description: string, createTime: string, state: string, status: record, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record, peftDetails: record, teftDetails: record, public: bool, conversationConfig: record, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: list, cluster: string, deprecationDate: record, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Model
#
# POST /v1/accounts/{account_id}/models
# operationId: Gateway_CreateModel
# --model shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, kind?: "KIND_UNSPECIFIED"|"HF_BASE_MODEL"|"HF_PEFT_ADDON"|"HF_TEFT_ADDON"|"FLUMINA_BASE_MODEL"|"FLUMINA_ADDON"|"DRAFT_ADDON"|"FIRE_AGENT"|"LIVE_MERGE"|"CUSTOM_MODEL"|"EMBEDDING_MODEL"|"SNAPSHOT_MODEL", githubUrl?: string, huggingFaceUrl?: string, baseModelDetails?: record, peftDetails?: record, teftDetails?: record, public?: bool, conversationConfig?: record, contextLength?: int, supportsImageInput?: bool, supportsTools?: bool, defaultDraftModel?: string, defaultDraftTokenCount?: int, deprecationDate?: record, supportsLora?: bool, useHfApplyChatTemplate?: bool, trainingContextLength?: int, snapshotType?: "FULL_SNAPSHOT"|"INCREMENTAL_SNAPSHOT"}
export def "accounts-models CreateModel" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: record # shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, kind?: "KIND_UNSPECIFIED"|"HF_BASE_MODEL"|"HF_PEFT_ADDON"|"HF_TEFT_ADDON"|"FLUMINA_BASE_MODEL"|"FLUMINA_ADDON"|"DRAFT_ADDON"|"FIRE_AGENT"|"LIVE_MERGE"|"CUSTOM_MODEL"|"EMBEDDING_MODEL"|"SNAPSHOT_MODEL", githubUrl?: string, huggingFaceUrl?: string, baseModelDetails?: record, peftDetails?: record, teftDetails?: record, public?: bool, conversationConfig?: record, contextLength?: int, supportsImageInput?: bool, supportsTools?: bool, defaultDraftModel?: string, defaultDraftTokenCount?: int, deprecationDate?: record, supportsLora?: bool, useHfApplyChatTemplate?: bool, trainingContextLength?: int, snapshotType?: "FULL_SNAPSHOT"|"INCREMENTAL_SNAPSHOT"}
  modelId: string # ID of the model.
  --cluster: string # The resource name of the BYOC cluster to which this model belongs. e.g. accounts/my-account/clusters/my-cluster. Empty if it belongs to a Fireworks cluster.
]: any -> record<name: string, displayName: string, description: string, createTime: string, state: string, status: record<code: string, message: string>, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record<worldSize: int, checkpointFormat: string, huggingfaceFiles: list<string>, parameterCount: string, moe: bool, tunable: bool, modelType: string, supportsFireattention: bool, defaultPrecision: string, supportsMtp: bool>, peftDetails: record<baseModel: string, r: int, targetModules: list<string>, baseModelType: string, mergeAddonModelName: string>, teftDetails: record, public: bool, conversationConfig: record<style: string, system: string, template: string>, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: table<name: string, deployment: string, state: string, default: bool, public: bool>, cluster: string, deprecationDate: record<year: int, month: int, day: int>, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models")
  let body = {model: $model, modelId: $modelId, cluster: $cluster} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Model
#
# GET /v1/accounts/{account_id}/models/{model_id}
# operationId: Gateway_GetModel
export def "accounts-models GetModel" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, state: string, status: record<code: string, message: string>, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record<worldSize: int, checkpointFormat: string, huggingfaceFiles: list<string>, parameterCount: string, moe: bool, tunable: bool, modelType: string, supportsFireattention: bool, defaultPrecision: string, supportsMtp: bool>, peftDetails: record<baseModel: string, r: int, targetModules: list<string>, baseModelType: string, mergeAddonModelName: string>, teftDetails: record, public: bool, conversationConfig: record<style: string, system: string, template: string>, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: table<name: string, deployment: string, state: string, default: bool, public: bool>, cluster: string, deprecationDate: record<year: int, month: int, day: int>, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Model
#
# PATCH /v1/accounts/{account_id}/models/{model_id}
# operationId: Gateway_UpdateModel
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --baseModelDetails shape: {worldSize?: int, checkpointFormat?: "CHECKPOINT_FORMAT_UNSPECIFIED"|"NATIVE"|"HUGGINGFACE"|"UNINITIALIZED", huggingfaceFiles?: list, parameterCount?: string, moe?: bool, tunable?: bool, modelType?: string, supportsFireattention?: bool, defaultPrecision?: "PRECISION_UNSPECIFIED"|"FP16"|"FP8"|"FP8_MM"|"FP8_AR"|"FP8_MM_KV_ATTN"|"FP8_KV"|"FP8_MM_V2"|"FP8_V2"|"FP8_MM_KV_ATTN_V2"|"NF4"|"FP4"|"BF16"|"FP4_BLOCKSCALED_MM"|"FP4_MX_MOE", supportsMtp?: bool}
# --peftDetails shape: {baseModel: string, r: int, targetModules: list, mergeAddonModelName?: string}
# --conversationConfig shape: {style: string, system?: string, template?: string}
# --deployedModelRefs item shape: {state?: "STATE_UNSPECIFIED"|"UNDEPLOYING"|"DEPLOYING"|"DEPLOYED"|"UPDATING"}
# --deprecationDate shape: {year?: int, month?: int, day?: int}
export def "accounts-models UpdateModel" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human-readable display name of the model. e.g. "My Model" Must be fewer than 64 characters long.
  --description: string # The description of the model. Must be fewer than 1000 characters long.
  --state: string@state-completer-2 # - UPLOADING: The model is still being uploaded (upload is asynchronous).  - READY: The model is ready to be used. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --kind: string@kind-completer # - HF_BASE_MODEL: An LLM base model.  - HF_PEFT_ADDON: A parameter-efficent fine-tuned addon.  - HF_TEFT_ADDON: A token-eficient fine-tuned addon.  - FLUMINA_BASE_MODEL: A Flumina base model.  - FLUMINA_ADDON: A Flumina addon.  - DRAFT_ADDON: A draft model used for speculative decoding in a deployment.  - FIRE_AGENT: A FireAgent model.  - LIVE_MERGE: A live-merge model.  - CUSTOM_MODEL: A customized model  - EMBEDDING_MODEL: An Embedding model.  - SNAPSHOT_MODEL: A snapshot model. (default: KIND_UNSPECIFIED)
  --githubUrl: string # The URL to GitHub repository of the model.
  --huggingFaceUrl: string # The URL to the Hugging Face model.
  --baseModelDetails: record # shape: {worldSize?: int, checkpointFormat?: "CHECKPOINT_FORMAT_UNSPECIFIED"|"NATIVE"|"HUGGINGFACE"|"UNINITIALIZED", huggingfaceFiles?: list, parameterCount?: string, moe?: bool, tunable?: bool, modelType?: string, supportsFireattention?: bool, defaultPrecision?: "PRECISION_UNSPECIFIED"|"FP16"|"FP8"|"FP8_MM"|"FP8_AR"|"FP8_MM_KV_ATTN"|"FP8_KV"|"FP8_MM_V2"|"FP8_V2"|"FP8_MM_KV_ATTN_V2"|"NF4"|"FP4"|"BF16"|"FP4_BLOCKSCALED_MM"|"FP4_MX_MOE", supportsMtp?: bool}
  --peftDetails: record # shape: {baseModel: string, r: int, targetModules: list, mergeAddonModelName?: string}
  --teftDetails: record
  --public: oneof<nothing, bool> # If true, the model will be publicly readable.
  --conversationConfig: record # shape: {style: string, system?: string, template?: string}
  --contextLength: int # The maximum context length supported by the model. (format: int32)
  --supportsImageInput: oneof<nothing, bool> # If set, images can be provided as input to the model.
  --supportsTools: oneof<nothing, bool> # If set, tools (i.e. functions) can be provided as input to the model, and the model may respond with one or more tool calls.
  --defaultDraftModel: string # The default draft model to use when creating a deployment. If empty, speculative decoding is disabled by default.
  --defaultDraftTokenCount: int # The default draft token count to use when creating a deployment. Must be specified if default_draft_model is specified. (format: int32)
  --deprecationDate: record # * A full date, with non-zero year, month, and day values * A month and day value, with a zero year, such as an anniversary * A year on its own, with zero month and day values * A year and month value, with a zero day, such as a credit card expiration date  Related types are [google.type.TimeOfDay][google.type.TimeOfDay] and `google.protobuf.Timestamp`. — shape: {year?: int, month?: int, day?: int}
  --supportsLora: oneof<nothing, bool> # Whether this model supports LoRA.
  --useHfApplyChatTemplate: oneof<nothing, bool> # If true, the model will use the Hugging Face apply_chat_template API to apply the chat template.
  --trainingContextLength: int # The maximum context length supported by the model. (format: int32)
  --snapshotType: string@snapshotType-completer # default: FULL_SNAPSHOT
]: any -> record<name: string, displayName: string, description: string, createTime: string, state: string, status: record<code: string, message: string>, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record<worldSize: int, checkpointFormat: string, huggingfaceFiles: list<string>, parameterCount: string, moe: bool, tunable: bool, modelType: string, supportsFireattention: bool, defaultPrecision: string, supportsMtp: bool>, peftDetails: record<baseModel: string, r: int, targetModules: list<string>, baseModelType: string, mergeAddonModelName: string>, teftDetails: record, public: bool, conversationConfig: record<style: string, system: string, template: string>, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: table<name: string, deployment: string, state: string, default: bool, public: bool>, cluster: string, deprecationDate: record<year: int, month: int, day: int>, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)")
  let body = {displayName: $displayName, description: $description, state: $state, status: $status, kind: $kind, githubUrl: $githubUrl, huggingFaceUrl: $huggingFaceUrl, baseModelDetails: $baseModelDetails, peftDetails: $peftDetails, teftDetails: $teftDetails, public: $public, conversationConfig: $conversationConfig, contextLength: $contextLength, supportsImageInput: $supportsImageInput, supportsTools: $supportsTools, defaultDraftModel: $defaultDraftModel, defaultDraftTokenCount: $defaultDraftTokenCount, deprecationDate: $deprecationDate, supportsLora: $supportsLora, useHfApplyChatTemplate: $useHfApplyChatTemplate, trainingContextLength: $trainingContextLength, snapshotType: $snapshotType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Model
#
# DELETE /v1/accounts/{account_id}/models/{model_id}
# operationId: Gateway_DeleteModel
export def "accounts-models DeleteModel" [
  account_id: string
  model_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for model versions. Create Model Version
#
# POST /v1/accounts/{account_id}/models/{model_id}/versions
# operationId: Gateway_CreateModelVersion
# --snapshot shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, kind?: "KIND_UNSPECIFIED"|"HF_BASE_MODEL"|"HF_PEFT_ADDON"|"HF_TEFT_ADDON"|"FLUMINA_BASE_MODEL"|"FLUMINA_ADDON"|"DRAFT_ADDON"|"FIRE_AGENT"|"LIVE_MERGE"|"CUSTOM_MODEL"|"EMBEDDING_MODEL"|"SNAPSHOT_MODEL", githubUrl?: string, huggingFaceUrl?: string, baseModelDetails?: record, peftDetails?: record, teftDetails?: record, public?: bool, conversationConfig?: record, contextLength?: int, supportsImageInput?: bool, supportsTools?: bool, defaultDraftModel?: string, defaultDraftTokenCount?: int, deprecationDate?: record, supportsLora?: bool, useHfApplyChatTemplate?: bool, trainingContextLength?: int, snapshotType?: "FULL_SNAPSHOT"|"INCREMENTAL_SNAPSHOT"}
export def "accounts-models-versions CreateModelVersion" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --versionId: string
  --snapshot: record # shape: {displayName?: string, description?: string, state?: "STATE_UNSPECIFIED"|"UPLOADING"|"READY", status?: record, kind?: "KIND_UNSPECIFIED"|"HF_BASE_MODEL"|"HF_PEFT_ADDON"|"HF_TEFT_ADDON"|"FLUMINA_BASE_MODEL"|"FLUMINA_ADDON"|"DRAFT_ADDON"|"FIRE_AGENT"|"LIVE_MERGE"|"CUSTOM_MODEL"|"EMBEDDING_MODEL"|"SNAPSHOT_MODEL", githubUrl?: string, huggingFaceUrl?: string, baseModelDetails?: record, peftDetails?: record, teftDetails?: record, public?: bool, conversationConfig?: record, contextLength?: int, supportsImageInput?: bool, supportsTools?: bool, defaultDraftModel?: string, defaultDraftTokenCount?: int, deprecationDate?: record, supportsLora?: bool, useHfApplyChatTemplate?: bool, trainingContextLength?: int, snapshotType?: "FULL_SNAPSHOT"|"INCREMENTAL_SNAPSHOT"}
]: any -> record<name: string, createTime: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, state: string, status: record<code: string, message: string>, kind: string, githubUrl: string, huggingFaceUrl: string, baseModelDetails: record<worldSize: int, checkpointFormat: string, huggingfaceFiles: list, parameterCount: string, moe: bool, tunable: bool, modelType: string, supportsFireattention: bool, defaultPrecision: string, supportsMtp: bool>, peftDetails: record<baseModel: string, r: int, targetModules: list, baseModelType: string, mergeAddonModelName: string>, teftDetails: record, public: bool, conversationConfig: record<style: string, system: string, template: string>, contextLength: int, supportsImageInput: bool, supportsTools: bool, importedFrom: string, fineTuningJob: string, defaultDraftModel: string, defaultDraftTokenCount: int, deployedModelRefs: list<record>, cluster: string, deprecationDate: record<year: int, month: int, day: int>, calibrated: bool, tunable: bool, supportsLora: bool, useHfApplyChatTemplate: bool, updateTime: string, defaultSamplingParams: record, rlTunable: bool, trainingContextLength: int, snapshotType: string, supportsServerless: bool, supervisedLoraTunable: bool, supervisedFullParameterTunable: bool, rlLoraTunable: bool, rlFullParameterTunable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)/versions" $qp)
  let body = {snapshot: $snapshot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deploy Model Version
#
# POST /v1/accounts/{account_id}/models/{model_id}/versions/{version_id}:deploy
# operationId: Gateway_DeployModelVersion
export def "accounts-models-versions DeployModelVersion" [
  account_id: string
  model_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  deployment: string
  rolloutStrategy: string@rolloutStrategy-completer # The rollout strategy to use when deploying the model version.   - ROLLOUT_STRATEGY_STANDARD: Standard rollout strategy updates the deployment using a normal k8s rolling restart  - ROLLOUT_STRATEGY_HOT_RELOAD: Hot reload rollout strategy updates the deployment by hot reloading the model version on the existing replicas of the deployment (default: ROLLOUT_STRATEGY_UNSPECIFIED)
]: any -> record<name: string, metadata: record<_type: string>, done: bool, error: record<code: int, message: string, details: list<record>>, response: record<_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)/versions/($version_id):deploy")
  let body = {deployment: $deployment, rolloutStrategy: $rolloutStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the number of model versions.
#
# GET /v1/accounts/{account_id}/models/{model_id}/versions:count
# operationId: Gateway_GetModelVersionCount
export def "accounts-models-versions-count GetModelVersionCount" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id)/versions:count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Model Download Endpoint
#
# GET /v1/accounts/{account_id}/models/{model_id}:getDownloadEndpoint
# operationId: Gateway_GetModelDownloadEndpoint
export def "accounts-models GetModelDownloadEndpoint" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<filenameToSignedUrls: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id):getDownloadEndpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Model Upload Endpoint
#
# POST /v1/accounts/{account_id}/models/{model_id}:getUploadEndpoint
# operationId: Gateway_GetModelUploadEndpoint
export def "accounts-models GetModelUploadEndpoint" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filenameToSize: record # A mapping from the file name to its size in bytes.
  --enableResumableUpload: oneof<nothing, bool> # If true, enable resumable upload instead of PUT.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: any -> record<filenameToSignedUrls: record, filenameToUnsignedUris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id):getUploadEndpoint")
  let body = {filenameToSize: $filenameToSize, enableResumableUpload: $enableResumableUpload, readMask: $readMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer model from S3 to GCP storage
#
# POST /v1/accounts/{account_id}/models/{model_id}:import
# operationId: Gateway_ImportModel
# --awsS3Source shape: {s3Bucket: string, s3Path?: string, roleArn?: string, accessKeyId?: string, accessSecret?: string}
# --azureBlobSource shape: {storageAccount: string, container: string, path?: string, sasTokenSecret?: string, clientId?: string, tenantId?: string}
export def "accounts-models ImportModel" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --awsS3Source: record # shape: {s3Bucket: string, s3Path?: string, roleArn?: string, accessKeyId?: string, accessSecret?: string}
  --azureBlobSource: record # shape: {storageAccount: string, container: string, path?: string, sasTokenSecret?: string, clientId?: string, tenantId?: string}
]: any -> record<name: string, metadata: record<_type: string>, done: bool, error: record<code: int, message: string, details: list<record>>, response: record<_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id):import")
  let body = {awsS3Source: $awsS3Source, azureBlobSource: $azureBlobSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Prepare Model for different precisions
#
# POST /v1/accounts/{account_id}/models/{model_id}:prepare
# operationId: Gateway_PrepareModel
export def "accounts-models PrepareModel" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --precision: string@precision-completer # default: PRECISION_UNSPECIFIED
  --readMask: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id):prepare")
  let body = {precision: $precision, readMask: $readMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate Model Upload
#
# GET /v1/accounts/{account_id}/models/{model_id}:validateUpload
# operationId: Gateway_ValidateModelUpload
export def "accounts-models ValidateModelUpload" [
  account_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipHfConfigValidation: oneof<nothing, bool> # If true, skip the Hugging Face config validation.
  --trustRemoteCode: oneof<nothing, bool> # If true, trusts remote code when validating the Hugging Face config.
  --configOnly: oneof<nothing, bool> # If true, skip tokenizer and parameter name validation.
]: nothing -> record<warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "skipHfConfigValidation" $skipHfConfigValidation "scalar") (serialize-qp "trustRemoteCode" $trustRemoteCode "scalar") (serialize-qp "configOnly" $configOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/models/($model_id):validateUpload" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the singleton PolicySettings for the given account.
#
# GET /v1/accounts/{account_id}/policySettings
# operationId: Gateway_GetPolicySettings
export def "accounts-policy-settings GetPolicySettings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, rules: table<model: string, allowServerless: bool, allowFineTuning: bool, allowDeployments: bool, effect: string>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/policySettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the per-account PolicySettings singleton.
#
# PATCH /v1/accounts/{account_id}/policySettings
# operationId: Gateway_UpdatePolicySettings
# --rules item shape: {model: string, allowServerless?: bool, allowFineTuning?: bool, allowDeployments?: bool, effect?: "UNSPECIFIED"|"DENY"}
export def "accounts-policy-settings UpdatePolicySettings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # Full model allowlist (governance doc §1); empty means default-deny for all models. — item shape: {model: string, allowServerless?: bool, allowFineTuning?: bool, allowDeployments?: bool, effect?: "UNSPECIFIED"|"DENY"}
]: any -> record<name: string, rules: table<model: string, allowServerless: bool, allowFineTuning: bool, allowDeployments: bool, effect: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/policySettings")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Pricing Plans
#
# GET /v1/accounts/{account_id}/pricingPlans
# operationId: Gateway_ListPricingPlans
export def "accounts-pricing-plans ListPricingPlans" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Maximum number of pricing plans to return (format: int32)
  --pageToken: string # Page token from a previous ListPricingPlans call
  --filter: string # Filter expression (e.g., "state=READY")
  --orderBy: string # Order by expression (e.g., "create_time desc")
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<pricingPlans: table<name: string, billingType: string, tokenConfig: list, acceleratorHourConfig: list, startTime: string, endTime: string, createTime: string, updateTime: string, state: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/pricingPlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for pricing plans. Get Pricing Plan
#
# GET /v1/accounts/{account_id}/pricingPlans/{pricing_plan_id}
# operationId: Gateway_GetPricingPlan
export def "accounts-pricing-plans GetPricingPlan" [
  account_id: string
  pricing_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, billingType: string, tokenConfig: table<baseModelName: string, inputTokenPricePerMillion: record, outputTokenPricePerMillion: record, uncachedInputTokenPricePerMillion: record, cachedInputTokenPricePerMillion: record>, acceleratorHourConfig: table<acceleratorType: string, acceleratorHourPrice: record>, startTime: string, endTime: string, createTime: string, updateTime: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/pricingPlans/($pricing_plan_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Quotas
#
# GET /v1/accounts/{account_id}/quotas
# operationId: Gateway_ListQuotas
export def "accounts-quotas ListQuotas" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of quotas to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListQuotas call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListQuotas must match the call that provided the page token.
  --filter: string # Only quota satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<quotas: table<name: string, value: string, maxValue: string, usage: float, updateTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/quotas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Quota
#
# GET /v1/accounts/{account_id}/quotas/{quota_id}
# operationId: Gateway_GetQuota
export def "accounts-quotas GetQuota" [
  account_id: string
  quota_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, value: string, maxValue: string, usage: float, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/quotas/($quota_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Quota
#
# PATCH /v1/accounts/{account_id}/quotas/{quota_id}
# operationId: Gateway_UpdateQuota
export def "accounts-quotas UpdateQuota" [
  account_id: string
  quota_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowMissing: oneof<nothing, bool> # If true, and the quota does not exist, it will be created.
  --value: string # The value of the quota being enforced. This may be lower than the max_value if the user manually lowers it. (format: int64)
  --maxValue: string # The maximum approved value. (format: int64)
]: any -> record<name: string, value: string, maxValue: string, usage: float, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "allowMissing" $allowMissing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/quotas/($quota_id)" $qp)
  let body = {value: $value, maxValue: $maxValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Reinforcement Fine-tuning Jobs
#
# GET /v1/accounts/{account_id}/reinforcementFineTuningJobs
# operationId: Gateway_ListReinforcementFineTuningJobs
export def "accounts-reinforcement-fine-tuning-jobs ListReinforcementFineTuningJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of fine-tuning jobs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListReinforcementLearningFineTuningJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListReinforcementLearningFineTuningJobs must match the call that provided the page token.
  --filter: string # Filter criteria for the returned jobs. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<reinforcementFineTuningJobs: table<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record, createdBy: string, trainingConfig: record, evaluator: string, wandbConfig: record, awsS3Config: record, azureBlobStorageConfig: record, outputStats: string, jobProgress: record, inferenceParameters: record, chunkSize: int, outputMetrics: string, maxInferenceReplicaCount: int, nodeCount: int, lossConfig: record, trainerLogsSignedUrl: string, acceleratorSeconds: record, maxConcurrentRollouts: int, maxConcurrentEvaluations: int, purpose: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Reinforcement Fine-tuning Job
#
# POST /v1/accounts/{account_id}/reinforcementFineTuningJobs
# operationId: Gateway_CreateReinforcementFineTuningJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --trainingConfig shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
# --inferenceParameters shape: {maxOutputTokens?: int, temperature?: float, topP?: float, responseCandidatesCount?: int, extraBody?: string, topK?: int}
# --lossConfig shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
export def "accounts-reinforcement-fine-tuning-jobs CreateReinforcementFineTuningJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reinforcementFineTuningJobId: string # ID of the reinforcement fine-tuning job, a random UUID will be generated if not specified.
  --displayName: string
  dataset: string # The name of the dataset used for training.
  --evaluationDataset: string # The name of a separate dataset to use for evaluation.
  --evalAutoCarveout: oneof<nothing, bool> # Whether to auto-carve the dataset for eval.
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --trainingConfig: record # shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
  evaluator: string # The evaluator resource name to use for RLOR fine-tuning job.
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --inferenceParameters: record # shape: {maxOutputTokens?: int, temperature?: float, topP?: float, responseCandidatesCount?: int, extraBody?: string, topK?: int}
  --chunkSize: int # Data chunking for rollout, default size 200, enabled when dataset > 300. Valid range is 1-10,000. (format: int32)
  --maxInferenceReplicaCount: int # format: int32
  --nodeCount: int # The number of nodes to use for the fine-tuning job. If not specified, the default is 1. (format: int32)
  --lossConfig: record # Loss method + hyperparameters for reinforcement-learning-style fine-tuning (e.g. RFT / RL trainers). For preference jobs (DPO API), the default loss method is GRPO when METHOD_UNSPECIFIED. — shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
  --maxConcurrentRollouts: int # Maximum number of concurrent rollouts during the RFT job. (format: int32)
  --maxConcurrentEvaluations: int # Maximum number of concurrent evaluations during the RFT job. (format: int32)
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, evaluator: string, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, outputStats: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, inferenceParameters: record<maxOutputTokens: int, temperature: float, topP: float, responseCandidatesCount: int, extraBody: string, topK: int>, chunkSize: int, outputMetrics: string, maxInferenceReplicaCount: int, nodeCount: int, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, trainerLogsSignedUrl: string, acceleratorSeconds: record, maxConcurrentRollouts: int, maxConcurrentEvaluations: int, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "reinforcementFineTuningJobId" $reinforcementFineTuningJobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs" $qp)
  let body = {displayName: $displayName, dataset: $dataset, evaluationDataset: $evaluationDataset, evalAutoCarveout: $evalAutoCarveout, state: $state, status: $status, trainingConfig: $trainingConfig, evaluator: $evaluator, wandbConfig: $wandbConfig, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, jobProgress: $jobProgress, inferenceParameters: $inferenceParameters, chunkSize: $chunkSize, maxInferenceReplicaCount: $maxInferenceReplicaCount, nodeCount: $nodeCount, lossConfig: $lossConfig, maxConcurrentRollouts: $maxConcurrentRollouts, maxConcurrentEvaluations: $maxConcurrentEvaluations, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Reinforcement Fine-tuning Job
#
# GET /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}
# operationId: Gateway_GetReinforcementFineTuningJob
export def "accounts-reinforcement-fine-tuning-jobs GetReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, evaluator: string, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, outputStats: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, inferenceParameters: record<maxOutputTokens: int, temperature: float, topP: float, responseCandidatesCount: int, extraBody: string, topK: int>, chunkSize: int, outputMetrics: string, maxInferenceReplicaCount: int, nodeCount: int, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, trainerLogsSignedUrl: string, acceleratorSeconds: record, maxConcurrentRollouts: int, maxConcurrentEvaluations: int, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Reinforcement Fine-tuning Job
#
# PATCH /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}
# operationId: Gateway_UpdateReinforcementFineTuningJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --trainingConfig shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
# --inferenceParameters shape: {maxOutputTokens?: int, temperature?: float, topP?: float, responseCandidatesCount?: int, extraBody?: string, topK?: int}
# --lossConfig shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
export def "accounts-reinforcement-fine-tuning-jobs UpdateReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  dataset: string # The name of the dataset used for training.
  --evaluationDataset: string # The name of a separate dataset to use for evaluation.
  --evalAutoCarveout: oneof<nothing, bool> # Whether to auto-carve the dataset for eval.
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --trainingConfig: record # shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
  evaluator: string # The evaluator resource name to use for RLOR fine-tuning job.
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --inferenceParameters: record # shape: {maxOutputTokens?: int, temperature?: float, topP?: float, responseCandidatesCount?: int, extraBody?: string, topK?: int}
  --chunkSize: int # Data chunking for rollout, default size 200, enabled when dataset > 300. Valid range is 1-10,000. (format: int32)
  --maxInferenceReplicaCount: int # format: int32
  --nodeCount: int # The number of nodes to use for the fine-tuning job. If not specified, the default is 1. (format: int32)
  --lossConfig: record # Loss method + hyperparameters for reinforcement-learning-style fine-tuning (e.g. RFT / RL trainers). For preference jobs (DPO API), the default loss method is GRPO when METHOD_UNSPECIFIED. — shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
  --maxConcurrentRollouts: int # Maximum number of concurrent rollouts during the RFT job. (format: int32)
  --maxConcurrentEvaluations: int # Maximum number of concurrent evaluations during the RFT job. (format: int32)
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, evaluator: string, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, outputStats: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, inferenceParameters: record<maxOutputTokens: int, temperature: float, topP: float, responseCandidatesCount: int, extraBody: string, topK: int>, chunkSize: int, outputMetrics: string, maxInferenceReplicaCount: int, nodeCount: int, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, trainerLogsSignedUrl: string, acceleratorSeconds: record, maxConcurrentRollouts: int, maxConcurrentEvaluations: int, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id)")
  let body = {displayName: $displayName, dataset: $dataset, evaluationDataset: $evaluationDataset, evalAutoCarveout: $evalAutoCarveout, state: $state, status: $status, trainingConfig: $trainingConfig, evaluator: $evaluator, wandbConfig: $wandbConfig, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, jobProgress: $jobProgress, inferenceParameters: $inferenceParameters, chunkSize: $chunkSize, maxInferenceReplicaCount: $maxInferenceReplicaCount, nodeCount: $nodeCount, lossConfig: $lossConfig, maxConcurrentRollouts: $maxConcurrentRollouts, maxConcurrentEvaluations: $maxConcurrentEvaluations, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Reinforcement Fine-tuning Job
#
# DELETE /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}
# operationId: Gateway_DeleteReinforcementFineTuningJob
export def "accounts-reinforcement-fine-tuning-jobs DeleteReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Reinforcement Fine-tuning Job
#
# POST /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}:cancel
# operationId: Gateway_CancelReinforcementFineTuningJob
export def "accounts-reinforcement-fine-tuning-jobs CancelReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id):cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Debug Reinforcement Fine-tuning Job
#
# POST /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}:debug
# operationId: Gateway_DebugReinforcementFineTuningJob
export def "accounts-reinforcement-fine-tuning-jobs DebugReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, failedJobName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id):debug")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}:getMetricsFileEndpoint
#
# operationId: Gateway_GetReinforcementFineTuningJobMetricsFileEndpoint
export def "accounts-reinforcement-fine-tuning-jobs GetReinforcementFineTuningJobMetricsFileEndpoint" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<signedUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id):getMetricsFileEndpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume Reinforcement Fine-tuning Job
#
# POST /v1/accounts/{account_id}/reinforcementFineTuningJobs/{reinforcement_fine_tuning_job_id}:resume
# operationId: Gateway_ResumeReinforcementFineTuningJob
export def "accounts-reinforcement-fine-tuning-jobs ResumeReinforcementFineTuningJob" [
  account_id: string
  reinforcement_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, evaluator: string, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, outputStats: string, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, inferenceParameters: record<maxOutputTokens: int, temperature: float, topP: float, responseCandidatesCount: int, extraBody: string, topK: int>, chunkSize: int, outputMetrics: string, maxInferenceReplicaCount: int, nodeCount: int, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, trainerLogsSignedUrl: string, acceleratorSeconds: record, maxConcurrentRollouts: int, maxConcurrentEvaluations: int, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/reinforcementFineTuningJobs/($reinforcement_fine_tuning_job_id):resume")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Reinforcement Fine-tuning Steps
#
# GET /v1/accounts/{account_id}/rlorTrainerJobs
# operationId: Gateway_ListRlorTrainerJobs
export def "accounts-rlor-trainer-jobs ListRlorTrainerJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of fine-tuning jobs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListRlorTuningJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListRlorTuningJobs must match the call that provided the page token.
  --filter: string # Filter criteria for the returned jobs. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<rlorTrainerJobs: table<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record, createdBy: string, trainingConfig: record, rewardWeights: list, wandbConfig: record, awsS3Config: record, azureBlobStorageConfig: record, jobProgress: record, keepAlive: bool, rolloutDeploymentName: string, lossConfig: record, nodeCount: int, acceleratorSeconds: record, serviceMode: bool, directRouteHandle: string, hotLoadDeploymentId: string, purpose: string, forwardOnly: bool, managedBy: string, inactivityTimeout: string, disableInactivityCleanup: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Reinforcement Fine-tuning Step
#
# POST /v1/accounts/{account_id}/rlorTrainerJobs
# operationId: Gateway_CreateRlorTrainerJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --trainingConfig shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
# --lossConfig shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
export def "accounts-rlor-trainer-jobs CreateRlorTrainerJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rlorTrainerJobId: string # ID of the RLOR trainer job, a random UUID will be generated if not specified.
  --trainingShape: string # Optional validated training-shape selector for service-mode launches. Accepted formats: - accounts/{account}/trainingShapes/{shape} - accounts/{account}/trainingShapes/{shape}/versions/{version} - accounts/{account}/trainingShapes/{shape}/versions/latest When a shape (without /versions/*) is provided, the latest validated version is used.
  --displayName: string
  --dataset: string # The name of the dataset used for training.
  --evaluationDataset: string # The name of a separate dataset to use for evaluation.
  --evalAutoCarveout: oneof<nothing, bool> # Whether to auto-carve the dataset for eval.
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --trainingConfig: record # shape: {outputModel?: string, baseModel?: string, warmStartFrom?: string, jinjaTemplate?: string, learningRate?: float, maxContextLength?: int, loraRank?: int, epochs?: int, batchSize?: int, gradientAccumulationSteps?: int, learningRateWarmupSteps?: int, batchSizeSamples?: int, optimizerWeightDecay?: float, trainerShardingScheme?: record, loraAlpha?: int, loraDropout?: float, loraTargetModules?: list}
  --rewardWeights: list # A list of reward metrics to use for training in format of "<reward_name>=<weight>".
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --keepAlive: oneof<nothing, bool>
  --rolloutDeploymentName: string # Rollout deployment name associated with this RLOR trainer job. This is optional. If not set, trainer will not trigger weight sync to rollout engine.
  --lossConfig: record # Loss method + hyperparameters for reinforcement-learning-style fine-tuning (e.g. RFT / RL trainers). For preference jobs (DPO API), the default loss method is GRPO when METHOD_UNSPECIFIED. — shape: {method?: "METHOD_UNSPECIFIED"|"GRPO"|"DAPO"|"DPO"|"ORPO"|"GSPO_TOKEN", klBeta?: float, dpo?: record, orpo?: record}
  --nodeCount: int # The number of nodes to use for the fine-tuning job. If not specified, the default is 1. (format: int32)
  --serviceMode: oneof<nothing, bool>
  --hotLoadDeploymentId: string # The deployment ID used for hot loading. When set, checkpoints are saved to this deployment's hot load bucket, enabling weight swaps on inference. Only valid for service-mode or keep-alive jobs.
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
  --forwardOnly: oneof<nothing, bool> # When true, run the trainer in forward-only mode (no backward/optimizer). Used for reference models in GRPO that only need forward passes.
  --managedBy: string # For managed service use only. Users do not need to set this field.
  --inactivityTimeout: string # Trainer inactivity timeout. The trainer reports tracked activity, including trainer API operations and active-session heartbeats. If no tracked activity is observed for this duration, the trainer is automatically stopped. When unset or 0, defaults to 60 minutes. Set disableInactivityCleanup to true to disable automatic cleanup. GPU usage continues to accrue while the trainer is running.
  --disableInactivityCleanup: oneof<nothing, bool> # Disable trainer inactivity cleanup. When true, the trainer is not automatically stopped due to inactivity. GPU usage continues to accrue while the trainer is running.
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, rewardWeights: list<string>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, keepAlive: bool, rolloutDeploymentName: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, nodeCount: int, acceleratorSeconds: record, serviceMode: bool, directRouteHandle: string, hotLoadDeploymentId: string, purpose: string, forwardOnly: bool, managedBy: string, inactivityTimeout: string, disableInactivityCleanup: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "rlorTrainerJobId" $rlorTrainerJobId "scalar") (serialize-qp "trainingShape" $trainingShape "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs" $qp)
  let body = {displayName: $displayName, dataset: $dataset, evaluationDataset: $evaluationDataset, evalAutoCarveout: $evalAutoCarveout, state: $state, status: $status, trainingConfig: $trainingConfig, rewardWeights: $rewardWeights, wandbConfig: $wandbConfig, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, jobProgress: $jobProgress, keepAlive: $keepAlive, rolloutDeploymentName: $rolloutDeploymentName, lossConfig: $lossConfig, nodeCount: $nodeCount, serviceMode: $serviceMode, hotLoadDeploymentId: $hotLoadDeploymentId, purpose: $purpose, forwardOnly: $forwardOnly, managedBy: $managedBy, inactivityTimeout: $inactivityTimeout, disableInactivityCleanup: $disableInactivityCleanup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Reinforcement Fine-tuning Step
#
# GET /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}
# operationId: Gateway_GetRlorTrainerJob
export def "accounts-rlor-trainer-jobs GetRlorTrainerJob" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, rewardWeights: list<string>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, keepAlive: bool, rolloutDeploymentName: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, nodeCount: int, acceleratorSeconds: record, serviceMode: bool, directRouteHandle: string, hotLoadDeploymentId: string, purpose: string, forwardOnly: bool, managedBy: string, inactivityTimeout: string, disableInactivityCleanup: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Reinforcement Fine-tuning Step
#
# DELETE /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}
# operationId: Gateway_DeleteRlorTrainerJob
export def "accounts-rlor-trainer-jobs DeleteRlorTrainerJob" [
  account_id: string
  rlor_trainer_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List checkpoints for an RLOR Trainer Job
#
# GET /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}/checkpoints
# operationId: Gateway_ListRlorTrainerJobCheckpoints
export def "accounts-rlor-trainer-jobs-checkpoints ListRlorTrainerJobCheckpoints" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Maximum number of checkpoints to return. Default is 50, max is 200. (format: int32)
  --pageToken: string # Page token from a previous call.
]: nothing -> record<checkpoints: table<name: string, createTime: string, updateTime: string, checkpointType: string, promotable: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id)/checkpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a signed URL for the public trainer logs of an RLOR Trainer Job.
#
# GET /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}/publicLogs
# operationId: Gateway_GetRlorTrainerJobPublicLogs
export def "accounts-rlor-trainer-jobs-public-logs GetRlorTrainerJobPublicLogs" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<signedUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id)/publicLogs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Rlor Trainer Job
#
# POST /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}:cancel
# operationId: Gateway_CancelRlorTrainerJob
export def "accounts-rlor-trainer-jobs CancelRlorTrainerJob" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id):cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute one training step for keep-alive Reinforcement Fine-tuning Step
#
# POST /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}:executeTrainStep
# operationId: Gateway_ExecuteRlorTrainStep
export def "accounts-rlor-trainer-jobs ExecuteRlorTrainStep" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset: string # Dataset to process for this iteration.
  outputModel: string # Output model to materialize when training completes.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id):executeTrainStep")
  let body = {dataset: $dataset, outputModel: $outputModel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resume Rlor Trainer Job
#
# POST /v1/accounts/{account_id}/rlorTrainerJobs/{rlor_trainer_job_id}:resume
# operationId: Gateway_ResumeRlorTrainerJob
export def "accounts-rlor-trainer-jobs ResumeRlorTrainerJob" [
  account_id: string
  rlor_trainer_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, evaluationDataset: string, evalAutoCarveout: bool, state: string, status: record<code: string, message: string>, createdBy: string, trainingConfig: record<outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, learningRate: float, maxContextLength: int, loraRank: int, epochs: int, batchSize: int, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, optimizerWeightDecay: float, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, loraAlpha: int, loraDropout: float, loraTargetModules: list<string>>, rewardWeights: list<string>, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, keepAlive: bool, rolloutDeploymentName: string, lossConfig: record<method: string, klBeta: float, dpo: record<beta: float, refCacheConcurrency: int, refCacheBatchSize: int>, orpo: record<lambda: float>>, nodeCount: int, acceleratorSeconds: record, serviceMode: bool, directRouteHandle: string, hotLoadDeploymentId: string, purpose: string, forwardOnly: bool, managedBy: string, inactivityTimeout: string, disableInactivityCleanup: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/rlorTrainerJobs/($rlor_trainer_job_id):resume")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Routers
#
# GET /v1/accounts/{account_id}/routers
# operationId: Gateway_ListRouters
export def "accounts-routers ListRouters" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of routers to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListRouters call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListRouters must match the call that provided the page token.
  --filter: string # Filter criteria for the returned routers. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<routers: table<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record, deployments: list, model: string, weightedRandom: record, evenLoad: record, aliases: list, autoGenerated: bool, public: bool>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/routers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Router
#
# POST /v1/accounts/{account_id}/routers
# operationId: Gateway_CreateRouter
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-routers CreateRouter" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --routerId: string # ID of the router.
  --displayName: string
  --state: string@state-completer-7 # - CREATING: The router is being created.  - READY: The router is ready for access.  - UPDATING: There are in-progress updates happening with the router.  - DELETING: The router is being deleted. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --deployments: list # The deployment names to be covered by the router.
  --model: string # The model name to route requests to. model is only applicable to single-region deployments. For multi-region deployments, model must be empty.
  --weightedRandom: record # Use replica count as weight.
  --evenLoad: record # Dynamically adjust traffic allocation to balance the load per replica across the deployments as much as possible.
  --public: oneof<nothing, bool> # True if the router is public (any account can query the underlying workload), false if the router is private (only the account that owns the router can query the underlying workload).
]: any -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, deployments: list<string>, model: string, weightedRandom: record, evenLoad: record, aliases: list<string>, autoGenerated: bool, public: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "routerId" $routerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/routers" $qp)
  let body = {displayName: $displayName, state: $state, status: $status, deployments: $deployments, model: $model, weightedRandom: $weightedRandom, evenLoad: $evenLoad, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Router
#
# GET /v1/accounts/{account_id}/routers/{router_id}
# operationId: Gateway_GetRouter
export def "accounts-routers GetRouter" [
  account_id: string
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, deployments: list<string>, model: string, weightedRandom: record, evenLoad: record, aliases: list<string>, autoGenerated: bool, public: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/routers/($router_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Router
#
# PATCH /v1/accounts/{account_id}/routers/{router_id}
# operationId: Gateway_UpdateRouter
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-routers UpdateRouter" [
  account_id: string
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --state: string@state-completer-7 # - CREATING: The router is being created.  - READY: The router is ready for access.  - UPDATING: There are in-progress updates happening with the router.  - DELETING: The router is being deleted. (default: STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --deployments: list # The deployment names to be covered by the router.
  --model: string # The model name to route requests to. model is only applicable to single-region deployments. For multi-region deployments, model must be empty.
  --weightedRandom: record # Use replica count as weight.
  --evenLoad: record # Dynamically adjust traffic allocation to balance the load per replica across the deployments as much as possible.
  --public: oneof<nothing, bool> # True if the router is public (any account can query the underlying workload), false if the router is private (only the account that owns the router can query the underlying workload).
]: any -> record<name: string, displayName: string, createTime: string, createdBy: string, state: string, status: record<code: string, message: string>, deployments: list<string>, model: string, weightedRandom: record, evenLoad: record, aliases: list<string>, autoGenerated: bool, public: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/routers/($router_id)")
  let body = {displayName: $displayName, state: $state, status: $status, deployments: $deployments, model: $model, weightedRandom: $weightedRandom, evenLoad: $evenLoad, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Router
#
# DELETE /v1/accounts/{account_id}/routers/{router_id}
# operationId: Gateway_DeleteRouter
export def "accounts-routers DeleteRouter" [
  account_id: string
  router_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/routers/($router_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Secrets
#
# GET /v1/accounts/{account_id}/secrets
# operationId: Gateway_ListSecrets
export def "accounts-secrets ListSecrets" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string # Unused but required to use existing ListRequest functionality.
  --orderBy: string # Unused but required to use existing ListRequest functionality.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<secrets: table<name: string, keyName: string, value: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/accounts/{account_id}/secrets
#
# operationId: Gateway_CreateSecret
export def "accounts-secrets CreateSecret" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  keyName: string
  --value: string # The secret value. This field is INPUT_ONLY and will not be returned in GET or LIST responses for security reasons. The value is only accepted when creating or updating secrets. (e.g. sk-1234567890abcdef)
]: any -> record<name: string, keyName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/secrets")
  let body = {name: $name, keyName: $keyName, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Secret
#
# GET /v1/accounts/{account_id}/secrets/{secret_id}
# operationId: Gateway_GetSecret
export def "accounts-secrets GetSecret" [
  account_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, keyName: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/secrets/($secret_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/accounts/{account_id}/secrets/{secret_id}
#
# operationId: Gateway_UpdateSecret
export def "accounts-secrets UpdateSecret" [
  account_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  keyName: string
  --value: string # The secret value. This field is INPUT_ONLY and will not be returned in GET or LIST responses for security reasons. The value is only accepted when creating or updating secrets. (e.g. sk-1234567890abcdef)
]: any -> record<name: string, keyName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/secrets/($secret_id)")
  let body = {keyName: $keyName, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/accounts/{account_id}/secrets/{secret_id}
#
# operationId: Gateway_DeleteSecret
export def "accounts-secrets DeleteSecret" [
  account_id: string
  secret_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/secrets/($secret_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists effective global rate limits for shared serverless pool deployments (fireworks-owned). Values reflect configured limits as observed in production monitoring.
#
# GET /v1/accounts/{account_id}/serverlessRateLimits
# operationId: Gateway_ListAccountServerlessRateLimits
export def "accounts-serverless-rate-limits ListAccountServerlessRateLimits" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment: string # If set, only return limits for this deployment resource name.
  --start: string # Start of the time range for time series data. Defaults to 30 days before `end`. (format: date-time)
  --end: string # End of the time range for time series data. Defaults to the request time. (format: date-time)
  --interval: string # Step size for the time series: each point is the peak effective limit observed within that window. Defaults to 4 hours.
]: nothing -> record<rateLimits: table<deployment: string, metric: string, effectiveLimit: float>, series: table<labels: record, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "deployment" $deployment "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/serverlessRateLimits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Serverless pool token throughput (tokens per minute) by time bucket and base model, from production usage metrics.
#
# GET /v1/accounts/{account_id}/serverlessTokenUsage
# operationId: Gateway_GetAccountServerlessTokenUsage
export def "accounts-serverless-token-usage GetAccountServerlessTokenUsage" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start of the time range. Defaults to 30 days before `end`. (format: date-time)
  --end: string # End of the time range. Defaults to the request time. (format: date-time)
  --interval: string # Step size for each point (peak or average TPM within each window). Defaults to 4 hours.
  --includePeakTokensPerMinuteByBaseModel: oneof<nothing, bool> # Whether to include each section in the response. At least one must be true; otherwise the request fails with INVALID_ARGUMENT.
  --includeAverageTokensPerMinuteByBaseModel: oneof<nothing, bool>
]: nothing -> record<averageTokensPerMinuteByBaseModel: table<labels: record, values: list>, totalPeakGeneratedTokensPerMinute: record<labels: record, values: list<record>>, totalPeakUncachedPromptTokensPerMinute: record<labels: record, values: list<record>>, totalPeakCachedPromptTokensPerMinute: record<labels: record, values: list<record>>, peakGeneratedTokensPerMinuteByBaseModel: table<labels: record, values: list>, peakUncachedPromptTokensPerMinuteByBaseModel: table<labels: record, values: list>, peakCachedPromptTokensPerMinuteByBaseModel: table<labels: record, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "includePeakTokensPerMinuteByBaseModel" $includePeakTokensPerMinuteByBaseModel "scalar") (serialize-qp "includeAverageTokensPerMinuteByBaseModel" $includeAverageTokensPerMinuteByBaseModel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/serverlessTokenUsage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Supervised Fine-tuning Jobs
#
# GET /v1/accounts/{account_id}/supervisedFineTuningJobs
# operationId: Gateway_ListSupervisedFineTuningJobs
export def "accounts-supervised-fine-tuning-jobs ListSupervisedFineTuningJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of fine-tuning jobs to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListSupervisedFineTuningJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListSupervisedFineTuningJobs must match the call that provided the page token.
  --filter: string # Filter criteria for the returned jobs. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<supervisedFineTuningJobs: table<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, awsS3Config: record, azureBlobStorageConfig: record, state: string, status: record, createdBy: string, outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, earlyStop: bool, epochs: int, learningRate: float, maxContextLength: int, loraRank: int, wandbConfig: record, evaluationDataset: string, isTurbo: bool, evalAutoCarveout: bool, updateTime: string, nodes: int, batchSize: int, mtpEnabled: bool, mtpNumDraftTokens: int, mtpFreezeBaseModel: bool, jobProgress: record, metricsFileSignedUrl: string, trainerLogsSignedUrl: string, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, estimatedCost: record, optimizerWeightDecay: float, purpose: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Supervised Fine-tuning Job
#
# POST /v1/accounts/{account_id}/supervisedFineTuningJobs
# operationId: Gateway_CreateSupervisedFineTuningJob
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
# --estimatedCost shape: {currencyCode?: string, units?: string, nanos?: int}
export def "accounts-supervised-fine-tuning-jobs CreateSupervisedFineTuningJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --supervisedFineTuningJobId: string # ID of the supervised fine-tuning job, a random UUID will be generated if not specified.
  --displayName: string
  dataset: string # The name of the dataset used for training.
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --outputModel: string # The model ID to be assigned to the resulting fine-tuned model. If not specified, the job ID will be used.
  --baseModel: string # The name of the base model to be fine-tuned Only one of 'base_model' or 'warm_start_from' should be specified.
  --warmStartFrom: string # The PEFT addon model in Fireworks format to be fine-tuned from Only one of 'base_model' or 'warm_start_from' should be specified.
  --jinjaTemplate: string
  --earlyStop: oneof<nothing, bool> # Whether to stop training early if the validation loss does not improve.
  --epochs: int # The number of epochs to train for. (format: int32)
  --learningRate: float # The learning rate used for training. (format: float)
  --maxContextLength: int # The maximum context length to use with the model. (format: int32)
  --loraRank: int # The rank of the LoRA layers. (format: int32)
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --evaluationDataset: string # The name of a separate dataset to use for evaluation.
  --isTurbo: oneof<nothing, bool> # Whether to run the fine-tuning job in turbo mode.
  --evalAutoCarveout: oneof<nothing, bool> # Whether to auto-carve the dataset for eval.
  --nodes: int # Deprecated: multi-node scheduling is now handled by the cookbook orchestrator in V2 workflows. This field is ignored for V2 jobs and will be removed in a future release. (format: int32)
  --batchSize: int # format: int32
  --mtpEnabled: oneof<nothing, bool> # Deprecated: MTP is not supported in V2 training. These fields are retained for V1 Helm-based SFT backward compatibility only.
  --mtpNumDraftTokens: int # Deprecated: see mtp_enabled. (format: int32)
  --mtpFreezeBaseModel: oneof<nothing, bool> # Deprecated: see mtp_enabled.
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --metricsFileSignedUrl: string
  --gradientAccumulationSteps: int # format: int32
  --learningRateWarmupSteps: int # format: int32
  --batchSizeSamples: int # The number of samples per gradient batch. (format: int32)
  --estimatedCost: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, units?: string, nanos?: int}
  --optimizerWeightDecay: float # Weight decay (L2 regularization) for optimizer. (format: float)
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, state: string, status: record<code: string, message: string>, createdBy: string, outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, earlyStop: bool, epochs: int, learningRate: float, maxContextLength: int, loraRank: int, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, evaluationDataset: string, isTurbo: bool, evalAutoCarveout: bool, updateTime: string, nodes: int, batchSize: int, mtpEnabled: bool, mtpNumDraftTokens: int, mtpFreezeBaseModel: bool, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, metricsFileSignedUrl: string, trainerLogsSignedUrl: string, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, estimatedCost: record<currencyCode: string, units: string, nanos: int>, optimizerWeightDecay: float, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "supervisedFineTuningJobId" $supervisedFineTuningJobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs" $qp)
  let body = {displayName: $displayName, dataset: $dataset, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, state: $state, status: $status, outputModel: $outputModel, baseModel: $baseModel, warmStartFrom: $warmStartFrom, jinjaTemplate: $jinjaTemplate, earlyStop: $earlyStop, epochs: $epochs, learningRate: $learningRate, maxContextLength: $maxContextLength, loraRank: $loraRank, wandbConfig: $wandbConfig, evaluationDataset: $evaluationDataset, isTurbo: $isTurbo, evalAutoCarveout: $evalAutoCarveout, nodes: $nodes, batchSize: $batchSize, mtpEnabled: $mtpEnabled, mtpNumDraftTokens: $mtpNumDraftTokens, mtpFreezeBaseModel: $mtpFreezeBaseModel, jobProgress: $jobProgress, metricsFileSignedUrl: $metricsFileSignedUrl, gradientAccumulationSteps: $gradientAccumulationSteps, learningRateWarmupSteps: $learningRateWarmupSteps, batchSizeSamples: $batchSizeSamples, estimatedCost: $estimatedCost, optimizerWeightDecay: $optimizerWeightDecay, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Supervised Fine-tuning Job
#
# GET /v1/accounts/{account_id}/supervisedFineTuningJobs/{supervised_fine_tuning_job_id}
# operationId: Gateway_GetSupervisedFineTuningJob
export def "accounts-supervised-fine-tuning-jobs GetSupervisedFineTuningJob" [
  account_id: string
  supervised_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, state: string, status: record<code: string, message: string>, createdBy: string, outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, earlyStop: bool, epochs: int, learningRate: float, maxContextLength: int, loraRank: int, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, evaluationDataset: string, isTurbo: bool, evalAutoCarveout: bool, updateTime: string, nodes: int, batchSize: int, mtpEnabled: bool, mtpNumDraftTokens: int, mtpFreezeBaseModel: bool, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, metricsFileSignedUrl: string, trainerLogsSignedUrl: string, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, estimatedCost: record<currencyCode: string, units: string, nanos: int>, optimizerWeightDecay: float, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs/($supervised_fine_tuning_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Supervised Fine-tuning Job
#
# DELETE /v1/accounts/{account_id}/supervisedFineTuningJobs/{supervised_fine_tuning_job_id}
# operationId: Gateway_DeleteSupervisedFineTuningJob
export def "accounts-supervised-fine-tuning-jobs DeleteSupervisedFineTuningJob" [
  account_id: string
  supervised_fine_tuning_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs/($supervised_fine_tuning_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Supervised Fine-tuning Job
#
# POST /v1/accounts/{account_id}/supervisedFineTuningJobs/{supervised_fine_tuning_job_id}:cancel
# operationId: Gateway_CancelSupervisedFineTuningJob
export def "accounts-supervised-fine-tuning-jobs CancelSupervisedFineTuningJob" [
  account_id: string
  supervised_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs/($supervised_fine_tuning_job_id):cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resume Supervised Fine-tuning Job
#
# POST /v1/accounts/{account_id}/supervisedFineTuningJobs/{supervised_fine_tuning_job_id}:resume
# operationId: Gateway_ResumeSupervisedFineTuningJob
export def "accounts-supervised-fine-tuning-jobs ResumeSupervisedFineTuningJob" [
  account_id: string
  supervised_fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string, displayName: string, createTime: string, completedTime: string, dataset: string, awsS3Config: record<credentialsSecret: string, iamRoleArn: string>, azureBlobStorageConfig: record<credentialsSecret: string, managedIdentityClientId: string, tenantId: string>, state: string, status: record<code: string, message: string>, createdBy: string, outputModel: string, baseModel: string, warmStartFrom: string, jinjaTemplate: string, earlyStop: bool, epochs: int, learningRate: float, maxContextLength: int, loraRank: int, wandbConfig: record<enabled: bool, apiKey: string, project: string, entity: string, runId: string, url: string>, evaluationDataset: string, isTurbo: bool, evalAutoCarveout: bool, updateTime: string, nodes: int, batchSize: int, mtpEnabled: bool, mtpNumDraftTokens: int, mtpFreezeBaseModel: bool, jobProgress: record<percent: int, epoch: int, totalInputRequests: int, totalProcessedRequests: int, successfullyProcessedRequests: int, failedRequests: int, outputRows: int, inputTokens: int, outputTokens: int, cachedInputTokenCount: int>, metricsFileSignedUrl: string, trainerLogsSignedUrl: string, gradientAccumulationSteps: int, learningRateWarmupSteps: int, batchSizeSamples: int, estimatedCost: record<currencyCode: string, units: string, nanos: int>, optimizerWeightDecay: float, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs/($supervised_fine_tuning_job_id):resume")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Estimate the cost of a Supervised Fine-tuning Job
#
# POST /v1/accounts/{account_id}/supervisedFineTuningJobs:estimateCost
# operationId: Gateway_EstimateSupervisedFineTuningJobCost
# --awsS3Config shape: {credentialsSecret?: string, iamRoleArn?: string}
# --azureBlobStorageConfig shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
# --wandbConfig shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
# --jobProgress shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
# --estimatedCost shape: {currencyCode?: string, units?: string, nanos?: int}
export def "accounts-supervised-fine-tuning-jobs-estimate-cost EstimateSupervisedFineTuningJobCost" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  dataset: string # The name of the dataset used for training.
  --awsS3Config: record # AwsS3Config is the configuration for AWS S3 dataset access which will be used by a training job. — shape: {credentialsSecret?: string, iamRoleArn?: string}
  --azureBlobStorageConfig: record # AzureBlobStorageConfig is the configuration for Azure Blob Storage dataset access which will be used by a training job. — shape: {credentialsSecret?: string, managedIdentityClientId?: string, tenantId?: string}
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --outputModel: string # The model ID to be assigned to the resulting fine-tuned model. If not specified, the job ID will be used.
  --baseModel: string # The name of the base model to be fine-tuned Only one of 'base_model' or 'warm_start_from' should be specified.
  --warmStartFrom: string # The PEFT addon model in Fireworks format to be fine-tuned from Only one of 'base_model' or 'warm_start_from' should be specified.
  --jinjaTemplate: string
  --earlyStop: oneof<nothing, bool> # Whether to stop training early if the validation loss does not improve.
  --epochs: int # The number of epochs to train for. (format: int32)
  --learningRate: float # The learning rate used for training. (format: float)
  --maxContextLength: int # The maximum context length to use with the model. (format: int32)
  --loraRank: int # The rank of the LoRA layers. (format: int32)
  --wandbConfig: record # WandbConfig is the configuration for the Weights & Biases (wandb) logging which will be used by a training job. — shape: {enabled?: bool, apiKey?: string, project?: string, entity?: string, runId?: string}
  --evaluationDataset: string # The name of a separate dataset to use for evaluation.
  --isTurbo: oneof<nothing, bool> # Whether to run the fine-tuning job in turbo mode.
  --evalAutoCarveout: oneof<nothing, bool> # Whether to auto-carve the dataset for eval.
  --nodes: int # Deprecated: multi-node scheduling is now handled by the cookbook orchestrator in V2 workflows. This field is ignored for V2 jobs and will be removed in a future release. (format: int32)
  --batchSize: int # format: int32
  --mtpEnabled: oneof<nothing, bool> # Deprecated: MTP is not supported in V2 training. These fields are retained for V1 Helm-based SFT backward compatibility only.
  --mtpNumDraftTokens: int # Deprecated: see mtp_enabled. (format: int32)
  --mtpFreezeBaseModel: oneof<nothing, bool> # Deprecated: see mtp_enabled.
  --jobProgress: record # Progress of a job, e.g. RLOR, EVJ, BIJ etc. — shape: {percent?: int, epoch?: int, totalInputRequests?: int, totalProcessedRequests?: int, successfullyProcessedRequests?: int, failedRequests?: int, outputRows?: int, inputTokens?: int, outputTokens?: int, cachedInputTokenCount?: int}
  --metricsFileSignedUrl: string
  --gradientAccumulationSteps: int # format: int32
  --learningRateWarmupSteps: int # format: int32
  --batchSizeSamples: int # The number of samples per gradient batch. (format: int32)
  --estimatedCost: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, units?: string, nanos?: int}
  --optimizerWeightDecay: float # Weight decay (L2 regularization) for optimizer. (format: float)
  --purpose: string@purpose-completer # Scheduling purpose for training jobs and deployments. (default: PURPOSE_UNSPECIFIED)
]: any -> record<estimatedCost: record<currencyCode: string, units: string, nanos: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/supervisedFineTuningJobs:estimateCost")
  let body = {displayName: $displayName, dataset: $dataset, awsS3Config: $awsS3Config, azureBlobStorageConfig: $azureBlobStorageConfig, state: $state, status: $status, outputModel: $outputModel, baseModel: $baseModel, warmStartFrom: $warmStartFrom, jinjaTemplate: $jinjaTemplate, earlyStop: $earlyStop, epochs: $epochs, learningRate: $learningRate, maxContextLength: $maxContextLength, loraRank: $loraRank, wandbConfig: $wandbConfig, evaluationDataset: $evaluationDataset, isTurbo: $isTurbo, evalAutoCarveout: $evalAutoCarveout, nodes: $nodes, batchSize: $batchSize, mtpEnabled: $mtpEnabled, mtpNumDraftTokens: $mtpNumDraftTokens, mtpFreezeBaseModel: $mtpFreezeBaseModel, jobProgress: $jobProgress, metricsFileSignedUrl: $metricsFileSignedUrl, gradientAccumulationSteps: $gradientAccumulationSteps, learningRateWarmupSteps: $learningRateWarmupSteps, batchSizeSamples: $batchSizeSamples, estimatedCost: $estimatedCost, optimizerWeightDecay: $optimizerWeightDecay, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Trails
#
# GET /v1/accounts/{account_id}/trails
# operationId: Gateway_ListTrails
export def "accounts-trails ListTrails" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of trails to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListTrails call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListTrails must match the call that provided the page token.
  --filter: string # Filter criteria for the returned trails. See https://google.aip.dev/160 for the filter syntax specification.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "create_time,display_name" The default sort order is ascending. To specify descending order for a field, append a " desc" suffix. e.g. "create_time desc" If not specified, the default order is by "create_time desc".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<trails: table<name: string, displayName: string, createTime: string, updateTime: string, description: string, createdBy: string, langfuseConfig: string, defaultModel: string, providerKey: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Trail
#
# POST /v1/accounts/{account_id}/trails
# operationId: Gateway_CreateTrail
export def "accounts-trails CreateTrail" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trailId: string # Optional ID for the trail. If not specified, a random UUID will be generated.
  --displayName: string
  --description: string
  --defaultModel: string # Default model for requests through this trail. Format: "{provider}/{model_id}" (e.g., "anthropic/claude-3-5-sonnet-20240620"). Can be overridden per request.
  --providerKey: string # Provider API key for this trail. When creating a trail: provide the raw API key (e.g., "sk-ant-api03-xxxx...") After creation: this field contains a secret reference (e.g., "accounts/{account_id}/secrets/trail-xxx-provider-key") The LiteLLM gateway retrieves the actual key from Secret Manager using this reference. Can be overridden by specifying api_key in the request body.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, description: string, createdBy: string, langfuseConfig: string, defaultModel: string, providerKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "trailId" $trailId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails" $qp)
  let body = {displayName: $displayName, description: $description, defaultModel: $defaultModel, providerKey: $providerKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CRUD APIs for trails. Get Trail
#
# GET /v1/accounts/{account_id}/trails/{trail_id}
# operationId: Gateway_GetTrail
export def "accounts-trails GetTrail" [
  account_id: string
  trail_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, createTime: string, updateTime: string, description: string, createdBy: string, langfuseConfig: string, defaultModel: string, providerKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails/($trail_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Trail
#
# PATCH /v1/accounts/{account_id}/trails/{trail_id}
# operationId: Gateway_UpdateTrail
export def "accounts-trails UpdateTrail" [
  account_id: string
  trail_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string
  --description: string
  --defaultModel: string # Default model for requests through this trail. Format: "{provider}/{model_id}" (e.g., "anthropic/claude-3-5-sonnet-20240620"). Can be overridden per request.
  --providerKey: string # Provider API key for this trail. When creating a trail: provide the raw API key (e.g., "sk-ant-api03-xxxx...") After creation: this field contains a secret reference (e.g., "accounts/{account_id}/secrets/trail-xxx-provider-key") The LiteLLM gateway retrieves the actual key from Secret Manager using this reference. Can be overridden by specifying api_key in the request body.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, description: string, createdBy: string, langfuseConfig: string, defaultModel: string, providerKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails/($trail_id)")
  let body = {displayName: $displayName, description: $description, defaultModel: $defaultModel, providerKey: $providerKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Trail
#
# DELETE /v1/accounts/{account_id}/trails/{trail_id}
# operationId: Gateway_DeleteTrail
export def "accounts-trails DeleteTrail" [
  account_id: string
  trail_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails/($trail_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trail Metrics (trace counts, token usage from tracing service)
#
# GET /v1/accounts/{account_id}/trails/{trail_id}:getMetrics
# operationId: Gateway_GetTrailMetrics
export def "accounts-trails GetTrailMetrics" [
  account_id: string
  trail_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<totalTraceCount: string, firstTraceTime: string, lastTraceTime: string, promptTokenCount: string, completionTokenCount: string, totalTokenCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trails/($trail_id):getMetrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List training session jobs for an account.
#
# GET /v1/accounts/{account_id}/trainingSessionJobs
# operationId: Gateway_ListTrainingSessionJobs
export def "accounts-training-session-jobs ListTrainingSessionJobs" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string
  --readMask: string
]: nothing -> record<trainingSessionJobs: table<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record, createdBy: string, baseModel: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a training session job that binds an account to a shared trainer.
#
# POST /v1/accounts/{account_id}/trainingSessionJobs
# operationId: Gateway_CreateTrainingSessionJob
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-training-session-jobs CreateTrainingSessionJob" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trainingSessionJobId: string
  --displayName: string # Human-readable display name of the training session job. e.g. "Reference sessions" Must be fewer than 64 characters long.
  --state: string@state-completer # JobState represents the state an asynchronous job can be in.   - JOB_STATE_PAUSED: Job is paused, typically due to account suspension or manual intervention.  - JOB_STATE_DELETED: Job has been deleted. (default: JOB_STATE_UNSPECIFIED)
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  baseModel: string # Base model used for sessions created under this training session job.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record<code: string, message: string>, createdBy: string, baseModel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "trainingSessionJobId" $trainingSessionJobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs" $qp)
  let body = {displayName: $displayName, state: $state, status: $status, baseModel: $baseModel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a training session job.
#
# GET /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}
# operationId: Gateway_GetTrainingSessionJob
export def "accounts-training-session-jobs GetTrainingSessionJob" [
  account_id: string
  training_session_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string
]: nothing -> record<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record<code: string, message: string>, createdBy: string, baseModel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a training session job and cascade-clean its child sessions and routes.
#
# DELETE /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}
# operationId: Gateway_DeleteTrainingSessionJob
export def "accounts-training-session-jobs DeleteTrainingSessionJob" [
  account_id: string
  training_session_job_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List training sessions under a training session job.
#
# GET /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}/trainingSessions
# operationId: Gateway_ListTrainingSessions
export def "accounts-training-session-jobs-training-sessions ListTrainingSessions" [
  account_id: string
  training_session_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --pageToken: string
  --filter: string
  --orderBy: string
  --readMask: string
]: nothing -> record<trainingSessions: table<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record, createdBy: string, referenceState: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)/trainingSessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a training session under a training session job.
#
# POST /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}/trainingSessions
# operationId: Gateway_CreateTrainingSession
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-training-session-jobs-training-sessions CreateTrainingSession" [
  account_id: string
  training_session_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trainingSessionId: string
  --displayName: string # Human-readable display name of the training session. e.g. "Training session" Must be fewer than 64 characters long.
  --state: string@state-completer-8 # default: TRAINING_SESSION_STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --referenceState: string@referenceState-completer # ReferenceState indicates whether the session currently references the base model or a loaded LoRA adapter. Updated automatically when ExecuteTrainingSessionLoadState is called.   - BASE: Session is using the base model (no adapter loaded).  - ADAPTER: Session has a LoRA adapter loaded. (default: TRAINING_SESSION_REFERENCE_STATE_UNSPECIFIED)
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record<code: string, message: string>, createdBy: string, referenceState: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "trainingSessionId" $trainingSessionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)/trainingSessions" $qp)
  let body = {displayName: $displayName, state: $state, status: $status, referenceState: $referenceState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a training session.
#
# GET /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}/trainingSessions/{training_session_id}
# operationId: Gateway_GetTrainingSession
export def "accounts-training-session-jobs-training-sessions GetTrainingSession" [
  account_id: string
  training_session_job_id: string
  training_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string
]: nothing -> record<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record<code: string, message: string>, createdBy: string, referenceState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)/trainingSessions/($training_session_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Load or switch the LoRA adapter state for a training session.
#
# POST /v1/accounts/{account_id}/trainingSessionJobs/{training_session_job_id}/trainingSessions/{training_session_id}:loadState
# operationId: Gateway_ExecuteTrainingSessionLoadState
export def "accounts-training-session-jobs-training-sessions ExecuteTrainingSessionLoadState" [
  account_id: string
  training_session_job_id: string
  training_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  path: string # Adapter checkpoint path to load into the training session.
]: any -> record<name: string, displayName: string, createTime: string, updateTime: string, state: string, status: record<code: string, message: string>, createdBy: string, referenceState: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingSessionJobs/($training_session_job_id)/trainingSessions/($training_session_id):loadState")
  let body = {path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Training Shapes
#
# GET /v1/accounts/{account_id}/trainingShapes
# operationId: Gateway_ListTrainingShapes
export def "accounts-training-shapes ListTrainingShapes" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of resources to return. Max page_size is 200; values above 200 are coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token from a previous ListTrainingShapes call.
  --filter: string # Filter per AIP-160.
  --orderBy: string # Order by fields, default "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<trainingShapes: table<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CRUD APIs for training shape. Create Training Shape
#
# POST /v1/accounts/{account_id}/trainingShapes
# operationId: Gateway_CreateTrainingShape
# --trainerShardingScheme shape: {tensorParallelism?: int, pipelineParallelism?: int, contextParallelism?: int, expertParallelism?: int, sequenceParallelism?: bool}
export def "accounts-training-shapes CreateTrainingShape" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trainingShapeId: string # The ID of the training shape. If not specified, a random ID will be generated. Must follow AIP-122 segment format and start with a letter.
  --displayName: string # Human-readable display name of the training shape. e.g. "Llama3 70B H200 BF16" Must be fewer than 64 characters long.
  --description: string # The description of the training shape. Must be fewer than 1000 characters long.
  baseModel: string
  --deploymentShapeVersion: string
  trainerImageTag: string # The validated trainer runtime image tag used for numerics verification.
  --trainerMode: string@trainerMode-completer # Trainer execution mode used for validated launch-profile matching. (default: TRAINER_MODE_UNSPECIFIED)
  --nodeCount: int # Node count validated for the launch profile. (format: int32)
  --trainerShardingScheme: record # Structured parallelism/sharding profile used by trainer launches. — shape: {tensorParallelism?: int, pipelineParallelism?: int, contextParallelism?: int, expertParallelism?: int, sequenceParallelism?: bool}
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --acceleratorCount: int # Total number of accelerators used by the job. (format: int32)
  --baseModelWeightPrecision: string@baseModelWeightPrecision-completer # The weight precision for model training/inference.   - BFLOAT16: no quantization applied  - INT8: enable 8-bit quantization with LLM.int8()  - NF4: enable 4-bit quantization with LLM.nf4()  - FP8: base model quantization in FP8  - FP4_FP8: base model linear module quantization in FP4, mixed with experts and some special keys/layers in FP8. (default: WEIGHT_PRECISION_UNSPECIFIED)
  --maxSupportedContextLength: int # Capacity limits validated for this shape. (format: int32)
]: any -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "trainingShapeId" $trainingShapeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes" $qp)
  let body = {displayName: $displayName, description: $description, baseModel: $baseModel, deploymentShapeVersion: $deploymentShapeVersion, trainerImageTag: $trainerImageTag, trainerMode: $trainerMode, nodeCount: $nodeCount, trainerShardingScheme: $trainerShardingScheme, acceleratorType: $acceleratorType, acceleratorCount: $acceleratorCount, baseModelWeightPrecision: $baseModelWeightPrecision, maxSupportedContextLength: $maxSupportedContextLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Training Shape
#
# GET /v1/accounts/{account_id}/trainingShapes/{training_shape_id}
# operationId: Gateway_GetTrainingShape
export def "accounts-training-shapes GetTrainingShape" [
  account_id: string
  training_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Training Shape
#
# PATCH /v1/accounts/{account_id}/trainingShapes/{training_shape_id}
# operationId: Gateway_UpdateTrainingShape
# --trainerShardingScheme shape: {tensorParallelism?: int, pipelineParallelism?: int, contextParallelism?: int, expertParallelism?: int, sequenceParallelism?: bool}
export def "accounts-training-shapes UpdateTrainingShape" [
  account_id: string
  training_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human-readable display name of the training shape. e.g. "Llama3 70B H200 BF16" Must be fewer than 64 characters long.
  --description: string # The description of the training shape. Must be fewer than 1000 characters long.
  baseModel: string
  --deploymentShapeVersion: string
  trainerImageTag: string # The validated trainer runtime image tag used for numerics verification.
  --trainerMode: string@trainerMode-completer # Trainer execution mode used for validated launch-profile matching. (default: TRAINER_MODE_UNSPECIFIED)
  --nodeCount: int # Node count validated for the launch profile. (format: int32)
  --trainerShardingScheme: record # Structured parallelism/sharding profile used by trainer launches. — shape: {tensorParallelism?: int, pipelineParallelism?: int, contextParallelism?: int, expertParallelism?: int, sequenceParallelism?: bool}
  --acceleratorType: string@acceleratorType-completer # default: ACCELERATOR_TYPE_UNSPECIFIED
  --acceleratorCount: int # Total number of accelerators used by the job. (format: int32)
  --baseModelWeightPrecision: string@baseModelWeightPrecision-completer # The weight precision for model training/inference.   - BFLOAT16: no quantization applied  - INT8: enable 8-bit quantization with LLM.int8()  - NF4: enable 4-bit quantization with LLM.nf4()  - FP8: base model quantization in FP8  - FP4_FP8: base model linear module quantization in FP4, mixed with experts and some special keys/layers in FP8. (default: WEIGHT_PRECISION_UNSPECIFIED)
  --maxSupportedContextLength: int # Capacity limits validated for this shape. (format: int32)
]: any -> record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)")
  let body = {displayName: $displayName, description: $description, baseModel: $baseModel, deploymentShapeVersion: $deploymentShapeVersion, trainerImageTag: $trainerImageTag, trainerMode: $trainerMode, nodeCount: $nodeCount, trainerShardingScheme: $trainerShardingScheme, acceleratorType: $acceleratorType, acceleratorCount: $acceleratorCount, baseModelWeightPrecision: $baseModelWeightPrecision, maxSupportedContextLength: $maxSupportedContextLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Training Shape
#
# DELETE /v1/accounts/{account_id}/trainingShapes/{training_shape_id}
# operationId: Gateway_DeleteTrainingShape
export def "accounts-training-shapes DeleteTrainingShape" [
  account_id: string
  training_shape_id: string
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
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Training Shapes Versions
#
# GET /v1/accounts/{account_id}/trainingShapes/{training_shape_id}/versions
# operationId: Gateway_ListTrainingShapeVersions
export def "accounts-training-shapes-versions ListTrainingShapeVersions" [
  account_id: string
  training_shape_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of versions to return. Max page_size is 200; values above 200 are coerced. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token from a previous ListTrainingShapeVersions call.
  --filter: string # Filter per AIP-160.
  --orderBy: string # Order by fields, default "create_time".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<trainingShapeVersions: table<name: string, createTime: string, snapshot: record, validated: bool, public: bool, latestValidated: bool, updateTime: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Training Shape Version
#
# GET /v1/accounts/{account_id}/trainingShapes/{training_shape_id}/versions/{version_id}
# operationId: Gateway_GetTrainingShapeVersion
export def "accounts-training-shapes-versions GetTrainingShapeVersion" [
  account_id: string
  training_shape_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, createTime: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int>, validated: bool, public: bool, latestValidated: bool, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)/versions/($version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Training Shape Version
#
# PATCH /v1/accounts/{account_id}/trainingShapes/{training_shape_id}/versions/{version_id}
# operationId: Gateway_UpdateTrainingShapeVersion
# --snapshot shape: {displayName?: string, description?: string, baseModel: string, deploymentShapeVersion?: string, trainerImageTag: string, trainerMode?: "TRAINER_MODE_UNSPECIFIED"|"POLICY_TRAINER"|"FORWARD_ONLY"|"LORA_TRAINER", nodeCount?: int, trainerShardingScheme?: record, acceleratorType?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_A100_80GB"|"NVIDIA_H100_80GB"|"AMD_MI300X_192GB"|"NVIDIA_A10G_24GB"|"NVIDIA_A100_40GB"|"NVIDIA_L4_24GB"|"NVIDIA_H200_141GB"|"NVIDIA_B200_180GB"|"AMD_MI325X_256GB"|"AMD_MI350X_288GB"|"NVIDIA_B300_288GB", acceleratorCount?: int, baseModelWeightPrecision?: "WEIGHT_PRECISION_UNSPECIFIED"|"BFLOAT16"|"INT8"|"NF4"|"FP8"|"FP4_FP8", maxSupportedContextLength?: int}
export def "accounts-training-shapes-versions UpdateTrainingShapeVersion" [
  account_id: string
  training_shape_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot: record # shape: {displayName?: string, description?: string, baseModel: string, deploymentShapeVersion?: string, trainerImageTag: string, trainerMode?: "TRAINER_MODE_UNSPECIFIED"|"POLICY_TRAINER"|"FORWARD_ONLY"|"LORA_TRAINER", nodeCount?: int, trainerShardingScheme?: record, acceleratorType?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_A100_80GB"|"NVIDIA_H100_80GB"|"AMD_MI300X_192GB"|"NVIDIA_A10G_24GB"|"NVIDIA_A100_40GB"|"NVIDIA_L4_24GB"|"NVIDIA_H200_141GB"|"NVIDIA_B200_180GB"|"AMD_MI325X_256GB"|"AMD_MI350X_288GB"|"NVIDIA_B300_288GB", acceleratorCount?: int, baseModelWeightPrecision?: "WEIGHT_PRECISION_UNSPECIFIED"|"BFLOAT16"|"INT8"|"NF4"|"FP8"|"FP4_FP8", maxSupportedContextLength?: int}
  --validated: oneof<nothing, bool> # Whether this version has been validated through capacity tests. Only superusers can set this flag.
  --public: oneof<nothing, bool> # If true, this version will be publicly readable.
]: any -> record<name: string, createTime: string, snapshot: record<name: string, displayName: string, description: string, createTime: string, updateTime: string, baseModel: string, deploymentShapeVersion: string, trainerImageTag: string, trainerMode: string, nodeCount: int, trainerShardingScheme: record<tensorParallelism: int, pipelineParallelism: int, contextParallelism: int, expertParallelism: int, sequenceParallelism: bool>, modelType: string, parameterCount: string, acceleratorType: string, acceleratorCount: int, baseModelWeightPrecision: string, maxSupportedContextLength: int>, validated: bool, public: bool, latestValidated: bool, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/trainingShapes/($training_shape_id)/versions/($version_id)")
  let body = {snapshot: $snapshot, validated: $validated, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Users
#
# GET /v1/accounts/{account_id}/users
# operationId: Gateway_ListUsers
export def "accounts-users ListUsers" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The maximum number of users to return. The maximum page_size is 200, values above 200 will be coerced to 200. If unspecified, the default is 50. (format: int32)
  --pageToken: string # A page token, received from a previous ListUsers call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListUsers must match the call that provided the page token.
  --filter: string # Only users satisfying the provided filter (if specified) will be returned. See https://google.aip.dev/160 for the filter grammar.
  --orderBy: string # A comma-separated list of fields to order by. e.g. "foo,bar" The default sort order is ascending. To specify a descending order for a field, append a " desc" suffix. e.g. "foo desc,bar" Subfields are specified with a "." character. e.g. "foo.bar" If not specified, the default order is by "name".
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<users: table<name: string, displayName: string, serviceAccount: bool, createTime: string, role: string, email: string, state: string, status: record, updateTime: string, permissionPreset: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User
#
# POST /v1/accounts/{account_id}/users
# operationId: Gateway_CreateUser
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-users CreateUser" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # The user ID to use in the user name. e.g. my-user If not specified, a default ID is generated from user.email.
  --displayName: string # Human-readable display name of the user. e.g. "Alice" Must be fewer than 64 characters long.
  --serviceAccount: oneof<nothing, bool>
  role: string # The user's role: admin, user, contributor, inference-user, or custom. When set to "custom", the user's permissions are governed by permission_preset.
  --email: string # The user's email address.
  --state: string@state-completer-7 # default: STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --permissionPreset: string # The permission preset for this user. Only valid when role is "custom".
]: any -> record<name: string, displayName: string, serviceAccount: bool, createTime: string, role: string, email: string, state: string, status: record<code: string, message: string>, updateTime: string, permissionPreset: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users" $qp)
  let body = {displayName: $displayName, serviceAccount: $serviceAccount, role: $role, email: $email, state: $state, status: $status, permissionPreset: $permissionPreset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get User
#
# GET /v1/accounts/{account_id}/users/{user_id}
# operationId: Gateway_GetUser
export def "accounts-users GetUser" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<name: string, displayName: string, serviceAccount: bool, createTime: string, role: string, email: string, state: string, status: record<code: string, message: string>, updateTime: string, permissionPreset: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User
#
# PATCH /v1/accounts/{account_id}/users/{user_id}
# operationId: Gateway_UpdateUser
# --status shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
export def "accounts-users UpdateUser" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human-readable display name of the user. e.g. "Alice" Must be fewer than 64 characters long.
  --serviceAccount: oneof<nothing, bool>
  role: string # The user's role: admin, user, contributor, inference-user, or custom. When set to "custom", the user's permissions are governed by permission_preset.
  --email: string # The user's email address.
  --state: string@state-completer-7 # default: STATE_UNSPECIFIED
  --status: record # shape: {code?: "OK"|"CANCELLED"|"UNKNOWN"|"INVALID_ARGUMENT"|"DEADLINE_EXCEEDED"|"NOT_FOUND"|"ALREADY_EXISTS"|"PERMISSION_DENIED"|"UNAUTHENTICATED"|"RESOURCE_EXHAUSTED"|"FAILED_PRECONDITION"|"ABORTED"|"OUT_OF_RANGE"|"UNIMPLEMENTED"|"INTERNAL"|"UNAVAILABLE"|"DATA_LOSS", message?: string}
  --permissionPreset: string # The permission preset for this user. Only valid when role is "custom".
]: any -> record<name: string, displayName: string, serviceAccount: bool, createTime: string, role: string, email: string, state: string, status: record<code: string, message: string>, updateTime: string, permissionPreset: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)")
  let body = {displayName: $displayName, serviceAccount: $serviceAccount, role: $role, email: $email, state: $state, status: $status, permissionPreset: $permissionPreset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API Keys
#
# GET /v1/accounts/{account_id}/users/{user_id}/apiKeys
# operationId: Gateway_ListApiKeys
export def "accounts-users-api-keys ListApiKeys" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Number of API keys to return in the response. Pagination support to be added. (format: int32)
  --pageToken: string # Token for fetching the next page of results. Pagination support to be added.
  --filter: string # Field for filtering results.
  --orderBy: string # Field for ordering results.
  --readMask: string # The fields to be returned in the response. If empty or "*", all fields will be returned.
]: nothing -> record<apiKeys: table<keyId: string, displayName: string, key: string, createTime: string, secure: bool, email: string, prefix: string, expireTime: string, annotations: record, lastUsed: string>, nextPageToken: string, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)/apiKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API Key
#
# POST /v1/accounts/{account_id}/users/{user_id}/apiKeys
# operationId: Gateway_CreateApiKey
# --apiKey shape: {displayName?: string, expireTime?: string, annotations?: record}
export def "accounts-users-api-keys CreateApiKey" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  apiKey: record # shape: {displayName?: string, expireTime?: string, annotations?: record}
]: any -> record<keyId: string, displayName: string, key: string, createTime: string, secure: bool, email: string, prefix: string, expireTime: string, annotations: record, lastUsed: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)/apiKeys")
  let body = {apiKey: $apiKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get API Key
#
# GET /v1/accounts/{account_id}/users/{user_id}/apiKeys/accounts/{account_id}/users/{user_id}
# operationId: Gateway_GetApiKey
export def "accounts-users-api-keys-accounts-users GetApiKey" [
  keyId: string
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keyId: string, displayName: string, key: string, createTime: string, secure: bool, email: string, prefix: string, expireTime: string, annotations: record, lastUsed: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)/apiKeys/accounts/{account_id}/users/{user_id}")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete API Key
#
# POST /v1/accounts/{account_id}/users/{user_id}/apiKeys:delete
# operationId: Gateway_DeleteApiKey
export def "accounts-users-api-keys-delete DeleteApiKey" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  keyId: string # The key ID for the API key.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/users/($user_id)/apiKeys:delete")
  let body = {keyId: $keyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Similar to preview evaluation, but no need to create the evaluation entry first.
#
# POST /v1/accounts/{account_id}:testeval
# operationId: Gateway_TestEvaluation
# --evaluation shape: {status?: record, evaluationType: string, description?: string, providers: list, assertions: list}
export def "accounts TestEvaluation" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluation: record # shape: {status?: record, evaluationType: string, description?: string, providers: list, assertions: list}
  sampleData: string
]: any -> record<results: table<success: bool, reason: string, score: float, messages: list, metrics: record>, totalSamples: int, totalRuntimeMs: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id):testeval")
  let body = {evaluation: $evaluation, sampleData: $sampleData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload Dataset Files
#
# POST /v1/accounts/{account_id}/datasets/{dataset_id}:upload
# operationId: Gateway_UploadDatasetFile
export def "accounts-datasets UploadDatasetFile" [
  account_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<id: string, object: string, bytes: int, created_at: int, filename: string, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai")
  let full_url = (build-url $base $"/v1/accounts/($account_id)/datasets/($dataset_id):upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create Response
#
# POST /v1/responses
# operationId: create_response_v1_responses_post
export def "responses post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # The model to use for generating the response. Example: `accounts/<ACCOUNT_ID>/models/<MODEL_ID>`.
  input: any # The input to the model. Can be a simple text string or a list of message objects for complex inputs with multiple content types.
  --previous-response-id: any # The ID of a previous response to continue the conversation from. When provided, the conversation history from that response will be automatically loaded.
  --instructions: any # System instructions that guide the model's behavior throughout the conversation. Similar to a system message.
  --max-output-tokens: any # The maximum number of tokens that can be generated in the response. Must be at least 1. If not specified, the model will generate up to its maximum context length.
  --max-tool-calls: any # The maximum number of tool calls allowed in a single response. Useful for controlling costs and limiting tool execution. Must be at least 1.
  --metadata: any # Set of up to 16 key-value pairs that can be attached to the response. Useful for storing additional information in a structured format.
  --parallel-tool-calls: any # Whether to enable parallel function calling during tool use. When true, the model can call multiple tools simultaneously. Default is True. (default: true)
  --reasoning: any # Configuration for reasoning output. When enabled, the model will return its reasoning process along with the response.
  --store: any # Whether to store the response. When set to false, the response will not be stored and will not be retrievable via the API. This is useful for ephemeral or sensitive data. See an example in our [Controlling Response Storage cookbook](https://github.com/fw-ai/cookbook/blob/main/learn/response-api/mcp_server_with_store_false_argument.ipynb). Default is True. (default: true)
  --stream: any # Whether to stream the response back as Server-Sent Events (SSE). When true, tokens are sent incrementally as they are generated. Default is False. (default: false)
  --temperature: any # The sampling temperature to use, between 0 and 2. Higher values like 0.8 make output more random, while lower values like 0.2 make it more focused and deterministic. Default is 1.0. (default: 1)
  --text: any # Text generation configuration parameters. Used for advanced text generation settings.
  --tool-choice: any # Controls which (if any) tool the model should use. Can be 'none' (never call tools), 'auto' (model decides), 'required' (must call at least one tool), or an object specifying a particular tool to call. Default is 'auto'. (default: auto)
  --tools: any # A list of MCP tools the model may call. See our cookbooks for examples on [basic MCP usage](https://github.com/fw-ai/cookbook/blob/main/learn/response-api/fireworks_mcp_examples.ipynb) and [streaming with MCP](https://github.com/fw-ai/cookbook/blob/main/learn/response-api/fireworks_mcp_with_streaming.ipynb).
  --top-p: any # An alternative to temperature sampling, called nucleus sampling, where the model considers the results of tokens with top_p probability mass. So 0.1 means only tokens comprising the top 10% probability mass are considered. Default is 1.0. We generally recommend altering this or temperature but not both. (default: 1)
  --truncation: any # The truncation strategy to use for the context when it exceeds the model's maximum length. Can be 'auto' (automatically truncate) or 'disabled' (return error if context too long). Default is 'disabled'. (default: disabled)
  --user: any # A unique identifier representing your end-user, which can help Fireworks to monitor and detect abuse. This can be a username, email, or any other unique identifier.
]: any -> record<id: any, object: string, created_at: int, status: string, model: string, output: list<any>, previous_response_id: any, usage: any, error: any, incomplete_details: any, instructions: any, max_output_tokens: any, max_tool_calls: any, parallel_tool_calls: bool, reasoning: any, store: any, temperature: float, text: any, tool_choice: any, tools: list<record>, top_p: float, truncation: string, user: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base "/v1/responses")
  let body = {model: $model, input: $input, previous_response_id: $previous_response_id, instructions: $instructions, max_output_tokens: $max_output_tokens, max_tool_calls: $max_tool_calls, metadata: $metadata, parallel_tool_calls: $parallel_tool_calls, reasoning: $reasoning, store: $store, stream: $stream, temperature: $temperature, text: $text, tool_choice: $tool_choice, tools: $tools, top_p: $top_p, truncation: $truncation, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Responses
#
# GET /v1/responses
# operationId: list_responses_v1_responses_get
export def "responses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20
  --after: string
  --before: string
]: nothing -> record<object: string, data: table<id: any, object: string, created_at: int, status: string, model: string, output: list, previous_response_id: any, usage: any, error: any, incomplete_details: any, instructions: any, max_output_tokens: any, max_tool_calls: any, parallel_tool_calls: bool, reasoning: any, store: any, temperature: float, text: any, tool_choice: any, tools: list, top_p: float, truncation: string, user: any, metadata: any>, has_more: bool, first_id: any, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Response
#
# GET /v1/responses/{response_id}
# operationId: get_response_v1_responses__response_id__get
export def "responses get" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: any, object: string, created_at: int, status: string, model: string, output: list<any>, previous_response_id: any, usage: any, error: any, incomplete_details: any, instructions: any, max_output_tokens: any, max_tool_calls: any, parallel_tool_calls: bool, reasoning: any, store: any, temperature: float, text: any, tool_choice: any, tools: list<record>, top_p: float, truncation: string, user: any, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base $"/v1/responses/($response_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Response
#
# DELETE /v1/responses/{response_id}
# operationId: delete_response_v1_responses__response_id__delete
export def "responses delete" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base $"/v1/responses/($response_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Completion
#
# POST /v1/completions
# operationId: create_completion_v1_completions_post
export def "completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  model: string # The name of the model to use.  Example: `"accounts/fireworks/models/kimi-k2-instruct-0905"`
  --user: any # A unique identifier representing your end-user, which can help monitor and detect abuse.
  --prompt-cache-key: any # A key used for prompt caching session affinity. Requests with the same prompt_cache_key are routed to the same backend to maximize KV cache hit rates. This is the preferred field for session affinity (takes priority over the 'user' field).
  --prompt-cache-isolation-key: any # Isolation key for prompt caching to separate cache entries.
  --raw-output: any # Return raw output from the model. (default: false)
  --perf-metrics-in-response: any # Whether to include performance metrics in the response body.  **Non-streaming requests:** Performance metrics are always included in response headers (e.g., `fireworks-prompt-tokens`, `fireworks-server-time-to-first-token`). Setting this to `true` additionally includes the same metrics in the response body under the `perf_metrics` field.  **Streaming requests:** Performance metrics are only included in the response body under the `perf_metrics` field in the final chunk (when `finish_reason` is set). This is because headers may not be accessible during streaming.  The response body `perf_metrics` field contains the following metrics:  **Basic Metrics (all deployments):**  - `prompt-tokens`: Number of tokens in the prompt - `cached-prompt-tokens`: Number of cached prompt tokens - `server-time-to-first-token`: Time from request start to first token (in seconds) - `server-processing-time`: Total processing time (in seconds, only for completed requests)  **Predicted Outputs Metrics:**  - `speculation-prompt-tokens`: Number of speculative prompt tokens - `speculation-prompt-matched-tokens`: Number of matched speculative prompt tokens (for completed requests)  **Dedicated Deployment Only Metrics:**  - `speculation-generated-tokens`: Number of speculative generated tokens (for completed requests) - `speculation-acceptance`: Speculation acceptance rates by position - `backend-host`: Hostname of the backend server - `num-concurrent-requests`: Number of concurrent requests - `deployment`: Deployment name - `tokenizer-queue-duration`: Time spent in tokenizer queue - `tokenizer-duration`: Time spent in tokenizer - `prefill-queue-duration`: Time spent in prefill queue - `prefill-duration`: Time spent in prefill - `generation-queue-duration`: Time spent in generation queue - `generation-duration`: Time spent in generation (default: false)
  --stream: any # Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (default: false)
  --n: int # How many completions to generate for each prompt.  **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`.  Required range: `1 <= x <= 128`  Example: `1` (default: 1)
  --service-tier: string@service-tier-completer # The service tier to use for the request. Specifies the processing type used for serving the request. Only "priority" is supported, while all other values will be treated as "default" tier. (default: default)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will NOT contain the stop sequence.
  --max-tokens: any # The maximum number of tokens to generate in the completion. If the token count of your prompt plus max_tokens exceeds the model's context length, the behavior depends on context_length_exceeded_behavior. By default, max_tokens will be lowered to fit in the context window instead of returning an error.
  --max-completion-tokens: any # Alias for max_tokens. Cannot be specified together with max_tokens.
  --temperature: any # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  We generally recommend altering this or top_p but not both.  Required range: `0 <= x <= 2`  Example: `1`
  --top-k: any # Top-k sampling is another sampling method where the k most probable next tokens are filtered and the probability mass is redistributed among only those k next tokens. The value of k controls the number of candidates for the next token at each step during text generation. Must be between 0 and 100.  Required range: `0 <= x <= 100`  Example: `50`
  --top-p: any # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.  We generally recommend altering this or temperature but not both.  Required range: `0 <= x <= 1`  Example: `1`
  --min-p: any # Minimum probability threshold for token selection. Only tokens with probability >= min_p are considered for selection. This is an alternative to `top_p` and `top_k` sampling.  Required range: `0 <= x <= 1`
  --typical-p: any # Typical-p sampling is an alternative to nucleus sampling. It considers the most typical tokens whose cumulative probability is at most typical_p.  Required range: `0 <= x <= 1`
  --frequency-penalty: any # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.  Reasonable value is around 0.1 to 1 if the aim is to just reduce repetitive samples somewhat. If the aim is to strongly suppress repetition, then one can increase the coefficients up to 2, but this can noticeably degrade the quality of samples. Negative values can be used to increase the likelihood of repetition.  See also `presence_penalty` for penalizing tokens that have at least one appearance at a fixed rate.  OpenAI compatible (follows OpenAI's conventions for handling token frequency and repetition penalties).  Required range: `-2 <= x <= 2`
  --presence-penalty: any # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.  Reasonable value is around 0.1 to 1 if the aim is to just reduce repetitive samples somewhat. If the aim is to strongly suppress repetition, then one can increase the coefficients up to 2, but this can noticeably degrade the quality of samples. Negative values can be used to increase the likelihood of repetition.  See also `frequency_penalty` for penalizing tokens at an increasing rate depending on how often they appear.  OpenAI compatible (follows OpenAI's conventions for handling token frequency and repetition penalties).  Required range: `-2 <= x <= 2`
  --repetition-penalty: any # Applies a penalty to repeated tokens to discourage or encourage repetition. A value of `1.0` means no penalty, allowing free repetition. Values above `1.0` penalize repetition, reducing the likelihood of repeating tokens. Values between `0.0` and `1.0` reward repetition, increasing the chance of repeated tokens. For a good balance, a value of `1.2` is often recommended. Note that the penalty is applied to both the generated output and the prompt in decoder-only models.  Required range: `0 <= x <= 2`
  --mirostat-target: any # Defines the target perplexity for the Mirostat algorithm. Perplexity measures the unpredictability of the generated text, with higher values encouraging more diverse and creative outputs, while lower values prioritize predictability and coherence. The algorithm dynamically adjusts the token selection to maintain this target during text generation.  If not specified, Mirostat sampling is disabled.
  --mirostat-lr: any # Specifies the learning rate for the Mirostat sampling algorithm, which controls how quickly the model adjusts its token distribution to maintain the target perplexity. A smaller value slows down the adjustments, leading to more stable but gradual shifts, while higher values speed up corrections at the cost of potential instability.
  --seed: any # Random seed for deterministic sampling.
  --logprobs: any # Include log probabilities in the response. This accepts either a boolean or an integer:  If set to `true`, log probabilities are included and the number of alternatives can be controlled via `top_logprobs` (OpenAI-compatible behavior).  If set to an integer N (0-5), include log probabilities for up to N most likely tokens per position in the legacy format.  The API will always return the logprob of the sampled token, so there may be up to `logprobs+1` elements in the response when an integer is used. The maximum value for the integer form is 5.
  --top-logprobs: any # An integer between 0 and 5 specifying the number of most likely tokens to return at each token position, each with an associated log probability. The minimum value is 0 and the maximum value is 5.  When `logprobs` is set, `top_logprobs` can be used to modify how many top log probabilities are returned. If `top_logprobs` is not set, the API will return up to `logprobs` tokens per position.  Required range: `0 <= x <= 5`
  --echo: any # Echo back the prompt in addition to the completion. (default: false)
  --echo-last: any # Echo back the last N tokens of the prompt in addition to the completion. This is useful for obtaining logprobs of the prompt suffix but without transferring too much data. Passing `echo_last=len(prompt)` is the same as `echo=True`
  --ignore-eos: oneof<nothing, bool> # This setting controls whether the model should ignore the End of Sequence (EOS) token. When set to `True`, the model will continue generating tokens even after the EOS token is produced. By default, it stops when the EOS token is reached. (default: false)
  --context-length-exceeded-behavior: string@context-length-exceeded-behavior-completer # What to do if the token count of prompt plus `max_tokens` exceeds the model's context window.  Passing `truncate` limits the `max_tokens` to at most `context_window_length - prompt_length`. This is the default.  Passing `error` would trigger a request error.  The default of `'truncate'` is selected as it allows to ask for high `max_tokens` value while respecting the context window length without having to do client-side prompt tokenization.  Note, that it differs from OpenAI's behavior that matches that of `error`. (default: truncate)
  --response-format: any # Allows to force the model to produce specific output format.  Setting to `{ "type": "json_object" }` enables JSON mode, which guarantees the message the model generates is valid JSON.  If `"type"` is `"json_schema"`, a JSON schema must be provided. E.g., `response_format = {"type": "json_schema", "json_schema": <json_schema>}`.  Important: when using JSON mode, it's crucial to also instruct the model to produce JSON via a system or user message. Without this, the model may generate an unending stream of whitespace until the generation reaches the token limit, resulting in a long-running and seemingly "stuck" request.  Also note that the message content may be partially cut off if `finish_reason="length"`, which indicates the generation exceeded `max_tokens` or the conversation exceeded the max context length. In this case the return value might not be a valid JSON.
  --logit-bias: any # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling.
  --speculation: any # Speculative decoding prompt or token IDs to speed up generation.
  --prediction: any # OpenAI-compatible predicted output for speculative decoding. Can be a PredictedOutput object or a simple string. Automatically transformed to speculation.
  --metadata: any # Additional metadata to store with the request for tracing/distillation.
  --reasoning-effort: any # Controls reasoning behavior for supported models. When enabled, the model's reasoning appears in the `reasoning_content` field of the response, separate from the final answer in `content`.  **Accepted values:**  - **String** (OpenAI-compatible): `'low'`, `'medium'`, `'high'`, or `'max'` to enable reasoning with varying effort levels; `'none'` to disable reasoning. - **Boolean** (Fireworks extension): `true` to enable reasoning, `false` to disable it. - **Integer** (Fireworks extension): A positive integer to set a hard token limit on reasoning output. Integer values enable the model's normal medium-style thinking behavior and force the model to end its thinking phase after at most that many generated thinking tokens.  **Important:** Boolean values are normalized internally: `true` becomes `'medium'`, and `false` becomes `'none'`. This normalization happens before model-specific validation, so if a model doesn't support `'none'`, passing `false` will produce an error referencing `'none'`.  **Model-specific behavior:**  - **Qwen3 (e.g., Qwen3-8B)**: Grammar-based reasoning. Default reasoning on. Use `'none'` or `false` to disable. Supports integer token limits to cap reasoning output. `'low'`, `'medium'`, and `'high'` keep their model-specific behavior and are not hard budgets. - **MiniMax M2**: Reasoning is required (always on). Defaults to `'medium'` when omitted. Accepts only string `reasoning_effort`: `'low'`, `'medium'`, or `'high'`. `'none'` and boolean values are rejected. - **DeepSeek V3.1**: Binary on/off reasoning. Default reasoning off (matches chat template). Use `true`, `'low'`, `'medium'`, or `'high'` to enable; `'none'` or `false` to disable. - **DeepSeek V3.2**: Binary on/off reasoning. Default reasoning on. Use `'none'` or `false` to disable; effort levels and integers have no additional effect. - **DeepSeek V4**: Accepts `'none'`, `'low'`, `'medium'`, `'high'`, `'xhigh'`, and `'max'`. Default reasoning on (`'high'`). `'xhigh'` is silently promoted to `'max'`. `'max'` prepends a thorough-reasoning preamble; `'high'` enables thinking. `'low'` and `'medium'` are silently promoted to `'high'`. `'none'` or `false` disables thinking. - **GLM 4.5, GLM 4.5 Air, GLM 4.6, GLM 4.7**: Binary on/off reasoning. Default reasoning on. Use `'none'` or `false` to disable; effort levels and integers have no additional effect. - **Harmony (OpenAI GPT-OSS 120B, GPT-OSS 20B)**: Accepts only `'low'`, `'medium'`, or `'high'`. Does not support `'none'`, `false`, or integer values — using these will return an error (e.g., "Invalid reasoning effort: none"). When omitted, defaults to `'medium'`. Lower effort produces faster responses with shorter reasoning.
  --reasoning-history: any # Controls how historical assistant reasoning content is included in the prompt for multi-turn conversations.  **Accepted values:**  - `null`: Use model/template default behavior (for **GLM-4.7**, the model/template default is `'interleaved'`, i.e. historical reasoning is cleared by default) - `'disabled'`: Strip `reasoning_content` from all messages before prompt construction - `'interleaved'`: Strip `reasoning_content` from messages up to (and including) the last user message - `'preserved'`: Preserve historical `reasoning_content` across the conversation  **Model support:**  | Model | Default | Supported values | | --- | --- | --- | | Kimi K2.6 | `'interleaved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | Kimi K2 Instruct | `'preserved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | MiniMax M2 | `'interleaved'` | `'disabled'`, `'interleaved'` | | GLM-4.7 | `'interleaved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | GLM-4.6 | `'interleaved'` | `'disabled'`, `'interleaved'` | | Qwen 3.6 | `'preserved'` | `'disabled'`, `'preserved'` | | DeepSeek V4 | `'interleaved'` | `'interleaved'` |  For other models, refer to the model provider's documentation.  **Note:** This parameter controls prompt formatting only. To disable reasoning computation entirely, use `reasoning_effort='none'`.
  --thinking: any # Configuration for enabling extended thinking (Anthropic-compatible format). This is an alternative to `reasoning_effort` for controlling reasoning behavior.  **Format:**  - `{"type": "enabled"}` - Enable thinking (equivalent to `reasoning_effort: true`) - `{"type": "enabled", "budget_tokens": <int>}` - Enable thinking with a token budget (equivalent to `reasoning_effort: <int>`). Must be >= 1024. - `{"type": "enabled", "keep": "all"}` - Enable thinking and preserve all historical reasoning content in the prompt (equivalent to `reasoning_history: "preserved"`). - `{"type": "disabled"}` - Disable thinking (equivalent to `reasoning_effort: "none"`)  **Note:** Cannot be specified together with `reasoning_effort`. If both are provided, a validation error will be raised.
  --return-token-ids: any # Return token IDs alongside text to avoid retokenization drift. (default: false)
  prompt: any # The prompt to generate completions for.  It can be a single string or an array of strings.  It can also be an array of integers or an array of integer arrays, which allows to pass already tokenized prompt.  If multiple prompts are specified, several choices with corresponding `index` will be returned in the output.
  --images: any # The list of base64 encoded images for visual language completition generation.  They should be formatted as MIME_TYPE,<base64 encoded str>  eg. data:image/jpeg;base64,<base64 encoded str>  Additionally, the number of images provided should match the number of '<image>' special token in the prompt
]: any -> record<id: string, object: string, created: int, model: string, choices: table<index: int, text: string, logprobs: any, finish_reason: any, raw_output: any, prompt_token_ids: any, token_ids: any>, usage: record<prompt_tokens: int, total_tokens: int, completion_tokens: any, prompt_tokens_details: any>, perf_metrics: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base "/v1/completions")
  let body = {model: $model, user: $user, prompt_cache_key: $prompt_cache_key, prompt_cache_isolation_key: $prompt_cache_isolation_key, raw_output: $raw_output, perf_metrics_in_response: $perf_metrics_in_response, stream: $stream, n: $n, service_tier: $service_tier, stop: $stop, max_tokens: $max_tokens, max_completion_tokens: $max_completion_tokens, temperature: $temperature, top_k: $top_k, top_p: $top_p, min_p: $min_p, typical_p: $typical_p, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, repetition_penalty: $repetition_penalty, mirostat_target: $mirostat_target, mirostat_lr: $mirostat_lr, seed: $seed, logprobs: $logprobs, top_logprobs: $top_logprobs, echo: $echo, echo_last: $echo_last, ignore_eos: $ignore_eos, context_length_exceeded_behavior: $context_length_exceeded_behavior, response_format: $response_format, logit_bias: $logit_bias, speculation: $speculation, prediction: $prediction, metadata: $metadata, reasoning_effort: $reasoning_effort, reasoning_history: $reasoning_history, thinking: $thinking, return_token_ids: $return_token_ids, prompt: $prompt, images: $images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Chat Completion
#
# POST /v1/chat/completions
# operationId: create_chat_completion_v1_chat_completions_post
# --messages item shape: {role: string, content?: any, reasoning_content?: any, tool_calls?: any, tool_call_id?: any}
# --tools item shape: {type: "function", function?: any}
# --functions item shape: {name: string, description?: any, parameters?: record, strict?: any}
@deprecated --flag functions
@deprecated --flag function-call
export def "chat-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  model: string # The name of the model to use.  Example: `"accounts/fireworks/models/kimi-k2-instruct-0905"`
  messages: list # A list of messages comprising the conversation so far. — item shape: {role: string, content?: any, reasoning_content?: any, tool_calls?: any, tool_call_id?: any}
  --tools: list # A list of tools the model may call. Currently, only functions are supported as a tool.  Use this to provide a list of functions the model may generate JSON inputs for.  See the our [model library](https://app.fireworks.ai/models/?filter=LLM&functionCalling=true) for the list of supported models — item shape: {type: "function", function?: any}
  --tool-choice: any # Controls which (if any) tool is called by the model.  - `none`: the model will not call any tool and instead generates a message. - `auto`: the model can pick between generating a message or calling one or more tools. - `required` (alias: `any`): the model must call one or more tools.   To force a specific function, pass an object of the form `{ "type": "function", "name": "my_function" }` or `{ "type": "function", "function": { "name": "my_function" } }` for OpenAI compatibility. (default: auto)
  --stream: any # Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (default: false)
  --response-format: any # Allows to force the model to produce specific output format.  Setting to `{ "type": "json_object" }` enables JSON mode, which guarantees the message the model generates is valid JSON.  If `"type"` is `"json_schema"`, a JSON schema must be provided. E.g., `response_format = {"type": "json_schema", "json_schema": <json_schema>}`.  Important: when using JSON mode, it's crucial to also instruct the model to produce JSON via a system or user message. Without this, the model may generate an unending stream of whitespace until the generation reaches the token limit, resulting in a long-running and seemingly "stuck" request.  Also note that the message content may be partially cut off if `finish_reason="length"`, which indicates the generation exceeded `max_tokens` or the conversation exceeded the max context length. In this case the return value might not be a valid JSON.
  --temperature: any # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  We generally recommend altering this or top_p but not both.  Required range: `0 <= x <= 2`  Example: `1`
  --top-k: any # Top-k sampling is another sampling method where the k most probable next tokens are filtered and the probability mass is redistributed among only those k next tokens. The value of k controls the number of candidates for the next token at each step during text generation. Must be between 0 and 100.  Required range: `0 <= x <= 100`  Example: `50`
  --user: any # A unique identifier representing your end-user, which can help monitor and detect abuse.
  --prompt-cache-key: any # A key used for prompt caching session affinity. Requests with the same prompt_cache_key are routed to the same backend to maximize KV cache hit rates. This is the preferred field for session affinity (takes priority over the 'user' field).
  --prompt-cache-isolation-key: any # Isolation key for prompt caching to separate cache entries.
  --raw-output: any # Return raw output from the model. (default: false)
  --perf-metrics-in-response: any # Whether to include performance metrics in the response body.  **Non-streaming requests:** Performance metrics are always included in response headers (e.g., `fireworks-prompt-tokens`, `fireworks-server-time-to-first-token`). Setting this to `true` additionally includes the same metrics in the response body under the `perf_metrics` field.  **Streaming requests:** Performance metrics are only included in the response body under the `perf_metrics` field in the final chunk (when `finish_reason` is set). This is because headers may not be accessible during streaming.  The response body `perf_metrics` field contains the following metrics:  **Basic Metrics (all deployments):**  - `prompt-tokens`: Number of tokens in the prompt - `cached-prompt-tokens`: Number of cached prompt tokens - `server-time-to-first-token`: Time from request start to first token (in seconds) - `server-processing-time`: Total processing time (in seconds, only for completed requests)  **Predicted Outputs Metrics:**  - `speculation-prompt-tokens`: Number of speculative prompt tokens - `speculation-prompt-matched-tokens`: Number of matched speculative prompt tokens (for completed requests)  **Dedicated Deployment Only Metrics:**  - `speculation-generated-tokens`: Number of speculative generated tokens (for completed requests) - `speculation-acceptance`: Speculation acceptance rates by position - `backend-host`: Hostname of the backend server - `num-concurrent-requests`: Number of concurrent requests - `deployment`: Deployment name - `tokenizer-queue-duration`: Time spent in tokenizer queue - `tokenizer-duration`: Time spent in tokenizer - `prefill-queue-duration`: Time spent in prefill queue - `prefill-duration`: Time spent in prefill - `generation-queue-duration`: Time spent in generation queue - `generation-duration`: Time spent in generation (default: false)
  --n: int # How many completions to generate for each prompt.  **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`.  Required range: `1 <= x <= 128`  Example: `1` (default: 1)
  --service-tier: string@service-tier-completer # The service tier to use for the request. Specifies the processing type used for serving the request. Only "priority" is supported, while all other values will be treated as "default" tier. (default: default)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will NOT contain the stop sequence.
  --max-tokens: any # The maximum number of tokens to generate in the completion. If the token count of your prompt plus max_tokens exceeds the model's context length, the behavior depends on context_length_exceeded_behavior. By default, max_tokens will be lowered to fit in the context window instead of returning an error.
  --max-completion-tokens: any # Alias for max_tokens. Cannot be specified together with max_tokens.
  --top-p: any # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.  We generally recommend altering this or temperature but not both.  Required range: `0 <= x <= 1`  Example: `1`
  --min-p: any # Minimum probability threshold for token selection. Only tokens with probability >= min_p are considered for selection. This is an alternative to `top_p` and `top_k` sampling.  Required range: `0 <= x <= 1`
  --typical-p: any # Typical-p sampling is an alternative to nucleus sampling. It considers the most typical tokens whose cumulative probability is at most typical_p.  Required range: `0 <= x <= 1`
  --frequency-penalty: any # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.  Reasonable value is around 0.1 to 1 if the aim is to just reduce repetitive samples somewhat. If the aim is to strongly suppress repetition, then one can increase the coefficients up to 2, but this can noticeably degrade the quality of samples. Negative values can be used to increase the likelihood of repetition.  See also `presence_penalty` for penalizing tokens that have at least one appearance at a fixed rate.  OpenAI compatible (follows OpenAI's conventions for handling token frequency and repetition penalties).  Required range: `-2 <= x <= 2`
  --presence-penalty: any # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.  Reasonable value is around 0.1 to 1 if the aim is to just reduce repetitive samples somewhat. If the aim is to strongly suppress repetition, then one can increase the coefficients up to 2, but this can noticeably degrade the quality of samples. Negative values can be used to increase the likelihood of repetition.  See also `frequency_penalty` for penalizing tokens at an increasing rate depending on how often they appear.  OpenAI compatible (follows OpenAI's conventions for handling token frequency and repetition penalties).  Required range: `-2 <= x <= 2`
  --repetition-penalty: any # Applies a penalty to repeated tokens to discourage or encourage repetition. A value of `1.0` means no penalty, allowing free repetition. Values above `1.0` penalize repetition, reducing the likelihood of repeating tokens. Values between `0.0` and `1.0` reward repetition, increasing the chance of repeated tokens. For a good balance, a value of `1.2` is often recommended. Note that the penalty is applied to both the generated output and the prompt in decoder-only models.  Required range: `0 <= x <= 2`
  --mirostat-target: any # Defines the target perplexity for the Mirostat algorithm. Perplexity measures the unpredictability of the generated text, with higher values encouraging more diverse and creative outputs, while lower values prioritize predictability and coherence. The algorithm dynamically adjusts the token selection to maintain this target during text generation.  If not specified, Mirostat sampling is disabled.
  --mirostat-lr: any # Specifies the learning rate for the Mirostat sampling algorithm, which controls how quickly the model adjusts its token distribution to maintain the target perplexity. A smaller value slows down the adjustments, leading to more stable but gradual shifts, while higher values speed up corrections at the cost of potential instability.
  --seed: any # Random seed for deterministic sampling.
  --logprobs: any # Include log probabilities in the response. This accepts either a boolean or an integer:  If set to `true`, log probabilities are included and the number of alternatives can be controlled via `top_logprobs` (OpenAI-compatible behavior).  If set to an integer N (0-5), include log probabilities for up to N most likely tokens per position in the legacy format.  The API will always return the logprob of the sampled token, so there may be up to `logprobs+1` elements in the response when an integer is used. The maximum value for the integer form is 5.
  --top-logprobs: any # An integer between 0 and 5 specifying the number of most likely tokens to return at each token position, each with an associated log probability. The minimum value is 0 and the maximum value is 5.  When `logprobs` is set, `top_logprobs` can be used to modify how many top log probabilities are returned. If `top_logprobs` is not set, the API will return up to `logprobs` tokens per position.  Required range: `0 <= x <= 5`
  --echo: any # Echo back the prompt in addition to the completion. (default: false)
  --echo-last: any # Echo back the last N tokens of the prompt in addition to the completion. This is useful for obtaining logprobs of the prompt suffix but without transferring too much data. Passing `echo_last=len(prompt)` is the same as `echo=True`
  --ignore-eos: oneof<nothing, bool> # This setting controls whether the model should ignore the End of Sequence (EOS) token. When set to `True`, the model will continue generating tokens even after the EOS token is produced. By default, it stops when the EOS token is reached. (default: false)
  --context-length-exceeded-behavior: string@context-length-exceeded-behavior-completer # What to do if the token count of prompt plus `max_tokens` exceeds the model's context window.  Passing `truncate` limits the `max_tokens` to at most `context_window_length - prompt_length`. This is the default.  Passing `error` would trigger a request error.  The default of `'truncate'` is selected as it allows to ask for high `max_tokens` value while respecting the context window length without having to do client-side prompt tokenization.  Note, that it differs from OpenAI's behavior that matches that of `error`. (default: truncate)
  --logit-bias: any # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling.
  --speculation: any # Speculative decoding prompt or token IDs to speed up generation.
  --prediction: any # OpenAI-compatible predicted output for speculative decoding. Can be a PredictedOutput object or a simple string. Automatically transformed to speculation.
  --metadata: any # Additional metadata to store with the request for tracing/distillation.
  --reasoning-effort: any # Controls reasoning behavior for supported models. When enabled, the model's reasoning appears in the `reasoning_content` field of the response, separate from the final answer in `content`.  **Accepted values:**  - **String** (OpenAI-compatible): `'low'`, `'medium'`, `'high'`, or `'max'` to enable reasoning with varying effort levels; `'none'` to disable reasoning. - **Boolean** (Fireworks extension): `true` to enable reasoning, `false` to disable it. - **Integer** (Fireworks extension): A positive integer to set a hard token limit on reasoning output. Integer values enable the model's normal medium-style thinking behavior and force the model to end its thinking phase after at most that many generated thinking tokens.  **Important:** Boolean values are normalized internally: `true` becomes `'medium'`, and `false` becomes `'none'`. This normalization happens before model-specific validation, so if a model doesn't support `'none'`, passing `false` will produce an error referencing `'none'`.  **Model-specific behavior:**  - **Qwen3 (e.g., Qwen3-8B)**: Grammar-based reasoning. Default reasoning on. Use `'none'` or `false` to disable. Supports integer token limits to cap reasoning output. `'low'`, `'medium'`, and `'high'` keep their model-specific behavior and are not hard budgets. - **MiniMax M2**: Reasoning is required (always on). Defaults to `'medium'` when omitted. Accepts only string `reasoning_effort`: `'low'`, `'medium'`, or `'high'`. `'none'` and boolean values are rejected. - **DeepSeek V3.1**: Binary on/off reasoning. Default reasoning off (matches chat template). Use `true`, `'low'`, `'medium'`, or `'high'` to enable; `'none'` or `false` to disable. - **DeepSeek V3.2**: Binary on/off reasoning. Default reasoning on. Use `'none'` or `false` to disable; effort levels and integers have no additional effect. - **DeepSeek V4**: Accepts `'none'`, `'low'`, `'medium'`, `'high'`, `'xhigh'`, and `'max'`. Default reasoning on (`'high'`). `'xhigh'` is silently promoted to `'max'`. `'max'` prepends a thorough-reasoning preamble; `'high'` enables thinking. `'low'` and `'medium'` are silently promoted to `'high'`. `'none'` or `false` disables thinking. - **GLM 4.5, GLM 4.5 Air, GLM 4.6, GLM 4.7**: Binary on/off reasoning. Default reasoning on. Use `'none'` or `false` to disable; effort levels and integers have no additional effect. - **Harmony (OpenAI GPT-OSS 120B, GPT-OSS 20B)**: Accepts only `'low'`, `'medium'`, or `'high'`. Does not support `'none'`, `false`, or integer values — using these will return an error (e.g., "Invalid reasoning effort: none"). When omitted, defaults to `'medium'`. Lower effort produces faster responses with shorter reasoning.
  --reasoning-history: any # Controls how historical assistant reasoning content is included in the prompt for multi-turn conversations.  **Accepted values:**  - `null`: Use model/template default behavior (for **GLM-4.7**, the model/template default is `'interleaved'`, i.e. historical reasoning is cleared by default) - `'disabled'`: Strip `reasoning_content` from all messages before prompt construction - `'interleaved'`: Strip `reasoning_content` from messages up to (and including) the last user message - `'preserved'`: Preserve historical `reasoning_content` across the conversation  **Model support:**  | Model | Default | Supported values | | --- | --- | --- | | Kimi K2.6 | `'interleaved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | Kimi K2 Instruct | `'preserved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | MiniMax M2 | `'interleaved'` | `'disabled'`, `'interleaved'` | | GLM-4.7 | `'interleaved'` | `'disabled'`, `'interleaved'`, `'preserved'` | | GLM-4.6 | `'interleaved'` | `'disabled'`, `'interleaved'` | | Qwen 3.6 | `'preserved'` | `'disabled'`, `'preserved'` | | DeepSeek V4 | `'interleaved'` | `'interleaved'` |  For other models, refer to the model provider's documentation.  **Note:** This parameter controls prompt formatting only. To disable reasoning computation entirely, use `reasoning_effort='none'`.
  --thinking: any # Configuration for enabling extended thinking (Anthropic-compatible format). This is an alternative to `reasoning_effort` for controlling reasoning behavior.  **Format:**  - `{"type": "enabled"}` - Enable thinking (equivalent to `reasoning_effort: true`) - `{"type": "enabled", "budget_tokens": <int>}` - Enable thinking with a token budget (equivalent to `reasoning_effort: <int>`). Must be >= 1024. - `{"type": "enabled", "keep": "all"}` - Enable thinking and preserve all historical reasoning content in the prompt (equivalent to `reasoning_history: "preserved"`). - `{"type": "disabled"}` - Disable thinking (equivalent to `reasoning_effort: "none"`)  **Note:** Cannot be specified together with `reasoning_effort`. If both are provided, a validation error will be raised.
  --return-token-ids: any # Return token IDs alongside text to avoid retokenization drift. (default: false)
  --functions: list # Deprecated in OpenAI. Use 'tools' instead. This will be automatically transformed to tools. (DEPRECATED) — item shape: {name: string, description?: any, parameters?: record, strict?: any}
  --prompt-truncate-len: any # The size (in tokens) to which to truncate chat prompts. This includes the system prompt (if any), previous user/assistant messages, and the current user message. Earlier user/assistant messages will be evicted first to fit the prompt into this length. The system prompt is preserved whenever possible and only truncated as a last resort.  This should usually be set to a number much smaller << than the model's maximum context size, to allow enough remaining tokens for generating a response.  If omitted, you may receive "prompt too long" errors in your responses as conversations grow. Note that even with this set, you may still receive "prompt too long" errors if individual messages (such as a very long system prompt or user message) exceed the model's context window on their own.
  --parallel-tool-calls: any # Enable parallel function calling.
  --safe-tokenization: any # When true, special tokens in user-provided content are never interpreted as actual special tokens during tokenization. This prevents prompt injection via special token strings (e.g. <|im_start|>, <｜User｜>). Supported for models using Jinja or HuggingFace chat templates with HuggingFace tokenizers. Returns an error if the model does not support it, or if combined with custom_chat_template on HuggingFace-backed models. Note: prompt_truncate_len is not applied when safe_tokenization is enabled.
  --function-call: any # Deprecated in OpenAI. Use 'tool_choice' instead. This will be automatically transformed to tool_choice. (DEPRECATED)
]: any -> record<id: string, object: string, created: int, model: string, choices: table<index: int, message: record, finish_reason: any, logprobs: any, raw_output: any, token_ids: any>, usage: any, perf_metrics: any, prompt_token_ids: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base "/v1/chat/completions")
  let body = {model: $model, messages: $messages, tools: $tools, tool_choice: $tool_choice, stream: $stream, response_format: $response_format, temperature: $temperature, top_k: $top_k, user: $user, prompt_cache_key: $prompt_cache_key, prompt_cache_isolation_key: $prompt_cache_isolation_key, raw_output: $raw_output, perf_metrics_in_response: $perf_metrics_in_response, n: $n, service_tier: $service_tier, stop: $stop, max_tokens: $max_tokens, max_completion_tokens: $max_completion_tokens, top_p: $top_p, min_p: $min_p, typical_p: $typical_p, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, repetition_penalty: $repetition_penalty, mirostat_target: $mirostat_target, mirostat_lr: $mirostat_lr, seed: $seed, logprobs: $logprobs, top_logprobs: $top_logprobs, echo: $echo, echo_last: $echo_last, ignore_eos: $ignore_eos, context_length_exceeded_behavior: $context_length_exceeded_behavior, logit_bias: $logit_bias, speculation: $speculation, prediction: $prediction, metadata: $metadata, reasoning_effort: $reasoning_effort, reasoning_history: $reasoning_history, thinking: $thinking, return_token_ids: $return_token_ids, functions: $functions, prompt_truncate_len: $prompt_truncate_len, parallel_tool_calls: $parallel_tool_calls, safe_tokenization: $safe_tokenization, function_call: $function_call} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a Message
#
# POST /v1/messages
# operationId: messages_post
# --messages item shape: {content: any, role: "user"|"assistant"}
# --metadata shape: {user_id?: any}
# --output_config shape: {effort?: any, format?: any}
export def "messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # The model that will complete your prompt. See the [Fireworks Model Library](https://app.fireworks.ai/models) for available models.
  messages: list # Input messages.  Models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.  Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.  If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.  Example with a single `user` message:  ```json [{"role": "user", "content": "Hello"}] ```  Example with multiple conversational turns:  ```json [   {"role": "user", "content": "Hello there."},   {"role": "assistant", "content": "Hi, I'm here to help. How can I help you?"},   {"role": "user", "content": "Can you explain LLMs in plain English?"}, ] ```  Example with a partially-filled response from the model:  ```json [   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},   {"role": "assistant", "content": "The best answer is ("}, ] ```  Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:  ```json {"role": "user", "content": "Hello"} ```  ```json {"role": "user", "content": [{"type": "text", "text": "Hello"}]} ```  See [input examples](https://docs.claude.com/en/api/messages-examples).  Note that if you want to include a [system prompt](/guides/querying-text-models), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.  There is a limit of 100,000 messages in a single request. — item shape: {content: any, role: "user"|"assistant"}
  --max-tokens: int # The maximum number of tokens to generate before stopping.  Note that models may stop _before_ reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.  Different models have different maximum values for this parameter.  See [models](https://app.fireworks.ai/models) for details.
  --metadata: record # shape: {user_id?: any}
  --output-config: record # shape: {effort?: any, format?: any}
  --stop-sequences: list # Custom text sequences that will cause the model to stop generating.  Models will normally stop when they have naturally completed their turn, which will result in a response `stop_reason` of `"end_turn"`.  If you want the model to stop generating when it encounters custom strings of text, you can use the `stop_sequences` parameter. If the model encounters one of the custom sequences, the response `stop_reason` value will be `"stop_sequence"` and the response `stop_sequence` value will contain the matched stop sequence.
  --stream: oneof<nothing, bool> # Whether to incrementally stream the response using server-sent events.  See [streaming](/guides/querying-text-models) for details.
  --system: any # System prompt.  A system prompt is a way of providing context and instructions to the model, such as specifying a particular goal or role. See the [guide to system prompts](/guides/querying-text-models).
  --temperature: float # Amount of randomness injected into the response.  Defaults to `1.0`. Ranges from `0.0` to `1.0`. Use `temperature` closer to `0.0` for analytical / multiple choice, and closer to `1.0` for creative and generative tasks.  Note that even with `temperature` of `0.0`, the results will not be fully deterministic.
  --thinking: any # Configuration for enabling the model's extended thinking.  When enabled, responses include `thinking` content blocks showing the model's thinking process before the final answer. Requires a minimum budget of 1,024 tokens and counts towards your `max_tokens` limit.  See [reasoning](/guides/reasoning) for details.  **Note:** The `adaptive` thinking type is not supported yet.
  --tool-choice: any # How the model should use the provided tools. The model can use a specific tool, any available tool, decide by itself, or not use tools at all.
  --tools: list # Definitions of tools that the model may use.  If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.  Each tool definition includes:  * `name`: Name of the tool. * `description`: Optional, but strongly-recommended description of the tool. * `input_schema`: [JSON schema](https://json-schema.org/draft/2020-12) for the tool `input` shape that the model will produce in `tool_use` output content blocks.  For example, if you defined `tools` as:  ```json [   {     "name": "get_stock_price",     "description": "Get the current stock price for a given ticker symbol.",     "input_schema": {       "type": "object",       "properties": {         "ticker": {           "type": "string",           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."         }       },       "required": ["ticker"]     }   } ] ```  And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:  ```json [   {     "type": "tool_use",     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "name": "get_stock_price",     "input": { "ticker": "^GSPC" }   } ] ```  You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:  ```json [   {     "type": "tool_result",     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "content": "259.75 USD"   } ] ```  Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.  See the [guide](/guides/function-calling) for more details.
  --top-k: int # Only sample from the top K options for each subsequent token.  Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).  Recommended for advanced use cases only. You usually only need to use `temperature`.
  --top-p: float # Use nucleus sampling.  In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by `top_p`. You should either alter `temperature` or `top_p`, but not both.  Recommended for advanced use cases only. You usually only need to use `temperature`.
  --raw-output: any # Return raw output from the model. (default: false)
]: any -> record<id: string, type: string, role: string, content: list<any>, model: string, stop_reason: any, stop_sequence: any, raw_output: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.fireworks.ai/inference")
  let full_url = (build-url $base "/v1/messages")
  let body = {model: $model, messages: $messages, max_tokens: $max_tokens, metadata: $metadata, output_config: $output_config, stop_sequences: $stop_sequences, stream: $stream, system: $system, temperature: $temperature, thinking: $thinking, tool_choice: $tool_choice, tools: $tools, top_k: $top_k, top_p: $top_p, raw_output: $raw_output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
