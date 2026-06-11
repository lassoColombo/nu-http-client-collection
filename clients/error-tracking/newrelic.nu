# Auto-generated client for api.newrelic.com vv2
# Source: https://api.eu.newrelic.com/docs/swagger.yml
# Auth: --token flag or $env.NEW_RELIC_API_KEY

const BASE_URL = "https://api.newrelic.com"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEW_RELIC_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {Api-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api.newrelic.com" "https://api.newrelic.com/v2" "https://api.eu.newrelic.com/v2" "https://staging-api.newrelic.com/v2"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applicationsjson get" } } | get name | first)
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

# List
#
# GET /applications.json
export def "applicationsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filtername: string # Filter by application name
  --filterhost: string # Filter by application host
  --filterids: list # Filter by application ids
  --filterlanguage: string # Filter by application language
  --exclude-links: string@bool-completer # Exclude links section from the response
  --page: int # Pagination index
]: nothing -> record<application: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, language: string, last_reported_at: string, links: record<servers: list, application_hosts: list, application_instances: list>, name: string, reporting: bool, settings: record<app_apdex_threshold: float, enable_real_user_monitoring: bool, end_user_apdex_threshold: float, use_server_side_config: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[host]" $filterhost "scalar") (serialize-qp "filter[ids]" $filterids "csv") (serialize-qp "filter[language]" $filterlanguage "scalar") (serialize-qp "exclude_links" $exclude_links "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /applications/{application_id}/deployments.json
export def "applications-deploymentsjson get" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # Pagination index
]: nothing -> record<deployment: record<changelog: string, description: string, id: int, links: record<application: int>, revision: string, timestamp: string, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/deployments.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /applications/{application_id}/deployments.json
# --deployment shape: {changelog?: string, description?: string, revision?: string, user?: string}
export def "applications-deploymentsjson post" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --deployment: record # shape: {changelog?: string, description?: string, revision?: string, user?: string}
]: any -> record<deployment: record<changelog: string, description: string, id: int, links: record<application: int>, revision: string, timestamp: string, user: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/deployments.json")
  let body = {deployment: $deployment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /applications/{application_id}/deployments/{id}.json
export def "applications-deployments delete" [
  application_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<deployment: record<changelog: string, description: string, id: int, links: record<application: int>, revision: string, timestamp: string, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/deployments/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /applications/{application_id}/hosts.json
export def "applications-hostsjson get" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filterhostname: string # Filter by server hostname
  --filterids: list # Filter by application host ids
  --page: int # Pagination index
]: nothing -> record<application_hosts: table<host: string, application_name: string, application_summary: record, end_user_summary: record, health_status: string, id: int, language: int, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[hostname]" $filterhostname "scalar") (serialize-qp "filter[ids]" $filterids "csv") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/hosts.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Names
#
# GET /applications/{application_id}/hosts/{host_id}/metrics.json
export def "applications-hosts-metricsjson get" [
  application_id: int
  host_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # Filter metrics by name
  --page: int # Pagination index (will be deprecated)
  --cursor: string # Cursor for next page (replacing page param)
]: nothing -> record<metrics: table<name: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/hosts/($host_id)/metrics.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Data
#
# GET /applications/{application_id}/hosts/{host_id}/metrics/data.json
export def "applications-hosts-metrics-datajson get" [
  application_id: int
  host_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --names: list # Retrieve specific metrics by name
  --values: list # Retrieve specific metric values
  --qp-from: string # Retrieve metrics after this time (format: date-time)
  --qp-to: string # Retrieve metrics before this time (format: date-time)
  --period: int # Period of timeslices in seconds
  --summarize: string@bool-completer # Summarize the data
  --qp-raw: string@bool-completer # Return unformatted raw values
]: nothing -> record<metric_data: record<from: string, metrics: list<record>, metrics_found: string, metrics_not_found: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "values" $values "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/hosts/($host_id)/metrics/data.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show
#
# GET /applications/{application_id}/hosts/{id}.json
export def "applications-hosts get" [
  application_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application_hosts: table<host: string, application_name: string, application_summary: record, end_user_summary: record, health_status: string, id: int, language: int, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/hosts/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /applications/{application_id}/instances.json
export def "applications-instancesjson get" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filterhostname: string # Filter by server hostname
  --filterids: list # Filter by application instance ids
  --page: int # Pagination index
]: nothing -> record<application_instance: record<host: string, application_name: string, application_summary: record<apdex_score: float, error_rate: float, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, response_time: float, throughput: float>, health_status: string, id: int, language: int, links: record<application: int, application_host: int, server: int>, port: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[hostname]" $filterhostname "scalar") (serialize-qp "filter[ids]" $filterids "csv") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/instances.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show
#
# GET /applications/{application_id}/instances/{id}.json
export def "applications-instances get" [
  application_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application_instance: record<host: string, application_name: string, application_summary: record<apdex_score: float, error_rate: float, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, response_time: float, throughput: float>, health_status: string, id: int, language: int, links: record<application: int, application_host: int, server: int>, port: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/instances/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Names
#
# GET /applications/{application_id}/instances/{instance_id}/metrics.json
export def "applications-instances-metricsjson get" [
  application_id: int
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # Filter metrics by name
  --page: int # Pagination index (will be deprecated)
  --cursor: string # Cursor for next page (replacing page param)
]: nothing -> record<metric: record<name: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/instances/($instance_id)/metrics.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Data
#
# GET /applications/{application_id}/instances/{instance_id}/metrics/data.json
export def "applications-instances-metrics-datajson get" [
  application_id: int
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --names: list # Retrieve specific metrics by name
  --values: list # Retrieve specific metric values
  --qp-from: string # Retrieve metrics after this time (format: date-time)
  --qp-to: string # Retrieve metrics before this time (format: date-time)
  --period: int # Period of timeslices in seconds
  --summarize: string@bool-completer # Summarize the data
  --qp-raw: string@bool-completer # Return unformatted raw values
]: nothing -> record<metric_data: record<from: string, metrics: list<record>, metrics_found: string, metrics_not_found: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "values" $values "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/instances/($instance_id)/metrics/data.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Names
#
# GET /applications/{application_id}/metrics.json
export def "applications-metricsjson get" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # Filter metrics by name
  --page: int # Pagination index (will be deprecated)
  --cursor: string # Cursor for next page (replacing page param)
]: nothing -> record<metric: record<name: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/metrics.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Data
#
# GET /applications/{application_id}/metrics/data.json
export def "applications-metrics-datajson get" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --names: list # Retrieve specific metrics by name
  --values: list # Retrieve specific metric values
  --qp-from: string # Retrieve metrics after this time (format: date-time)
  --qp-to: string # Retrieve metrics before this time (format: date-time)
  --period: int # Period of timeslices in seconds
  --summarize: string@bool-completer # Summarize the data
  --qp-raw: string@bool-completer # Return unformatted raw values
]: nothing -> record<metric_data: record<from: string, metrics: list<record>, metrics_found: string, metrics_not_found: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "values" $values "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/metrics/data.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show
#
# GET /applications/{id}.json
export def "applications get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, language: string, last_reported_at: string, links: record<servers: list, application_hosts: list, application_instances: list>, name: string, reporting: bool, settings: record<app_apdex_threshold: float, enable_real_user_monitoring: bool, end_user_apdex_threshold: float, use_server_side_config: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /applications/{id}.json
# --application shape: {name?: string, settings?: record}
export def "applications put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --application: record # shape: {name?: string, settings?: record}
]: any -> record<application: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, language: string, last_reported_at: string, links: record<servers: list, application_hosts: list, application_instances: list>, name: string, reporting: bool, settings: record<app_apdex_threshold: float, enable_real_user_monitoring: bool, end_user_apdex_threshold: float, use_server_side_config: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id).json")
  let body = {application: $application} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /applications/{id}.json
export def "applications delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, language: string, last_reported_at: string, links: record<servers: list, application_hosts: list, application_instances: list>, name: string, reporting: bool, settings: record<app_apdex_threshold: float, enable_real_user_monitoring: bool, end_user_apdex_threshold: float, use_server_side_config: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /key_transactions.json
export def "key-transactionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filtername: string # Filter by name
  --filterids: list # Filter by policy IDs
  --page: int # Pagination index
]: nothing -> record<key_transaction: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, last_reported_at: string, links: record<application: int>, name: string, reporting: bool, transaction_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[ids]" $filterids "csv") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/key_transactions.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show
#
# GET /key_transactions/{id}.json
export def "key-transactions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key_transaction: record<application_summary: record<apdex_score: float, apdex_target: float, concurrent_instance_count: int, error_rate: float, host_count: int, instance_count: int, response_time: float, throughput: float>, end_user_summary: record<apdex_score: float, apdex_target: float, response_time: float, throughput: float>, health_status: string, id: int, last_reported_at: string, links: record<application: int>, name: string, reporting: bool, transaction_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/key_transactions/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /mobile_applications.json
export def "mobile-applicationsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application: record<crash_summary: record<crash_count: int, crash_rate: float, supports_crash_data: bool, unresolved_crash_count: int>, health_status: string, id: int, mobile_summary: record<active_users: int, calls_per_session: float, failed_call_rate: float, interaction_time: float, launch_count: int, remote_error_rate: float, response_time: float, throughput: float>, name: string, reporting: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mobile_applications.json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show
#
# GET /mobile_applications/{id}.json
export def "mobile-applications get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<application: record<crash_summary: record<crash_count: int, crash_rate: float, supports_crash_data: bool, unresolved_crash_count: int>, health_status: string, id: int, mobile_summary: record<active_users: int, calls_per_session: float, failed_call_rate: float, interaction_time: float, launch_count: int, remote_error_rate: float, response_time: float, throughput: float>, name: string, reporting: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mobile_applications/($id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Names
#
# GET /mobile_applications/{mobile_application_id}/metrics.json
export def "mobile-applications-metricsjson get" [
  mobile_application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # Filter metrics by name
  --page: int # Pagination index (will be deprecated)
  --cursor: string # Cursor for next page (replacing page param)
]: nothing -> record<metric: record<name: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mobile_applications/($mobile_application_id)/metrics.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Metric Data
#
# GET /mobile_applications/{mobile_application_id}/metrics/data.json
export def "mobile-applications-metrics-datajson get" [
  mobile_application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --names: list # Retrieve specific metrics by name
  --values: list # Retrieve specific metric values
  --qp-from: string # Retrieve metrics after this time (format: date-time)
  --qp-to: string # Retrieve metrics before this time (format: date-time)
  --period: int # Period of timeslices in seconds
  --summarize: string@bool-completer # Summarize the data
  --qp-raw: string@bool-completer # Return unformatted raw values
]: nothing -> record<metric_data: record<from: string, metrics: list<record>, metrics_found: string, metrics_not_found: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "values" $values "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mobile_applications/($mobile_application_id)/metrics/data.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_channels.json
export def "alerts-channelsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # Pagination index
]: nothing -> record<channel: record<configuration: record, id: int, links: record<policy_ids: list>, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_channels.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_channels.json
# --channel shape: {configuration?: record, name?: string, type?: string}
export def "alerts-channelsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-ids: list # Policy IDs to associate with channel
  --channel: record # shape: {configuration?: record, name?: string, type?: string}
]: any -> record<channel: record<configuration: record, id: int, links: record<policy_ids: list>, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_ids" $policy_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_channels.json" $qp)
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_channels/{channel_id}.json
export def "alerts-channels delete" [
  channel_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<channel: record<configuration: record, id: int, links: record<policy_ids: list>, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_channels/($channel_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_conditions.json
export def "alerts-conditionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Alerts policy ID
  --page: int # Pagination index
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_conditions.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_conditions/policies/{policy_id}.json
# --condition shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
export def "alerts-conditions-policies post" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --condition: record # shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
]: any -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_conditions/policies/($policy_id).json")
  let body = {condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_conditions/{condition_id}.json
# --condition shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
export def "alerts-conditions put" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --condition: record # shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
]: any -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_conditions/($condition_id).json")
  let body = {condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_conditions/{condition_id}.json
export def "alerts-conditions delete" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_conditions/($condition_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_entity_conditions/{entity_id}.json
export def "alerts-entity-conditions get" [
  entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --entity-type: string # Entity Type
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts_entity_conditions/($entity_id).json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add
#
# PUT /alerts_entity_conditions/{entity_id}.json
export def "alerts-entity-conditions put" [
  entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --entity-type: string # Entity Type
  --condition-id: int # Alerts condition ID
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "condition_id" $condition_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts_entity_conditions/($entity_id).json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove
#
# DELETE /alerts_entity_conditions/{entity_id}.json
export def "alerts-entity-conditions delete" [
  entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --entity-type: string # Entity Type
  --condition-id: int # Alerts condition ID
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "condition_id" $condition_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts_entity_conditions/($entity_id).json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_events.json
export def "alerts-eventsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filterproduct: string # Filter by New Relic product
  --filterentity-type: string # Filter by entity type
  --filterentity-group-id: int # Filter by entity group ID
  --filterentity-id: int # Filter by entity ID
  --filterevent-type: string # Filter by event type
  --filterincident-id: int # Filter by incident id
  --page: int # Pagination index
]: nothing -> record<recent_event: record<description: string, entity_group_id: int, entity_id: int, entity_type: string, event_type: string, id: int, incident_id: int, priority: string, product: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[product]" $filterproduct "scalar") (serialize-qp "filter[entity_type]" $filterentity_type "scalar") (serialize-qp "filter[entity_group_id]" $filterentity_group_id "scalar") (serialize-qp "filter[entity_id]" $filterentity_id "scalar") (serialize-qp "filter[event_type]" $filterevent_type "scalar") (serialize-qp "filter[incident_id]" $filterincident_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_events.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_external_service_conditions.json
export def "alerts-external-service-conditionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Alerts policy ID
  --page: int # Pagination index
]: nothing -> record<external_service_condition: record<enabled: bool, entities: list<int>, external_service_url: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_external_service_conditions.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_external_service_conditions/policies/{policy_id}.json
# --external_service_condition shape: {enabled?: bool, entities?: list, external_service_url?: string, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string}
export def "alerts-external-service-conditions-policies post" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --external-service-condition: record # shape: {enabled?: bool, entities?: list, external_service_url?: string, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string}
]: any -> record<external_service_condition: record<enabled: bool, entities: list<int>, external_service_url: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_external_service_conditions/policies/($policy_id).json")
  let body = {external_service_condition: $external_service_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_external_service_conditions/{condition_id}.json
# --external_service_condition shape: {enabled?: bool, entities?: list, external_service_url?: string, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string}
export def "alerts-external-service-conditions put" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --external-service-condition: record # shape: {enabled?: bool, entities?: list, external_service_url?: string, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string}
]: any -> record<external_service_condition: record<enabled: bool, entities: list<int>, external_service_url: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_external_service_conditions/($condition_id).json")
  let body = {external_service_condition: $external_service_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_external_service_conditions/{condition_id}.json
export def "alerts-external-service-conditions delete" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<external_service_condition: record<enabled: bool, entities: list<int>, external_service_url: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_external_service_conditions/($condition_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_incidents.json
export def "alerts-incidentsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # Pagination index
  --only-open: string@bool-completer # Filter by open incidents
]: nothing -> record<incident: record<closed_at: int, id: int, incident_preference: int, links: record<policy_id: int, violations: list>, opened_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "only_open" $only_open "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_incidents.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_location_failure_conditions/policies/{policy_id}.json
export def "alerts-location-failure-conditions-policies get" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # Pagination index
]: nothing -> table<condition: record<condition_scope: string, enabled: bool, entities: list, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list, type: string, user_defined: record, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts_location_failure_conditions/policies/($policy_id).json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_location_failure_conditions/policies/{policy_id}.json
# --condition shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, id?: int, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
export def "alerts-location-failure-conditions-policies post" [
  policy_id: int
  location_failure_condition: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --condition: record # shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, id?: int, metric?: string, name?: string, runbook_url?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
]: any -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_location_failure_conditions/policies/($policy_id).json")
  let body = {condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_location_failure_conditions/{condition_id}.json
# --condition shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
export def "alerts-location-failure-conditions put" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --condition: record # shape: {condition_scope?: string, enabled?: bool, entities?: list, gc_metric?: string, metric?: string, name?: string, terms?: list, type?: string, user_defined?: record, violation_close_timer?: int}
]: any -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_location_failure_conditions/($condition_id).json")
  let body = {condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_location_failure_conditions/{condition_id}.json
export def "alerts-location-failure-conditions delete" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<condition: record<condition_scope: string, enabled: bool, entities: list<int>, gc_metric: string, id: int, metric: string, name: string, runbook_url: string, terms: list<record>, type: string, user_defined: record<metric: string, value_function: string>, violation_close_timer: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_location_failure_conditions/($condition_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_nrql_conditions.json
export def "alerts-nrql-conditionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Alerts policy ID
  --page: int # Pagination index
]: nothing -> record<nrql_condition: record<enabled: bool, expected_groups: int, id: int, ignore_overlap: bool, name: string, nrql: record<query: string, since_value: string>, runbook_url: string, terms: list<record>, type: string, value_function: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_nrql_conditions.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_nrql_conditions/policies/{policy_id}.json
# --nrql_condition shape: {enabled?: bool, expected_groups?: int, ignore_overlap?: bool, name?: string, nrql?: record, runbook_url?: string, terms?: list, value_function?: string}
export def "alerts-nrql-conditions-policies post" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --nrql-condition: record # shape: {enabled?: bool, expected_groups?: int, ignore_overlap?: bool, name?: string, nrql?: record, runbook_url?: string, terms?: list, value_function?: string}
]: any -> record<nrql_condition: record<enabled: bool, expected_groups: int, id: int, ignore_overlap: bool, name: string, nrql: record<query: string, since_value: string>, runbook_url: string, terms: list<record>, type: string, value_function: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_nrql_conditions/policies/($policy_id).json")
  let body = {nrql_condition: $nrql_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_nrql_conditions/{condition_id}.json
# --nrql_condition shape: {enabled?: bool, expected_groups?: int, ignore_overlap?: bool, name?: string, nrql?: record, runbook_url?: string, terms?: list, value_function?: string}
export def "alerts-nrql-conditions put" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --nrql-condition: record # shape: {enabled?: bool, expected_groups?: int, ignore_overlap?: bool, name?: string, nrql?: record, runbook_url?: string, terms?: list, value_function?: string}
]: any -> record<nrql_condition: record<enabled: bool, expected_groups: int, id: int, ignore_overlap: bool, name: string, nrql: record<query: string, since_value: string>, runbook_url: string, terms: list<record>, type: string, value_function: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_nrql_conditions/($condition_id).json")
  let body = {nrql_condition: $nrql_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_nrql_conditions/{condition_id}.json
export def "alerts-nrql-conditions delete" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<nrql_condition: record<enabled: bool, expected_groups: int, id: int, ignore_overlap: bool, name: string, nrql: record<query: string, since_value: string>, runbook_url: string, terms: list<record>, type: string, value_function: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_nrql_conditions/($condition_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_policies.json
export def "alerts-policiesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filtername: string # Name (must be exact match)
  --page: int # Pagination index
]: nothing -> record<policy: record<created_at: int, id: int, incident_preference: string, name: string, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_policies.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_policies.json
# --policy shape: {incident_preference?: string, name?: string}
export def "alerts-policiesjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy: record # shape: {incident_preference?: string, name?: string}
]: any -> record<policy: record<created_at: int, id: int, incident_preference: string, name: string, updated_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts_policies.json")
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_policies/{policy_id}.json
# --policy shape: {incident_preference?: string, name?: string}
export def "alerts-policies put" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy: record # shape: {incident_preference?: string, name?: string}
]: any -> record<policy: record<created_at: int, id: int, incident_preference: string, name: string, updated_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_policies/($policy_id).json")
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_policies/{policy_id}.json
export def "alerts-policies delete" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<policy: record<created_at: int, id: int, incident_preference: string, name: string, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_policies/($policy_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /alerts_policy_channels.json
export def "alerts-policy-channelsjson put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Policy ID
  --channel-ids: list # Channel IDs
]: nothing -> record<policy: record<channel_ids: list<int>, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "channel_ids" $channel_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_policy_channels.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete
#
# DELETE /alerts_policy_channels.json
export def "alerts-policy-channelsjson delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Policy ID
  --channel-id: int # Channel ID
]: nothing -> record<channel: record<configuration: record, id: int, links: record<policy_ids: list>, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "channel_id" $channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_policy_channels.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_synthetics_conditions.json
export def "alerts-synthetics-conditionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --policy-id: int # Alerts policy ID
  --page: int # Pagination index
]: nothing -> record<synthetics_condition: record<enabled: bool, id: int, monitor_id: string, name: string, runbook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_synthetics_conditions.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /alerts_synthetics_conditions/policies/{policy_id}.json
# --synthetics_condition shape: {enabled?: bool, monitor_id?: string, name?: string, runbook_url?: string}
export def "alerts-synthetics-conditions-policies post" [
  policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --synthetics-condition: record # shape: {enabled?: bool, monitor_id?: string, name?: string, runbook_url?: string}
]: any -> record<synthetics_condition: record<enabled: bool, id: int, monitor_id: string, name: string, runbook_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_synthetics_conditions/policies/($policy_id).json")
  let body = {synthetics_condition: $synthetics_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /alerts_synthetics_conditions/{condition_id}.json
# --synthetics_condition shape: {enabled?: bool, monitor_id?: string, name?: string, runbook_url?: string}
export def "alerts-synthetics-conditions put" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --synthetics-condition: record # shape: {enabled?: bool, monitor_id?: string, name?: string, runbook_url?: string}
]: any -> record<synthetics_condition: record<enabled: bool, id: int, monitor_id: string, name: string, runbook_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_synthetics_conditions/($condition_id).json")
  let body = {synthetics_condition: $synthetics_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /alerts_synthetics_conditions/{condition_id}.json
export def "alerts-synthetics-conditions delete" [
  condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<synthetics_condition: record<enabled: bool, id: int, monitor_id: string, name: string, runbook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts_synthetics_conditions/($condition_id).json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /alerts_violations.json
export def "alerts-violationsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # Pagination index
  --start-date: string # Retrieve violations created after this time (format: date-time)
  --end-date: string # Retrieve violations created before this time (format: date-time)
  --only-open: string@bool-completer # Filter by open violations
]: nothing -> record<violation: record<closed_at: int, condition_name: string, duration: int, entity: record<group_id: int, id: int, name: string, product: string, type: string>, id: int, label: string, links: record<condition_id: int, incident_id: int, policy_id: int>, opened_at: int, policy_name: string, priority: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "only_open" $only_open "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts_violations.json" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
