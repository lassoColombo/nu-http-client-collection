# Auto-generated client for Elastic Cloud API v1
# Source: https://api.elastic-cloud.com/api/v1/api-docs-user/swagger.json
# Auth: --token flag or $env.ELASTIC_CLOUD_API_KEY

const BASE_URL = "https://api.elastic-cloud.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ELASTIC_CLOUD_API_KEY | default "" }
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

def base-url-completer [] { ["https://api.elastic-cloud.com" "https://api.elastic-cloud.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bucketing-strategy-completer [] { ["daily" "monthly"] }
def extension-type-completer [] { ["bundle" "plugin"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get-current-account" } } | get name | first)
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

# Fetch current account information
#
# GET /account
# operationId: get-current-account
export def "account get-current-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, trust: record<trust_all: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the current account
#
# PUT /account
# operationId: update-current-account
# --trust shape: {trust_all: bool}
export def "account update-current-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trust: record # Settings related to the level of trust of the clusters in this account — shape: {trust_all: bool}
]: any -> record<id: string, trust: record<trust_all: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = {trust: $trust} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the current account
#
# PATCH /account
# operationId: patch-current-account
export def "account patch-current-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: string, trust: record<trust_all: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get costs overview for the organization. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}
# DEPRECATED
# operationId: get-costs-overview
@deprecated
export def "billing-costs get-costs-overview" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch costs. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch costs. Defaults to the current date.
]: nothing -> record<costs: record<total: float, dimensions: list<record>>, trials: float, hourly_rate: float, balance: record<available: float, remaining: float, line_items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get charts for the organization. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}/charts
# DEPRECATED
# operationId: get-costs-charts
@deprecated
export def "billing-costs-charts get-costs-charts" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch costs. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch costs. Defaults to the current date.
  --bucketing-strategy: string@bucketing-strategy-completer # The desired bucketing strategy for the charts. Defaults to `daily`. (default: daily)
]: nothing -> record<data: table<timestamp: int, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "bucketing_strategy" $bucketing_strategy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)/charts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployments costs for the organization. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}/deployments
# DEPRECATED
# operationId: get-costs-deployments
@deprecated
export def "billing-costs-deployments get-costs-deployments" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch activity. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch activity. Defaults to the current date.
  --Accept: string # Accept header containing the content preference.
]: nothing -> record<total_cost: float, deployments: table<deployment_id: string, deployment_name: string, costs: record, hourly_rate: float, period: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)/deployments" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get charts by deployment. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}/deployments/{deployment_id}/charts
# DEPRECATED
# operationId: get-costs-charts-by-deployment
@deprecated
export def "billing-costs-deployments-charts get-costs-charts-by-deployment" [
  organization_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch costs. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch costs. Defaults to the current date.
  --bucketing-strategy: string@bucketing-strategy-completer # The desired bucketing strategy for the charts. Defaults to `daily`. (default: daily)
]: nothing -> record<data: table<timestamp: int, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "bucketing_strategy" $bucketing_strategy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)/deployments/($deployment_id)/charts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get itemized costs by deployments. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}/deployments/{deployment_id}/items
# DEPRECATED
# operationId: get-costs-items-by-deployment
@deprecated
export def "billing-costs-deployments-items get-costs-items-by-deployment" [
  organization_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch costs. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch costs. Defaults to the current date.
  --Accept: string # Determines the response body format. Can be either application/json or text/csv.
]: nothing -> record<costs: record<total: float, dimensions: list<record>>, data_transfer_and_storage: table<cost: float, name: string, quantity: record, rate: record, sku: string, type: string>, resources: table<hours: int, instance_count: int, period: record, kind: string, price: float, price_per_hour: float, name: string, sku: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)/deployments/($deployment_id)/items" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get itemized costs for the organization. Currently unavailable in self-hosted ECE.
#
# GET /billing/costs/{organization_id}/items
# DEPRECATED
# operationId: get-costs-items
@deprecated
export def "billing-costs-items get-costs-items" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # A datetime for the beginning of the desired range for which to fetch costs. Defaults to start of current month.
  --qp-to: string # A datetime for the end of the desired range for which to fetch costs. Defaults to the current date.
]: nothing -> record<costs: record<total: float, dimensions: list<record>>, data_transfer_and_storage: table<cost: float, name: string, quantity: record, rate: record, sku: string, type: string>, resources: table<hours: int, instance_count: int, period: record, kind: string, price: float, price_per_hour: float, name: string, sku: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/costs/($organization_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deployments
#
# GET /deployments
# operationId: list-deployments
export def "deployments list-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deployments: table<id: string, name: string, resources: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deployment
#
# POST /deployments
# operationId: create-deployment
# --resources shape: {elasticsearch?: list, kibana?: list, apm?: list, appsearch?: list, enterprise_search?: list, integrations_server?: list}
# --settings shape: {traffic_filter_settings?: record, observability?: record, byok?: record, autoscaling_enabled?: bool, solution_type?: string}
# --metadata shape: {tags?: list}
export def "deployments create-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string # An optional idempotency token - if two create requests share the same request_id token (min size 32 characters, max 128) then only one deployment will be created, the second request will return the info of that deployment (in the same format described below, but with blanks for auth-related fields)
  --validate-only: oneof<nothing, bool> # If true, will just validate the Deployment definition but will not perform the creation (default: false)
  --template-id: string # An optional template id - if present, the referenced template will be used to fill in the resources field of the deployment creation request. If any resources are present in the request together with the template, the ones coming in the request will prevail and no merging with the template will be performed.
  --name: string # A name for the deployment; otherwise this will be the generated deployment id
  --resources: record # Describes the resources that will belong to a Deployment — shape: {elasticsearch?: list, kibana?: list, apm?: list, appsearch?: list, enterprise_search?: list, integrations_server?: list}
  --settings: record # Additional configuration for the new deployment object. — shape: {traffic_filter_settings?: record, observability?: record, byok?: record, autoscaling_enabled?: bool, solution_type?: string}
  --metadata: record # Additional information about the new deployment object. — shape: {tags?: list}
  --alias: string # A user-defined alias to use in place of Cluster IDs for user-friendly URLs
  --region: string # Identifier of the region to be used as the default for all the resources of the deployment
  --version: string # The version for all the resources of the deployment (must be one of the supported versions). Defaults to the latest version if not specified.
]: any -> record<id: string, name: string, alias: string, created: bool, resources: table<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, kind: string, region: string, cloud_id: string, credentials: record, secret_token: string, warnings: list>, diagnostics: record<creates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>, updates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar") (serialize-qp "validate_only" $validate_only "scalar") (serialize-qp "template_id" $template_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments" $qp)
  let body = {name: $name, resources: $resources, settings: $settings, metadata: $metadata, alias: $alias, region: $region, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Deployments
#
# POST /deployments/_search
# operationId: search-deployments
# --query shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
export def "deployments-search search-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --minimal-metadata: string # Comma separated list of attributes to include in response for deployments found. Useful for reducing response size when retrieving many deployments. Use of this parameter moves the result to the minimal_metadata section of the response.
  --body-from: int # Deprecated, use cursor for a more scalable approach to paging. (format: int32)
  --cursor: string # To retrieve the next page of hits, set this to the cursor value of the previous response. When set, all other fields are ignored.
  --size: int # The maximum number of search results to return. (format: int32)
  --body-query: record # The container for all of the allowed Elasticsearch queries. Specify only one property each time. — shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
  --body-sort: list # An array of fields to sort the search results by. Defaults to query rank and last modified date descending.
]: any -> record<return_count: int, match_count: int, deployments: table<id: string, name: string, alias: string, healthy: bool, resources: record, settings: record, metadata: record>, minimal_metadata: list<record>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minimal_metadata" $minimal_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments/_search" $qp)
  let body = {from: $body_from, cursor: $cursor, size: $size, query: $body_query, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get eligible remote clusters
#
# POST /deployments/eligible-remote-clusters
# operationId: search-eligible-remote-clusters
# --query shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
export def "deployments-eligible-remote-clusters search-eligible-remote-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version of the Elasticsearch cluster cluster that will potentially be configured to have remote clusters.
  --body-from: int # Deprecated, use cursor for a more scalable approach to paging. (format: int32)
  --cursor: string # To retrieve the next page of hits, set this to the cursor value of the previous response. When set, all other fields are ignored.
  --size: int # The maximum number of search results to return. (format: int32)
  --body-query: record # The container for all of the allowed Elasticsearch queries. Specify only one property each time. — shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
  --body-sort: list # An array of fields to sort the search results by. Defaults to query rank and last modified date descending.
]: any -> record<return_count: int, match_count: int, deployments: table<id: string, name: string, alias: string, healthy: bool, resources: record, settings: record, metadata: record>, minimal_metadata: list<record>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments/eligible-remote-clusters" $qp)
  let body = {from: $body_from, cursor: $cursor, size: $size, query: $body_query, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Extensions
#
# GET /deployments/extensions
# operationId: list-extensions
export def "deployments-extensions list-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<extensions: table<id: string, name: string, description: string, url: string, download_url: string, extension_type: string, version: string, deployments: list, file_metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/extensions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an extension
#
# POST /deployments/extensions
# operationId: create-extension
export def "deployments-extensions create-extension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The extension name. Only ASCII alphanumeric and [_.-] characters allowed
  --description: string # The extension description.
  --download-url: string # The URL to download the extension archive.
  extension_type: string@extension-type-completer # The extension type.
  version: string # The Elasticsearch version.
]: any -> record<id: string, name: string, description: string, url: string, download_url: string, extension_type: string, version: string, deployments: list<string>, file_metadata: record<last_modified_date: string, size: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/extensions")
  let body = {name: $name, description: $description, download_url: $download_url, extension_type: $extension_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Extension
#
# GET /deployments/extensions/{extension_id}
# operationId: get-extension
export def "deployments-extensions get-extension" [
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deployments: oneof<nothing, bool> # Include deployments referencing this extension. Up to only 10000 deployments will be included. (default: false)
]: nothing -> record<id: string, name: string, description: string, url: string, download_url: string, extension_type: string, version: string, deployments: list<string>, file_metadata: record<last_modified_date: string, size: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deployments" $include_deployments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Extension
#
# POST /deployments/extensions/{extension_id}
# operationId: update-extension
export def "deployments-extensions update-extension" [
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The extension name.
  --description: string # The extension description.
  --download-url: string # The URL to download the extension archive.
  extension_type: string@extension-type-completer # The extension type.
  version: string # The Elasticsearch version.
]: any -> record<id: string, name: string, description: string, url: string, download_url: string, extension_type: string, version: string, deployments: list<string>, file_metadata: record<last_modified_date: string, size: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/extensions/($extension_id)")
  let body = {name: $name, description: $description, download_url: $download_url, extension_type: $extension_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Uploads the Extension
#
# PUT /deployments/extensions/{extension_id}
# operationId: upload-extension
export def "deployments-extensions upload-extension" [
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: path # Zip file that contains the extension
]: any -> record<id: string, name: string, description: string, url: string, download_url: string, extension_type: string, version: string, deployments: list<string>, file_metadata: record<last_modified_date: string, size: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/extensions/($extension_id)")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Extension
#
# DELETE /deployments/extensions/{extension_id}
# operationId: delete-extension
export def "deployments-extensions delete-extension" [
  extension_id: string
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
  let full_url = (build-url $base $"/deployments/extensions/($extension_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployment templates
#
# GET /deployments/templates
# operationId: get-deployment-templates-v2
export def "deployments-templates get-deployment-templates-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # An optional key/value pair in the form of (key:value) that will act as a filter and exclude any templates that do not have a matching metadata item associated.
  --show-instance-configurations: oneof<nothing, bool> # If true, will return details for each instance configuration referenced by the template. (default: true)
  --show-max-zones: oneof<nothing, bool> # If true, will populate the max_zones field in the instance configurations. Only relevant if show_instance_configurations=true. (default: false)
  --stack-version: string # If present, it will cause the returned deployment templates to be adapted to return only the elements allowed in that version.
  --hide-deprecated: oneof<nothing, bool> # If true, templates flagged as deprecated will NOT be returned. (default: false)
  --region: string # Region of the deployment templates
]: nothing -> table<id: string, name: string, description: string, deployment_template: record<name: string, resources: record, settings: record, metadata: record, alias: string, region: string, version: string>, system_owned: bool, source: record<facilitator: string, action: string, date: string, user_id: string, admin_id: string, remote_addresses: list>, metadata: list<record>, instance_configurations: list<record>, order: int, min_version: string, template_category_id: string, kibana_deeplink: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "show_instance_configurations" $show_instance_configurations "scalar") (serialize-qp "show_max_zones" $show_max_zones "scalar") (serialize-qp "stack_version" $stack_version "scalar") (serialize-qp "hide_deprecated" $hide_deprecated "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployment template
#
# GET /deployments/templates/{template_id}
# operationId: get-deployment-template-v2
export def "deployments-templates get-deployment-template-v2" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-instance-configurations: oneof<nothing, bool> # If true, will return details for each instance configuration referenced by the template. (default: true)
  --show-max-zones: oneof<nothing, bool> # If true, will populate the max_zones field in the instance configurations. Only relevant if show_instance_configurations=true. (default: false)
  --stack-version: string # If present, it will cause the returned deployment template to be adapted to return only the elements allowed in that version.
  --region: string # Region of the deployment template
]: nothing -> record<id: string, name: string, description: string, deployment_template: record<name: string, resources: record<elasticsearch: list, kibana: list, apm: list, appsearch: list, enterprise_search: list, integrations_server: list>, settings: record<traffic_filter_settings: record, observability: record, byok: record, autoscaling_enabled: bool, solution_type: string>, metadata: record<tags: list>, alias: string, region: string, version: string>, system_owned: bool, source: record<facilitator: string, action: string, date: string, user_id: string, admin_id: string, remote_addresses: list<string>>, metadata: table<key: string, value: string>, instance_configurations: table<id: string, name: string, config_version: int, description: string, instance_type: string, node_types: list, discrete_sizes: record, storage_multiplier: float, cpu_multiplier: float, metadata: record, max_zones: int>, order: int, min_version: string, template_category_id: string, kibana_deeplink: table<semver: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_instance_configurations" $show_instance_configurations "scalar") (serialize-qp "show_max_zones" $show_max_zones "scalar") (serialize-qp "stack_version" $stack_version "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/templates/($template_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get associated rulesets
#
# GET /deployments/traffic-filter/associations/{association_type}/{associated_entity_id}/rulesets
# operationId: get-traffic-filter-deployment-ruleset-associations
export def "deployments-traffic-filter-associations-rulesets get-traffic-filter-deployment-ruleset-associations" [
  association_type: string
  associated_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rulesets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/traffic-filter/associations/($association_type)/($associated_entity_id)/rulesets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List traffic filter claimed link id
#
# GET /deployments/traffic-filter/link-ids
# operationId: get-traffic-filter-claimed-link-ids
export def "deployments-traffic-filter-link-ids get-traffic-filter-claimed-link-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # If provided limits the claimed id to that region only.
  --organization-id: string # Retrieves a list of resources that are associated to the specified organization ID. It only takes effect if the user is an admin.
]: nothing -> record<claimed_link_ids: table<link_id: string, azure_endpoint_name: string, azure_endpoint_guid: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments/traffic-filter/link-ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Claim a link id
#
# POST /deployments/traffic-filter/link-ids/_claim
# operationId: claim-traffic-filter-link-id
export def "deployments-traffic-filter-link-ids-claim claim-traffic-filter-link-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --link-id: string # Link id. A GCP private service connect ID or AWS VPC endpoint ID
  --azure-endpoint-name: string # Name of the Azure Private Endpoint to allow connections from
  --azure-endpoint-guid: string # Resource GUID of the Azure Private Endpoint to allow connections from
  region: string # The claimed link id can be used only for traffic filter in the specific region
]: any -> record<link_id: string, azure_endpoint_name: string, azure_endpoint_guid: string, region: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/traffic-filter/link-ids/_claim")
  let body = {link_id: $link_id, azure_endpoint_name: $azure_endpoint_name, azure_endpoint_guid: $azure_endpoint_guid, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unclaims a link id
#
# POST /deployments/traffic-filter/link-ids/_unclaim
# operationId: unclaim-traffic-filter-link-id
export def "deployments-traffic-filter-link-ids-unclaim unclaim-traffic-filter-link-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --link-id: string # Link id. A GCP private service connect ID or AWS VPC endpoint ID
  --azure-endpoint-name: string # Name of the Azure Private Endpoint to allow connections from
  --azure-endpoint-guid: string # Resource GUID of the Azure Private Endpoint to allow connections from
  region: string # The claimed link id can be used only for traffic filter in the specific region
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/traffic-filter/link-ids/_unclaim")
  let body = {link_id: $link_id, azure_endpoint_name: $azure_endpoint_name, azure_endpoint_guid: $azure_endpoint_guid, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List traffic filter rulesets
#
# GET /deployments/traffic-filter/rulesets
# operationId: get-traffic-filter-rulesets
export def "deployments-traffic-filter-rulesets get-traffic-filter-rulesets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-associations: oneof<nothing, bool> # Retrieves a list of resources that are associated to the specified ruleset. (default: false)
  --region: string # If provided limits the rulesets to that region only.
  --organization-id: string # Retrieves a list of resources that are associated to the specified organization ID. It only takes effect if the user is an admin.
]: nothing -> record<rulesets: table<id: string, name: string, description: string, type: string, include_by_default: bool, region: string, rules: list, associations: list, total_associations: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_associations" $include_associations "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments/traffic-filter/rulesets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ruleset
#
# POST /deployments/traffic-filter/rulesets
# operationId: create-traffic-filter-ruleset
# --rules item shape: {id?: string, remote_cluster_org_id?: string, remote_cluster_id?: string, description?: string, source?: string, azure_endpoint_name?: string, azure_endpoint_guid?: string, egress_rule?: record}
export def "deployments-traffic-filter-rulesets create-traffic-filter-ruleset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the ruleset
  --description: string # Description of the ruleset
  type: string # Type of the ruleset
  --include-by-default: oneof<nothing, bool> # Should the ruleset be automatically included in the new deployments
  region: string # The ruleset can be attached only to deployments in the specific region
  rules: list # List of rules — item shape: {id?: string, remote_cluster_org_id?: string, remote_cluster_id?: string, description?: string, source?: string, azure_endpoint_name?: string, azure_endpoint_guid?: string, egress_rule?: record}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/traffic-filter/rulesets")
  let body = {name: $name, description: $description, type: $type, include_by_default: $include_by_default, region: $region, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the ruleset by ID.
#
# GET /deployments/traffic-filter/rulesets/{ruleset_id}
# operationId: get-traffic-filter-ruleset
export def "deployments-traffic-filter-rulesets get-traffic-filter-ruleset" [
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-associations: oneof<nothing, bool> # Retrieves a list of resources that are associated to the specified ruleset. (default: false)
]: nothing -> record<id: string, name: string, description: string, type: string, include_by_default: bool, region: string, rules: table<id: string, remote_cluster_org_id: string, remote_cluster_id: string, description: string, source: string, azure_endpoint_name: string, azure_endpoint_guid: string, egress_rule: record>, associations: table<entity_type: string, id: string>, total_associations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_associations" $include_associations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a ruleset
#
# PUT /deployments/traffic-filter/rulesets/{ruleset_id}
# operationId: update-traffic-filter-ruleset
# --rules item shape: {id?: string, remote_cluster_org_id?: string, remote_cluster_id?: string, description?: string, source?: string, azure_endpoint_name?: string, azure_endpoint_guid?: string, egress_rule?: record}
export def "deployments-traffic-filter-rulesets update-traffic-filter-ruleset" [
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the ruleset
  --description: string # Description of the ruleset
  type: string # Type of the ruleset
  --include-by-default: oneof<nothing, bool> # Should the ruleset be automatically included in the new deployments
  region: string # The ruleset can be attached only to deployments in the specific region
  rules: list # List of rules — item shape: {id?: string, remote_cluster_org_id?: string, remote_cluster_id?: string, description?: string, source?: string, azure_endpoint_name?: string, azure_endpoint_guid?: string, egress_rule?: record}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)")
  let body = {name: $name, description: $description, type: $type, include_by_default: $include_by_default, region: $region, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a ruleset
#
# DELETE /deployments/traffic-filter/rulesets/{ruleset_id}
# operationId: delete-traffic-filter-ruleset
export def "deployments-traffic-filter-rulesets delete-traffic-filter-ruleset" [
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-associations: oneof<nothing, bool> # When true, ignores the associations and deletes the ruleset. When false, recognizes the associations, which prevents the deletion of the rule set. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_associations" $ignore_associations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get associated deployments
#
# GET /deployments/traffic-filter/rulesets/{ruleset_id}/associations
# operationId: get-traffic-filter-ruleset-deployment-associations
export def "deployments-traffic-filter-rulesets-associations get-traffic-filter-ruleset-deployment-associations" [
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<associations: table<entity_type: string, id: string>, total_associations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)/associations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ruleset association
#
# POST /deployments/traffic-filter/rulesets/{ruleset_id}/associations
# operationId: create-traffic-filter-ruleset-association
export def "deployments-traffic-filter-rulesets-associations create-traffic-filter-ruleset-association" [
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_type: string # Type of the traffic filter ruleset association, such as 'deployment', 'cluster'
  id: string # ID of the entity, such as the deployment ID or Elasticsearch cluster ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)/associations")
  let body = {entity_type: $entity_type, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete ruleset association
#
# DELETE /deployments/traffic-filter/rulesets/{ruleset_id}/associations/{association_type}/{associated_entity_id}
# operationId: delete-traffic-filter-ruleset-association
export def "deployments-traffic-filter-rulesets-associations delete-traffic-filter-ruleset-association" [
  ruleset_id: string
  association_type: string
  associated_entity_id: string
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
  let full_url = (build-url $base $"/deployments/traffic-filter/rulesets/($ruleset_id)/associations/($association_type)/($associated_entity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment
#
# GET /deployments/{deployment_id}
# operationId: get-deployment
export def "deployments get-deployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-security: oneof<nothing, bool> # Whether to include the Elasticsearch 2.x security information in the response - can be large per cluster and also include credentials (default: false)
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include the plan history with the current and pending plan information. The results can be very large per cluster.  By default, if a given resource kind (e.g. Elasticsearch, Kibana, etc.) has more than 100 plans  (which should be very rare, most likely caused by a bug) only 100 plans are returned for the given resource type:  The first 10 plans, and the last 90 plans for that resource type.  If ALL of the plans are desired, pass the `force_all_plan_history` parameter with a value of `true`.  (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative) (default: false)
  --convert-legacy-plans: oneof<nothing, bool> # If showing plans, whether to leave pre-2.0.0 plans in their legacy format (the default), or whether to update them to 2.0.x+ format (if 'true') (default: false)
  --show-system-alerts: int # Number of system alerts (such as forced restarts due to memory limits) to be included in the response - can be large per cluster. Negative numbers or 0 will not return field. (default: 0)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --show-instance-metrics: oneof<nothing, bool> # Whether to show resources instance metrics in the response. (default: true)
  --show-instance-configurations: oneof<nothing, bool> # If true, will return details for each instance configuration referenced by the deployment. (default: true)
  --enrich-with-template: oneof<nothing, bool> # If showing plans, whether to enrich the plan by including the missing elements from the deployment template it is based on (default: true)
  --force-all-plan-history: oneof<nothing, bool> # Force show the entire plan history no matter how long.  As noted in the `show_plan_history` parameter description, by default, a maximum of 100 plans are shown per resource.   If `true`, this parameter overrides the default, and ALL plans are returned.  Use with care as the plan history can be VERY large. Consider pairing with `show_plan_logs=false`.   (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<id: string, name: string, alias: string, healthy: bool, resources: record<elasticsearch: list<record>, kibana: list<record>, apm: list<record>, appsearch: list<record>, enterprise_search: list<record>, integrations_server: list<record>>, settings: record<traffic_filter_settings: record<rulesets: list>, observability: record<logging: record, metrics: record>, autoscaling_enabled: bool, auto_ops: record<status: string>, byok: record<key_resource_path: string>, solution_type: string>, metadata: record<tags: list<record>, byok_enabled: bool>, observability: record<healthy: bool, logging: record<healthy: bool, urls: record, issues: list>, metrics: record<healthy: bool, urls: record, issues: list>, issues: list<record>>, instance_configurations: table<id: string, name: string, config_version: int, description: string, instance_type: string, node_types: list, discrete_sizes: record, storage_multiplier: float, cpu_multiplier: float, metadata: record, max_zones: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_security" $show_security "scalar") (serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "convert_legacy_plans" $convert_legacy_plans "scalar") (serialize-qp "show_system_alerts" $show_system_alerts "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "show_instance_metrics" $show_instance_metrics "scalar") (serialize-qp "show_instance_configurations" $show_instance_configurations "scalar") (serialize-qp "enrich_with_template" $enrich_with_template "scalar") (serialize-qp "force_all_plan_history" $force_all_plan_history "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Deployment
#
# PUT /deployments/{deployment_id}
# operationId: update-deployment
# --resources shape: {elasticsearch?: list, kibana?: list, apm?: list, appsearch?: list, enterprise_search?: list, integrations_server?: list}
# --settings shape: {observability?: record, autoscaling_enabled?: bool, auto_ops?: record}
# --metadata shape: {tags?: list}
export def "deployments update-deployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hide-pruned-orphans: oneof<nothing, bool> # Whether or not to hide orphaned resources that were shut down (relevant if prune on the request is true) (default: false)
  --skip-snapshot: oneof<nothing, bool> # Whether or not to skip snapshots before shutting down orphaned resources (relevant if prune on the request is true) (default: false)
  --validate-only: oneof<nothing, bool> # If true, will just validate the Deployment definition but will not perform the update (default: false)
  --version: string # If specified then checks for conflicts against the version stored in the persistent store (returned in 'x-cloud-resource-version' of the GET request)
  --name: string # A new name for the deployment, otherwise stays the same.
  --prune-orphans: oneof<nothing, bool> # Whether or not to prune orphan resources that are no longer mentioned in this request. Note that resourcesare tracked by ref_id, and if a resource's ref_id is changed, any previous running resources created with that previousref_id are considered to be orphaned as well.
  --resources: record # Describes the Deployment resource updates — shape: {elasticsearch?: list, kibana?: list, apm?: list, appsearch?: list, enterprise_search?: list, integrations_server?: list}
  --settings: record # Additional configuration for the new deployment object. — shape: {observability?: record, autoscaling_enabled?: bool, auto_ops?: record}
  --metadata: record # Additional information about the current deployment object. — shape: {tags?: list}
  --alias: string # A user-defined alias to use in place of Cluster IDs for user-friendly URLs
]: any -> record<id: string, name: string, alias: string, resources: table<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, kind: string, region: string, cloud_id: string, credentials: record, secret_token: string, warnings: list>, shutdown_resources: record<elasticsearch: list<record>, kibana: list<string>, apm: list<string>, appsearch: list<string>, enterprise_search: list<string>, integrations_server: list<string>>, diagnostics: record<creates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>, updates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>>, settings: record<traffic_filter_settings: record<rulesets: list>, observability: record<logging: record, metrics: record>, autoscaling_enabled: bool, auto_ops: record<status: string>, byok: record<key_resource_path: string>, solution_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hide_pruned_orphans" $hide_pruned_orphans "scalar") (serialize-qp "skip_snapshot" $skip_snapshot "scalar") (serialize-qp "validate_only" $validate_only "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)" $qp)
  let body = {name: $name, prune_orphans: $prune_orphans, resources: $resources, settings: $settings, metadata: $metadata, alias: $alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restores a shutdown Deployment
#
# POST /deployments/{deployment_id}/_restore
# operationId: restore-deployment
export def "deployments-restore restore-deployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --restore-snapshot: oneof<nothing, bool> # Whether or not to restore a snapshot for those resources that allow it. (default: false)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restore_snapshot" $restore_snapshot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/_restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shuts down Deployment
#
# POST /deployments/{deployment_id}/_shutdown
# operationId: shutdown-deployment
export def "deployments-shutdown shutdown-deployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hide: oneof<nothing, bool> # Whether or not to hide the deployment and its resources.Only applicable for Platform administrators.
  --skip-snapshot: oneof<nothing, bool> # Whether or not to skip snapshots before shutting down the resources (default: false)
]: nothing -> record<id: string, name: string, orphaned: record<elasticsearch: list<record>, kibana: list<string>, apm: list<string>, appsearch: list<string>, enterprise_search: list<string>, integrations_server: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hide" $hide "scalar") (serialize-qp "skip_snapshot" $skip_snapshot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/_shutdown" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment APM Resource Info
#
# GET /deployments/{deployment_id}/apm/{ref_id}
# operationId: get-deployment-apm-resource-info
export def "deployments-apm get-deployment-apm-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, region: string, info: record<id: string, name: string, elasticsearch_cluster: record<elasticsearch_id: string, links: record>, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, external_links: list<record>, links: record, settings: record<metadata: record>, region: string, apm_server_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/apm/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the secret token for an APM resource.
#
# POST /deployments/{deployment_id}/apm/{ref_id}/_reset-token
# operationId: deployment-apm-reset-secret-token
export def "deployments-apm-reset-token deployment-apm-reset-secret-token" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apm_id: string, secret_token: string, diagnostics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/apm/($ref_id)/_reset-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment App Search Resource Info
#
# GET /deployments/{deployment_id}/appsearch/{ref_id}
# operationId: get-deployment-appsearch-resource-info
export def "deployments-appsearch get-deployment-appsearch-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, region: string, info: record<id: string, name: string, elasticsearch_cluster: record<elasticsearch_id: string, links: record>, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, external_links: list<record>, links: record, settings: record<metadata: record>, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/appsearch/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set AppSearch read-only status
#
# GET /deployments/{deployment_id}/appsearch/{ref_id}/read_only_mode
# operationId: get-appsearch-read-only-mode
export def "deployments-appsearch-read-only-mode get-appsearch-read-only-mode" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/appsearch/($ref_id)/read_only_mode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set AppSearch read-only status
#
# PUT /deployments/{deployment_id}/appsearch/{ref_id}/read_only_mode
# operationId: set-appsearch-read-only-mode
export def "deployments-appsearch-read-only-mode set-appsearch-read-only-mode" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Enabled or disabled read-only mode
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/appsearch/($ref_id)/read_only_mode")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get certificate authority
#
# GET /deployments/{deployment_id}/certificate-authority
# operationId: get-deployment-certificate-authority
export def "deployments-certificate-authority get-deployment-certificate-authority" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recommended_trust_restriction: string, public_certificates: table<active: bool, pem: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/certificate-authority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment Elasticsearch Resource Info
#
# GET /deployments/{deployment_id}/elasticsearch/{ref_id}
# operationId: get-deployment-es-resource-info
export def "deployments-elasticsearch get-deployment-es-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-security: oneof<nothing, bool> # Whether to include the Elasticsearch 2.x security information in the response - can be large per cluster and also include credentials. (default: false)
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --convert-legacy-plans: oneof<nothing, bool> # If showing plans, whether to leave pre-2.0.0 plans in their legacy format (the default), or whether to update them to 2.0.x+ format (if 'true'). (default: false)
  --show-system-alerts: int # Number of system alerts (such as forced restarts due to memory limits) to be included in the response - can be large per cluster. Negative numbers or 0 will not return field. (default: 0)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --enrich-with-template: oneof<nothing, bool> # If showing plans, whether to enrich the plan by including the missing elements from the deployment template it is based on. (default: true)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, id: string, region: string, info: record<cluster_id: string, cluster_name: string, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, elasticsearch: record<healthy: bool, shard_info: record, shards_status: record, master_info: record, blocking_issues: record, cluster_blocking_issues: record>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, system_alerts: list<record>, associated_kibana_clusters: list<record>, associated_apm_clusters: list<record>, associated_appsearch_clusters: list<record>, associated_enterprise_search_clusters: list<record>, security: record<version: int, last_modified: string, users: list, roles: record, users_roles: list>, elasticsearch_monitoring_info: record<healthy: bool, last_modified: string, last_update_status: string, source_cluster_ids: list, destination_cluster_ids: list>, snapshots: record<healthy: bool, count: int, latest_successful: bool, latest_status: string, scheduled_time: string, latest_end_time: string, latest_successful_end_time: string, recent_success: bool>, external_links: list<record>, links: record, settings: record<snapshot: record, monitoring: record, metadata: record, curation: record, dedicated_masters_threshold: int, traffic_filter: record, trust: record, keystore_contents: record>, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_security" $show_security "scalar") (serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "convert_legacy_plans" $convert_legacy_plans "scalar") (serialize-qp "show_system_alerts" $show_system_alerts "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "enrich_with_template" $enrich_with_template "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate Elasticsearch and associated Kibana resources to enable CCR
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_enable-ccr
# operationId: enable-deployment-resource-ccr
export def "deployments-elasticsearch-enable-ccr enable-deployment-resource-ccr" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validate-only: oneof<nothing, bool> # When `true`, will not enable CCR but returns warnings if any elements may lose availability during CCR enablement (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_only" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_enable-ccr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate Elasticsearch resource to use ILM
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_enable-ilm
# operationId: enable-deployment-resource-ilm
# --index_patterns item shape: {index_pattern: string, policy_name: string, node_attributes?: record}
export def "deployments-elasticsearch-enable-ilm enable-deployment-resource-ilm" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validate-only: oneof<nothing, bool> # When `true`, does not enable ILM but returns warnings if any applications may lose availability during ILM migration. (default: false)
  index_patterns: list # A locally-unique user-specified id for Kibana — item shape: {index_pattern: string, policy_name: string, node_attributes?: record}
]: any -> record<warnings: table<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_only" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_enable-ilm" $qp)
  let body = {index_patterns: $index_patterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate Elasticsearch resource to use SLM
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_enable-slm
# operationId: enable-deployment-resource-slm
export def "deployments-elasticsearch-enable-slm enable-deployment-resource-slm" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validate-only: oneof<nothing, bool> # When `true`, does not enable SLM but returns warnings if any applications may lose availability during SLM migration. (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_only" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_enable-slm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset 'elastic' user password
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_reset-password
# operationId: reset-elasticsearch-user-password
export def "deployments-elasticsearch-reset-password reset-elasticsearch-user-password" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --check-completion: oneof<nothing, bool> # If true, will not reset elastic user password and instead will return a status code signaling whether or not the current credentials are ready to use (eg from creation or the last call to _reset_password) (default: false)
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "check_completion" $check_completion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_reset-password" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart Deployment Elasticsearch Resource
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_restart
# operationId: restart-deployment-es-resource
export def "deployments-elasticsearch-restart restart-deployment-es-resource" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --restore-snapshot: oneof<nothing, bool> # When set to true and restoring from shutdown, then will restore the cluster from the last snapshot (if available). (default: true)
  --skip-snapshot: oneof<nothing, bool> # If true, will not take a snapshot of the cluster before restarting. (default: true)
  --cancel-pending: oneof<nothing, bool> # If true, cancels any pending plans before restarting. If false and there are pending plans, returns an error. (default: false)
  --group-attribute: string # Indicates the property or properties used to divide the list of instances to restart in groups. Valid options are: '\_\_all\_\_' (restart all at once), '\_\_zone\_\_' by logical zone, '\_\_name\_\_' one instance at a time, or a comma-separated list of attributes of the instances (default: __zone__)
  --shard-init-wait-time: int # The time, in seconds, to wait for shards that show no progress of initializing, before rolling the next group (default: 10 minutes) (default: 600)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restore_snapshot" $restore_snapshot "scalar") (serialize-qp "skip_snapshot" $skip_snapshot "scalar") (serialize-qp "cancel_pending" $cancel_pending "scalar") (serialize-qp "group_attribute" $group_attribute "scalar") (serialize-qp "shard_init_wait_time" $shard_init_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shutdown Deployment Elasticsearch Resource
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/_shutdown
# operationId: shutdown-deployment-es-resource
export def "deployments-elasticsearch-shutdown shutdown-deployment-es-resource" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hide: oneof<nothing, bool> # Hide cluster on shutdown. Hidden clusters are not listed by default. Only applicable for Platform administrators.
  --skip-snapshot: oneof<nothing, bool> # If true, will skip taking a snapshot of the cluster before shutting the cluster down (if even possible). (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hide" $hide "scalar") (serialize-qp "skip_snapshot" $skip_snapshot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/_shutdown" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get eligible remote clusters
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/eligible-remote-clusters
# operationId: get-deployment-es-resource-eligible-remote-clusters
# --query shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
export def "deployments-elasticsearch-eligible-remote-clusters get-deployment-es-resource-eligible-remote-clusters" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: int # Deprecated, use cursor for a more scalable approach to paging. (format: int32)
  --cursor: string # To retrieve the next page of hits, set this to the cursor value of the previous response. When set, all other fields are ignored.
  --size: int # The maximum number of search results to return. (format: int32)
  --body-query: record # The container for all of the allowed Elasticsearch queries. Specify only one property each time. — shape: {match?: record, match_all?: record, match_none?: record, term?: record, bool?: record, query_string?: record, nested?: record, prefix?: record, exists?: record, range?: record, simple_query_string?: record}
  --body-sort: list # An array of fields to sort the search results by. Defaults to query rank and last modified date descending.
]: any -> record<return_count: int, match_count: int, deployments: table<id: string, name: string, alias: string, healthy: bool, resources: record, settings: record, metadata: record>, minimal_metadata: list<record>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/eligible-remote-clusters")
  let body = {from: $body_from, cursor: $cursor, size: $size, query: $body_query, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the items in the Elasticsearch resource keystore
#
# GET /deployments/{deployment_id}/elasticsearch/{ref_id}/keystore
# operationId: get-deployment-es-resource-keystore
export def "deployments-elasticsearch-keystore get-deployment-es-resource-keystore" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<secrets: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/keystore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove items from the Elasticsearch resource keystore
#
# PATCH /deployments/{deployment_id}/elasticsearch/{ref_id}/keystore
# operationId: set-deployment-es-resource-keystore
export def "deployments-elasticsearch-keystore set-deployment-es-resource-keystore" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validate-only: oneof<nothing, bool> # When `true`, does nothing except return the entries' allowlist and reloadability statuses. (default: false)
  secrets: record # List of secrets
]: any -> record<secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_only" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/keystore" $qp)
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get certificate based remote clusters
#
# GET /deployments/{deployment_id}/elasticsearch/{ref_id}/remote-clusters
# operationId: get-deployment-es-resource-remote-clusters
export def "deployments-elasticsearch-remote-clusters get-deployment-es-resource-remote-clusters" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resources: table<deployment_id: string, elasticsearch_ref_id: string, alias: string, skip_unavailable: bool, info: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/remote-clusters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set certificate based remote clusters
#
# PUT /deployments/{deployment_id}/elasticsearch/{ref_id}/remote-clusters
# operationId: set-deployment-es-resource-remote-clusters
# --resources item shape: {deployment_id: string, elasticsearch_ref_id: string, alias: string, skip_unavailable?: bool, info?: record}
export def "deployments-elasticsearch-remote-clusters set-deployment-es-resource-remote-clusters" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resources: list # The remote resources — item shape: {deployment_id: string, elasticsearch_ref_id: string, alias: string, skip_unavailable?: bool, info?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/remote-clusters")
  let body = {resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the attached snapshot repositories
#
# GET /deployments/{deployment_id}/elasticsearch/{ref_id}/snapshot/repository
# operationId: get-deployment-es-resource-snapshot-repository
export def "deployments-elasticsearch-snapshot-repository get-deployment-es-resource-snapshot-repository" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<repositories: table<cluster_id: string, deployment_id: string, deployment_name: string, repository_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/snapshot/repository")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snapshot repository for Elasticsearch resource
#
# POST /deployments/{deployment_id}/elasticsearch/{ref_id}/snapshot/repository
# operationId: create-deployment-es-resource-snapshot-repository
export def "deployments-elasticsearch-snapshot-repository create-deployment-es-resource-snapshot-repository" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_deployment_id: string # Source deployment ID whose snapshots will be accessible from the target cluster
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/snapshot/repository")
  let body = {source_deployment_id: $source_deployment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove the attached snapshot repository
#
# DELETE /deployments/{deployment_id}/elasticsearch/{ref_id}/snapshot/repository/{repository_name}
# operationId: delete-deployment-es-resource-snapshot-repository
export def "deployments-elasticsearch-snapshot-repository delete-deployment-es-resource-snapshot-repository" [
  deployment_id: string
  ref_id: string
  repository_name: string
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
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/snapshot/repository/($repository_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Elasticsearch tiers
#
# GET /deployments/{deployment_id}/elasticsearch/{ref_id}/tiers
# operationId: get-deployment-es-resource-tiers
export def "deployments-elasticsearch-tiers get-deployment-es-resource-tiers" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hot_content: record<memory_size: int, zone_count: int, available_sizes: list<int>>, warm: record<memory_size: int, zone_count: int, available_sizes: list<int>>, cold: record<memory_size: int, zone_count: int, available_sizes: list<int>>, frozen: record<memory_size: int, zone_count: int, available_sizes: list<int>>, master: record<memory_size: int, zone_count: int, available_sizes: list<int>>, coordinating: record<memory_size: int, zone_count: int, available_sizes: list<int>>, ml: record<memory_size: int, zone_count: int, available_sizes: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/tiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Elasticsearch tiers
#
# PATCH /deployments/{deployment_id}/elasticsearch/{ref_id}/tiers
# operationId: update-deployment-es-resource-tier
# --hot_content shape: {memory_size?: int, zone_count?: int}
# --warm shape: {memory_size?: int, zone_count?: int}
# --cold shape: {memory_size?: int, zone_count?: int}
# --frozen shape: {memory_size?: int, zone_count?: int}
# --master shape: {memory_size?: int, zone_count?: int}
# --coordinating shape: {memory_size?: int, zone_count?: int}
# --ml shape: {memory_size?: int, zone_count?: int}
export def "deployments-elasticsearch-tiers update-deployment-es-resource-tier" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hot-content: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --warm: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --cold: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --frozen: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --master: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --coordinating: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
  --ml: record # Desired configuration for an individual Elasticsearch tier — shape: {memory_size?: int, zone_count?: int}
]: any -> record<id: string, name: string, alias: string, resources: table<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, kind: string, region: string, cloud_id: string, credentials: record, secret_token: string, warnings: list>, shutdown_resources: record<elasticsearch: list<record>, kibana: list<string>, apm: list<string>, appsearch: list<string>, enterprise_search: list<string>, integrations_server: list<string>>, diagnostics: record<creates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>, updates: record<elasticsearch: list, kibana: list, apm: list, integrations_server: list, appsearch: list, enterprise_search: list>>, settings: record<traffic_filter_settings: record<rulesets: list>, observability: record<logging: record, metrics: record>, autoscaling_enabled: bool, auto_ops: record<status: string>, byok: record<key_resource_path: string>, solution_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/elasticsearch/($ref_id)/tiers")
  let body = {hot_content: $hot_content, warm: $warm, cold: $cold, frozen: $frozen, master: $master, coordinating: $coordinating, ml: $ml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Deployment Enterprise Search Resource Info
#
# GET /deployments/{deployment_id}/enterprise_search/{ref_id}
# operationId: get-deployment-enterprise-search-resource-info
export def "deployments-enterprise-search get-deployment-enterprise-search-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, region: string, info: record<id: string, name: string, elasticsearch_cluster: record<elasticsearch_id: string, links: record>, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, external_links: list<record>, links: record, settings: record<metadata: record>, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/enterprise_search/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment Integrations Server Resource Info
#
# GET /deployments/{deployment_id}/integrations_server/{ref_id}
# operationId: get-deployment-integrations-server-resource-info
export def "deployments-integrations-server get-deployment-integrations-server-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, region: string, info: record<id: string, name: string, elasticsearch_cluster: record<elasticsearch_id: string, links: record>, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, external_links: list<record>, links: record, settings: record<metadata: record>, region: string, apm_server_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/integrations_server/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment Kibana Resource Info
#
# GET /deployments/{deployment_id}/kibana/{ref_id}
# operationId: get-deployment-kib-resource-info
export def "deployments-kibana get-deployment-kib-resource-info" [
  deployment_id: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-metadata: oneof<nothing, bool> # Whether to include the full cluster metadata in the response - can be large per cluster and also include credentials. (default: false)
  --show-plans: oneof<nothing, bool> # Whether to include the full current and pending plan information in the response - can be large per cluster. (default: true)
  --show-plan-logs: oneof<nothing, bool> # Whether to include with the current and pending plan information the attempt log - can be very large per cluster. (default: false)
  --show-plan-history: oneof<nothing, bool> # Whether to include with the current and pending plan information the plan history- can be very large per cluster. (default: false)
  --show-plan-defaults: oneof<nothing, bool> # If showing plans, whether to show values that are left at their default value (less readable but more informative). (default: false)
  --convert-legacy-plans: oneof<nothing, bool> # If showing plans, whether to leave pre-2.0.0 plans in their legacy format (the default), or whether to update them to 2.0.x+ format (if 'true'). (default: false)
  --show-settings: oneof<nothing, bool> # Whether to show cluster settings in the response. (default: false)
  --clear-transient: oneof<nothing, bool> # If set (defaults to false) then removes the transient section from all child resources, making it safe to reapply via an update (default: false)
]: nothing -> record<ref_id: string, elasticsearch_cluster_ref_id: string, id: string, region: string, info: record<cluster_id: string, cluster_name: string, elasticsearch_cluster: record<elasticsearch_id: string, links: record>, deployment_id: string, healthy: bool, status: string, plan_info: record<healthy: bool, current: record, pending: record, history: list>, metadata: record<version: int, last_modified: string, endpoint: string, service_url: string, aliased_endpoint: string, aliased_url: string, cloud_id: string, raw: record, ports: record, services_urls: list>, topology: record<healthy: bool, instances: list>, external_links: list<record>, links: record, settings: record<metadata: record>, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_metadata" $show_metadata "scalar") (serialize-qp "show_plans" $show_plans "scalar") (serialize-qp "show_plan_logs" $show_plan_logs "scalar") (serialize-qp "show_plan_history" $show_plan_history "scalar") (serialize-qp "show_plan_defaults" $show_plan_defaults "scalar") (serialize-qp "convert_legacy_plans" $convert_legacy_plans "scalar") (serialize-qp "show_settings" $show_settings "scalar") (serialize-qp "clear_transient" $clear_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/kibana/($ref_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Build request to migrate deployment to a different template
#
# GET /deployments/{deployment_id}/migrate_template
# operationId: migrate-deployment-template
export def "deployments-migrate-template migrate-deployment-template" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-id: string # The ID of the deployment template to migrate to
  --skip-instance-metrics-check: oneof<nothing, bool> # If true, will skip the instance metrics check for memory and disk usage calculations (default: false)
]: nothing -> record<name: string, prune_orphans: bool, resources: record<elasticsearch: list<record>, kibana: list<record>, apm: list<record>, appsearch: list<record>, enterprise_search: list<record>, integrations_server: list<record>>, settings: record<observability: record<logging: record, metrics: record>, autoscaling_enabled: bool, auto_ops: record<status: string>>, metadata: record<tags: list<record>>, alias: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template_id" $template_id "scalar") (serialize-qp "skip_instance_metrics_check" $skip_instance_metrics_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/migrate_template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the tags for a Deployment
#
# GET /deployments/{deployment_id}/tags
# operationId: get-deployment-tags
export def "deployments-tags get-deployment-tags" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the tags for a Deployment
#
# PUT /deployments/{deployment_id}/tags
# operationId: set-deployment-tags
# --tags item shape: {key: string, value: string}
export def "deployments-tags set-deployment-tags" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: list # Arbitrary user-defined metadata associated with this deployment — item shape: {key: string, value: string}
]: any -> record<tags: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/tags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade a Deployment to a new Elastic Stack version
#
# POST /deployments/{deployment_id}/upgrade
# operationId: upgrade-deployment
export def "deployments-upgrade upgrade-deployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target_version: string # Target Elastic Stack version to which to upgrade
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/upgrade")
  let body = {target_version: $target_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Deployment upgrade assistant status
#
# GET /deployments/{deployment_id}/upgrade_assistant/status
# operationId: get-deployment-upgrade-assistant-status
export def "deployments-upgrade-assistant-status get-deployment-upgrade-assistant-status" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target-version: string # If present, value is included in resource request to provide additional context (only supported for Kibana)
]: nothing -> record<ready_for_upgrade: bool, details: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_version" $target_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/upgrade_assistant/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores a shutdown resource
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/_restore
# operationId: restore-deployment-resource
export def "deployments-restore restore-deployment-resource" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --restore-snapshot: oneof<nothing, bool> # Whether or not to restore a snapshot for those resources that allow it. (default: false)
]: nothing -> record<id: string, kind: string, ref_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restore_snapshot" $restore_snapshot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/_restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start all instances
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/_start
# operationId: start-deployment-resource-instances-all
export def "deployments-instances-start start-deployment-resource-instances-all" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/_start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop all instances
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/_stop
# operationId: stop-deployment-resource-instances-all
export def "deployments-instances-stop stop-deployment-resource-instances-all" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/_stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start maintenance mode (all instances)
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/maintenance-mode/_start
# operationId: start-deployment-resource-instances-all-maintenance-mode
export def "deployments-instances-maintenance-mode-start start-deployment-resource-instances-all-maintenance-mode" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/maintenance-mode/_start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop maintenance mode (all instances)
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/maintenance-mode/_stop
# operationId: stop-deployment-resource-instances-all-maintenance-mode
export def "deployments-instances-maintenance-mode-stop stop-deployment-resource-instances-all-maintenance-mode" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/maintenance-mode/_stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start instances
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/{instance_ids}/_start
# operationId: start-deployment-resource-instances
export def "deployments-instances-start start-deployment-resource-instances" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  instance_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-missing: oneof<nothing, bool> # If true and the instance does not exist then quietly proceed to the next instance, otherwise treated as an error (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_missing" $ignore_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/($instance_ids)/_start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop instances
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/{instance_ids}/_stop
# operationId: stop-deployment-resource-instances
export def "deployments-instances-stop stop-deployment-resource-instances" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  instance_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-missing: oneof<nothing, bool> # If true and the instance does not exist then quietly proceed to the next instance, otherwise treated as an error. (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_missing" $ignore_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/($instance_ids)/_stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start maintenance mode
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/{instance_ids}/maintenance-mode/_start
# operationId: start-deployment-resource-maintenance-mode
export def "deployments-instances-maintenance-mode-start start-deployment-resource-maintenance-mode" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  instance_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-missing: oneof<nothing, bool> # If true and the instance does not exist then quietly proceed to the next instance, otherwise treated as an error. (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_missing" $ignore_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/($instance_ids)/maintenance-mode/_start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop maintenance mode
#
# POST /deployments/{deployment_id}/{resource_kind}/{ref_id}/instances/{instance_ids}/maintenance-mode/_stop
# operationId: stop-deployment-resource-maintenance-mode
export def "deployments-instances-maintenance-mode-stop stop-deployment-resource-maintenance-mode" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  instance_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-missing: oneof<nothing, bool> # If true and the instance does not exist then quietly proceed to the next instance, otherwise treated as an error. (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_missing" $ignore_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/instances/($instance_ids)/maintenance-mode/_stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel resource pending plan
#
# DELETE /deployments/{deployment_id}/{resource_kind}/{ref_id}/plan/pending
# operationId: cancel-deployment-resource-pending-plan
export def "deployments-plan-pending cancel-deployment-resource-pending-plan" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-delete: oneof<nothing, bool> # When `true`, deletes the pending plan instead of attempting a graceful cancellation. The default is `false`. (default: false)
  --ignore-missing: oneof<nothing, bool> # When `true`, returns successfully, even when plans are missing. The default is `false`. (default: false)
]: nothing -> record<id: string, kind: string, ref_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_delete" $force_delete "scalar") (serialize-qp "ignore_missing" $ignore_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/plan/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the user settings of a Deployment resource
#
# GET /deployments/{deployment_id}/{resource_kind}/{ref_id}/user_settings
# operationId: get-deployment-resource-user-settings
export def "deployments-user-settings get-deployment-resource-user-settings" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/user_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user settings for a deployment resource
#
# PUT /deployments/{deployment_id}/{resource_kind}/{ref_id}/user_settings
# operationId: update-deployment-resource-user-settings
export def "deployments-user-settings update-deployment-resource-user-settings" [
  deployment_id: string
  resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_settings: record # A JSON object containing the user settings for the resource. Replaces all existing user settings when submitted via PUT.
]: any -> record<user_settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_id)/($resource_kind)/($ref_id)/user_settings")
  let body = {user_settings: $user_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restart Deployment Stateless Resource
#
# POST /deployments/{deployment_id}/{stateless_resource_kind}/{ref_id}/_restart
# operationId: restart-deployment-stateless-resource
export def "deployments-restart restart-deployment-stateless-resource" [
  deployment_id: string
  stateless_resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancel-pending: oneof<nothing, bool> # If true, cancels any pending plans before restarting. If false and there are pending plans, returns an error. (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cancel_pending" $cancel_pending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($stateless_resource_kind)/($ref_id)/_restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shutdown Deployment Stateless Resource
#
# POST /deployments/{deployment_id}/{stateless_resource_kind}/{ref_id}/_shutdown
# operationId: shutdown-deployment-stateless-resource
export def "deployments-shutdown shutdown-deployment-stateless-resource" [
  deployment_id: string
  stateless_resource_kind: string
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hide: oneof<nothing, bool> # Hide cluster on shutdown. Hidden clusters are not listed by default. Only applicable for Platform administrators.
  --skip-snapshot: oneof<nothing, bool> # If true, will skip taking a snapshot of the cluster before shutting the cluster down (if even possible) (default: false)
]: nothing -> record<warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hide" $hide "scalar") (serialize-qp "skip_snapshot" $skip_snapshot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($deployment_id)/($stateless_resource_kind)/($ref_id)/_shutdown" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /organizations
# operationId: list-organizations
export def "organizations list-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizations: table<id: string, name: string, default_disk_usage_alerts_enabled: bool, notifications_allowed_email_domains: list, billing_contacts: list, operational_contacts: list, sso_login_identifier: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization invitation
#
# GET /organizations/invitations/{invitation_token}
# operationId: get-organization-invitation
export def "organizations-invitations get-organization-invitation" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: string, email: string, created_at: string, expires_at: string, expired: bool, accepted_at: string, organization: record<id: string, name: string, default_disk_usage_alerts_enabled: bool, notifications_allowed_email_domains: list<string>, billing_contacts: list<string>, operational_contacts: list<string>, sso_login_identifier: string>, role_assignments: record<platform: list<record>, organization: list<record>, deployment: list<record>, project: record<elasticsearch: list, observability: list, security: list, workplaceai: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/invitations/($invitation_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept an organization invitation
#
# POST /organizations/invitations/{invitation_token}/_accept
# operationId: accept-organization-invitation
export def "organizations-invitations-accept accept-organization-invitation" [
  invitation_token: string
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
  let full_url = (build-url $base $"/organizations/invitations/($invitation_token)/_accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch organization information
#
# GET /organizations/{organization_id}
# operationId: get-organization
export def "organizations get-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, default_disk_usage_alerts_enabled: bool, notifications_allowed_email_domains: list<string>, billing_contacts: list<string>, operational_contacts: list<string>, sso_login_identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organization
#
# PUT /organizations/{organization_id}
# operationId: update-organization
export def "organizations update-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The organization's friendly name
  --default-disk-usage-alerts-enabled: oneof<nothing, bool> # Whether the default disk alerts are enabled
  --notifications-allowed-email-domains: list # The list of allowed domains for notification-email recipients
  --billing-contacts: list # The list of contacts for billing notifications
  --operational-contacts: list # The list of contacts for operational notifications
]: any -> record<id: string, name: string, default_disk_usage_alerts_enabled: bool, notifications_allowed_email_domains: list<string>, billing_contacts: list<string>, operational_contacts: list<string>, sso_login_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let body = {name: $name, default_disk_usage_alerts_enabled: $default_disk_usage_alerts_enabled, notifications_allowed_email_domains: $notifications_allowed_email_domains, billing_contacts: $billing_contacts, operational_contacts: $operational_contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get domain claims
#
# GET /organizations/{organization_id}/domains
# operationId: domain-claim-get-domain-claims
export def "organizations-domains domain-claim-get-domain-claims" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domains: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete domain claim
#
# DELETE /organizations/{organization_id}/domains
# operationId: domain-claim-delete
export def "organizations-domains domain-claim-delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_claim_request: string # The request to remove a domain claim
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains")
  let body = {domain_claim_request: $domain_claim_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate verification code
#
# POST /organizations/{organization_id}/domains/_generate_verification_code
# operationId: domain-claim-generate-verification-code
export def "organizations-domains-generate-verification-code domain-claim-generate-verification-code" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_claim_request: string # The domain claim request
]: any -> record<verification: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains/_generate_verification_code")
  let body = {domain_claim_request: $domain_claim_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify domain claim
#
# POST /organizations/{organization_id}/domains/_verify
# operationId: domain-claim-verify-domain
export def "organizations-domains-verify domain-claim-verify-domain" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_claim_request: string # The domain claim request
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains/_verify")
  let body = {domain_claim_request: $domain_claim_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization IdP
#
# GET /organizations/{organization_id}/idp
# operationId: get-organization-idp
export def "organizations-idp get-organization-idp" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<login_identifier: string, sso_login_url: string, metadata_url: string, acs: string, sp_entity_id: string, signing_certificate: list<string>, configuration: record<enabled: bool, login_identifier_prefix: string, saml_idp: record<public_certificate: list, issuer: string, sso_url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/idp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Setup organization IdP
#
# PUT /organizations/{organization_id}/idp
# operationId: setup-organization-idp
# --saml_idp shape: {public_certificate: list, issuer: string, sso_url: string}
export def "organizations-idp setup-organization-idp" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether or not the IdP is enabled
  login_identifier_prefix: string # The prefix of the login identifier that will be generated
  saml_idp: record # SAML2 IdP configuration object — shape: {public_certificate: list, issuer: string, sso_url: string}
]: any -> record<login_identifier: string, sso_login_url: string, metadata_url: string, acs: string, sp_entity_id: string, signing_certificate: list<string>, configuration: record<enabled: bool, login_identifier_prefix: string, saml_idp: record<public_certificate: list, issuer: string, sso_url: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/idp")
  let body = {enabled: $enabled, login_identifier_prefix: $login_identifier_prefix, saml_idp: $saml_idp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tear down organization IdP
#
# DELETE /organizations/{organization_id}/idp
# operationId: teardown-organization-idp
export def "organizations-idp teardown-organization-idp" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/idp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization service provider SAML2 metadata.xml for configuring the identity provider
#
# GET /organizations/{organization_id}/idp/metadata.xml
# operationId: get-organization-idp-metadata
export def "organizations-idp-metadataxml get-organization-idp-metadata" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/idp/metadata.xml")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization invitations
#
# GET /organizations/{organization_id}/invitations
# operationId: list-organization-invitations
export def "organizations-invitations list-organization-invitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invitations: table<token: string, email: string, created_at: string, expires_at: string, expired: bool, accepted_at: string, organization: record, role_assignments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization invitations
#
# POST /organizations/{organization_id}/invitations
# operationId: create-organization-invitations
# --role_assignments shape: {platform?: list, organization?: list, deployment?: list, project?: record}
export def "organizations-invitations create-organization-invitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emails: list # The email addresses to invite to the organization
  --expires-in: string # The date and time when the invitation expires. Defaults to three days from now.
  --role-assignments: record # Roles assigned to users, API keys or organization invitations. Currently unavailable in self-hosted ECE. — shape: {platform?: list, organization?: list, deployment?: list, project?: record}
]: any -> record<invitations: table<token: string, email: string, created_at: string, expires_at: string, expired: bool, accepted_at: string, organization: record, role_assignments: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations")
  let body = {emails: $emails, expires_in: $expires_in, role_assignments: $role_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization invitations
#
# DELETE /organizations/{organization_id}/invitations/{invitation_tokens}
# operationId: delete-organization-invitations
export def "organizations-invitations delete-organization-invitations" [
  organization_id: string
  invitation_tokens: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/($invitation_tokens)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization members
#
# GET /organizations/{organization_id}/members
# operationId: list-organization-members
export def "organizations-members list-organization-members" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<members: table<organization_id: string, user_id: string, name: string, email: string, member_since: string, role_assignments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete organization memberships
#
# DELETE /organizations/{organization_id}/members/{user_ids}
# operationId: delete-organization-memberships
export def "organizations-members delete-organization-memberships" [
  organization_id: string
  user_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Whether or not to force the removal of Org memberships (effective only for Platform Admins) (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/members/($user_ids)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get role mappings
#
# GET /organizations/{organization_id}/role_mappings
# operationId: get-role-mappings
export def "organizations-role-mappings get-role-mappings" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mappings: table<enabled: bool, name: string, rule: record, role_assignments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/role_mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates role mappings
#
# PUT /organizations/{organization_id}/role_mappings
# operationId: update-role-mappings
# --mappings item shape: {enabled: bool, name: string, rule: record, role_assignments: record}
export def "organizations-role-mappings update-role-mappings" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mappings: list # The rules for mapping role assignments in the organization — item shape: {enabled: bool, name: string, rule: record, role_assignments: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/role_mappings")
  let body = {mappings: $mappings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete role mappings
#
# DELETE /organizations/{organization_id}/role_mappings
# operationId: delete-role-mappings
export def "organizations-role-mappings delete-role-mappings" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/role_mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stack versions
#
# GET /stack/versions
# operationId: get-version-stacks
export def "stack-versions get-version-stacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-deleted: oneof<nothing, bool> # Whether to show deleted stack versions or not (default: false)
  --show-unusable: oneof<nothing, bool> # Whether to show versions that are unusable by the authenticated user (default: false)
]: nothing -> record<stacks: table<version: string, template: record, elasticsearch: record, kibana: record, apm: record, appsearch: record, metadata: record, deleted: bool, upgradable_to: list, min_upgradable_from: string, whitelisted: bool, accessible: bool, rolling_upgrade_compatible_versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_deleted" $show_deleted "scalar") (serialize-qp "show_unusable" $show_unusable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stack/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trusted environments
#
# GET /trusted-environments
# operationId: get-trusted-envs
export def "trusted-environments get-trusted-envs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accounts: table<account_id: string, name: string, trust_all: bool, trust_allowlist: list>, external: table<trust_relationship_id: string, name: string, trust_all: bool, trust_allowlist: list>, direct: table<uid: string, name: string, type: string, trust_all: bool, trust_allowlist: list, scope_id: string, additional_node_names: list, certificates: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trusted-environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all API keys
#
# GET /users/auth/keys
# operationId: get-api-keys
export def "users-auth-keys get-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --next-page: string # Pagination cursor to get the next page of records
]: nothing -> record<keys: table<id: string, user_id: string, organization_id: string, description: string, key: string, creation_date: string, expiration_date: string, role_assignments: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/auth/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create API key
#
# POST /users/auth/keys
# operationId: create-api-key
# --role_assignments shape: {platform?: list, organization?: list, deployment?: list, project?: record}
export def "users-auth-keys create-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # API key description. Useful if there are multiple keys
  --expiration: string # The optional expiration for the API key, provided as a duration (ex: '1d', '3h')
  --role-assignments: record # Roles assigned to users, API keys or organization invitations. Currently unavailable in self-hosted ECE. — shape: {platform?: list, organization?: list, deployment?: list, project?: record}
]: any -> record<id: string, user_id: string, organization_id: string, description: string, key: string, creation_date: string, expiration_date: string, role_assignments: record<platform: list<record>, organization: list<record>, deployment: list<record>, project: record<elasticsearch: list, observability: list, security: list, workplaceai: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/auth/keys")
  let body = {description: $description, expiration: $expiration, role_assignments: $role_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete API keys
#
# DELETE /users/auth/keys
# operationId: delete-api-keys
export def "users-auth-keys delete-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keys: list # The list of API key IDs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/auth/keys")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get API key
#
# GET /users/auth/keys/{api_key_id}
# operationId: get-api-key
export def "users-auth-keys get-api-key" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user_id: string, organization_id: string, description: string, key: string, creation_date: string, expiration_date: string, role_assignments: record<platform: list<record>, organization: list<record>, deployment: list<record>, project: record<elasticsearch: list, observability: list, security: list, workplaceai: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/auth/keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete API key
#
# DELETE /users/auth/keys/{api_key_id}
# operationId: delete-api-key
export def "users-auth-keys delete-api-key" [
  api_key_id: string
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
  let full_url = (build-url $base $"/users/auth/keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Role Assignments
#
# POST /users/{user_id}/role_assignments
# operationId: add-role-assignments
# --platform item shape: {role_id: string}
# --organization item shape: {role_id: string, organization_id: string, application_roles?: list}
# --deployment item shape: {role_id: string, organization_id: string, all?: bool, deployment_ids?: list, application_roles?: list}
# --project shape: {elasticsearch?: list, observability?: list, security?: list, workplaceai?: list}
export def "users-role-assignments add-role-assignments" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platform: list # Assignments for roles with platform scope. — item shape: {role_id: string}
  --organization: list # Assignments for roles with organization scope. — item shape: {role_id: string, organization_id: string, application_roles?: list}
  --deployment: list # Assignments for roles with deployment scope. — item shape: {role_id: string, organization_id: string, all?: bool, deployment_ids?: list, application_roles?: list}
  --project: record # Assignments for roles with project scope. — shape: {elasticsearch?: list, observability?: list, security?: list, workplaceai?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/role_assignments")
  let body = {platform: $platform, organization: $organization, deployment: $deployment, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Role Assignments
#
# DELETE /users/{user_id}/role_assignments
# operationId: remove-role-assignments
# --platform item shape: {role_id: string}
# --organization item shape: {role_id: string, organization_id: string, application_roles?: list}
# --deployment item shape: {role_id: string, organization_id: string, all?: bool, deployment_ids?: list, application_roles?: list}
# --project shape: {elasticsearch?: list, observability?: list, security?: list, workplaceai?: list}
export def "users-role-assignments remove-role-assignments" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platform: list # Assignments for roles with platform scope. — item shape: {role_id: string}
  --organization: list # Assignments for roles with organization scope. — item shape: {role_id: string, organization_id: string, application_roles?: list}
  --deployment: list # Assignments for roles with deployment scope. — item shape: {role_id: string, organization_id: string, all?: bool, deployment_ids?: list, application_roles?: list}
  --project: record # Assignments for roles with project scope. — shape: {elasticsearch?: list, observability?: list, security?: list, workplaceai?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/role_assignments")
  let body = {platform: $platform, organization: $organization, deployment: $deployment, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
