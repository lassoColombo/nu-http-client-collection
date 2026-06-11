# Auto-generated client for Dash0 API v1.0.0
# Source: https://api.eu-west-1.aws.dash0.com/openapi.json
# Auth: --token flag or $env.DASH0_API_TOKEN

const BASE_URL = "https://api.eu-west-1.aws.dash0.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DASH0_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.eu-west-1.aws.dash0.com" "https://api.eu-central-1.aws.dash0.com" "https://api.us-west-2.aws.dash0.com" "https://api.europe-west4.gcp.dash0.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["Dashboard"] }
def kind-completer-1 [] { ["Dash0SyntheticCheck"] }
def kind-completer-2 [] { ["Dash0View"] }
def kind-completer-3 [] { ["Dash0NotificationChannel"] }
def apiVersion-completer [] { ["monitoring.coreos.com/v1"] }
def kind-completer-4 [] { ["PrometheusRule"] }
def kind-completer-5 [] { ["Dash0Sampling"] }
def kind-completer-6 [] { ["Dash0SignalToMetrics"] }
def apiVersion-completer-1 [] { ["openslo/v1"] }
def kind-completer-7 [] { ["SLO"] }
def accept-completer [] { ["application/json" "application/yaml"] }
def apiVersion-completer-2 [] { ["v1alpha1"] }
def kind-completer-8 [] { ["Dash0SpamFilter"] }
def kind-completer-9 [] { ["Dash0Team"] }
def token-endpoint-auth-method-completer [] { ["none"] }
def token-type-hint-completer [] { ["access_token" "refresh_token"] }
def grant-type-completer [] { ["authorization_code" "refresh_token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-oauth-authorization-server get" } } | get name | first)
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

# OAuth 2.0 Authorization Server Metadata
#
# GET /.well-known/oauth-authorization-server
export def "well-known-oauth-authorization-server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<issuer: string, authorization_endpoint: string, token_endpoint: string, registration_endpoint: string, revocation_endpoint: string, introspection_endpoint: string, scopes_supported: list<string>, response_types_supported: list<string>, grant_types_supported: list<string>, code_challenge_methods_supported: list<string>, token_endpoint_auth_methods_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/oauth-authorization-server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Protected Resource Metadata
#
# GET /.well-known/oauth-protected-resource
export def "well-known-oauth-protected-resource get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resource: string, authorization_servers: list<string>, scopes_supported: list<string>, bearer_methods_supported: list<string>, resource_documentation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/oauth-protected-resource")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of check rule ids.
#
# GET /api/alerting/check-rules
@deprecated --flag idPrefix
export def "alerting-check-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  --idPrefix: string # If provided, only check rules for which the origin starts with the given string are returned. (deprecated)  The `originPrefix` query parameter takes precedence over this parameter if both are provided.  (DEPRECATED)
  --originPrefix: string # If provided, only check rules for which the origin starts with the given string are returned.
]: nothing -> table<id: string, origin: string, source: string, dataset: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "idPrefix" $idPrefix "scalar") (serialize-qp "originPrefix" $originPrefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alerting/check-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new check rule.
#
# POST /api/alerting/check-rules
# --metadata shape: {labels?: record}
# --thresholds shape: {degraded?: float, failed?: float}
# --annotations shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
@deprecated --flag summary
@deprecated --flag description
@deprecated --flag keepFiringFor
export def "alerting-check-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The associated dataset.
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --metadata: record # Server-populated metadata for the alert rule. Read-only on responses; ignored on write. — shape: {labels?: record}
  --id: string # User defined id for getting/updating/deleting the alert rule through the API.
  name: string # Human-readable and templatable name for the check. In Prometheus alerting rules this is called "alert".
  expression: string # An editable PromQL expression that can leverage the complete Dash0 Query Language. It furthermore supports a variable called $__threshold.  - `$__threshold` can be used as a placeholder for both the degraded and failed thresholds. The   thresholds are defined in the thresholds field. When `$__threshold` is used in the expression,   the `thresholds` field is required and at least one of the thresholds must be defined.    Usage of `$__threshold` implies that the PromQL expression may have to be evaluated up to two   times using the degraded threshold and critical threshold respectively.  - Top-level AND statements are treated as enablement conditions that specify when the check should   "be running", i.e., is active. The use-cases for enablement conditions are several, e.g., requiring   a minimum amount of requests being served before triggering due to errors rates,   maintenance windows or muted timeframes.
  --thresholds: any # Thresholds to use for the `$__threshold` variable in the expression field. — shape: {degraded?: float, failed?: float}
  --interval: string
  --body-for: string
  --keep-firing-for: string
  --labels: record # Label are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "labels" field.
  --annotations: record # Annotations are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "annotations" field.  The "summary" and "description" annotations are expected and are used as the human-readable summary and description of the check rule. — shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
  --enabled: string@bool-completer # A boolean flag to enable or disable the check rule. When a check rule is disabled, it will not be evaluated, and no check evaluations will be created. This field is optional and defaults to true.
  --summary: string # Deprecated: use the "summary" annotation instead. (DEPRECATED)
  --description: string # Deprecated: use the "description" annotation instead. (DEPRECATED)
  --keepFiringFor: string # Deprecated: use "keep_firing_for" instead. (DEPRECATED)
]: any -> record<dataset: string, metadata: record<labels: record<dash0_com_source: string>>, id: string, name: string, expression: string, thresholds: record<degraded: float, failed: float>, interval: string, for: string, keep_firing_for: string, labels: record, annotations: record<summary: string, description: string, folderPath: string, sharing: string>, enabled: bool, summary: string, description: string, keepFiringFor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alerting/check-rules" $qp)
  let body = {dataset: $dataset, metadata: $metadata, id: $id, name: $name, expression: $expression, thresholds: $thresholds, interval: $interval, for: $body_for, keep_firing_for: $keep_firing_for, labels: $labels, annotations: $annotations, enabled: $enabled, summary: $summary, description: $description, keepFiringFor: $keepFiringFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk create check rules.
#
# POST /api/alerting/check-rules/bulk
# --items item shape: {dataset?: string, metadata?: record, id?: string, name: string, expression: string, thresholds?: any, interval?: string, for?: string, keep_firing_for?: string, labels?: record, annotations?: record, enabled?: bool, summary?: string, description?: string, keepFiringFor?: string}
export def "alerting-check-rules-bulk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The dataset to deploy rules into. Required to prevent accidental deployment to the wrong dataset.
  items: list # item shape: {dataset?: string, metadata?: record, id?: string, name: string, expression: string, thresholds?: any, interval?: string, for?: string, keep_firing_for?: string, labels?: record, annotations?: record, enabled?: bool, summary?: string, description?: string, keepFiringFor?: string}
]: any -> record<created: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alerting/check-rules/bulk" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific check rule (Prometheus alert rule) by origin or id.
#
# DELETE /api/alerting/check-rules/{originOrId}
export def "alerting-check-rules delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/alerting/check-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific check rule (Prometheus alert rule) by its origin or id.
#
# GET /api/alerting/check-rules/{originOrId}
export def "alerting-check-rules get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<dataset: string, metadata: record<labels: record<dash0_com_source: string>>, id: string, name: string, expression: string, thresholds: record<degraded: float, failed: float>, interval: string, for: string, keep_firing_for: string, labels: record, annotations: record<summary: string, description: string, folderPath: string, sharing: string>, enabled: bool, summary: string, description: string, keepFiringFor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/alerting/check-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or insert a specific check rule (Prometheus alert rule) by origin or id.
#
# PUT /api/alerting/check-rules/{originOrId}
# --metadata shape: {labels?: record}
# --thresholds shape: {degraded?: float, failed?: float}
# --annotations shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
@deprecated --flag summary
@deprecated --flag description
@deprecated --flag keepFiringFor
export def "alerting-check-rules put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --metadata: record # Server-populated metadata for the alert rule. Read-only on responses; ignored on write. — shape: {labels?: record}
  --id: string # User defined id for getting/updating/deleting the alert rule through the API.
  name: string # Human-readable and templatable name for the check. In Prometheus alerting rules this is called "alert".
  expression: string # An editable PromQL expression that can leverage the complete Dash0 Query Language. It furthermore supports a variable called $__threshold.  - `$__threshold` can be used as a placeholder for both the degraded and failed thresholds. The   thresholds are defined in the thresholds field. When `$__threshold` is used in the expression,   the `thresholds` field is required and at least one of the thresholds must be defined.    Usage of `$__threshold` implies that the PromQL expression may have to be evaluated up to two   times using the degraded threshold and critical threshold respectively.  - Top-level AND statements are treated as enablement conditions that specify when the check should   "be running", i.e., is active. The use-cases for enablement conditions are several, e.g., requiring   a minimum amount of requests being served before triggering due to errors rates,   maintenance windows or muted timeframes.
  --thresholds: any # Thresholds to use for the `$__threshold` variable in the expression field. — shape: {degraded?: float, failed?: float}
  --interval: string
  --body-for: string
  --keep-firing-for: string
  --labels: record # Label are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "labels" field.
  --annotations: record # Annotations are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "annotations" field.  The "summary" and "description" annotations are expected and are used as the human-readable summary and description of the check rule. — shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
  --enabled: string@bool-completer # A boolean flag to enable or disable the check rule. When a check rule is disabled, it will not be evaluated, and no check evaluations will be created. This field is optional and defaults to true.
  --summary: string # Deprecated: use the "summary" annotation instead. (DEPRECATED)
  --description: string # Deprecated: use the "description" annotation instead. (DEPRECATED)
  --keepFiringFor: string # Deprecated: use "keep_firing_for" instead. (DEPRECATED)
]: any -> record<dataset: string, metadata: record<labels: record<dash0_com_source: string>>, id: string, name: string, expression: string, thresholds: record<degraded: float, failed: float>, interval: string, for: string, keep_firing_for: string, labels: record, annotations: record<summary: string, description: string, folderPath: string, sharing: string>, enabled: bool, summary: string, description: string, keepFiringFor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/alerting/check-rules/($originOrId)" $qp)
  let body = {dataset: $dataset, metadata: $metadata, id: $id, name: $name, expression: $expression, thresholds: $thresholds, interval: $interval, for: $body_for, keep_firing_for: $keep_firing_for, labels: $labels, annotations: $annotations, enabled: $enabled, summary: $summary, description: $description, keepFiringFor: $keepFiringFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive a list of dashboards
#
# GET /api/dashboards
export def "dashboards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> table<id: string, origin: string, dataset: string, name: string, description: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dashboards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /api/dashboards
# --metadata shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
export def "dashboards post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer
  metadata: any # shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
  spec: record
]: any -> record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string, dash0Extensions: record<tags: list, dataset: string, id: string, origin: string, createdBy: string>, labels: record<dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dashboards" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific dashboard by its origin or id.
#
# DELETE /api/dashboards/{originOrId}
export def "dashboards delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/dashboards/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receive a specific dashboard by its origin or id.
#
# GET /api/dashboards/{originOrId}
export def "dashboards get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string, dash0Extensions: record<tags: list, dataset: string, id: string, origin: string, createdBy: string>, labels: record<dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/dashboards/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or insert a specific dashboard by its origin or id.
#
# PUT /api/dashboards/{originOrId}
# --metadata shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
export def "dashboards put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer
  metadata: any # shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
  spec: record
]: any -> record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string, dash0Extensions: record<tags: list, dataset: string, id: string, origin: string, createdBy: string>, labels: record<dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/dashboards/($originOrId)" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve settings for the organization identified by the provided Dash0 auth token
#
# GET /api/edge/settings
export def "edge-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<technicalID: string, datasetSettings: table<slug: string, name: string, version: int, preferred: bool, createdAt: string, updatedAt: string, tracing: record, logging: record, metrics: record, profiling: record, semanticConventionUpgrades: string, telemetryFilters: list, ipAddresses: record, geoLocation: record, permissions: list, permittedActions: list>, timeSeriesAggregationSettings: table<kind: string, metadata: record, spec: record>, samplingSettings: table<kind: string, metadata: record, spec: record>, sourceMapSettings: table<kind: string, spec: record>, signalToMetricsSettings: table<kind: string, metadata: record, spec: record>, telemetryTransformationRuleSettings: table<kind: string, metadata: record, spec: record>, observedPatterns: table<dataset: string, extractorType: string, scopeKey: string, template: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/edge/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a check rule.
#
# POST /api/import/check-rule
# --metadata shape: {labels?: record}
# --thresholds shape: {degraded?: float, failed?: float}
# --annotations shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
@deprecated --flag summary
@deprecated --flag description
@deprecated --flag keepFiringFor
export def "import-check-rule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The associated dataset.
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --metadata: record # Server-populated metadata for the alert rule. Read-only on responses; ignored on write. — shape: {labels?: record}
  --id: string # User defined id for getting/updating/deleting the alert rule through the API.
  name: string # Human-readable and templatable name for the check. In Prometheus alerting rules this is called "alert".
  expression: string # An editable PromQL expression that can leverage the complete Dash0 Query Language. It furthermore supports a variable called $__threshold.  - `$__threshold` can be used as a placeholder for both the degraded and failed thresholds. The   thresholds are defined in the thresholds field. When `$__threshold` is used in the expression,   the `thresholds` field is required and at least one of the thresholds must be defined.    Usage of `$__threshold` implies that the PromQL expression may have to be evaluated up to two   times using the degraded threshold and critical threshold respectively.  - Top-level AND statements are treated as enablement conditions that specify when the check should   "be running", i.e., is active. The use-cases for enablement conditions are several, e.g., requiring   a minimum amount of requests being served before triggering due to errors rates,   maintenance windows or muted timeframes.
  --thresholds: any # Thresholds to use for the `$__threshold` variable in the expression field. — shape: {degraded?: float, failed?: float}
  --interval: string
  --body-for: string
  --keep-firing-for: string
  --labels: record # Label are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "labels" field.
  --annotations: record # Annotations are key-value pairs that can be used to add additional metadata to a check. They map to Prometheus alerting rules' "annotations" field.  The "summary" and "description" annotations are expected and are used as the human-readable summary and description of the check rule. — shape: {summary?: string, description?: string, folderPath?: string, sharing?: string}
  --enabled: string@bool-completer # A boolean flag to enable or disable the check rule. When a check rule is disabled, it will not be evaluated, and no check evaluations will be created. This field is optional and defaults to true.
  --summary: string # Deprecated: use the "summary" annotation instead. (DEPRECATED)
  --description: string # Deprecated: use the "description" annotation instead. (DEPRECATED)
  --keepFiringFor: string # Deprecated: use "keep_firing_for" instead. (DEPRECATED)
]: any -> record<dataset: string, metadata: record<labels: record<dash0_com_source: string>>, id: string, name: string, expression: string, thresholds: record<degraded: float, failed: float>, interval: string, for: string, keep_firing_for: string, labels: record, annotations: record<summary: string, description: string, folderPath: string, sharing: string>, enabled: bool, summary: string, description: string, keepFiringFor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/check-rule" $qp)
  let body = {dataset: $dataset, metadata: $metadata, id: $id, name: $name, expression: $expression, thresholds: $thresholds, interval: $interval, for: $body_for, keep_firing_for: $keep_firing_for, labels: $labels, annotations: $annotations, enabled: $enabled, summary: $summary, description: $description, keepFiringFor: $keepFiringFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import multiple check rules in one batch.
#
# POST /api/import/check-rules
# --items item shape: {dataset?: string, metadata?: record, id?: string, name: string, expression: string, thresholds?: any, interval?: string, for?: string, keep_firing_for?: string, labels?: record, annotations?: record, enabled?: bool, summary?: string, description?: string, keepFiringFor?: string}
export def "import-check-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The associated dataset.
  items: list # item shape: {dataset?: string, metadata?: record, id?: string, name: string, expression: string, thresholds?: any, interval?: string, for?: string, keep_firing_for?: string, labels?: record, annotations?: record, enabled?: bool, summary?: string, description?: string, keepFiringFor?: string}
]: any -> record<created: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/check-rules" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import a dashboard
#
# POST /api/import/dashboard
# --metadata shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
export def "import-dashboard post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer
  metadata: any # shape: {name: string, createdAt?: string, updatedAt?: string, version?: int, project?: string, dash0Extensions?: any, labels?: any, annotations?: any}
  spec: record
]: any -> record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string, dash0Extensions: record<tags: list, dataset: string, id: string, origin: string, createdBy: string>, labels: record<dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/dashboard" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk upsert signal-to-metrics configs.
#
# PUT /api/import/signal-to-metrics
# --items item shape: {kind: "Dash0SignalToMetrics", metadata: any, spec: any}
export def "import-signal-to-metrics put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The dataset to deploy rules into. Required to prevent accidental deployment to the wrong dataset.
  items: list # item shape: {kind: "Dash0SignalToMetrics", metadata: any, spec: any}
]: any -> record<created: int, updated: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/signal-to-metrics" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import a synthetic check
#
# POST /api/import/synthetic-check
# --metadata shape: {name: string, description?: string, labels?: any, annotations?: any}
# --spec shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
export def "import-synthetic-check post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-1
  metadata: any # shape: {name: string, description?: string, labels?: any, annotations?: any}
  spec: any # shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
]: any -> record<kind: string, metadata: record<name: string, description: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<display: record<name: string>, plugin: any, schedule: record<strategy: string, interval: string, locations: list>, retries: any, notifications: record<channels: list, onlyCriticalChannels: list>, permissions: list<record>, labels: record, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/synthetic-check" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import a view
#
# POST /api/import/view
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
export def "import-view post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-2
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<type: string, display: record<name: string, description: string>, permissions: list<record>, groupBy: list<string>, filter: list<record>, implicitFilter: list<record>, table: record<columns: list, sort: list>, visualizations: list<record>, serviceMapProperties: record<layout: string, externalServices: string, selectedMetric: string, particles: bool, nodeSizing: bool, expandedGroups: list>, query: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/import/view" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns OTLP logs records
#
# POST /api/logs
# --filter item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
# --timeRange shape: {from: any, to: any}
# --sampling shape: {mode: "adaptive"|"disabled", timeRange: any}
# --ordering item shape: {key: string, direction: "ascending"|"descending"}
# --pagination shape: {cursor?: string, limit?: int}
export def "logs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: list # e.g. [{key: service.name, operator: is, value: foo}] — item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
  timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --sampling: any # shape: {mode: "adaptive"|"disabled", timeRange: any}
  --ordering: list # Any supported attribute keys to order by. — item shape: {key: string, direction: "ascending"|"descending"}
  --pagination: any # Cursor pagination is a technique for paging through a result set using a cursor. It is similar to offset pagination except that the cursor is an opaque value that encodes the position within the result set. This allows for fetching the next page of results from the current position without having to skip over a potentially large number of rows.  It is also more resilient against late-arriving data which otherwise would cause issues with offset pagination. For example, if a row is inserted between two pages of results then the second page would contain a duplicate row and the third page would be missing. — shape: {cursor?: string, limit?: int}
]: any -> record<executionTime: string, timeRange: record<from: string, to: string>, cursors: record<before: string, after: string>, resourceLogs: table<resource: record, scopeLogs: list, schemaUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logs")
  let body = {filter: $filter, timeRange: $timeRange, dataset: $dataset, sampling: $sampling, ordering: $ordering, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive a list of organization members.
#
# GET /api/members
export def "members get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<kind: string, metadata: record<name: string, labels: record>, spec: record<display: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a member to the organization.
#
# POST /api/members
export def "members post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emailAddress: string
  role: string
]: any -> record<error: record<code: int, message: string, traceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/members")
  let body = {emailAddress: $emailAddress, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from the organization.
#
# DELETE /api/members/{memberID}
export def "members delete" [
  memberID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/members/($memberID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all notification channels for the organization
#
# GET /api/notification-channels
export def "notification-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<type: string, config: any, frequency: string, routing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/notification-channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new notification channel
#
# POST /api/notification-channels
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {type: "slack"|"slack_bot"|"email"|"email_v2"|"webhook"|"incidentio"|"prometheus_webhook"|"betterstack"|"prometheus_alertmanager"|"opsgenie"|"pagerduty"|"jira_service_management_ops"|"teams_webhook"|"discord_webhook"|"google_chat_webhook"|"ilert"|"all_quiet", config: any, frequency?: string, routing?: any}
export def "notification-channels post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  kind: string@kind-completer-3
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {type: "slack"|"slack_bot"|"email"|"email_v2"|"webhook"|"incidentio"|"prometheus_webhook"|"betterstack"|"prometheus_alertmanager"|"opsgenie"|"pagerduty"|"jira_service_management_ops"|"teams_webhook"|"discord_webhook"|"google_chat_webhook"|"ilert"|"all_quiet", config: any, frequency?: string, routing?: any}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string>>, spec: record<type: string, config: any, frequency: string, routing: record<assets: list, filters: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/notification-channels")
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a notification channel
#
# DELETE /api/notification-channels/{originOrId}
export def "notification-channels delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/notification-channels/($originOrId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific notification channel
#
# GET /api/notification-channels/{originOrId}
export def "notification-channels get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string>>, spec: record<type: string, config: any, frequency: string, routing: record<assets: list, filters: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/notification-channels/($originOrId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a notification channel
#
# PUT /api/notification-channels/{originOrId}
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {type: "slack"|"slack_bot"|"email"|"email_v2"|"webhook"|"incidentio"|"prometheus_webhook"|"betterstack"|"prometheus_alertmanager"|"opsgenie"|"pagerduty"|"jira_service_management_ops"|"teams_webhook"|"discord_webhook"|"google_chat_webhook"|"ilert"|"all_quiet", config: any, frequency?: string, routing?: any}
export def "notification-channels put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  kind: string@kind-completer-3
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {type: "slack"|"slack_bot"|"email"|"email_v2"|"webhook"|"incidentio"|"prometheus_webhook"|"betterstack"|"prometheus_alertmanager"|"opsgenie"|"pagerduty"|"jira_service_management_ops"|"teams_webhook"|"discord_webhook"|"google_chat_webhook"|"ilert"|"all_quiet", config: any, frequency?: string, routing?: any}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string>>, spec: record<type: string, config: any, frequency: string, routing: record<assets: list, filters: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/notification-channels/($originOrId)")
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluates and returns a formatted version of the query.
#
# GET /api/prometheus/api/v1/format_query
export def "prometheus-format-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # PromQL expression to validate and pretty-print. The response `data` is the formatted expression. If the query contains Dash0 template variables (e.g. `$__range`, `$__interval`), the original query is returned unmodified.
]: nothing -> record<status: string, data: string, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/format_query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluates and returns a formatted version of the query.
#
# POST /api/prometheus/api/v1/format_query
export def "prometheus-format-query post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string
]: any -> record<status: string, data: string, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/format_query")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of label values for a provided label name.
#
# GET /api/prometheus/api/v1/label/{label_name}/values
export def "prometheus-label-values get" [
  label_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start timestamp to restrict the set of returned label values. (format: rfc3339 | unix_timestamp)
  --end: string # End timestamp to restrict the set of returned label values. (format: rfc3339 | unix_timestamp)
  --qp-match: list # Repeated series selector that restricts the label values returned.
  --limit: int # Maximum number of results. Defaults to and is capped at the server-configured maximum. (format: int64)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "match[]" $qp_match "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/prometheus/api/v1/label/($label_name)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of label values for a provided label name.
#
# POST /api/prometheus/api/v1/label/{label_name}/values
export def "prometheus-label-values post" [
  label_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # format: rfc3339 | unix_timestamp
  --end: string # format: rfc3339 | unix_timestamp
  --body-match: list
  --limit: int # format: int64
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: list<string>, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/prometheus/api/v1/label/($label_name)/values")
  let body = {start: $start, end: $end, match[]: $body_match, limit: $limit, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of label names.
#
# GET /api/prometheus/api/v1/labels
export def "prometheus-labels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start timestamp to restrict the set of returned label names. (format: rfc3339 | unix_timestamp)
  --end: string # End timestamp to restrict the set of returned label names. (format: rfc3339 | unix_timestamp)
  --qp-match: list # Repeated series selector that restricts the label names returned.
  --limit: int # Maximum number of results. Defaults to and is capped at the server-configured maximum. (format: int64)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "match[]" $qp_match "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of label names.
#
# POST /api/prometheus/api/v1/labels
export def "prometheus-labels post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # format: rfc3339 | unix_timestamp
  --end: string # format: rfc3339 | unix_timestamp
  --body-match: list
  --limit: int # format: int64
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: list<string>, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/labels")
  let body = {start: $start, end: $end, match[]: $body_match, limit: $limit, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns metadata about metrics currently scraped from targets.
#
# GET /api/prometheus/api/v1/metadata
export def "prometheus-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of metrics to return. When omitted, all metrics are returned. (format: int64)
  --limit-per-metric: int # Maximum number of metadata entries to return per metric. (format: int64)
  --metric: string # If provided, only metadata for this metric name is returned. When omitted, metadata for all metrics is returned.
  --start: string # Start timestamp. Must be provided together with `end`. (format: rfc3339 | unix_timestamp)
  --end: string # End timestamp. Must be provided together with `start`. (format: rfc3339 | unix_timestamp)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: record, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "limit_per_metric" $limit_per_metric "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about metrics currently scraped from targets.
#
# POST /api/prometheus/api/v1/metadata
export def "prometheus-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int64
  --limit-per-metric: int # format: int64
  --metric: string
  --start: string # format: rfc3339 | unix_timestamp
  --end: string # format: rfc3339 | unix_timestamp
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: record, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/metadata")
  let body = {limit: $limit, limit_per_metric: $limit_per_metric, metric: $metric, start: $start, end: $end, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluates an instant query at a single point in time.
#
# GET /api/prometheus/api/v1/query
export def "prometheus-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # PromQL expression to evaluate.
  --time: string # Evaluation timestamp. Defaults to the current server time when omitted. (format: rfc3339 | unix_timestamp)
  --timeout: string # Per-query timeout, clamped to the server-configured maximum. (format: duration)
  --limit: int # Maximum number of returned series. Defaults to and is capped at the server-configured maximum.  (format: int64)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: record<resultType: string, result: any>, warnings: list<string>, infos: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluates an instant query at a single point in time.
#
# POST /api/prometheus/api/v1/query
export def "prometheus-query post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string
  --time: string # format: rfc3339 | unix_timestamp
  --timeout: string # format: duration
  --limit: int # format: int64
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: record<resultType: string, result: any>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/query")
  let body = {query: $body_query, time: $time, timeout: $timeout, limit: $limit, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluates a PromQL expression over a range of time.
#
# GET /api/prometheus/api/v1/query_range
export def "prometheus-query-range get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # PromQL expression to evaluate.
  --start: string # Start timestamp of the range (inclusive). (format: rfc3339 | unix_timestamp)
  --end: string # End timestamp of the range (inclusive). Must not be before `start`. (format: rfc3339 | unix_timestamp)
  --step: string # Query resolution step width, as a duration or a number of seconds. (format: duration | float_seconds)
  --timeout: string # Per-query timeout, clamped to the server-configured maximum. (format: duration)
  --limit: int # Maximum number of returned series. Defaults to and is capped at the server-configured maximum.  (format: int64)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: record<resultType: string, result: any>, warnings: list<string>, infos: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "step" $step "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/query_range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluates a PromQL expression over a range of time.
#
# POST /api/prometheus/api/v1/query_range
export def "prometheus-query-range post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string
  --start: string # format: rfc3339 | unix_timestamp
  --end: string # format: rfc3339 | unix_timestamp
  step: string # format: duration | float_seconds
  --timeout: string # format: duration
  --limit: int # format: int64
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: record<resultType: string, result: any>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/query_range")
  let body = {query: $body_query, start: $start, end: $end, step: $step, timeout: $timeout, limit: $limit, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the list of time series that match a label selector.
#
# GET /api/prometheus/api/v1/series
export def "prometheus-series get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start timestamp to restrict the set of returned series. (format: rfc3339 | unix_timestamp)
  --end: string # End timestamp to restrict the set of returned series. (format: rfc3339 | unix_timestamp)
  --qp-match: list # Repeated series selector that selects the series to return. Upstream Prometheus requires at least one selector.
  --limit: int # Maximum number of results. Defaults to and is capped at the server-configured maximum. (format: int64)
  --dataset: string # Dataset to query. Defaults to the organization's default dataset.
]: nothing -> record<status: string, data: list<record>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "match[]" $qp_match "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prometheus/api/v1/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the list of time series that match a label selector.
#
# POST /api/prometheus/api/v1/series
export def "prometheus-series post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # format: rfc3339 | unix_timestamp
  --end: string # format: rfc3339 | unix_timestamp
  --body-match: list
  --limit: int # format: int64
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
]: any -> record<status: string, data: list<record>, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/series")
  let body = {start: $start, end: $end, match[]: $body_match, limit: $limit, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns various build information properties about the Prometheus-compatible server.
#
# GET /api/prometheus/api/v1/status/buildinfo
export def "prometheus-status-buildinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, data: record<version: string, revision: string, branch: string, buildUser: string, buildDate: string, goVersion: string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/status/buildinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns various runtime information properties about the Prometheus-compatible server.
#
# GET /api/prometheus/api/v1/status/runtimeinfo
export def "prometheus-status-runtimeinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, data: record<startTime: string, CWD: string, hostname: string, serverTime: string, reloadConfigSuccess: bool, lastConfigTime: string, corruptionCount: int, goroutineCount: int, GOMAXPROCS: int, GOMEMLIMIT: int, GOGC: string, GODEBUG: string, storageRetention: string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/prometheus/api/v1/status/runtimeinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of recording rules.
#
# GET /api/recording-rules
export def "recording-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Filter by dataset.
  --originPrefix: string # Filter by origin prefix.
]: nothing -> table<apiVersion: string, kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "originPrefix" $originPrefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/recording-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a recording rule.
#
# POST /api/recording-rules
# --metadata shape: {name: string, labels?: record, annotations?: record}
# --spec shape: {groups: list}
export def "recording-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Target dataset. Overrides dash0.com/dataset in metadata.labels if both are provided.
  apiVersion: string@apiVersion-completer # API version of the PrometheusRule CRD.
  kind: string@kind-completer-4 # Kind of the PrometheusRule CRD.
  metadata: any # Metadata for the PrometheusRule resource, following Kubernetes metadata conventions. — shape: {name: string, labels?: record, annotations?: record}
  spec: any # Spec of the PrometheusRule resource containing rule groups. — shape: {groups: list}
]: any -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<groups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/recording-rules" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific recording rule.
#
# DELETE /api/recording-rules/{originOrId}
export def "recording-rules delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/recording-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the latest version of a specific recording rule.
#
# GET /api/recording-rules/{originOrId}
export def "recording-rules get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<groups: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/recording-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific recording rule.
#
# PUT /api/recording-rules/{originOrId}
# --metadata shape: {name: string, labels?: record, annotations?: record}
# --spec shape: {groups: list}
export def "recording-rules put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Target dataset. Overrides dash0.com/dataset in metadata.labels if both are provided.
  apiVersion: string@apiVersion-completer # API version of the PrometheusRule CRD.
  kind: string@kind-completer-4 # Kind of the PrometheusRule CRD.
  metadata: any # Metadata for the PrometheusRule resource, following Kubernetes metadata conventions. — shape: {name: string, labels?: record, annotations?: record}
  spec: any # Spec of the PrometheusRule resource containing rule groups. — shape: {groups: list}
]: any -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<groups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/recording-rules/($originOrId)" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all sampling rules for the organization
#
# GET /api/sampling-rules
export def "sampling-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<samplingRules: table<kind: string, metadata: record, spec: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sampling-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new sampling rule
#
# POST /api/sampling-rules
# --metadata shape: {name: string, labels?: any}
# --spec shape: {enabled: bool, display?: any, conditions: any, rateLimit?: any}
export def "sampling-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-5
  metadata: any # shape: {name: string, labels?: any}
  spec: any # shape: {enabled: bool, display?: any, conditions: any, rateLimit?: any}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>>, spec: record<enabled: bool, display: record<name: string>, conditions: any, rateLimit: record<rate: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sampling-rules" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a sampling rule by origin or ID
#
# DELETE /api/sampling-rules/{originOrId}
export def "sampling-rules delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/sampling-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific sampling rule by origin or ID
#
# GET /api/sampling-rules/{originOrId}
export def "sampling-rules get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>>, spec: record<enabled: bool, display: record<name: string>, conditions: any, rateLimit: record<rate: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/sampling-rules/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or create a sampling rule by origin or ID
#
# PUT /api/sampling-rules/{originOrId}
# --metadata shape: {name: string, labels?: any}
# --spec shape: {enabled: bool, display?: any, conditions: any, rateLimit?: any}
export def "sampling-rules put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-5
  metadata: any # shape: {name: string, labels?: any}
  spec: any # shape: {enabled: bool, display?: any, conditions: any, rateLimit?: any}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>>, spec: record<enabled: bool, display: record<name: string>, conditions: any, rateLimit: record<rate: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/sampling-rules/($originOrId)" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all signal-to-metrics configs for the organization
#
# GET /api/signal-to-metrics
export def "signal-to-metrics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  --limit: int # Maximum number of items to return. (default: 50)
  --offset: int # Number of items to skip. (default: 0)
  --originPrefix: string # Filter by origin prefix.
  --name: string # Case-insensitive substring search on the rule name.
  --signal: string # Filter by signal type.
  --enabled: string@bool-completer # Filter by enabled state.
]: nothing -> record<signalToMetrics: table<kind: string, metadata: record, spec: record>, hasMore: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "originPrefix" $originPrefix "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "signal" $signal "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/signal-to-metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new signal-to-metrics config
#
# POST /api/signal-to-metrics
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {enabled: bool, display: any, match: any, output: any, targetDatasetMode?: "original"|"alternative"|"both", alternativeDatasetId?: string}
export def "signal-to-metrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-6
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {enabled: bool, display: any, match: any, output: any, targetDatasetMode?: "original"|"alternative"|"both", alternativeDatasetId?: string}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<enabled: bool, display: record<name: string>, match: record<signal: string, filters: list>, output: record<name: string, description: string, interval: string, keepResourceAttributes: list, keepSignalAttributes: list>, targetDatasetMode: string, alternativeDatasetId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/signal-to-metrics" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a signal-to-metrics config
#
# POST /api/signal-to-metrics/test
# --definition shape: {kind: "Dash0SignalToMetrics", metadata: any, spec: any}
# --timeRange shape: {from: any, to: any}
export def "signal-to-metrics-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  definition: any # shape: {kind: "Dash0SignalToMetrics", metadata: any, spec: any}
  --timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
]: any -> record<executionTime: string, timeRange: record<from: string, to: string>, matchedCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/signal-to-metrics/test" $qp)
  let body = {definition: $definition, timeRange: $timeRange} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a signal-to-metrics config by origin or ID
#
# DELETE /api/signal-to-metrics/{originOrId}
export def "signal-to-metrics delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/signal-to-metrics/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific signal-to-metrics config by origin or ID
#
# GET /api/signal-to-metrics/{originOrId}
export def "signal-to-metrics get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<enabled: bool, display: record<name: string>, match: record<signal: string, filters: list>, output: record<name: string, description: string, interval: string, keepResourceAttributes: list, keepSignalAttributes: list>, targetDatasetMode: string, alternativeDatasetId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/signal-to-metrics/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or create a signal-to-metrics config by origin or ID
#
# PUT /api/signal-to-metrics/{originOrId}
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {enabled: bool, display: any, match: any, output: any, targetDatasetMode?: "original"|"alternative"|"both", alternativeDatasetId?: string}
export def "signal-to-metrics put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-6
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {enabled: bool, display: any, match: any, output: any, targetDatasetMode?: "original"|"alternative"|"both", alternativeDatasetId?: string}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<enabled: bool, display: record<name: string>, match: record<signal: string, filters: list>, output: record<name: string, description: string, interval: string, keepResourceAttributes: list, keepSignalAttributes: list>, targetDatasetMode: string, alternativeDatasetId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/signal-to-metrics/($originOrId)" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of SLOs.
#
# GET /api/slos
export def "slos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Filter by dataset.
  --originPrefix: string # Filter by origin prefix.
]: nothing -> table<apiVersion: string, kind: string, metadata: record<name: string, labels: record, annotations: record>, spec: record<description: string, service: string, indicator: record, indicatorRef: string, timeWindow: list, budgetingMethod: string, objectives: list, alertPolicies: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "originPrefix" $originPrefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/slos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SLO.
#
# POST /api/slos
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {description?: string, service?: string, indicator?: any, indicatorRef?: string, timeWindow?: list, budgetingMethod: "Occurrences"|"Timeslices"|"RatioTimeslices", objectives: list, alertPolicies?: list}
export def "slos post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Target dataset. Overrides dash0.com/dataset in metadata.labels if both are provided.
  apiVersion: string@apiVersion-completer-1
  kind: string@kind-completer-7
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {description?: string, service?: string, indicator?: any, indicatorRef?: string, timeWindow?: list, budgetingMethod: "Occurrences"|"Timeslices"|"RatioTimeslices", objectives: list, alertPolicies?: list}
]: any -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string, dash0_com_enabled: string>>, spec: record<description: string, service: string, indicator: record<metadata: record, spec: record>, indicatorRef: string, timeWindow: list<record>, budgetingMethod: string, objectives: list<record>, alertPolicies: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/slos" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific SLO.
#
# DELETE /api/slos/{originOrId}
export def "slos delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/slos/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the latest version of a specific SLO.
#
# GET /api/slos/{originOrId}
export def "slos get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --dataset: string
  --format: string # Return OpenSLO YAML instead of JSON. Equivalent to `Accept: application/yaml`.
]: nothing -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string, dash0_com_enabled: string>>, spec: record<description: string, service: string, indicator: record<metadata: record, spec: record>, indicatorRef: string, timeWindow: list<record>, budgetingMethod: string, objectives: list<record>, alertPolicies: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/slos/($originOrId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific SLO.
#
# PUT /api/slos/{originOrId}
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {description?: string, service?: string, indicator?: any, indicatorRef?: string, timeWindow?: list, budgetingMethod: "Occurrences"|"Timeslices"|"RatioTimeslices", objectives: list, alertPolicies?: list}
export def "slos put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Target dataset. Overrides dash0.com/dataset in metadata.labels if both are provided.
  apiVersion: string@apiVersion-completer-1
  kind: string@kind-completer-7
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {description?: string, service?: string, indicator?: any, indicatorRef?: string, timeWindow?: list, budgetingMethod: "Occurrences"|"Timeslices"|"RatioTimeslices", objectives: list, alertPolicies?: list}
]: any -> record<apiVersion: string, kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_created_at: string, dash0_com_updated_at: string, dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string, dash0_com_enabled: string>>, spec: record<description: string, service: string, indicator: record<metadata: record, spec: record>, indicatorRef: string, timeWindow: list<record>, budgetingMethod: string, objectives: list<record>, alertPolicies: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/slos/($originOrId)" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all spam filters for the organization
#
# GET /api/spam-filters
export def "spam-filters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<spamFilters: table<apiVersion: string, kind: string, metadata: record, spec: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/spam-filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new spam filter
#
# POST /api/spam-filters
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {contexts: list, filter: list}
export def "spam-filters post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  --apiVersion: string@apiVersion-completer-2
  --kind: string@kind-completer-8
  --metadata: any # shape: {name: string, labels?: any, annotations?: any}
  --spec: any # v1alpha1 spam filter specification. The `filter` field defines structured criteria that the server compiles into an OTTL condition for evaluation. — shape: {contexts: list, filter: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/spam-filters" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a spam filter by origin or ID
#
# DELETE /api/spam-filters/{originOrId}
export def "spam-filters delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/spam-filters/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific spam filter by origin or ID
#
# GET /api/spam-filters/{originOrId}
export def "spam-filters get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/spam-filters/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or create a spam filter by origin or ID
#
# PUT /api/spam-filters/{originOrId}
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {contexts: list, filter: list}
export def "spam-filters put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  --apiVersion: string@apiVersion-completer-2
  --kind: string@kind-completer-8
  --metadata: any # shape: {name: string, labels?: any, annotations?: any}
  --spec: any # v1alpha1 spam filter specification. The `filter` field defines structured criteria that the server compiles into an OTTL condition for evaluation. — shape: {contexts: list, filter: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/spam-filters/($originOrId)" $qp)
  let body = {apiVersion: $apiVersion, kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns OTLP spans
#
# POST /api/spans
# --filter item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
# --timeRange shape: {from: any, to: any}
# --sampling shape: {mode: "adaptive"|"disabled", timeRange: any}
# --ordering item shape: {key: string, direction: "ascending"|"descending"}
# --pagination shape: {cursor?: string, limit?: int}
export def "spans post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: list # e.g. [{key: service.name, operator: is, value: foo}] — item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
  timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --sampling: any # shape: {mode: "adaptive"|"disabled", timeRange: any}
  --ordering: list # Any supported attribute keys to order by. — item shape: {key: string, direction: "ascending"|"descending"}
  --pagination: any # Cursor pagination is a technique for paging through a result set using a cursor. It is similar to offset pagination except that the cursor is an opaque value that encodes the position within the result set. This allows for fetching the next page of results from the current position without having to skip over a potentially large number of rows.  It is also more resilient against late-arriving data which otherwise would cause issues with offset pagination. For example, if a row is inserted between two pages of results then the second page would contain a duplicate row and the third page would be missing. — shape: {cursor?: string, limit?: int}
]: any -> record<executionTime: string, timeRange: record<from: string, to: string>, cursors: record<before: string, after: string>, resourceSpans: table<resource: record, scopeSpans: list, schemaUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/spans")
  let body = {filter: $filter, timeRange: $timeRange, dataset: $dataset, sampling: $sampling, ordering: $ordering, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execute a SQL query and return results as JSON.
#
# POST /api/sql
# --timeRange shape: {from: any, to: any}
export def "sql post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --body-query: string
]: any -> record<executionTime: string, timeRange: record<from: string, to: string>, error: string, queryError: record<title: string, description: string, correctedQuery: string>, progress: record<rowsRead: int, bytesRead: int, totalRowsToRead: int, executionTimeMillis: int>, resultRows: table<values: list>, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sql")
  let body = {timeRange: $timeRange, dataset: $dataset, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive a list of synthetic checks
#
# GET /api/synthetic-checks
export def "synthetic-checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> table<id: string, origin: string, source: string, dataset: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/synthetic-checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a synthetic check
#
# POST /api/synthetic-checks
# --metadata shape: {name: string, description?: string, labels?: any, annotations?: any}
# --spec shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
export def "synthetic-checks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-1
  metadata: any # shape: {name: string, description?: string, labels?: any, annotations?: any}
  spec: any # shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
]: any -> record<kind: string, metadata: record<name: string, description: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<display: record<name: string>, plugin: any, schedule: record<strategy: string, interval: string, locations: list>, retries: any, notifications: record<channels: list, onlyCriticalChannels: list>, permissions: list<record>, labels: record, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/synthetic-checks" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve list of synthetic check locations
#
# GET /api/synthetic-checks/locations
export def "synthetic-checks-locations get" [
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
  let full_url = (build-url $base "/api/synthetic-checks/locations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a test run of a synthetic check
#
# POST /api/synthetic-checks/test
# --definition shape: {kind: "Dash0SyntheticCheck", metadata: any, spec: any}
export def "synthetic-checks-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  definition: any # shape: {kind: "Dash0SyntheticCheck", metadata: any, spec: any}
]: any -> record<syntheticCheckAttempt: record<syntheticCheckId: string, syntheticCheckVersion: string, runId: string, location: string, attemptId: string, isTestRun: bool, traceId: string, spanId: string, startTime: string, duration: int, statusCode: int, errorType: string, errorMessage: string, failedCriticalAssertions: list<record>, failedDegradedAssertions: list<record>, passedCriticalAssertions: list<any>, passedDegradedAssertions: list<any>, spanAttributes: list<record>, events: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/synthetic-checks/test")
  let body = {dataset: $dataset, definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific synthetic check by origin or id.
#
# DELETE /api/synthetic-checks/{originOrId}
export def "synthetic-checks delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/synthetic-checks/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receive a specific synthetic check by its origin or id.
#
# GET /api/synthetic-checks/{originOrId}
export def "synthetic-checks get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<kind: string, metadata: record<name: string, description: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<display: record<name: string>, plugin: any, schedule: record<strategy: string, interval: string, locations: list>, retries: any, notifications: record<channels: list, onlyCriticalChannels: list>, permissions: list<record>, labels: record, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/synthetic-checks/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or insert a specific synthetic check by its origin or id.
#
# PUT /api/synthetic-checks/{originOrId}
# --metadata shape: {name: string, description?: string, labels?: any, annotations?: any}
# --spec shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
export def "synthetic-checks put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-1
  metadata: any # shape: {name: string, description?: string, labels?: any, annotations?: any}
  spec: any # shape: {display?: any, plugin: any, schedule: any, retries: any, notifications: any, permissions?: list, labels?: record, enabled: bool}
]: any -> record<kind: string, metadata: record<name: string, description: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string, custom: record>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<display: record<name: string>, plugin: any, schedule: record<strategy: string, interval: string, locations: list>, retries: any, notifications: record<channels: list, onlyCriticalChannels: list>, permissions: list<record>, labels: record, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/synthetic-checks/($originOrId)" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive a list of teams
#
# GET /api/teams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, origin: string, source: string, name: string, color: record<from: string, to: string>, members: list<record>, totalMemberCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team
#
# POST /api/teams
# --metadata shape: {name: string, labels?: any}
# --spec shape: {display: any, members: list}
export def "teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  kind: string@kind-completer-9
  metadata: any # shape: {name: string, labels?: any}
  spec: any # shape: {display: any, members: list}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_source: string>>, spec: record<display: record<name: string, color: record>, members: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/teams")
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific team by its origin or id.
#
# DELETE /api/teams/{originOrId}
export def "teams delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($originOrId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receive a specific team by its origin or id.
#
# GET /api/teams/{originOrId}
export def "teams get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team: record<kind: string, metadata: record<name: string, labels: record>, spec: record<display: record, members: list>>, members: table<kind: string, metadata: record, spec: record>, dashboards: table<id: string, name: string, type: string, permittedActions: list, createdAt: string, creator: record, dataset: string, hasAccess: bool>, checkRules: table<id: string, name: string, type: string, permittedActions: list, createdAt: string, creator: record, dataset: string, hasAccess: bool>, syntheticChecks: table<id: string, name: string, type: string, permittedActions: list, createdAt: string, creator: record, dataset: string, hasAccess: bool>, views: table<id: string, name: string, type: string, permittedActions: list, createdAt: string, creator: record, dataset: string, hasAccess: bool>, datasets: table<id: string, name: string, type: string, permittedActions: list, createdAt: string, creator: record, dataset: string, hasAccess: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($originOrId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific team display option.
#
# PUT /api/teams/{originOrId}/display
# --color shape: {from: string, to: string}
export def "teams-display put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  color: any # A color gradient from one color to another. — shape: {from: string, to: string}
]: any -> record<error: record<code: int, message: string, traceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($originOrId)/display")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add members to a team.
#
# POST /api/teams/{originOrId}/members
export def "teams-members post" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  memberIds: list # Add an existing organization member to this team.
]: any -> record<error: record<code: int, message: string, traceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($originOrId)/members")
  let body = {memberIds: $memberIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a team.
#
# DELETE /api/teams/{originOrId}/members/{memberID}
export def "teams-members delete" [
  originOrId: string
  memberID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($originOrId)/members/($memberID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the OTLP spans and log records (if any) associated with the trace ID.
#
# POST /api/trace/details
# --timeRange shape: {from: any, to: any}
export def "trace-details post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  traceId: string
  --timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
  --includeLinkedTraces: string@bool-completer # If true, recursively fetches all traces referenced via forward links (dash0ForwardLinks) and returns them in `additionalResourceSpans`. Implies includeOTLPSchemaExtensions=true.  (default: false)
]: any -> record<resourceSpans: table<resource: record, scopeSpans: list, schemaUrl: string>, resourceLogs: table<resource: record, scopeLogs: list, schemaUrl: string>, webEvents: table<resource: record, scopeLogs: list, schemaUrl: string>, syntheticCheckAttemptDetails: record<syntheticCheckId: string, syntheticCheckVersion: string, runId: string, location: string, attemptId: string, isTestRun: bool, traceId: string, spanId: string, startTime: string, duration: int, statusCode: int, errorType: string, errorMessage: string, failedCriticalAssertions: list<record>, failedDegradedAssertions: list<record>, passedCriticalAssertions: list<any>, passedDegradedAssertions: list<any>, spanAttributes: list<record>, events: list<record>>, additionalResourceSpans: table<resource: record, scopeSpans: list, schemaUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/trace/details")
  let body = {dataset: $dataset, traceId: $traceId, timeRange: $timeRange, includeLinkedTraces: $includeLinkedTraces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns unique trace IDs matching the given filters.
#
# POST /api/trace/ids
# --filter item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
# --timeRange shape: {from: any, to: any}
# --sampling shape: {mode: "adaptive"|"disabled", timeRange: any}
# --ordering item shape: {key: string, direction: "ascending"|"descending"}
# --pagination shape: {cursor?: string, limit?: int}
export def "trace-ids post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: list # e.g. [{key: service.name, operator: is, value: foo}] — item shape: {key: string, operator: "is"|"is_not"|"is_set"|"is_not_set"|"is_one_of"|"is_not_one_of"|"gt"|"lt"|"gte"|"lte"|"matches"|"does_not_match"|"contains"|"does_not_contain"|"starts_with"|"does_not_start_with"|"ends_with"|"does_not_end_with"|"is_any", value?: any, values?: list}
  timeRange: any # A range of time between two time references.  (e.g. {from: now-30m, to: now}) — shape: {from: any, to: any}
  --dataset: string # Optional dataset to query across. Defaults to whatever is configured to be the default dataset for the organization.
  --sampling: any # shape: {mode: "adaptive"|"disabled", timeRange: any}
  --ordering: list # Any supported attribute keys to order by. — item shape: {key: string, direction: "ascending"|"descending"}
  --pagination: any # Cursor pagination is a technique for paging through a result set using a cursor. It is similar to offset pagination except that the cursor is an opaque value that encodes the position within the result set. This allows for fetching the next page of results from the current position without having to skip over a potentially large number of rows.  It is also more resilient against late-arriving data which otherwise would cause issues with offset pagination. For example, if a row is inserted between two pages of results then the second page would contain a duplicate row and the third page would be missing. — shape: {cursor?: string, limit?: int}
]: any -> record<traceIds: list<string>, cursors: record<before: string, after: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/trace/ids")
  let body = {filter: $filter, timeRange: $timeRange, dataset: $dataset, sampling: $sampling, ordering: $ordering, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive a list of views
#
# GET /api/views
export def "views list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> table<id: string, origin: string, dataset: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a view
#
# POST /api/views
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
export def "views post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-2
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<type: string, display: record<name: string, description: string>, permissions: list<record>, groupBy: list<string>, filter: list<record>, implicitFilter: list<record>, table: record<columns: list, sort: list>, visualizations: list<record>, serviceMapProperties: record<layout: string, externalServices: string, selectedMetric: string, particles: bool, nodeSizing: bool, expandedGroups: list>, query: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/views" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific view by origin or id.
#
# DELETE /api/views/{originOrId}
export def "views delete" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/views/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receive a specific view by its origin or id.
#
# GET /api/views/{originOrId}
export def "views get" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
]: nothing -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<type: string, display: record<name: string, description: string>, permissions: list<record>, groupBy: list<string>, filter: list<record>, implicitFilter: list<record>, table: record<columns: list, sort: list>, visualizations: list<record>, serviceMapProperties: record<layout: string, externalServices: string, selectedMetric: string, particles: bool, nodeSizing: bool, expandedGroups: list>, query: string, serviceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/views/($originOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update or insert a specific view by its origin or id.
#
# PUT /api/views/{originOrId}
# --metadata shape: {name: string, labels?: any, annotations?: any}
# --spec shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
export def "views put" [
  originOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string
  kind: string@kind-completer-2
  metadata: any # shape: {name: string, labels?: any, annotations?: any}
  spec: any # shape: {type: "resources"|"services"|"spans"|"logs"|"metrics"|"failed_checks"|"web_events"|"sql"|"profiles"|"gcp_cloud_run_services"|"gcp_cloud_run_jobs"|"gcp_pubsub"|"gcp_cloud_storage"|"gcp_cloud_sql_instances"|"aws_lambda", display: any, permissions?: list, groupBy?: list, filter?: list, implicitFilter?: list, table?: any, visualizations?: list, serviceMapProperties?: any, query?: string, serviceName?: string}
]: any -> record<kind: string, metadata: record<name: string, labels: record<dash0_com_id: string, dash0_com_origin: string, dash0_com_version: string, dash0_com_dataset: string, dash0_com_source: string>, annotations: record<dash0_com_deleted_at: string, dash0_com_folder_path: string, dash0_com_sharing: string>>, spec: record<type: string, display: record<name: string, description: string>, permissions: list<record>, groupBy: list<string>, filter: list<record>, implicitFilter: list<record>, table: record<columns: list, sort: list>, visualizations: list<record>, serviceMapProperties: record<layout: string, externalServices: string, selectedMetric: string, particles: bool, nodeSizing: bool, expandedGroups: list>, query: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/views/($originOrId)" $qp)
  let body = {kind: $kind, metadata: $metadata, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# OAuth 2.0 Authorization Endpoint (Unauthenticated)
#
# GET /oauth/authorize
export def "oauth-authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --response-type: string # Must be "code" for the authorization code flow.
  --client-id: string # The client identifier obtained during registration.
  --redirect-uri: string # Must match one of the client's registered redirect URIs. (format: uri)
  --scope: string # Space-separated list of requested scopes.
  --state: string # Opaque value for CSRF protection, returned unchanged in the redirect.
  --code-challenge: string # PKCE code challenge (RFC 7636).
  --code-challenge-method: string # Must be "S256".
  --prompt: string # Space-separated list of prompt directives. Supported value: "consent".
]: nothing -> record<error: record<code: int, message: string, traceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "prompt" $prompt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a new OAuth client
#
# POST /oauth/register
export def "oauth-register post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_name: string # Human-readable name of the client.
  redirect_uris: list # Array of allowed redirect URIs.
  --grant-types: list # Grant types the client intends to use.
  --response-types: list # Response types the client intends to use.
  --token-endpoint-auth-method: string@token-endpoint-auth-method-completer # - `none`: Public client, no client authentication (used by CLI/MCP clients). Only public clients are supported. This deviates from RFC 7591 which defaults to `client_secret_basic` when omitted.
  --scope: string # Space-separated list of scopes the client is requesting.
  --client-uri: string # URL of the client's home page. (format: uri)
  --logo-uri: string # URL of the client's logo image. (format: uri)
]: any -> record<client_id: string, client_name: string, redirect_uris: list<string>, grant_types: list<string>, response_types: list<string>, token_endpoint_auth_method: string, scope: string, client_uri: string, logo_uri: string, registration_access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/register")
  let body = {client_name: $client_name, redirect_uris: $redirect_uris, grant_types: $grant_types, response_types: $response_types, token_endpoint_auth_method: $token_endpoint_auth_method, scope: $scope, client_uri: $client_uri, logo_uri: $logo_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# OAuth 2.0 Token Revocation
#
# POST /oauth/revoke
export def "oauth-revoke post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token to be revoked.
  --token-type-hint: string@token-type-hint-completer # - `access_token`: An OAuth 2.0 access token. - `refresh_token`: An OAuth 2.0 refresh token.
]: any -> record<error: record<code: int, message: string, traceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/revoke")
  let body = {token: $body_token, token_type_hint: $token_type_hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# OAuth 2.0 Token Endpoint
#
# POST /oauth/token
export def "oauth-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_type: string@grant-type-completer # - `authorization_code`: The standard authorization code grant (RFC 6749 section 4.1). - `refresh_token`: Exchange a refresh token for new tokens (RFC 6749 section 6).
  --code: string # The authorization code (required for authorization_code grant).
  --redirect-uri: string # Must match the redirect_uri used in the authorization request (required for authorization_code grant). (format: uri)
  --client-id: string # The client identifier.
  --code-verifier: string # PKCE code verifier (required for authorization_code grant). All public clients must use PKCE (RFC 7636).
  --refresh-token: string # The refresh token (required for refresh_token grant).
  --scope: string # Space-separated list of requested scopes. For refresh_token grant, must be equal to or a subset of the originally granted scopes.
]: any -> record<access_token: string, token_type: string, expires_in: int, refresh_token: string, scope: string, dataset_restriction: string, datasets: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, client_id: $client_id, code_verifier: $code_verifier, refresh_token: $refresh_token, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
