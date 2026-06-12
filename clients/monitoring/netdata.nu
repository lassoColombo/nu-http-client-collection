# Auto-generated client for Netdata API vv1-rolling
# Source: https://raw.githubusercontent.com/netdata/netdata/master/src/web/api/netdata-swagger.yaml
# Auth: --token flag or $env.NETDATA_API_TOKEN

const BASE_URL = "https://registry.my-netdata.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETDATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "x-forwarded-for" => { {headers: {X-Forwarded-For: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://registry.my-netdata.io" "http://registry.my-netdata.io" "http://localhost:19999"] }
def auth-scheme-completer [] { ["bearer" "x-forwarded-for"] }

# Completers for enum parameters
def action-completer [] { ["disable" "enable" "get" "restart" "schema" "tree"] }
def action-completer-1 [] { ["add" "test" "update"] }
def aggregation-completer [] { ["average" "avg" "extremes" "max" "min" "percentage" "sum"] }
def time-group-completer [] { ["average" "avg" "countif" "cv" "des" "ema" "extremes" "incremental-sum" "max" "median" "min" "percentile" "percentile25" "percentile50" "percentile75" "percentile80" "percentile90" "percentile95" "percentile97" "percentile98" "percentile99" "ses" "stddev" "sum" "trimmed-mean" "trimmed-mean1" "trimmed-mean10" "trimmed-mean15" "trimmed-mean2" "trimmed-mean20" "trimmed-mean25" "trimmed-mean3" "trimmed-mean5" "trimmed-median" "trimmed-median1" "trimmed-median10" "trimmed-median15" "trimmed-median2" "trimmed-median20" "trimmed-median25" "trimmed-median3" "trimmed-median5"] }
def format-completer [] { ["array" "csv" "csvjsonarray" "datasource" "datatable" "html" "json" "json2" "jsonp" "markdown" "ssv" "ssvcomma" "tsv" "tsv-excel"] }
def accept-completer [] { ["application/json" "application/x-javascript" "text/html" "text/plain"] }
def format-completer-1 [] { ["array" "csv" "csvjsonarray" "datasource" "datatable" "html" "json" "jsonp" "markdown" "ssv" "ssvcomma" "tsv" "tsv-excel"] }
def group-completer [] { ["average" "avg" "countif" "cv" "des" "ema" "extremes" "incremental-sum" "max" "median" "min" "percentile" "percentile25" "percentile50" "percentile75" "percentile80" "percentile90" "percentile95" "percentile97" "percentile98" "percentile99" "ses" "stddev" "sum" "trimmed-mean" "trimmed-mean1" "trimmed-mean10" "trimmed-mean15" "trimmed-mean2" "trimmed-mean20" "trimmed-mean25" "trimmed-mean3" "trimmed-mean5" "trimmed-median" "trimmed-median1" "trimmed-median10" "trimmed-median15" "trimmed-median2" "trimmed-median20" "trimmed-median25" "trimmed-median3" "trimmed-median5"] }
def format-completer-2 [] { ["json" "prometheus" "prometheus_all_hosts" "shell"] }
def variables-completer [] { ["no" "yes"] }
def timestamps-completer [] { ["no" "yes"] }
def names-completer [] { ["no" "yes"] }
def oldunits-completer [] { ["no" "yes"] }
def hideunits-completer [] { ["no" "yes"] }
def data-completer [] { ["as-collected" "average" "sum"] }
def variables-completer-1 [] { ["0" "1" "false" "no" "true" "yes"] }
def timestamps-completer-1 [] { ["0" "1" "false" "no" "true" "yes"] }
def names-completer-1 [] { ["0" "1" "false" "no" "true" "yes"] }
def oldunits-completer-1 [] { ["0" "1" "false" "no" "true" "yes"] }
def hideunits-completer-1 [] { ["0" "1" "false" "no" "true" "yes"] }
def accept-completer-1 [] { ["application/json" "application/openmetrics-text" "text/plain"] }
def accept-completer-2 [] { ["application/json" "text/plain"] }
def action-completer-2 [] { ["add" "disable" "enable" "get" "remove" "restart" "schema" "test" "tree" "update" "userconfig"] }
def bearer-protection-completer [] { ["false" "no" "off" "on" "true" "yes"] }
def method-completer [] { ["anomaly-rate" "ks2" "value" "volume"] }
def status-completer [] { ["CLEAR" "CRITICAL" "RAISED" "REMOVED" "UNDEFINED" "UNINITIALIZED" "WARNING"] }
def cmd-completer [] { ["DISABLE" "DISABLE ALL" "LIST" "RESET" "SILENCE" "SILENCE ALL"] }
def action-completer-3 [] { ["access" "delete" "hello" "search" "switch"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "nodes get" } } | get name | first)
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

# Nodes Info v2
#
# GET /api/v2/nodes
# DEPRECATED
# operationId: getNodes2
@deprecated
export def "nodes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, nodes: table<mg: string, nd: string, nm: string, ni: int, st: record, version: string, hops: int, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Nodes Info v3
#
# GET /api/v3/nodes
# operationId: getNodes3
export def "nodes get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, nodes: table<mg: string, nd: string, nm: string, ni: int, st: record, version: string, hops: int, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contexts Info v2
#
# GET /api/v2/contexts
# DEPRECATED
# operationId: getContexts2
@deprecated
export def "contexts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, contexts: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/contexts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contexts Info v3
#
# GET /api/v3/contexts
# operationId: getContexts3
export def "contexts get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, contexts: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/contexts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Full Text Search v2
#
# GET /api/v2/q
# DEPRECATED
# operationId: q2
@deprecated
export def "q q2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The strings to search for, formatted as a simple pattern (format: simple pattern)
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, contexts: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/q" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Full Text Search v3
#
# GET /api/v3/q
# operationId: q3
export def "q q3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The strings to search for, formatted as a simple pattern (format: simple pattern)
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect the output of contexts metadata queries. * `minify` - Remove unnecessary spaces and newlines from the output to reduce bandwidth. * `debug` - Provide additional debugging information in the response. * `config` - Include alert configuration information (used by /api/v2/alert_transitions). * `instances` - Include alert/context instance information (used by /api/v2/alerts). * `values` - Include latest metric values (used by /api/v2/alerts). * `summary` - Include summary counters (used by /api/v2/alerts). * `mcp` - Format output for Model Context Protocol (MCP) integration. * `dimensions` - Include dimension information for each context. * `labels` - Include label information for each context. * `priorities` - Include priority information for each context. * `titles` - Include title information for each context. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  Note: Some options like `retention`, `liveness`, `family`, and `units` are automatically included by specific endpoints and cannot be controlled via this parameter.  (default: [])
]: nothing -> record<api: int, agents: table<mg: string, nd: string, nm: string, ai: int, now: int>, versions: record<nodes_hard_hash: int, contexts_hard_hash: int, contexts_soft_hash: int, alerts_hard_hash: int, alerts_soft_hash: int>, contexts: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "options" $options "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/q" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Info v1
#
# GET /api/v1/info
# DEPRECATED
# operationId: getNodeInfo1
@deprecated
export def "info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: string, uid: string, mirrored_hosts: list<string>, mirrored_hosts_status: table<guid: string, reachable: bool, claim_id: string>, os_name: string, os_id: string, os_id_like: string, os_version: string, os_version_id: string, os_detection: string, kernel_name: string, kernel_version: string, is_k8s_node: bool, architecture: string, virtualization: string, virt_detection: string, container: string, container_detection: string, stream_compression: bool, labels: record<app: string>, collectors: table<plugin: string, module: string>, alarms: record<normal: int, warning: int, critical: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all charts v1 - EOL
#
# GET /api/v1/charts
# DEPRECATED
# operationId: getNodeCharts1
@deprecated
export def "charts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hostname: string, version: string, release_channel: string, timezone: string, os: string, history: float, memory_mode: string, update_every: float, charts: record, charts_count: float, dimensions_count: float, alarms_count: float, rrd_memory_bytes: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/charts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one chart v1 - EOL
#
# GET /api/v1/chart
# DEPRECATED
# operationId: getNodeChart1
@deprecated
export def "chart get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # The id of the chart as returned by the `/api/v1/charts` call. (format: as returned by `/api/v1/charts`)
]: nothing -> record<id: string, name: string, type: string, family: string, title: string, priority: float, enabled: bool, units: string, data_url: string, chart_type: string, duration: float, first_entry: float, last_entry: float, update_every: float, dimensions: record, chart_variables: record, green: float, red: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all node contexts available v1
#
# GET /api/v1/contexts
# DEPRECATED
# operationId: getNodeContexts1
@deprecated
export def "contexts get-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dimensions: string # a simple pattern matching dimensions (use comma or pipe as separator) (allows empty value)
  --chart-label-key: string # Specify the chart label keys that need to match for context queries as comma separated values. At least one matching key is needed to match the corresponding chart.  (format: key1,key2,key3)
  --chart-labels-filter: string # Specify the chart label keys and values to match for context queries. All keys/values need to match for the chart to be included in the query. The labels are specified as key1:value1,key2:value2  (format: key1:value1,key2:value2,key3:value3)
  --options: list # Options that affect data generation. * `full` or `all` - Include all available information. * `charts` - Include chart information. * `dimensions` - Include dimension information. * `labels` - Include label information. * `uuids` - Include UUIDs in the response. * `queue` - Include queue information. * `flags` - Include internal flags. * `deleted` - Include deleted items. * `deepscan` - Perform a deep scan for contexts. * `rfc3339` - Return timestamps in RFC3339 format instead of Unix timestamps.
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
]: nothing -> record<hostname: string, machine_guid: string, node_id: string, claim_id: string, host_labels: record, context: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "chart_label_key" $chart_label_key "scalar") (serialize-qp "chart_labels_filter" $chart_labels_filter "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/contexts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get info about a specific context
#
# GET /api/v1/context
# DEPRECATED
# operationId: getNodeContext1
@deprecated
export def "context get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # The context of the chart as returned by the /charts call. (format: as returned by /charts)
  --dimensions: string # a simple pattern matching dimensions (use comma or pipe as separator) (allows empty value)
  --chart-label-key: string # Specify the chart label keys that need to match for context queries as comma separated values. At least one matching key is needed to match the corresponding chart.  (format: key1,key2,key3)
  --chart-labels-filter: string # Specify the chart label keys and values to match for context queries. All keys/values need to match for the chart to be included in the query. The labels are specified as key1:value1,key2:value2  (format: key1:value1,key2:value2,key3:value3)
  --options: list # Options that affect data generation. * `full` or `all` - Include all available information. * `charts` - Include chart information. * `dimensions` - Include dimension information. * `labels` - Include label information. * `uuids` - Include UUIDs in the response. * `queue` - Include queue information. * `flags` - Include internal flags. * `deleted` - Include deleted items. * `deepscan` - Perform a deep scan for contexts. * `rfc3339` - Return timestamps in RFC3339 format instead of Unix timestamps.
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
]: nothing -> record<version: string, hub_version: string, family: string, title: string, priority: float, units: string, chart_type: string, first_time_t: float, last_time_t: float, charts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context" $context "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "chart_label_key" $chart_label_key "scalar") (serialize-qp "chart_labels_filter" $chart_labels_filter "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/context" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get info about a specific context - Latest API
#
# GET /api/v3/context
# operationId: getNodeContext3
export def "context get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # The context identifier to query. This is a required parameter.  A context represents a type of metric collected across multiple instances. Each context groups charts that measure the same thing but for different entities.  **Common Context Examples:** - `system.cpu` - CPU utilization metrics - `system.ram` - RAM usage metrics - `disk.io` - Disk I/O operations - `disk.ops` - Disk operation counts - `net.packets` - Network packet statistics - `net.drops` - Network packet drops - `cgroup.cpu` - Container CPU usage - `nginx.requests` - Nginx request rates  **Finding Available Contexts:** Use the `/api/v3/contexts` endpoint to get a list of all available contexts.  **Alias:** Can also be specified as `ctx` for brevity.  (e.g. system.cpu)
  --dimensions: string # a simple pattern matching dimensions (use comma or pipe as separator) (allows empty value)
  --chart-label-key: string # Specify the chart label keys that need to match for context queries as comma separated values. At least one matching key is needed to match the corresponding chart.  (format: key1,key2,key3)
  --chart-labels-filter: string # Specify the chart label keys and values to match for context queries. All keys/values need to match for the chart to be included in the query. The labels are specified as key1:value1,key2:value2  (format: key1:value1,key2:value2,key3:value3)
  --options: string # Comma or pipe-separated list of options to control the response content and format.  **Available Options:** - `full` or `all` - Include all possible information (equivalent to enabling all options below) - `charts` - Include the list of charts belonging to this context - `dimensions` - Include dimension information for each chart - `queue` - Include data collection queue statistics - `flags` - Include internal flags and states - `labels` - Include chart labels - `alerts` - Include alert configurations and states for this context  **Option Combinations:** Options can be combined. For example: `options=charts,dimensions,labels` will include charts with their dimensions and labels.  **Default Behavior:** When not specified, returns basic context information without detailed chart data.  **Examples:** - `options=full` - Complete information - `options=charts,dimensions` - Charts with dimension details - `options=charts|labels` - Charts with labels (pipe separator)
  --after: int # Return only charts that have collected data after this timestamp.  This filters charts based on their data collection activity, excluding charts that haven't collected data since the specified time.  **Format:** Unix timestamp in seconds  **Use Cases:** - Find recently active charts - Exclude stale or obsolete charts - Filter charts by collection timeframe  **Example:** `after=1609459200` (charts active after January 1, 2021)  When not specified, all charts are included regardless of their last update time.  (format: int64, e.g. 1609459200)
  --before: int # Return only charts that have collected data before this timestamp.  This filters charts based on their data collection activity, excluding charts that only have data after the specified time.  **Format:** Unix timestamp in seconds  **Use Cases:** - Historical analysis of chart availability - Find charts that were active during a specific time period - Exclude newer charts from results  **Example:** `before=1640995200` (charts active before January 1, 2022)  When combined with `after`, you can specify an exact time window: `after=1609459200&before=1640995200` (charts active during 2021)  When not specified, all charts are included regardless of their collection timeline.  (format: int64, e.g. 1640995200)
]: nothing -> record<version: string, hub_version: string, family: string, title: string, priority: float, units: string, chart_type: string, first_time_t: float, last_time_t: float, charts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context" $context "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "chart_label_key" $chart_label_key "scalar") (serialize-qp "chart_labels_filter" $chart_labels_filter "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/context" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dynamic configuration information.  **Security & Access Control:** - 📊 **Public Data API** - Bearer token optional, IP-based ACL restrictions apply - **Default Access:** Public (no authentication required) - **Bearer Protection:** When enabled via `/api/v3/bearer_protection`, requires bearer token - **IP Restrictions:** Subject to `allow dashboard from` in netdata.conf - **Access Methods:** Direct HTTP/HTTPS, Netdata Cloud, external tools
#
# GET /api/v1/config
# DEPRECATED
# operationId: getConfig
@deprecated
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # The type of information required (default: tree)
  --id: string # The ID of the dynamic configuration entity
  --path: string # Top level path of the configuration entities, used with action 'tree' (default: /)
  --timeout: float # The timeout in seconds (default: 120)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post dynamic configuration to Netdata.
#
# POST /api/v1/config
# operationId: postConfig
export def "config post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # The type of action required.
  --id: string # The ID of the dynamic configuration entity to configure.
  --name: string # Name of the dynamic configuration entity, used with action 'add'
  --timeout: float # The timeout in seconds (default: 120)
]: nothing -> record<status: int, message: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Data Query v2
#
# GET /api/v2/data
# DEPRECATED
# operationId: dataQuery2
@deprecated
export def "data dataQuery2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-by: list # A comma separated list of the groupings required. All possible values can be combined together, except `selected`. If `selected` is given in the list, all others are ignored. The order they are placed in the list is currently ignored. This parameter is also accepted as `group_by[0]` and `group_by[1]` when multiple grouping passes are required.  (default: [dimension])
  --group-by-label: string # A comma separated list of the label keys to group by their values. The order of the labels in the list is respected. This parameter is also accepted as `group_by_label[0]` and `group_by_label[1]` when multiple grouping passes are required.  (format: comma separated list of label keys to group by, default: )
  --aggregation: string@aggregation-completer # The aggregation function to apply when grouping metrics together. When option `raw` is given, `average` and `avg` behave like `sum` and the caller is expected to calculate the average. This parameter is also accepted as `aggregation[0]` and `aggregation[1]` when multiple grouping passes are required.  (default: average)
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-instances: string # A simple pattern limiting the instances scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-labels: string # A simple pattern limiting the labels scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query based on their labels. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by scope nodes, scope contexts, and scope instances). Only instances having labels that match this pattern will be included in the query. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-dimensions: string # A simple pattern limiting the dimensions scope of the query. The scope controls both data and metadata response. This limits which dimensions are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against both the dimension `id` and `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --instances: string # A simple pattern matching the instances to be queried. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --labels: string # A simple pattern matching the labels to be queried. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by all the above: scope nodes, scope contexts, nodes, contexts and instances). Negative simple patterns should not be used in this filter.  (format: simple pattern, default: *)
  --alerts: string # A simple pattern matching the alerts to be queried. The simple pattern is checked against the `name` of alerts and the combination of `name:status`, when status is one of `CLEAR`, `WARNING`, `CRITICAL`, `REMOVED`, `UNDEFINED`, `UNINITIALIZED`, of all the alerts of all the eligible instances (as filtered by all the above). A negative simple pattern will exclude the instances having the labels matched.  (format: simple pattern, default: *)
  --dimensions: string # A simple patterns matching the dimensions to be queried. The simple pattern is checked against and `id` and the `name` of the dimensions of the eligible instances (as filtered by all the above). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --time-group: string@time-group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --time-group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
  --time-resampling: float # For incremental values that are "per second", this value is used to resample them to "per minute` (60) or "per hour" (3600). It can only be used in conjunction with group=average.  (format: integer, default: 0)
  --format: string@format-completer # The format of the data to be returned. (default: json2)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --callback: string # For JSONP responses, the callback function name.
  --filename: string # Add `Content-Disposition: attachment; filename=` header to the response, that will instruct the browser to save the response with the given filename."
  --tqx: string # [Google Visualization API](https://developers.google.com/chart/interactive/docs/dev/implementing_data_source?hl=en) formatted parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "multi") (serialize-qp "group_by_label" $group_by_label "scalar") (serialize-qp "aggregation" $aggregation "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "scope_instances" $scope_instances "scalar") (serialize-qp "scope_labels" $scope_labels "scalar") (serialize-qp "scope_dimensions" $scope_dimensions "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "instances" $instances "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "alerts" $alerts "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "options" $options "multi") (serialize-qp "time_group" $time_group "scalar") (serialize-qp "time_group_options" $time_group_options "scalar") (serialize-qp "time_resampling" $time_resampling "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "tqx" $tqx "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Data Query v3
#
# GET /api/v3/data
# operationId: dataQuery3
export def "data dataQuery3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-by: list # A comma separated list of the groupings required. All possible values can be combined together, except `selected`. If `selected` is given in the list, all others are ignored. The order they are placed in the list is currently ignored. This parameter is also accepted as `group_by[0]` and `group_by[1]` when multiple grouping passes are required.  (default: [dimension])
  --group-by-label: string # A comma separated list of the label keys to group by their values. The order of the labels in the list is respected. This parameter is also accepted as `group_by_label[0]` and `group_by_label[1]` when multiple grouping passes are required.  (format: comma separated list of label keys to group by, default: )
  --aggregation: string@aggregation-completer # The aggregation function to apply when grouping metrics together. When option `raw` is given, `average` and `avg` behave like `sum` and the caller is expected to calculate the average. This parameter is also accepted as `aggregation[0]` and `aggregation[1]` when multiple grouping passes are required.  (default: average)
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-instances: string # A simple pattern limiting the instances scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-labels: string # A simple pattern limiting the labels scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query based on their labels. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by scope nodes, scope contexts, and scope instances). Only instances having labels that match this pattern will be included in the query. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-dimensions: string # A simple pattern limiting the dimensions scope of the query. The scope controls both data and metadata response. This limits which dimensions are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against both the dimension `id` and `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --instances: string # A simple pattern matching the instances to be queried. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --labels: string # A simple pattern matching the labels to be queried. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by all the above: scope nodes, scope contexts, nodes, contexts and instances). Negative simple patterns should not be used in this filter.  (format: simple pattern, default: *)
  --alerts: string # A simple pattern matching the alerts to be queried. The simple pattern is checked against the `name` of alerts and the combination of `name:status`, when status is one of `CLEAR`, `WARNING`, `CRITICAL`, `REMOVED`, `UNDEFINED`, `UNINITIALIZED`, of all the alerts of all the eligible instances (as filtered by all the above). A negative simple pattern will exclude the instances having the labels matched.  (format: simple pattern, default: *)
  --dimensions: string # A simple patterns matching the dimensions to be queried. The simple pattern is checked against and `id` and the `name` of the dimensions of the eligible instances (as filtered by all the above). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --time-group: string@time-group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --time-group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
  --time-resampling: float # For incremental values that are "per second", this value is used to resample them to "per minute` (60) or "per hour" (3600). It can only be used in conjunction with group=average.  (format: integer, default: 0)
  --format: string@format-completer # The format of the data to be returned. (default: json2)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --callback: string # For JSONP responses, the callback function name.
  --filename: string # Add `Content-Disposition: attachment; filename=` header to the response, that will instruct the browser to save the response with the given filename."
  --tqx: string # [Google Visualization API](https://developers.google.com/chart/interactive/docs/dev/implementing_data_source?hl=en) formatted parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "multi") (serialize-qp "group_by_label" $group_by_label "scalar") (serialize-qp "aggregation" $aggregation "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "scope_instances" $scope_instances "scalar") (serialize-qp "scope_labels" $scope_labels "scalar") (serialize-qp "scope_dimensions" $scope_dimensions "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "instances" $instances "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "alerts" $alerts "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "options" $options "multi") (serialize-qp "time_group" $time_group "scalar") (serialize-qp "time_group_options" $time_group_options "scalar") (serialize-qp "time_resampling" $time_resampling "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "tqx" $tqx "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Data Query v1 - Single node, single chart or context queries. without group-by.
#
# GET /api/v1/data
# DEPRECATED
# operationId: dataQuery1
@deprecated
export def "data dataQuery1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chart: string # The id of the chart as returned by the `/api/v1/charts` call. (format: as returned by `/api/v1/charts`)
  --context: string # The context of the chart as returned by the /charts call. (format: as returned by /charts)
  --dimension: list # Zero, one or more dimension ids or names, as returned by the /chart call, separated with comma or pipe. Netdata simple patterns are supported.
  --chart-label-key: string # Specify the chart label keys that need to match for context queries as comma separated values. At least one matching key is needed to match the corresponding chart.  (format: key1,key2,key3)
  --chart-labels-filter: string # Specify the chart label keys and values to match for context queries. All keys/values need to match for the chart to be included in the query. The labels are specified as key1:value1,key2:value2  (format: key1:value1,key2:value2,key3:value3)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --format: string@format-completer-1 # The format of the data to be returned. (default: json)
  --group: string@group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
  --gtime: float # The grouping number of seconds. This is used in conjunction with group=average to change the units of metrics (ie when the data is per-second, setting gtime=60 will turn them to per-minute).  (format: integer, default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --callback: string # For JSONP responses, the callback function name.
  --filename: string # Add `Content-Disposition: attachment; filename=` header to the response, that will instruct the browser to save the response with the given filename."
  --tqx: string # [Google Visualization API](https://developers.google.com/chart/interactive/docs/dev/implementing_data_source?hl=en) formatted parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "chart_label_key" $chart_label_key "scalar") (serialize-qp "chart_labels_filter" $chart_labels_filter "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "options" $options "multi") (serialize-qp "format" $format "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "group_options" $group_options "scalar") (serialize-qp "gtime" $gtime "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "tqx" $tqx "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Metrics v1 - Fetch latest value for all metrics
#
# GET /api/v1/allmetrics
# DEPRECATED
# operationId: allMetrics1
@deprecated
export def "allmetrics allMetrics1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-2 # The format of the response to be returned. (default: shell)
  --filter: string # Allows to filter charts out using simple patterns. (format: any text)
  --qp-variables: string@variables-completer # When enabled, netdata will expose various system configuration variables.  (default: no)
  --timestamps: string@timestamps-completer # Enable or disable timestamps in prometheus output.  (default: yes)
  --names: string@names-completer # When enabled netdata will report dimension names. When disabled netdata will report dimension IDs. The default is controlled in netdata.conf.  (default: yes)
  --oldunits: string@oldunits-completer # When enabled, netdata will show metric names for the default `source=average` as they appeared before 1.12, by using the legacy unit naming conventions.  (default: yes)
  --hideunits: string@hideunits-completer # When enabled, netdata will not include the units in the metric names, for the default `source=average`.  (default: yes)
  --server: string # Set a distinct name of the client querying prometheus metrics. Netdata will use the client IP if this is not set.  (format: any text)
  --prefix: string # Prefix all prometheus metrics with this string.  (format: any text)
  --data: string@data-completer # Select the prometheus response data source. There is a setting in netdata.conf for the default.  (default: average)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "variables" $qp_variables "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "names" $names "scalar") (serialize-qp "oldunits" $oldunits "scalar") (serialize-qp "hideunits" $hideunits "scalar") (serialize-qp "server" $server "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/allmetrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a badge in form of SVG image for a chart (or dimension)
#
# GET /api/v1/badge.svg
# DEPRECATED
# operationId: badge1
@deprecated
export def "badgesvg badge1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # The id of the chart as returned by the `/api/v1/charts` call. (format: as returned by `/api/v1/charts`)
  --dimension: list # Zero, one or more dimension ids or names, as returned by the /chart call, separated with comma or pipe. Netdata simple patterns are supported.
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --group: string@group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --alarm: string # The name of an alarm linked to the chart. (format: any text, allows empty value)
  --label: string # A text to be used as the label. (format: any text, allows empty value)
  --units: string # A text to be used as the units. (format: any text, allows empty value)
  --label-color: string # A color to be used for the background of the label side(left side) of the badge. One of predefined colors or specific color in hex `RGB` or `RRGGBB` format (without preceding `#` character). If value wrong or not given default color will be used.  (allows empty value)
  --value-color: string # A color to be used for the background of the value *(right)* part of badge. You can set multiple using a pipe with a condition each, like this: `color<value|color:null` The following operators are supported: >, <, >=, <=, =, :null (to check if no value exists). Each color can be specified in same manner as for `label_color` parameter. Currently only integers are supported as values.  (format: any text, allows empty value)
  --text-color-lbl: string # Font color for label *(left)* part of the badge. One of predefined colors or as HTML hexadecimal color without preceding `#` character. Formats allowed `RGB` or `RRGGBB`. If no or wrong value given default color will be used.  (allows empty value)
  --text-color-val: string # Font color for value *(right)* part of the badge. One of predefined colors or as HTML hexadecimal color without preceding `#` character. Formats allowed `RGB` or `RRGGBB`. If no or wrong value given default color will be used.  (allows empty value)
  --multiply: float # Multiply the value with this number for rendering it at the image (integer value required). (format: integer, allows empty value)
  --divide: float # Divide the value with this number for rendering it at the image (integer value required). (format: integer, allows empty value)
  --scale: float # Set the scale of the badge (greater or equal to 100). (format: integer, allows empty value)
  --fixed-width-lbl: float # This parameter overrides auto-sizing of badge and creates it with fixed width. This parameter determines the size of the label's left side *(label/name)*. You must set this parameter together with `fixed_width_val` otherwise it will be ignored. You should set the label/value widths wide enough to provide space for all the possible values/contents of the badge you're requesting. In case the text cannot fit the space given it will be clipped. The `scale` parameter still applies on the values you give to `fixed_width_lbl` and `fixed_width_val`.  (format: integer)
  --fixed-width-val: float # This parameter overrides auto-sizing of badge and creates it with fixed width. This parameter determines the size of the label's right side *(value)*. You must set this parameter together with `fixed_width_lbl` otherwise it will be ignored. You should set the label/value widths wide enough to provide space for all the possible values/contents of the badge you're requesting. In case the text cannot fit the space given it will be clipped. The `scale` parameter still applies on the values you give to `fixed_width_lbl` and `fixed_width_val`.  (format: integer)
  --points: int # The number of points to use for the calculation. Default is 1. (default: 1, allows empty value)
  --group-options: string # Additional options for the grouping function. (allows empty value)
  --precision: int # Number of decimal places to show in the value. Default is -1 (automatic). (default: -1, allows empty value)
  --refresh: string # Auto-refresh interval in seconds. Use "auto" to automatically determine refresh interval based on the time range or alarm update frequency. For alarms, defaults to the alarm's update_every. For charts with RRDR_OPTION_NOT_ALIGNED, defaults to the chart's update_every. Otherwise calculated from the time range (before - after).  (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "options" $options "multi") (serialize-qp "alarm" $alarm "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "label_color" $label_color "scalar") (serialize-qp "value_color" $value_color "scalar") (serialize-qp "text_color_lbl" $text_color_lbl "scalar") (serialize-qp "text_color_val" $text_color_val "scalar") (serialize-qp "multiply" $multiply "scalar") (serialize-qp "divide" $divide "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "fixed_width_lbl" $fixed_width_lbl "scalar") (serialize-qp "fixed_width_val" $fixed_width_val "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "group_options" $group_options "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/badge.svg" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a badge in form of SVG image for a chart (or dimension) - Latest API
#
# GET /api/v3/badge.svg
# operationId: badge3
export def "badgesvg badge3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # The id of the chart as returned by the `/api/v1/charts` call. (format: as returned by `/api/v1/charts`)
  --dimension: list # Zero, one or more dimension ids or names, as returned by the /chart call, separated with comma or pipe. Netdata simple patterns are supported.
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --group: string@group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --alarm: string # The name of an alarm linked to the chart. When specified, the badge will display the alarm's current value and use alarm status for color selection. (allows empty value)
  --label: string # Custom text to use as the badge label (left side). If not specified: - For alarms: uses the alarm name (with underscores replaced by spaces) - For dimensions: uses the dimension name - Otherwise: uses the chart name  (allows empty value)
  --units: string # Custom text to use as the units suffix. If not specified: - For alarms: uses the alarm's configured units or empty string - For percentage queries: uses "%" - Otherwise: uses the chart's units  (allows empty value)
  --label-color: string # Background color for the label (left) side of the badge. Can be: - One of the predefined color names - Hex RGB format (3 digits): e.g., "f00" for red - Hex RRGGBB format (6 digits): e.g., "ff0000" for red Note: Do not include the '#' character. If value is invalid, default color will be used.  (allows empty value)
  --value-color: string # Background color for the value (right) side of the badge. Supports conditional coloring based on the value.  Can be specified as: - Simple color: Same format as label_color - Conditional: Multiple color rules separated by pipe (|), each with format: `color<operator>value`  Supported operators: - `>`: greater than - `<`: less than - `>=`: greater than or equal - `<=`: less than or equal - `=`: equal to - `:null`: true when no value exists  Example: `green<80|yellow<95|red` (green if value < 80, yellow if < 95, otherwise red)  Note: Currently only integers are supported as values. Colors follow same format as label_color.  (allows empty value)
  --text-color-lbl: string # Font color for the label (left) side text. Can be: - One of the predefined color names - Hex RGB or RRGGBB format without '#' character If not specified or invalid, default color will be used.  (allows empty value)
  --text-color-val: string # Font color for the value (right) side text. Can be: - One of the predefined color names - Hex RGB or RRGGBB format without '#' character If not specified or invalid, default color will be used.  (allows empty value)
  --multiply: int # Multiply the displayed value by this number before rendering. Integer value required. Useful for unit conversions or scaling. Default is 1.  (default: 1, allows empty value)
  --divide: int # Divide the displayed value by this number before rendering. Integer value required. Useful for unit conversions or scaling. Default is 1.  (default: 1, allows empty value)
  --scale: int # Scale factor for the badge size as a percentage. Must be >= 100. - 100 = normal size (default) - 150 = 1.5x larger - 200 = 2x larger  (default: 100, allows empty value)
  --fixed-width-lbl: int # Fixed width for the label (left) side in pixels. Must be used together with `fixed_width_val`.  This overrides automatic sizing and creates a badge with fixed dimensions. Ensure the width is sufficient for your content - text that doesn't fit will be clipped.  The `scale` parameter still applies to these fixed width values.
  --fixed-width-val: int # Fixed width for the value (right) side in pixels. Must be used together with `fixed_width_lbl`.  This overrides automatic sizing and creates a badge with fixed dimensions. Ensure the width is sufficient for your content - text that doesn't fit will be clipped.  The `scale` parameter still applies to these fixed width values.
  --points: int # Number of data points to use for the calculation. Default is 1. Higher values provide averaging over more samples.  (default: 1, allows empty value)
  --group-options: string # Additional options for the time-series grouping function. Format depends on the selected group method. (allows empty value)
  --precision: int # Number of decimal places to display in the value. - Positive number: exact decimal places (e.g., 2 = "12.34") - -1 (default): automatic precision based on value magnitude  (default: -1, allows empty value)
  --refresh: string # Auto-refresh interval for the badge. Can be: - "auto": Automatically determine refresh based on context   - For alarms: uses the alarm's update_every interval   - For non-aligned charts: uses the chart's update_every   - For time-range queries: uses the query time span - Integer: Specific refresh interval in seconds  When refresh is set, the response includes a Refresh HTTP header.  (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "options" $options "multi") (serialize-qp "alarm" $alarm "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "label_color" $label_color "scalar") (serialize-qp "value_color" $value_color "scalar") (serialize-qp "text_color_lbl" $text_color_lbl "scalar") (serialize-qp "text_color_val" $text_color_val "scalar") (serialize-qp "multiply" $multiply "scalar") (serialize-qp "divide" $divide "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "fixed_width_lbl" $fixed_width_lbl "scalar") (serialize-qp "fixed_width_val" $fixed_width_val "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "group_options" $group_options "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/badge.svg" $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Metrics v3 - Export all metrics in various formats - Latest API
#
# GET /api/v3/allmetrics
# operationId: allMetrics3
export def "allmetrics allMetrics3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --format: string@format-completer-2 # The export format for the metrics. Required parameter.  **Formats:** - `shell`: Bash variables (default) - Exports as NETDATA_CHARTNAME_DIMENSIONNAME="value" - `prometheus`: Prometheus format (single host) - Compatible with Prometheus scraping - `prometheus_all_hosts`: Prometheus format (all hosts) - Includes metrics from child nodes with host labels - `json`: JSON format - Full metadata including chart names, families, contexts, units, and timestamps  **Format Details:** - Shell format includes alarm status variables (NETDATA_ALARM_CHART_ALARM_STATUS, NETDATA_ALARM_CHART_ALARM_VALUE) - Prometheus formats respect Prometheus metric naming conventions - JSON format provides complete chart and dimension information  (default: shell)
  --filter: string # Simple pattern filter to include only specific charts. Uses Netdata simple pattern matching.  **Pattern Syntax:** - Exact match: `system.cpu` - Wildcard: `system.*` (all system charts) - Multiple patterns: `system.* disk.*` (space-separated) - Negation: `!system.cpu` (exclude specific chart)  When not specified, all charts are exported.  **Examples:** - `system.*` - Export only system charts - `disk.* net.*` - Export disk and network charts - `* !*.mdstat` - Export all except mdstat charts
  --qp-variables: string@variables-completer-1 # **Prometheus format only**: Include or exclude system configuration variables in the output.  When enabled (yes/1/true), Netdata exposes various system configuration variables as Prometheus metrics. This includes: - Netdata configuration parameters - System environment information - Collection plugin states  Note: Only affects Prometheus format output. Ignored for shell and json formats.  (default: no)
  --timestamps: string@timestamps-completer-1 # **Prometheus format only**: Include or exclude timestamps in Prometheus metrics.  When enabled (default), each metric includes a timestamp of when it was collected. When disabled, metrics are exported without timestamps (Prometheus will use scrape time).  Note: Only affects Prometheus format output. Ignored for shell and json formats.  (default: yes)
  --names: string@names-completer-1 # **Prometheus format only**: Use dimension names vs IDs in metric names.  When enabled (default), Prometheus metrics use human-readable dimension names. When disabled, metrics use dimension IDs (which never change).  **Example:** - names=yes: `netdata_system_cpu_percentage_average{dimension="user"}` - names=no: `netdata_system_cpu_percentage_average{dimension="user"}`  The default is controlled by the global Netdata configuration. This parameter allows per-request override.  Note: Only affects Prometheus format output.
  --oldunits: string@oldunits-completer-1 # **Prometheus format only**: Use legacy unit naming conventions (pre-1.12 format).  When enabled, metric names for `source=average` use the old unit naming conventions as they appeared before Netdata version 1.12.  This is provided for backward compatibility with existing Prometheus configurations.  Note: Only affects Prometheus format with source=average.  (default: no)
  --hideunits: string@hideunits-completer-1 # **Prometheus format only**: Exclude units from metric names for source=average.  When enabled, units are not included in the Prometheus metric names for the default `source=average` data.  **Example:** - hideunits=no: `netdata_system_cpu_percentage_average` - hideunits=yes: `netdata_system_cpu_average`  Note: Only affects Prometheus format with source=average.  (default: no)
  --server: string # **Prometheus format only**: Set a custom identifier for the client scraping the metrics.  This parameter is used to identify the client in Prometheus metric labels. If not specified, Netdata uses the client's IP address.  Useful when multiple Prometheus instances scrape the same Netdata agent, or when scraping through a proxy.  **Example:** `server=prometheus-prod-1`  Note: Only affects Prometheus format output. This value appears in metric labels to distinguish scraping sources.
  --prefix: string # **Prometheus format only**: Prefix all Prometheus metric names with a custom string.  Useful for namespacing metrics when aggregating from multiple sources or to comply with organizational metric naming conventions.  **Example:** `prefix=mycompany_` produces metrics like `mycompany_system_cpu_percentage_average`  The default prefix is controlled by the global Netdata configuration. This parameter allows per-request override.  Note: Only affects Prometheus format output.
  --data: string@data-completer # **Prometheus format only**: Select the data source/aggregation method for Prometheus metrics.  **Options:** - `as-collected`: Raw values as collected by data collection plugins (no aggregation) - `average`: Average values over the collection interval (default) - `sum`: Sum of values over the collection interval  The `as-collected` source provides the most recent raw sample, while `average` and `sum` provide values aggregated over the chart's update interval.  The default is controlled by the global Netdata exporting configuration. This parameter allows per-request override.  **Use Cases:** - `as-collected`: For counter metrics that Prometheus will rate() - `average`: For gauge metrics showing typical values - `sum`: For accumulating metrics  Aliases: `source`, `data source`, `data-source`, `data_source`, `datasource`  Note: Only affects Prometheus format output.  (default: average)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "variables" $qp_variables "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "names" $names "scalar") (serialize-qp "oldunits" $oldunits "scalar") (serialize-qp "hideunits" $hideunits "scalar") (serialize-qp "server" $server "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/allmetrics" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Current Alert Status - Multi-node Alert Information - Latest API
#
# GET /api/v3/alerts
# operationId: alerts3
export def "alerts alerts3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --alert: string # Filter alerts by alert name pattern. Uses Netdata simple pattern matching.  **Pattern Syntax:** - Exact match: `cpu_usage` - Wildcard: `cpu_*` (all CPU-related alerts) - Multiple patterns: `cpu_* ram_*` (space-separated) - Negation: `!cpu_usage` (all except this alert)  **Common Alert Names:** - `ram_in_use` - RAM utilization - `disk_space_usage` - Disk space - `10min_cpu_usage` - CPU usage over 10 minutes - `tcp_listen_overflows` - TCP connection queue overflows - `disk_backlog` - Disk I/O backlog  When not specified, all alerts are included.  **Examples:** - `alert=ram_in_use` - Only RAM usage alert - `alert=*cpu*` - All CPU-related alerts - `alert=* !*_critical` - All alerts except those ending with _critical
  --status: string # Filter alerts by their current status. Can specify multiple statuses.  **Alert Statuses:** - `CRITICAL` - Alert is in critical state (highest severity) - `WARNING` - Alert is in warning state - `CLEAR` - Alert is in normal state (not triggered) - `UNDEFINED` - Alert could not be evaluated (e.g., division by zero, missing data) - `UNINITIALIZED` - Alert has not been evaluated yet (no data collected)  **Multiple Statuses:** To show multiple statuses, separate them with commas: `status=CRITICAL,WARNING`  **Use Cases:** - `status=CRITICAL` - Show only critical alerts requiring immediate attention - `status=CRITICAL,WARNING` - Show all alerts that need attention - `status=CLEAR` - Show alerts that are currently in normal state - Not specified - Show alerts in all states  **Default:** When not specified, typically returns only alerts in WARNING or CRITICAL state (this depends on options parameter).
  --options: string # Comma or pipe-separated list of options to control response content.  **Alert-Specific Options:** - `summary` - Include summary counters (total alerts, by status, by type)  **General Options:** - `contexts` - Include context information - `instances` - Include alert instance details - `values` - Include current alert values - `configurations` - Include alert configuration details  **Examples:** - `options=summary` - Include alert count summaries - `options=summary,values` - Summaries and current values - `options=summary|configurations` - Summaries and configs (pipe separator)  When not specified, returns basic alert information without detailed configs or summaries.
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: int # Maximum time in milliseconds to wait for the query to complete.  This is useful for preventing long-running queries from blocking when querying large infrastructures with many nodes and alerts.  **Format:** Integer (milliseconds)  **Default:** Server default timeout (typically 30000ms = 30 seconds)  **Examples:** - `timeout=5000` - 5 second timeout - `timeout=60000` - 60 second timeout  When the timeout is exceeded, the server returns a partial result with whatever data was collected before the timeout.  (format: int64, e.g. 30000)
  --cardinality: int # Limit the number of alert instances returned to prevent response explosion.  When monitoring large infrastructures, some alert types may have hundreds or thousands of instances (e.g., disk space alerts for every disk on every node).  This parameter limits the number of unique alert instances in the response.  **Format:** Integer (maximum number of alert instances)  **Default:** No limit  **Use Cases:** - Preventing huge responses when there are many alert instances - Getting a sample of alerts rather than complete list - Dashboard widgets with limited display space  **Example:** - `cardinality=100` - Return at most 100 alert instances  **Alias:** Can also be specified as `cardinality_limit`  When the limit is exceeded, the response may indicate how many alerts were omitted.  (e.g. 100)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "alert" $alert "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve alert state transition history across all nodes with advanced filtering
#
# GET /api/v3/alert_transitions
# operationId: alert_transitions_v3
export def "alert-transitions v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Filter transitions to only include specific nodes using simple pattern matching.  This parameter defines which nodes to include in the search using Netdata's simple pattern syntax (not regex).  **Pattern Syntax:** - `*` matches any number of characters (including none) - `node1 node2` space-separated list matches any of the nodes - `!node3` exclude specific nodes (prefix with !) - Can combine inclusion and exclusion: `web* !web-test*`  **Examples:** - `scope_nodes=web*` - All nodes starting with "web" - `scope_nodes=web* db*` - All web and database nodes - `scope_nodes=* !test*` - All nodes except test nodes - `scope_nodes=prod-web-01` - Specific node only  **Use Cases:** - Focus on specific node groups (production vs staging) - Exclude test/development nodes from analysis - Investigate issues on specific infrastructure tiers  When not specified, transitions from all nodes are included.
  --nodes: string # Filter transitions to specific nodes by their exact names.  Unlike `scope_nodes` which supports patterns, this parameter requires exact node names. Multiple nodes are separated by comma or pipe.  **Format:** Comma or pipe-separated list of exact node names  **Examples:** - `nodes=web-server-01` - Single specific node - `nodes=web-server-01,web-server-02,db-server-01` - Multiple specific nodes - `nodes=web-server-01|web-server-02` - Pipe separator also works  **Difference from scope_nodes:** - `scope_nodes`: Pattern matching, filters at query time - `nodes`: Exact names, more efficient for known node names  **Best Practice:** Use `nodes` when you know exact node names, use `scope_nodes` for pattern-based filtering.  When not specified, transitions from all nodes matching scope_nodes (or all nodes if scope_nodes is also not specified) are included.  (e.g. web-server-01,db-server-01)
  --scope-contexts: string # Filter transitions to only include alerts from specific metric contexts using pattern matching.  Contexts group similar metrics across instances (e.g., `system.cpu` groups CPU metrics from all nodes, `disk.io` groups disk I/O from all disks).  **Pattern Syntax:** - `*` matches any number of characters - `context1 context2` space-separated list matches any of the contexts - `!context3` exclude specific contexts - Can combine: `system.* !system.io*`  **Common Context Patterns:** - `system.*` - All system-level metrics - `disk.*` - All disk-related metrics - `net.*` - All network-related metrics - `mysql.*` - All MySQL metrics - `nginx.*` - All Nginx metrics  **Examples:** - `scope_contexts=system.cpu` - Only CPU alerts - `scope_contexts=disk.* net.*` - All disk and network alerts - `scope_contexts=* !system.ip*` - All contexts except IP-related  **Use Cases:** - Focus on specific subsystem (e.g., storage, network) - Exclude noisy alert types - Component-specific incident investigation  When not specified, transitions from all contexts are included.
  --contexts: string # Filter transitions to specific contexts by their exact names.  Unlike `scope_contexts` which supports patterns, this parameter requires exact context names.  **Format:** Comma or pipe-separated list of exact context names  **Examples:** - `contexts=system.cpu` - Single specific context - `contexts=system.cpu,system.load,system.ram` - Multiple contexts - `contexts=disk.space|disk.inodes` - Pipe separator  **Difference from scope_contexts:** - `scope_contexts`: Pattern matching for flexible filtering - `contexts`: Exact names for precise filtering  When not specified, transitions from all contexts matching scope_contexts are included.  (e.g. system.cpu,system.ram,disk.space)
  --alert: string # Filter transitions to a specific alert by its exact name.  Alert names are unique identifiers for specific alert configurations.  **Format:** Exact alert name (case-sensitive)  **Examples:** - `alert=disk_space_usage` - Transitions for disk space alert - `alert=cpu_usage` - Transitions for CPU usage alert - `alert=ram_in_use` - Transitions for RAM usage alert  **Use Cases:** - Analyze history of a specific alert - Tune alert thresholds based on historical behavior - Investigate alert flapping (rapid state changes) - Track alert effectiveness  **Tip:** To find available alert names, query `/api/v3/alerts` first or use the `/api/v3/alert_config` endpoint.  When not specified, transitions for all alerts are included.  (e.g. disk_space_usage)
  --transition: string # Filter to a specific transition by its unique identifier.  Each transition has a unique ID (UUID). This parameter is rarely used but can retrieve exact transition records.  **Format:** UUID string  **Use Case:** Retrieve exact transition details when you have the transition ID from another query or notification.  When not specified, all transitions matching other filters are included.  (e.g. 550e8400-e29b-41d4-a716-446655440000)
  --last: int # Limit the number of transition records returned.  This controls how many transition records to include in the response, ordered by time (most recent first).  **Format:** Positive integer  **Default:** 1 (returns only the most recent transition)  **Examples:** - `last=1` - Most recent transition only (default) - `last=100` - Last 100 transitions - `last=1000` - Last 1000 transitions  **Use Cases:** - Dashboard widgets showing recent N alerts - API clients with pagination - Limiting response size for performance  **Pagination:** For datasets larger than `last`, use the `anchor_gi` parameter to navigate to the next page: 1. Make request with `last=100` 2. Note the `global_id` of the last transition in response 3. Make next request with `last=100&anchor_gi=<global_id>`  **Performance Note:** Smaller values of `last` result in faster queries and smaller responses.  **IMPORTANT:** This parameter is required. If not specified, defaults to 1.  (default: 1, e.g. 100)
  --anchor-gi: int # Global ID anchor for pagination through large result sets.  Each transition has a unique global_id (an incrementing number). Use this parameter to paginate through results by specifying the global_id of the last transition from the previous page.  **How Pagination Works:** 1. First request: `?last=100` - Returns first 100 transitions 2. Extract `global_id` of the 100th (last) transition from response 3. Next request: `?last=100&anchor_gi=<global_id>` - Returns next 100 transitions  **Format:** Positive integer (global_id from previous response)  **Examples:** - `anchor_gi=12345` - Start from transition with global_id 12345 - Combined with last: `last=100&anchor_gi=12345` - Get 100 transitions starting after global_id 12345  **Use Cases:** - Processing large alert history datasets - Implementing "load more" in UIs - Batch processing of transition records - Exporting complete alert history  **Direction:** - Results are ordered by global_id (which correlates with time) - Anchor specifies "start after this ID" - Each page contains `last` number of records  When not specified, pagination starts from the most recent transition.  (format: int64, e.g. 12345678)
  --f-status: string # **Facet Filter:** Filter transitions by their NEW status (the status the alert transitioned TO).  **Available Status Values:** - `CRITICAL` - Alert in critical state (highest severity) - `WARNING` - Alert in warning state - `CLEAR` - Alert returned to normal state - `UNDEFINED` - Alert evaluation failed (e.g., metric missing, division by zero) - `UNINITIALIZED` - Alert not yet evaluated (no data yet) - `REMOVED` - Alert was removed (plugin stopped, configuration changed)  **Format:** Comma-separated list of status values  **Examples:** - `f_status=CRITICAL` - Only transitions TO critical state - `f_status=CRITICAL,WARNING` - Transitions to critical or warning - `f_status=CLEAR` - When alerts cleared (returned to normal)  **Use Cases:** - Find when alerts became critical: `f_status=CRITICAL` - Track alert recovery: `f_status=CLEAR` - Find alert failures: `f_status=UNDEFINED` - Incident timeline: `f_status=CRITICAL,WARNING`  **Note:** This filters by the NEW status. To see transitions FROM a status to another, you'll need to examine the old_status field in the response.  When not specified, transitions to all statuses are included.
  --f-type: string # **Facet Filter:** Filter transitions by alert type.  Alert types categorize alerts by what they monitor (e.g., "System", "Database", "Web Server").  **Format:** Comma-separated list of alert type names  **Common Alert Types:** - `System` - System-level alerts (CPU, RAM, load) - `Database` - Database monitoring alerts - `Web Server` - Web server alerts (Nginx, Apache) - `Network` - Network-related alerts - `Storage` - Storage and disk alerts  **Examples:** - `f_type=System` - Only system alerts - `f_type=Database,Web Server` - Database and web server alerts  **Use Cases:** - Focus on specific infrastructure component types - Filter by technology stack (databases, web servers, etc.) - Team-specific alert filtering  **Note:** The exact type values depend on your alert configurations. Query `/api/v3/alerts` to see available types in your installation.  When not specified, transitions of all types are included.  (e.g. System,Database)
  --f-role: string # **Facet Filter:** Filter transitions by recipient role.  Roles define who should be notified about alerts (e.g., "sysadmin", "dba", "webmaster").  **Format:** Comma-separated list of role names  **Common Roles:** - `sysadmin` - System administrators - `dba` - Database administrators - `webmaster` - Web server administrators - `devops` - DevOps team - `security` - Security team  **Examples:** - `f_role=sysadmin` - Alerts for sysadmin role - `f_role=sysadmin,dba` - Alerts for sysadmins and DBAs  **Use Cases:** - Team-specific alert filtering - Role-based alert analysis - Notification audit trails  **Note:** Roles are defined in your alert configurations. The exact role values depend on your Netdata setup.  When not specified, transitions for all roles are included.  (e.g. sysadmin,dba)
  --f-class: string # **Facet Filter:** Filter transitions by alert classification.  Alert classifications categorize alerts by their nature (e.g., "Errors", "Latency", "Utilization").  **Format:** Comma-separated list of classification names  **Common Classifications:** - `Errors` - Error-related alerts - `Latency` - Performance/latency alerts - `Utilization` - Resource utilization alerts - `Availability` - Availability/uptime alerts - `Workload` - Workload-related alerts  **Examples:** - `f_class=Errors` - Only error-related transitions - `f_class=Latency,Utilization` - Performance and utilization alerts  **Use Cases:** - Focus on specific problem categories - SLA/SLO tracking by classification - Alert categorization analysis  When not specified, transitions of all classifications are included.  (e.g. Errors,Latency)
  --f-component: string # **Facet Filter:** Filter transitions by system component.  Components identify which part of the system the alert relates to (e.g., "Network", "Disk", "Memory").  **Format:** Comma-separated list of component names  **Common Components:** - `Network` - Network-related alerts - `Disk` - Disk/storage alerts - `Memory` - Memory alerts - `CPU` - CPU alerts - `Database` - Database component alerts  **Examples:** - `f_component=Disk` - Only disk-related transitions - `f_component=Network,Disk` - Network and disk alerts  **Use Cases:** - Component-specific incident investigation - Infrastructure subsystem analysis - Capacity planning by component  When not specified, transitions for all components are included.  (e.g. Disk,Network)
  --f-node: string # **Facet Filter:** Filter transitions by exact node hostname.  This is a facet filter alternative to the `nodes` parameter, typically used when you want to combine it with other facets.  **Format:** Comma-separated list of exact node hostnames  **Examples:** - `f_node=web-server-01` - Single specific node - `f_node=web-server-01,db-server-01` - Multiple nodes  **Difference from `nodes` parameter:** - Both accept exact node names - `f_node` is a facet filter (can be combined with other f_* filters) - `nodes` is a direct filter parameter  **Best Practice:** Use `nodes` for simple node filtering, use `f_node` when combining with other facets in complex queries.  When not specified, all nodes are included.  (e.g. web-server-01)
  --f-alert: string # **Facet Filter:** Filter transitions by exact alert name.  This is a facet filter alternative to the `alert` parameter.  **Format:** Comma-separated list of exact alert names  **Examples:** - `f_alert=disk_space_usage` - Single alert - `f_alert=cpu_usage,ram_in_use` - Multiple alerts  **Difference from `alert` parameter:** - `alert`: Single alert name - `f_alert`: Multiple alert names, facet filter  When not specified, all alerts are included.  (e.g. disk_space_usage,ram_in_use)
  --f-instance: string # **Facet Filter:** Filter transitions by chart instance name.  Chart instances are specific monitored entities (e.g., "disk_sda", "eth0", "mysql_localhost").  **Format:** Comma-separated list of instance names  **Examples:** - `f_instance=sda` - Alerts for disk sda - `f_instance=eth0,eth1` - Alerts for network interfaces eth0 and eth1  **Use Cases:** - Device-specific alert history (specific disk, NIC, etc.) - Instance-level troubleshooting - Resource-specific analysis  **Note:** Instance names depend on your system configuration and what's being monitored.  When not specified, all instances are included.  (e.g. sda,sdb)
  --f-context: string # **Facet Filter:** Filter transitions by exact metric context.  This is a facet filter alternative to the `contexts` parameter.  **Format:** Comma-separated list of exact context names  **Examples:** - `f_context=system.cpu` - CPU context only - `f_context=disk.space,disk.inodes` - Disk space and inodes  **Difference from `contexts` parameter:** - Both accept exact context names - `f_context` is a facet filter (can be combined with other f_* filters) - `contexts` is a direct filter parameter  When not specified, all contexts are included.  (e.g. system.cpu,system.ram)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: int # Maximum time in milliseconds to wait for the query to complete.  Alert transition queries can be expensive when searching large time ranges or across many nodes.  **Format:** Integer (milliseconds)  **Default:** Server default timeout (typically 30000ms = 30 seconds)  **Examples:** - `timeout=5000` - 5 second timeout - `timeout=60000` - 60 second timeout (for large queries)  **Use Cases:** - Prevent long-running queries from blocking - API clients with strict latency requirements - Dashboard widgets needing fast responses  When timeout is exceeded, the server returns a partial result with whatever transitions were collected before timeout, or an error if no results were ready.  (format: int64, e.g. 30000)
  --cardinality: int # Limit the number of transition records returned to prevent response explosion.  **Format:** Integer (maximum number of transitions)  **Default:** No limit (but respects `last` parameter)  **Relationship with `last`:** - `last`: Controls result set size (pagination) - `cardinality`: Hard limit on response size  **Use Cases:** - Ensure responses stay within size limits - Protect against accidentally requesting huge result sets - API clients with memory constraints  **Example:** - `cardinality=1000` - Never return more than 1000 transitions  **Alias:** Can also be specified as `cardinality_limit`  **Best Practice:** Use `last` for normal pagination, use `cardinality` as a safety limit.  When the limit is exceeded, the response may indicate how many transitions were omitted.  (e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "alert" $alert "scalar") (serialize-qp "transition" $transition "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "anchor_gi" $anchor_gi "scalar") (serialize-qp "f_status" $f_status "scalar") (serialize-qp "f_type" $f_type "scalar") (serialize-qp "f_role" $f_role "scalar") (serialize-qp "f_class" $f_class "scalar") (serialize-qp "f_component" $f_component "scalar") (serialize-qp "f_node" $f_node "scalar") (serialize-qp "f_alert" $f_alert "scalar") (serialize-qp "f_instance" $f_instance "scalar") (serialize-qp "f_context" $f_context "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/alert_transitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the configuration of a specific alert by its config hash ID
#
# GET /api/v3/alert_config
# operationId: alert_config_v3
export def "alert-config v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --config: string # The unique configuration hash ID (UUID) of the alert whose configuration to retrieve.  **Format:** UUID string (with or without hyphens)  **Where to Find Config Hash IDs:** 1. **From /api/v3/alerts Response:**    Each alert in the response includes a `config_hash_id` field containing the UUID  2. **From /api/v3/alert_transitions Response:**    Transition records include `config_hash_id` showing which config was active  3. **From Alert Notifications:**    Alert notifications (email, Slack, etc.) often include the config hash  4. **From Logs:**    Netdata logs may reference config hashes when loading alert configurations  **UUID Format Examples:** - With hyphens: `550e8400-e29b-41d4-a716-446655440000` - Without hyphens: `550e8400e29b41d4a716446655440000` - Both formats are accepted  **Important Notes:** - This parameter is **REQUIRED** - Must be a valid UUID format - Must reference an existing alert configuration - Case-insensitive  **Common Errors:** - Missing config parameter → 400 Bad Request with message "A config hash ID is required" - Invalid UUID format → 400 Bad Request - Non-existent UUID → 404 or empty result  **Example Usage:** ``` GET /api/v3/alert_config?config=550e8400-e29b-41d4-a716-446655440000 ```  **Tip:** To find all config hash IDs for a specific alert name, query the alerts endpoint first: ``` GET /api/v3/alerts?alert=disk_space_usage ``` Then extract the `config_hash_id` from the response.  (format: uuid, e.g. 550e8400-e29b-41d4-a716-446655440000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config" $config "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/alert_config" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the value of a specific chart variable used in alert expressions
#
# GET /api/v3/variable
# operationId: variable_v3
export def "variable v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # The chart identifier (ID or name) where the variable is defined.  **Chart Identifier Format:** Charts can be specified by either their unique ID or their name.  **Chart ID Format:** - Format: `type.name` (e.g., `system.cpu`, `disk.sda_io`, `mysql.queries`) - This is the canonical identifier shown in chart metadata - Case-sensitive - More reliable as it doesn't change  **Chart Name Format:** - Human-readable name (e.g., "System CPU") - May contain spaces - Less reliable as it can change - The API will try to find by name if ID lookup fails  **How to Find Chart IDs:** 1. **From /api/v1/charts:**    ```    GET /api/v1/charts    ```    Response includes all chart IDs in the system  2. **From /api/v3/contexts:**    ```    GET /api/v3/contexts    ```    Lists contexts and their chart instances  3. **From Alert Configuration:**    Alert configs reference charts in their `on` clause  4. **From Netdata Dashboard:**    Chart IDs are shown in chart metadata  **Examples:** - `chart=system.cpu` - System CPU chart - `chart=system.ram` - System RAM chart - `chart=disk.sda_io` - Disk sda I/O chart - `chart=mysql.queries` - MySQL queries chart  **Common Chart IDs by Category:** - **System:** `system.cpu`, `system.load`, `system.ram`, `system.io` - **Disk:** `disk.space`, `disk.io`, `disk.inodes` - **Network:** `net.eth0`, `net.packets` - **Databases:** `mysql.queries`, `postgres.connections`, `redis.memory`  **Important Notes:** - This parameter is **REQUIRED** - Must reference an existing chart on the specified host - Chart must be actively collecting data - Case-sensitive  **Error Handling:** - Missing parameter → 400 Bad Request: "A chart= and a variable= are required." - Invalid/non-existent chart → 404 Not Found: "Chart is not found: <chart>"
  --variable: string # The variable name to look up within the specified chart.  **Variable Name Format:** Variable names typically follow these conventions: - Start with `$` in alert expressions, but the `$` is optional in this parameter - Names are case-sensitive - Can reference dimensions, calculated values, or lookups  **Variable Name Categories:**  **1. Dimension Variables (most common):** Direct references to chart dimensions: - `used` - Value of "used" dimension - `free` - Value of "free" dimension - `cached` - Value of "cached" dimension - `buffers` - Value of "buffers" dimension - `read` - Read operations/bytes - `write` - Write operations/bytes  **2. Special Variables:** - `this` - The calculated/evaluated value from alert expression - `status` - Current alert status - `value` - Current metric value  **3. Lookup Variables:** Variables created via lookup operations: - Format: `<duration>_<dimension>_<method>` - Example: `1hour_cpu_avg` - Average CPU over last hour - Example: `5min_disk_used_max` - Max disk used in last 5 minutes  **4. Calculated Variables:** Custom variables defined in alert configurations: - `ram_percentage` - (used / total) * 100 - `disk_usage_ratio` - used / total - `error_rate` - errors / total_requests  **5. Chart Metadata Variables:** - `family` - Chart family/category - `units` - Chart units - `chart_type` - Chart type  **How to Discover Available Variables:** 1. **From Alert Configuration:**    Alert expressions reveal which variables are available    ```    GET /api/v3/alert_config?config=<uuid>    ```  2. **From /api/v1/alarm_variables:**    Lists all variables for a chart    ```    GET /api/v1/alarm_variables?chart=system.ram    ```  3. **From Chart Dimensions:**    Dimension names are typically available as variables    ```    GET /api/v1/chart?chart=system.ram    ```  **Common Variable Examples by Chart:**  **For system.ram:** - `used`, `free`, `cached`, `buffers`  **For system.cpu:** - `user`, `system`, `nice`, `idle`, `iowait`  **For disk.space:** - `used`, `avail` (available), `reserved`  **For disk.io:** - `read`, `write`  **For mysql.queries:** - `select`, `insert`, `update`, `delete`  **Important Notes:** - This parameter is **REQUIRED** - Variable name must exist in the chart's variable set - Case-sensitive - The `$` prefix is optional (both `$used` and `used` work)  **Error Handling:** - Missing parameter → 400 Bad Request: "A chart= and a variable= are required." - Non-existent variable → Returns trace showing variable not found
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar") (serialize-qp "variable" $variable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/variable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve detailed Netdata agent information across all nodes
#
# GET /api/v3/info
# operationId: info_v3
export def "info v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Filter to specific nodes using simple pattern matching.  **Pattern Syntax:** - `*` matches any characters - Space-separated list for multiple patterns - `!` prefix to exclude - Combine with: `web* !web-test*`  **Examples:** - `scope_nodes=web*` - All web servers - `scope_nodes=prod-*` - All production nodes - `scope_nodes=* !test*` - All except test nodes  **Use Cases:** - Focus on specific infrastructure tiers - Exclude development/test environments - Group by naming conventions  When not specified, returns info for all nodes.  (e.g. prod-*)
  --nodes: string # Filter to specific nodes by exact names.  Unlike `scope_nodes`, this requires exact node names (no patterns).  **Format:** Comma or pipe-separated list  **Examples:** - `nodes=web-server-01` - Single node - `nodes=web-server-01,db-server-01` - Multiple nodes - `nodes=web-01|web-02` - Pipe separator  **Best Practice:** - Use `nodes` when you know exact names - Use `scope_nodes` for pattern-based filtering  When not specified, returns info for all nodes matching scope_nodes.  (e.g. web-server-01,db-server-01)
  --options: string # Control the level of detail and what information to include in the response.  **Available Options:** - `full` or `all` - Include all available information - `labels` - Include host labels - `uuids` - Include UUIDs and identifiers - `deleted` - Include information about deleted/offline nodes - `hidden` - Include hidden agents  **Examples:** - `options=full` - Complete information - `options=labels,uuids` - Labels and identifiers - `options=labels|uuids` - Pipe separator also works  **Default Behavior:** When not specified, returns standard information without deleted/hidden nodes and without excessive detail.  **Use Cases:** - Inventory systems need `full` detail - Label-based filtering needs `labels` - Historical analysis may need `deleted`  (e.g. full,labels)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: int # Maximum time in milliseconds to wait for the query to complete.  **Format:** Integer (milliseconds)  **Default:** Server default timeout  **Example:** - `timeout=30000` - 30 second timeout  For agent info queries, timeouts are rarely needed as this is a fast metadata-only operation. However, on very large multi-node setups, you may want to limit query time.  (format: int64, e.g. 30000)
  --cardinality: int # Limit the number of nodes returned.  **Format:** Integer (maximum nodes)  **Default:** No limit  **Example:** - `cardinality=100` - Return at most 100 nodes  **Use Cases:** - Prevent huge responses in very large infrastructures - Get a sample of nodes for testing - Dashboard widgets with limited display space  When exceeded, response indicates how many nodes were omitted.  (e.g. 100)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve chart instances organized by node across the infrastructure
#
# GET /api/v3/node_instances
# operationId: node_instances_v3
export def "node-instances v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Filter to specific nodes using pattern matching.  **Pattern Syntax:** - `*` matches any characters - Space-separated for multiple patterns - `!` prefix excludes - Example: `prod-* !prod-test*`  **Examples:** - `scope_nodes=web*` - All web servers - `scope_nodes=db-* cache-*` - Database and cache nodes - `scope_nodes=* !test*` - All except test nodes  When not specified, returns instances from all nodes.  (e.g. prod-*)
  --nodes: string # Filter to specific nodes by exact names.  **Format:** Comma or pipe-separated exact names  **Examples:** - `nodes=web-server-01` - Single node - `nodes=web-01,db-01` - Multiple nodes  **Best Practice:** Use `nodes` for exact names, `scope_nodes` for patterns.  When not specified, returns instances from all nodes.  (e.g. web-server-01,db-server-01)
  --options: string # Control response detail level and included information.  **Available Options:** - `full` or `all` - Complete instance information - `labels` - Include instance labels - `uuids` - Include UUIDs and identifiers - `deleted` - Include deleted/offline instances - `hidden` - Include hidden instances - `instances` or `charts` - Include chart instances (default) - `metrics` or `dimensions` - Include dimension details  **Examples:** - `options=full` - All information - `options=labels,dimensions` - Labels and dimension details - `options=labels|uuids` - Pipe separator  **Default:** Returns basic instance information without excessive detail.  (e.g. full,labels,dimensions)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: int # Maximum time in milliseconds to wait for query completion.  **Format:** Integer (milliseconds)  **Default:** Server default timeout  **Example:** `timeout=30000` (30 seconds)  For large multi-node infrastructures, you may need to increase timeout to allow complete instance enumeration.  (format: int64, e.g. 30000)
  --cardinality: int # Limit the number of instances returned per node.  **Format:** Integer (max instances per node)  **Default:** No limit  **Example:** `cardinality=500` - At most 500 instances per node  **Use Cases:** - Prevent huge responses from nodes with many instances - Sample instances for testing - Dashboard widgets with limited space  When exceeded, response indicates how many instances were omitted per node.  (e.g. 500)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/node_instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve streaming topology path for nodes
#
# GET /api/v3/stream_path
# operationId: stream_path
export def "stream-path path" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Simple pattern to match node hostnames for scope filtering. Uses Netdata's simple pattern matching (not regex). Matched nodes define the scope for topology analysis.  **Pattern Syntax:** - `*` matches any number of characters - Use `|` to separate multiple patterns (OR logic) - Matches are case-insensitive - No regex support - only simple wildcards  **Examples:** - `prod-*` - All production nodes - `*-web-*` - All web server nodes - `db-*|cache-*` - All database or cache nodes - `*` - All nodes (default)  (default: *, e.g. prod-*)
  --nodes: string # Simple pattern to filter which nodes to include in the streaming path response. After scope is determined, this filters the results. Uses the same pattern syntax as scope_nodes.  **Difference from scope_nodes:** - `scope_nodes` defines what nodes to analyze for relationships - `nodes` filters which nodes to include in the output  **Examples:** - `web-*` - Only show web server nodes in output - `parent-*` - Only show parent nodes - Specific hostnames: `node1|node2|node3`  (default: *, e.g. web-*)
  --options: string # Comma-separated list of options to control response content and format.  **Available Options:** - `minify` - Minimize JSON output (no pretty-printing) - `debug` - Include debug information about streaming connections - `raw` - Include raw streaming metadata  **Examples:** - `minify` - Compact JSON response - `debug,raw` - Debug mode with raw metadata  (e.g. debug)
  --timeout: int # Maximum time in seconds to wait for the query to complete before timing out.  **Guidelines:** - Recommended: 30-60 seconds for most queries - Large infrastructures may need longer timeouts - Queries timeout if streaming metadata collection takes too long  (default: 60, e.g. 30)
  --cardinality: int # Maximum number of nodes to include in the response to prevent overwhelming large responses. When this limit is exceeded, the response will indicate how many nodes were omitted.  **Purpose:** - Prevent memory exhaustion from very large infrastructures - Control response size for performance - Useful when exploring large node hierarchies incrementally  **Recommendations:** - Small infrastructures (< 50 nodes): Use default or increase - Medium infrastructures (50-500 nodes): 200-500 - Large infrastructures (> 500 nodes): Use filtering or increase limit carefully  (default: 1000, e.g. 500)
]: nothing -> record<nodes: table<hostname: string, machine_guid: string, parent: string, parent_guid: string, streaming_status: string, path: list>, omitted: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/stream_path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Netdata agent version information across nodes
#
# GET /api/v3/versions
# operationId: versions3
export def "versions versions3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Simple pattern to match node hostnames for scope filtering. Uses Netdata's simple pattern matching (not regex). Matched nodes define the scope for version information retrieval.  **Pattern Syntax:** - `*` matches any number of characters - Use `|` to separate multiple patterns (OR logic) - Matches are case-insensitive - No regex support - only simple wildcards  **Examples:** - `prod-*` - All production nodes - `*-db-*` - All database nodes - `web-*|app-*` - All web or application nodes - `*` - All nodes (default)  (default: *, e.g. prod-*)
  --nodes: string # Simple pattern to filter which nodes to include in the version information response. After scope is determined, this filters the results. Uses the same pattern syntax as scope_nodes.  **Difference from scope_nodes:** - `scope_nodes` defines what nodes to analyze - `nodes` filters which nodes appear in the output  **Examples:** - `old-*` - Only show nodes matching "old-*" pattern - Specific hostnames: `node1|node2|node3`  (default: *, e.g. *)
  --options: string # Comma-separated list of options to control response content and format.  **Available Options:** - `minify` - Minimize JSON output (no pretty-printing) - `debug` - Include additional debug information - `raw` - Include raw version metadata  **Examples:** - `minify` - Compact JSON response - `debug,raw` - Debug mode with raw metadata  (e.g. debug)
  --timeout: int # Maximum time in seconds to wait for the query to complete before timing out.  **Guidelines:** - Recommended: 10-30 seconds for most queries - Version information is usually quick to retrieve - Timeout mainly applies to very large infrastructures  (default: 60, e.g. 10)
  --cardinality: int # Maximum number of nodes to include in the response to prevent overwhelming large responses. When this limit is exceeded, the response will indicate how many nodes were omitted.  **Purpose:** - Prevent memory exhaustion from very large infrastructures - Control response size for performance - Useful when exploring large node sets incrementally  **Recommendations:** - Small infrastructures (< 100 nodes): Use default - Medium infrastructures (100-1000 nodes): 500-1000 - Large infrastructures (> 1000 nodes): Use filtering or increase limit carefully  (default: 1000, e.g. 500)
]: nothing -> record<versions: table<hostname: string, machine_guid: string, version: string, build_info: string, commit_hash: string, protocol_version: int, features: list>, omitted: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Track progress of long-running function executions
#
# GET /api/v3/progress
# operationId: progress3
export def "progress progress3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: string # Transaction ID (UUID) of the function execution to track. This ID is returned when initiating a function execution via `/api/v3/function` or similar endpoints.  **UUID Format:** - Standard UUID v4 format - Example: `550e8400-e29b-41d4-a716-446655440000` - Case-insensitive  **Transaction Lifecycle:** - **Created**: When function execution starts - **Active**: While function is running - **Expired**: After completion, failure, or timeout - **Retention**: Transaction state kept briefly after completion for final status retrieval  **Invalid Transaction Handling:** - Missing transaction: Returns 400 Bad Request - Malformed UUID: Returns 400 Bad Request - Expired transaction: Returns 404 Not Found - Unknown transaction: Returns 404 Not Found  (format: uuid, e.g. 550e8400-e29b-41d4-a716-446655440000)
]: nothing -> record<transaction: string, status: string, percentage: int, message: string, done: int, all: int, eta_seconds: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transaction" $transaction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute a Netdata function on a specific node
#
# GET /api/v3/function
# operationId: function3
export def "function function3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --function: string # Name of the function to execute. Each Netdata plugin can provide multiple functions with different capabilities.  **Function Names:** - Kebab-case naming: `function-name-here` - Provided by plugins: different plugins provide different functions - Discoverable via `/api/v3/functions` endpoint - Case-sensitive  **Common Built-in Functions:** - `systemd-list-units` - List systemd services - `processes` - Running processes with CPU/memory usage - `network-connections` - Active network connections and sockets - `mount-points` - Mounted filesystems and usage - `ipmi-sensors` - IPMI hardware sensors (if available)  **Plugin-Specific Functions:** - Docker plugin: `docker-containers`, `docker-images` - Apps plugin: `apps-processes` - Logs plugin: `logs-query` - And many more depending on enabled plugins  **Invalid Function Names:** - Missing function: Returns 400 Bad Request - Unknown function: Returns 404 Not Found or function-specific error - Disabled function: Returns 403 Forbidden  (e.g. processes)
  --timeout: int # Maximum time in seconds to wait for function execution before timing out. Different functions have different execution times.  **Timeout Guidelines by Function Type:** - **Fast queries** (< 1s): processes, mount-points   Recommended: 10-30 seconds - **Medium queries** (1-5s): systemd-list-units, network-connections   Recommended: 30-60 seconds - **Slow operations** (5-30s): docker operations, log queries   Recommended: 60-300 seconds  **Timeout Behavior:** - If execution completes before timeout: Returns results immediately - If timeout expires: Function is cancelled and error returned - For async functions: Returns transaction ID immediately, timeout applies to overall operation  **Best Practices:** - Set conservative timeouts for production systems - Consider network latency for remote nodes - Monitor timeout errors and adjust accordingly  (default: 60, e.g. 30)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "function" $function "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/function" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute a Netdata function with request body parameters
#
# POST /api/v3/function
# operationId: function3_post
export def "function post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --function: string # Name of the function to execute (see GET method for details) (e.g. processes)
  --timeout: int # Maximum time in seconds to wait for function execution (see GET method for details) (default: 60, e.g. 30)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "function" $function "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/function" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List available functions across all nodes
#
# GET /api/v3/functions
# operationId: functions3
export def "functions functions3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # Simple pattern to match node hostnames for scope filtering. Uses Netdata's simple pattern matching (not regex). Matched nodes define the scope for function discovery.  **Pattern Syntax:** - `*` matches any number of characters - Use `|` to separate multiple patterns (OR logic) - Matches are case-insensitive - No regex support - only simple wildcards  **Examples:** - `prod-*` - All production nodes - `*-web-*` - All web server nodes - `db-*|cache-*` - All database or cache nodes - `*` - All nodes (default)  (default: *, e.g. prod-*)
  --nodes: string # Simple pattern to filter which nodes to include in the functions list. After scope is determined, this filters the results. Uses the same pattern syntax as scope_nodes.  **Difference from scope_nodes:** - `scope_nodes` defines what nodes to query for functions - `nodes` filters which nodes appear in the output  **Examples:** - `web-*` - Only show functions from web servers - Specific hostnames: `node1|node2|node3`  (default: *, e.g. *)
  --options: string # Comma-separated list of options to control response content and format.  **Available Options:** - `minify` - Minimize JSON output (no pretty-printing) - `debug` - Include detailed function metadata and plugin information - `raw` - Include raw function definitions  **Examples:** - `minify` - Compact JSON response - `debug,raw` - Full debug information  (e.g. debug)
  --timeout: int # Maximum time in seconds to wait for the query to complete before timing out.  **Guidelines:** - Recommended: 10-30 seconds for most queries - Function listing is usually fast - Timeout mainly applies to very large infrastructures  (default: 60, e.g. 10)
  --cardinality: int # Maximum number of nodes to include in the response to prevent overwhelming large responses. When this limit is exceeded, the response will indicate how many nodes were omitted.  **Purpose:** - Prevent memory exhaustion from very large infrastructures - Control response size for performance - Useful when exploring large node sets incrementally  **Recommendations:** - Small infrastructures (< 100 nodes): Use default - Medium infrastructures (100-1000 nodes): 500-1000 - Large infrastructures (> 1000 nodes): Use filtering or increase limit carefully  (default: 1000, e.g. 500)
]: nothing -> record<nodes: table<hostname: string, machine_guid: string, functions: list>, omitted: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality" $cardinality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manage Netdata dynamic configuration
#
# GET /api/v3/config
# operationId: config3
export def "config config3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # Configuration action to perform. Different actions require different additional parameters.  **Available Actions:**  - **`tree`** (default): Browse configuration hierarchy   - Additional params: `path` (optional, default "/"), `id` (optional)   - Returns: Tree structure of configurable components  - **`get`**: Retrieve current configuration   - Required params: `id`   - Returns: Current active configuration  - **`schema`**: Get configuration schema/template   - Required params: `id`   - Returns: Schema defining valid configuration structure  - **`update`**: Modify existing configuration   - Required params: `id`   - Request body: JSON with configuration changes   - Returns: Success/error status  - **`add`**: Create new job/instance   - Required params: `id`, `name`   - Request body: JSON with initial configuration   - Returns: Success/error status  - **`remove`**: Delete job/instance   - Required params: `id`   - Returns: Success/error status  - **`enable`**: Activate disabled component   - Required params: `id`   - Returns: Success/error status  - **`disable`**: Deactivate component without removing   - Required params: `id`   - Returns: Success/error status  - **`test`**: Validate configuration without applying   - Required params: `id`, `name`   - Request body: JSON with configuration to test   - Returns: Validation results  - **`restart`**: Restart component with new configuration   - Required params: `id`   - Returns: Success/error status  - **`userconfig`**: Get user-editable configuration file   - Required params: `id`   - Returns: Configuration in user-editable format  (default: tree, e.g. tree)
  --path: string # Path in configuration tree when using `action=tree`. Specifies which branch of the configuration hierarchy to explore.  **Path Format:** - Root: `/` - Collectors: `/collectors` - Specific plugin: `/collectors/go.d` - Health: `/health`  **Examples:** - `/` - Root level (all categories) - `/collectors` - All collectors - `/collectors/go.d` - Go collectors  (default: /, e.g. /collectors)
  --id: string # Configuration component ID using colon-separated hierarchical notation. Required for most actions except `tree`.  **ID Format:** `category:plugin:collector[:job-name]`  **Examples:** - `collectors:go.d:prometheus` - Prometheus collector - `collectors:go.d:prometheus:local` - Specific Prometheus job "local" - `collectors:python.d:nginx` - Nginx Python collector - `health:notifications` - Health notification settings  **ID Validation:** - Alphanumeric characters, dots, underscores, hyphens - Colons separate hierarchy levels - Invalid IDs return 400 Bad Request  (e.g. collectors:go.d:prometheus)
  --name: string # Name for new job/instance when using `action=add` or `action=test`.  **Name Requirements:** - Alphanumeric characters, dots, underscores, hyphens - Must be unique within the collector/plugin - Will be appended to `id` to form full configuration path  **Examples:** - If `id=collectors:go.d:prometheus` and `name=my-app` - Full config ID becomes: `collectors:go.d:prometheus:my-app`  **Invalid Names:** - Empty or missing (when required): Returns 400 Bad Request - Special characters: Returns 400 Bad Request - Duplicate name: May return error or override behavior depends on action  (e.g. my-app)
  --timeout: int # Maximum time in seconds to wait for configuration operation to complete.  **Timeout Guidelines:** - Read operations (get, schema, tree): 10-30 seconds - Write operations (update, add, remove): 30-120 seconds - Test operations: 60-120 seconds (may involve validation checks) - Restart operations: 120-300 seconds (component restart time)  **Minimum:** 10 seconds (enforced by code) **Default:** 120 seconds  (default: 120, e.g. 60)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manage Netdata configuration with request body data
#
# POST /api/v3/config
# operationId: config3_post
export def "config post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # Configuration action to perform (see GET method for details) (default: tree, e.g. update)
  --path: string # Path in configuration tree (see GET method for details) (default: /, e.g. /collectors)
  --id: string # Configuration component ID (see GET method for details) (e.g. collectors:go.d:prometheus)
  --name: string # Name for new job/instance (see GET method for details) (e.g. my-app)
  --timeout: int # Maximum timeout in seconds (see GET method for details) (default: 120, e.g. 60)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/config" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve user settings/preferences (GET)
#
# GET /api/v3/settings
# operationId: settings_get
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # Name of the settings file to retrieve.  **File Naming Rules:** - Alphanumeric characters only - Dashes (-) and underscores (_) allowed - No spaces or special characters - Case-sensitive  **Access Control:** - **Anonymous users**: Only `file=default` allowed - **Authenticated users (bearer token)**: Any valid file name  **Examples:** - `default` - Default settings file - `my-dashboard` - Custom dashboard settings - `prod-alerts` - Production alert preferences - `mobile-view` - Mobile UI settings  **Invalid File Names:** - Missing or empty: Returns 400 Bad Request - Special characters: Returns 400 Bad Request - Non-default for anonymous: Returns 400 Bad Request  (default: default, e.g. default)
]: nothing -> record<version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update user settings/preferences (PUT)
#
# PUT /api/v3/settings
# operationId: settings_put
export def "settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # Name of the settings file to create or update.  **File Naming Rules:** - Alphanumeric characters only - Dashes (-) and underscores (_) allowed - No spaces or special characters - Case-sensitive  **Access Control:** - **Anonymous users**: Only `file=default` allowed - **Authenticated users (bearer token)**: Any valid file name  **File Creation:** - If file doesn't exist: Created with initial payload - If file exists: Updated with new payload (version check applies)  (default: default, e.g. my-dashboard)
  version: int # Current version from GET request
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/settings" $qp)
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get streaming information and statistics
#
# GET /api/v3/stream_info
# operationId: stream_info
export def "stream-info info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --machine-guid: string # Machine GUID (unique node identifier) to query streaming information for. If not specified, returns streaming information for the local agent.  **GUID Format:** - UUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` - Case-insensitive - Can be obtained from `/api/v3/nodes` endpoint  **Use Cases:** - Query specific child node's streaming status - Check parent node's connection to specific child - Diagnostic queries for particular node  **Examples:** - `12345678-1234-1234-1234-123456789012` - Specific node - Empty/omitted - Local agent (default)  **Invalid GUIDs:** - Malformed UUID: May return error or empty result - Non-existent GUID: Returns empty or not-found response  (format: uuid, e.g. 12345678-1234-1234-1234-123456789012)
]: nothing -> record<machine_guid: string, hostname: string, streaming_mode: string, sender: record<connected: bool, parent_hostname: string, uptime_seconds: int, reconnects: int, bytes_sent: int, bytes_compressed: int, compression_ratio: float, buffer_used_bytes: int, buffer_max_bytes: int, buffer_used_percentage: float, drops: int>, receiver: record<children: list<record>>, protocol_version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "machine_guid" $machine_guid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/stream_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Establish WebRTC peer connection by exchanging SDP offer/answer
#
# POST /api/v3/rtc_offer
# operationId: rtcOffer3
export def "rtc-offer rtcOffer3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<sdp: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/rtc_offer")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Claim agent to Netdata Cloud
#
# GET /api/v3/claim
# operationId: claim3
export def "claim claim3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # **Verification key (UUID) obtained from the server's file system.**  This is a randomly generated session ID that proves the requester has access to the server. To obtain this key: 1. Call the endpoint without parameters to get the OS-specific command 2. Run the command on the server (requires sudo/admin access) 3. Copy the UUID from the file content 4. Use it in the claim request  **Security Notes:** - Key is randomly generated on each info request - Key is regenerated after each claim attempt (prevents reuse) - Mismatched key triggers new key generation (prevents brute force) - Validates server ownership through file system access  **When to Include:** - Omit when requesting claiming info/status - Include when submitting actual claim request  Example: `12345678-1234-1234-1234-123456789abc`  (format: uuid)
  --qp-token: string # **Claiming token from Netdata Cloud.**  This token authorizes the agent to connect to a specific Netdata Cloud space. Obtained from Netdata Cloud UI: Space settings → Nodes tab → Add Nodes → Copy claim token  **Validation:** - Must contain only alphanumeric characters, dots, commas, dashes, colons, slashes, underscores - Required when key parameter is provided - Invalid token triggers error and key regeneration  **Token Characteristics:** - Space-specific (each cloud space has different tokens) - Can be regenerated in cloud UI if compromised - Does not expire (remains valid until regenerated)  Example: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
  --qp-url: string # **Netdata Cloud API base URL.**  The endpoint URL for Netdata Cloud API where the agent will connect.  **Standard Values:** - Production: `https://api.netdata.cloud` - Staging/Testing: `https://api-staging.netdata.cloud` (if applicable)  **Validation:** - Must contain only alphanumeric characters, dots, commas, dashes, colons, slashes, underscores - Required when key parameter is provided - Should be valid HTTPS URL pointing to Netdata Cloud API  **Important Notes:** - Use the URL provided in Netdata Cloud UI claim instructions - Different cloud regions may have different URLs - Invalid URL prevents successful claiming  Example: `https://api.netdata.cloud`  (format: uri)
  --rooms: string # **Comma-separated list of war room IDs to add the agent to.**  War rooms are organizational units within a Netdata Cloud space for grouping related nodes.  **Format:** - Comma-separated room IDs (no spaces) - Each room ID validated for safe characters - Optional parameter (agent claimed to space without specific rooms if omitted)  **Validation:** - Must contain only alphanumeric characters, dots, commas, dashes, colons, slashes, underscores - Invalid format triggers error and key regeneration  **Room IDs:** - Obtained from Netdata Cloud UI (room settings) - Room must exist in the target space - Agent added to all specified rooms after claiming - Can be modified later in cloud UI  **Use Cases:** - Add agent to production monitoring room - Organize by environment (dev, staging, prod) - Group by application or service type  Example: `room-1234-5678-90ab,room-cdef-0123-4567`
]: nothing -> record<success: bool, message: string, cloud_status: string, can_be_claimed: bool, key_filename: string, cmd: string, help: string, agents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "rooms" $rooms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable or disable bearer token authentication requirement
#
# GET /api/v3/bearer_protection
# operationId: bearerProtection3
export def "bearer-protection bearerProtection3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bearer-protection: string@bearer-protection-completer # **Whether to enable or disable bearer token authentication requirement.**  **Valid Values:** - Enable: `on`, `true`, `yes` - Disable: `off`, `false`, `no`  **Default Behavior:** - If omitted, maintains current bearer protection state - When agent is unclaimed, defaults to disabled - When agent is claimed, typically enabled by Netdata Cloud  **Effect:** - When enabled: All API requests must include valid bearer token in Authorization header - When disabled: API requests work without bearer tokens (less secure)  Example: `bearer_protection=on`
  --claim-id: string # **Claim ID of the agent from Netdata Cloud.**  This identifies which Netdata Cloud space the agent is claimed to. Used to verify the request is for the correct agent.  **Validation:** - Must match the agent's current claim ID - Request fails with HTTP 400 if claim ID doesn't match - Prevents accidentally enabling protection on wrong agent  **Where to Find:** - Obtained from cloud when agent is claimed - Available in agent's claiming configuration - Included in cloud API responses  Example: `claim_id=1234567890abcdef`
  --machine-guid: string # **Machine GUID of the agent.**  Hardware-based unique identifier for the agent instance. Generated based on machine characteristics.  **Purpose:** - Verifies request is for the specific agent instance - Prevents applying protection to wrong node - Part of multi-factor agent identification  **Characteristics:** - Persists across agent restarts - May change if hardware changes significantly - Matches the `machine_guid` in agent info  **Where to Find:** - Available in `/api/v3/info` response - Stored in agent's state files - Shown in Netdata Cloud node details  Example: `machine_guid=12345678-1234-1234-1234-123456789abc`
  --node-id: string # **Node UUID of the agent.**  Persistent unique identifier for the agent. More stable than machine_guid.  **Purpose:** - Provides additional verification layer - Ensures request targets correct node - Used alongside claim_id and machine_guid for security  **Characteristics:** - Generated once and persists - Does not change with hardware changes - Unique across all Netdata installations  **Where to Find:** - Available in `/api/v3/info` response - Stored in agent's persistent state - Used by Netdata Cloud for node identification  Example: `node_id=23456789-2345-2345-2345-234567890abc`  (format: uuid)
]: nothing -> record<bearer_protection: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bearer_protection" $bearer_protection "scalar") (serialize-qp "claim_id" $claim_id "scalar") (serialize-qp "machine_guid" $machine_guid "scalar") (serialize-qp "node_id" $node_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/bearer_protection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain bearer authentication token
#
# GET /api/v3/bearer_get_token
# operationId: bearerGetToken3
export def "bearer-get-token bearerGetToken3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --claim-id: string # **Claim ID of the agent from Netdata Cloud.**  Identifies which Netdata Cloud space the agent belongs to. Used to verify the token request is for the correct agent.  **Validation:** - Must match the agent's current claim ID - Request fails with HTTP 400 if claim ID doesn't match - Can use `claim_id_matches_any()` for multi-agent parents  **Security:** - Prevents token generation for wrong agent - Ensures cloud can only get tokens for agents it manages - Part of multi-factor agent verification  Example: `claim_id=1234567890abcdef`
  --machine-guid: string # **Machine GUID of the target agent.**  Hardware-based unique identifier for the agent instance.  **Purpose:** - Verifies request is for the specific agent instance - Prevents token generation for wrong node - Must match exactly or request fails  **Where to Find:** - Available in `/api/v3/info` response - Included in cloud agent registration - Stored in agent state files  **Validation:** - Compared against host->machine_guid - Both claim_id and machine_guid must match - node_id also verified for triple authentication  Example: `machine_guid=12345678-1234-1234-1234-123456789abc`
  --node-id: string # **Node UUID of the target agent.**  Persistent unique identifier for the agent node.  **Purpose:** - Additional verification layer beyond machine_guid - Ensures correct node identification - Used in combination with other identifiers  **Characteristics:** - More stable than machine_guid - Persists across hardware changes - Unique across all Netdata installations  **Validation:** - Must be non-zero UUID - Must match host->node_id exactly - Compared in lowercase format  Example: `node_id=23456789-2345-2345-2345-234567890abc`  (format: uuid)
]: nothing -> record<status: int, mg: string, bearer_protection: bool, token: string, expiration: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "claim_id" $claim_id "scalar") (serialize-qp "machine_guid" $machine_guid "scalar") (serialize-qp "node_id" $node_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/bearer_get_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current authenticated user information
#
# GET /api/v3/me
# operationId: me3
export def "me me3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth: string, cloud_account_id: string, client_name: string, access: list<string>, user_role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Score or weight all or some of the metrics, across all nodes, according to various algorithms.
#
# GET /api/v2/weights
# DEPRECATED
# operationId: weights2
@deprecated
export def "weights weights2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # The weighting / scoring algorithm.
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-instances: string # A simple pattern limiting the instances scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-labels: string # A simple pattern limiting the labels scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query based on their labels. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by scope nodes, scope contexts, and scope instances). Only instances having labels that match this pattern will be included in the query. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-dimensions: string # A simple pattern limiting the dimensions scope of the query. The scope controls both data and metadata response. This limits which dimensions are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against both the dimension `id` and `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --instances: string # A simple pattern matching the instances to be queried. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --labels: string # A simple pattern matching the labels to be queried. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by all the above: scope nodes, scope contexts, nodes, contexts and instances). Negative simple patterns should not be used in this filter.  (format: simple pattern, default: *)
  --alerts: string # A simple pattern matching the alerts to be queried. The simple pattern is checked against the `name` of alerts and the combination of `name:status`, when status is one of `CLEAR`, `WARNING`, `CRITICAL`, `REMOVED`, `UNDEFINED`, `UNINITIALIZED`, of all the alerts of all the eligible instances (as filtered by all the above). A negative simple pattern will exclude the instances having the labels matched.  (format: simple pattern, default: *)
  --dimensions: string # A simple patterns matching the dimensions to be queried. The simple pattern is checked against and `id` and the `name` of the dimensions of the eligible instances (as filtered by all the above). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --baseline-after: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_after` can be a negative number of seconds, up to 3 years (-94608000), relative to `baseline_before`. If not set, it is usually assumed to be -300.  (default: -600)
  --baseline-before: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `baseline_before` is positive, it is assumed to be a unix epoch timestamp.  (default: 0)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --time-group: string@time-group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --time-group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "scope_instances" $scope_instances "scalar") (serialize-qp "scope_labels" $scope_labels "scalar") (serialize-qp "scope_dimensions" $scope_dimensions "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "instances" $instances "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "alerts" $alerts "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "baseline_after" $baseline_after "scalar") (serialize-qp "baseline_before" $baseline_before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "options" $options "multi") (serialize-qp "time_group" $time_group "scalar") (serialize-qp "time_group_options" $time_group_options "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/weights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get current alert status across all nodes (use /api/v3/alerts instead)
#
# GET /api/v2/alerts
# DEPRECATED
# operationId: alerts2
@deprecated
export def "alerts alerts2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --status: string # Filter alerts by status (e.g., CRITICAL, WARNING, CLEAR)
  --alert: string # Filter by alert name pattern
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "alert" $alert "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get alert state transition history (use /api/v3/alert_transitions instead)
#
# GET /api/v2/alert_transitions
# DEPRECATED
# operationId: alertTransitions2
@deprecated
export def "alert-transitions alertTransitions2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --alert: string # Filter by alert name
  --transition: string # Filter by transition type
  --last: int # Return only the last N transitions
  --anchor-gi: int # Global ID anchor for pagination (format: int64)
  --f-status: string # Facet filter for alert status
  --f-type: string # Facet filter for alert type
  --f-role: string # Facet filter for recipient role
  --f-class: string # Facet filter for alert class
  --f-component: string # Facet filter for alert component
  --f-node: string # Facet filter for node
  --f-alert: string # Facet filter for alert name
  --f-instance: string # Facet filter for chart/instance name
  --f-context: string # Facet filter for context
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "alert" $alert "scalar") (serialize-qp "transition" $transition "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "anchor_gi" $anchor_gi "scalar") (serialize-qp "f_status" $f_status "scalar") (serialize-qp "f_type" $f_type "scalar") (serialize-qp "f_role" $f_role "scalar") (serialize-qp "f_class" $f_class "scalar") (serialize-qp "f_component" $f_component "scalar") (serialize-qp "f_node" $f_node "scalar") (serialize-qp "f_alert" $f_alert "scalar") (serialize-qp "f_instance" $f_instance "scalar") (serialize-qp "f_context" $f_context "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/alert_transitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get alert configuration by hash ID (use /api/v3/alert_config instead)
#
# GET /api/v2/alert_config
# DEPRECATED
# operationId: alertConfig2
@deprecated
export def "alert-config alertConfig2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: string # Alert configuration hash ID (UUID) (format: uuid)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config" $config "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/alert_config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get agent information (use /api/v3/info instead)
#
# GET /api/v2/info
# DEPRECATED
# operationId: info2
@deprecated
export def "info info2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get node instances hierarchy (use /api/v3/node_instances instead)
#
# GET /api/v2/node_instances
# DEPRECATED
# operationId: nodeInstances2
@deprecated
export def "node-instances nodeInstances2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/node_instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get agent version information (use /api/v3/versions instead)
#
# GET /api/v2/versions
# DEPRECATED
# operationId: versions2
@deprecated
export def "versions versions2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Track async operation progress (use /api/v3/progress instead)
#
# GET /api/v2/progress
# DEPRECATED
# operationId: progress2
@deprecated
export def "progress progress2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: string # Transaction UUID from async operation (format: uuid)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transaction" $transaction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: List available functions (use /api/v3/functions instead)
#
# GET /api/v2/functions
# DEPRECATED
# operationId: functions2
@deprecated
export def "functions functions2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "options" $options "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Establish WebRTC connection (use /api/v3/rtc_offer instead)
#
# POST /api/v2/rtc_offer
# DEPRECATED
# operationId: rtcOffer2
@deprecated
export def "rtc-offer rtcOffer2" [
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
  let full_url = (build-url $base "/api/v2/rtc_offer")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# OBSOLETE: Claim agent to Netdata Cloud (use /api/v3/claim instead)
#
# GET /api/v2/claim
# DEPRECATED
# operationId: claim2
@deprecated
export def "claim claim2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Verification key obtained from server file system (format: uuid)
  --qp-token: string # Claiming token from Netdata Cloud
  --qp-url: string # Netdata Cloud API base URL (format: uri)
  --rooms: string # Comma-separated war room IDs
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "rooms" $rooms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Enable/disable bearer authentication (use /api/v3/bearer_protection instead)
#
# GET /api/v2/bearer_protection
# DEPRECATED
# operationId: bearerProtection2
@deprecated
export def "bearer-protection bearerProtection2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bearer-protection: string@bearer-protection-completer # Enable or disable bearer protection
  --claim-id: string # Agent's claim ID
  --machine-guid: string # Agent's machine GUID
  --node-id: string # Agent's node UUID (format: uuid)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bearer_protection" $bearer_protection "scalar") (serialize-qp "claim_id" $claim_id "scalar") (serialize-qp "machine_guid" $machine_guid "scalar") (serialize-qp "node_id" $node_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/bearer_protection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OBSOLETE: Get bearer authentication token (use /api/v3/bearer_get_token instead)
#
# GET /api/v2/bearer_get_token
# DEPRECATED
# operationId: bearerGetToken2
@deprecated
export def "bearer-get-token bearerGetToken2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --claim-id: string # Agent's claim ID
  --machine-guid: string # Agent's machine GUID
  --node-id: string # Agent's node UUID (format: uuid)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "claim_id" $claim_id "scalar") (serialize-qp "machine_guid" $machine_guid "scalar") (serialize-qp "node_id" $node_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/bearer_get_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Score or weight all or some of the metrics, across all nodes, according to various algorithms.
#
# GET /api/v3/weights
# operationId: weights3
export def "weights weights3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # The weighting / scoring algorithm.
  --scope-nodes: string # A simple pattern limiting the nodes scope of the query. The scope controls both data and metadata response. The simple pattern is checked against the nodes' machine guid, node id and hostname. The default nodes scope is all nodes for which this Agent has data for. Usually the nodes scope is used to slice the entire dashboard (e.g. the Global Nodes Selector at the Netdata Cloud overview dashboard). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-contexts: string # A simple pattern limiting the contexts scope of the query. The scope controls both data and metadata response. The default contexts scope is all contexts for which this Agent has data for. Usually the contexts scope is used to slice data on the dashboard (e.g. each context based chart has its own contexts scope, limiting the chart to all the instances of the selected context). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-instances: string # A simple pattern limiting the instances scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-labels: string # A simple pattern limiting the labels scope of the query. The scope controls both data and metadata response. This limits which instances are even considered for the query based on their labels. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by scope nodes, scope contexts, and scope instances). Only instances having labels that match this pattern will be included in the query. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --scope-dimensions: string # A simple pattern limiting the dimensions scope of the query. The scope controls both data and metadata response. This limits which dimensions are even considered for the query, including their visibility in the query response metadata. The simple pattern is checked against both the dimension `id` and `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --nodes: string # A simple pattern matching the nodes to be queried. This only controls the data response, not the metadata. The simple pattern is checked against the nodes' machine guid, node id, hostname. The default nodes selector is all the nodes matched by the nodes scope. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --contexts: string # A simple pattern matching the contexts to be queried. This only controls the data response, not the metadata. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --instances: string # A simple pattern matching the instances to be queried. The simple pattern is checked against the instance `id`, the instance `name`, the fully qualified name of the instance `id` and `name`, like `instance@machine_guid`, where `instance` is either its `id` or `name`. Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --labels: string # A simple pattern matching the labels to be queried. The simple pattern is checked against `name:value` of all the labels of all the eligible instances (as filtered by all the above: scope nodes, scope contexts, nodes, contexts and instances). Negative simple patterns should not be used in this filter.  (format: simple pattern, default: *)
  --alerts: string # A simple pattern matching the alerts to be queried. The simple pattern is checked against the `name` of alerts and the combination of `name:status`, when status is one of `CLEAR`, `WARNING`, `CRITICAL`, `REMOVED`, `UNDEFINED`, `UNINITIALIZED`, of all the alerts of all the eligible instances (as filtered by all the above). A negative simple pattern will exclude the instances having the labels matched.  (format: simple pattern, default: *)
  --dimensions: string # A simple patterns matching the dimensions to be queried. The simple pattern is checked against and `id` and the `name` of the dimensions of the eligible instances (as filtered by all the above). Both positive and negative simple pattern expressions are supported.  (format: simple pattern, default: *)
  --baseline-after: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_after` can be a negative number of seconds, up to 3 years (-94608000), relative to `baseline_before`. If not set, it is usually assumed to be -300.  (default: -600)
  --baseline-before: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `baseline_before` is positive, it is assumed to be a unix epoch timestamp.  (default: 0)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --time-group: string@time-group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --time-group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
  --cardinality-limit: int # Limits the number of unique items (contexts, instances, dimensions) returned in the query result. This is useful for preventing excessive memory usage and response sizes when queries match a large number of metrics. The query engine will return the most relevant items up to this limit.  (format: int64, default: 10000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "scope_nodes" $scope_nodes "scalar") (serialize-qp "scope_contexts" $scope_contexts "scalar") (serialize-qp "scope_instances" $scope_instances "scalar") (serialize-qp "scope_labels" $scope_labels "scalar") (serialize-qp "scope_dimensions" $scope_dimensions "scalar") (serialize-qp "nodes" $nodes "scalar") (serialize-qp "contexts" $contexts "scalar") (serialize-qp "instances" $instances "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "alerts" $alerts "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "baseline_after" $baseline_after "scalar") (serialize-qp "baseline_before" $baseline_before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "options" $options "multi") (serialize-qp "time_group" $time_group "scalar") (serialize-qp "time_group_options" $time_group_options "scalar") (serialize-qp "cardinality_limit" $cardinality_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/weights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Score or weight all or some of the metrics of a single node, according to various algorithms.
#
# GET /api/v1/weights
# DEPRECATED
# operationId: weights1
@deprecated
export def "weights weights1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # The weighting / scoring algorithm.
  --context: string # The context of the chart as returned by the /charts call. (format: as returned by /charts)
  --baseline-after: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_after` can be a negative number of seconds, up to 3 years (-94608000), relative to `baseline_before`. If not set, it is usually assumed to be -300.  (default: -600)
  --baseline-before: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `baseline_before` is positive, it is assumed to be a unix epoch timestamp.  (default: 0)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --group: string@group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
]: nothing -> record<after: int, before: int, duration: int, points: int, baseline_after: int, baseline_before: int, baseline_duration: int, baseline_points: int, group: string, method: string, options: string, correlated_dimensions: any, total_dimensions_count: int, statistics: record<query_time_ms: float, db_queries: int, db_points_read: int, query_result_points: int, binary_searches: int>, contexts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "baseline_after" $baseline_after "scalar") (serialize-qp "baseline_before" $baseline_before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "options" $options "multi") (serialize-qp "group" $group "scalar") (serialize-qp "group_options" $group_options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/weights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Analyze all the metrics to find their correlations - EOL
#
# GET /api/v1/metric_correlations
# DEPRECATED
# operationId: metricCorrelations1
@deprecated
export def "metric-correlations metricCorrelations1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # The weighting / scoring algorithm.
  --baseline-after: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_after` can be a negative number of seconds, up to 3 years (-94608000), relative to `baseline_before`. If not set, it is usually assumed to be -300.  (default: -600)
  --baseline-before: int # `baseline_after` and `baseline_before` define the baseline time-frame of a comparative query. `baseline_before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `baseline_before` is positive, it is assumed to be a unix epoch timestamp.  (default: 0)
  --after: int # `after` and `before` define the time-frame of a query. `after` can be a negative number of seconds, up to 3 years (-94608000), relative to `before`. If not set, it is usually assumed to be -600. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: -600)
  --before: int # `after` and `before` define the time-frame of a query. `before` can be a negative number of seconds, up to 3 years (-94608000), relative to current clock. If not set, it is assumed to be the current clock time. When `before` is positive, it is assumed to be a unix epoch timestamp. When non-data endpoints support the `after` and `before`, they use the time-frame to limit their response for objects having data retention within the time-frame given.  (default: 0)
  --points: float # The number of points to be returned. If not given, or it is <= 0, or it is bigger than the points stored in the database for the given duration, all the available collected values for the given duration will be returned. For `weights` endpoints that do statistical analysis, the `points` define the detail of this analysis (the default is 500).  (format: integer, default: 0)
  --tier: float # Use only the given dbengine tier for executing the query. Setting this parameters automatically sets the option `selected-tier` for the query.  (format: integer)
  --timeout: float # Specify a timeout value in milliseconds after which the Agent will abort the query and return a 503 error. A value of 0 indicates no timeout.  (format: integer, default: 0)
  --options: list # Options that affect data generation. * `jsonwrap` - Wrap the output in a JSON object with metadata about the query. * `raw` - change the output so that it is aggregatable across multiple such queries. Supported by `/api/v2` data queries and `json2` format. * `minify` - Remove unnecessary spaces and newlines from the output. * `debug` - Provide additional information in `jsonwrap` output to help tracing issues. * `nonzero` - Do not return dimensions that all their values are zero, to improve the visual appearance of charts. They will still be returned if all the dimensions are entirely zero. * `null2zero` - Replace `null` values with `0`. * `absolute` or `abs` - Traditionally Netdata returns select dimensions negative to improve visual appearance. This option turns this feature off. * `display-absolute` - Only used by badges, to do color calculation using the signed value, but render the value without a sign. * `flip` or `reversed` - Order the timestamps array in reverse order (newest to oldest). * `min2max` - When flattening multi-dimensional data into a single metric format, use `max - min` instead of `sum`. This is EOL - use `/api/v2` to control aggregation across dimensions. * `percentage` - Convert all values into a percentage vs the row total. When enabled, Netdata will query all dimensions, even the ones that have not been selected or are hidden, to find the row total, in order to calculate the percentage of each dimension selected. * `seconds` - Output timestamps in seconds instead of dates. * `milliseconds` or `ms` - Output timestamps in milliseconds instead of dates. * `unaligned` - by default queries are aligned to the the view, so that as time passes past data returned do not change. When a data query will not be used for visualization, `unaligned` can be given to avoid aligning the query time-frame for visual precision. * `match-ids`, `match-names`. By default filters match both IDs and names when they are available. Setting either of the two options will disable the other. * `anomaly-bit` - query the anomaly information instead of metric values. This is EOL, use `/api/v2` and `json2` format which always returns this information and many more. * `jw-anomaly-rates` - return anomaly rates as a separate result set in the same `json` format response. This is EOL, use `/api/v2` and `json2` format which always returns information and many more.  * `details` - `/api/v2/data` returns in `jsonwrap` the full tree of dimensions that have been matched by the query. * `group-by-labels` - `/api/v2/data` returns in `jsonwrap` flattened labels per output dimension. These are used to identify the instances that have been aggregated into each dimension, making it possible to provide a map, like Netdata does for Kubernetes. * `natural-points` - return timestamps as found in the database. The result is again fixed-step, but the query engine attempts to align them with the timestamps found in the database. * `virtual-points` - return timestamps independent of the database alignment. This is needed aggregating data across multiple Netdata Agents, to ensure that their outputs do not need to be interpolated to be merged. * `selected-tier` - use data exclusively from the selected tier given with the `tier` parameter. This option is set automatically when the `tier` parameter is set. * `all-dimensions` - In `/api/v1` `jsonwrap` include metadata for all candidate metrics examined. In `/api/v2` this is standard behavior and no option is needed. * `label-quotes` - In `csv` output format, enclose each header label in quotes. * `objectrows` - Each row of value should be an object, not an array (only for `json` format). * `google_json` - Comply with google JSON/JSONP specs (only for `json` format). * `minimal-stats` or `minimal` - Reduce the amount of statistics returned in `jsonwrap` format to save bandwidth. * `long-json-keys` or `long-keys` - Use descriptive key names in JSON output instead of abbreviated ones. * `mcp-info` - Include additional metadata useful for the Model Context Protocol (MCP) integration. * `rfc3339` - Return timestamps in RFC3339 format (e.g., "2023-01-01T00:00:00Z") instead of Unix timestamps.  (default: [seconds, jsonwrap])
  --group: string@group-completer # Time aggregation function. If multiple collected values are to be grouped in order to return fewer points, this parameters defines the method of grouping. If the `absolute` option is set, the values are turned positive before applying this calculation.  (default: average)
  --group-options: string # When the time grouping function supports additional parameters, this field can be used to pass them to it. Currently `countif`, `trimmed-mean`, `trimmed-median` and `percentile` support this. For `countif` the string may start with `<`, `<=`, `<:`, `<>`, `!=`, `>`, `>=`, `>:`. For all others just a number is expected.
]: nothing -> record<after: int, before: int, duration: int, points: int, baseline_after: int, baseline_before: int, baseline_duration: int, baseline_points: int, group: string, method: string, options: string, correlated_dimensions: any, total_dimensions_count: int, statistics: record<query_time_ms: float, db_queries: int, db_points_read: int, query_result_points: int, binary_searches: int>, correlated_charts: record<chart_id1: record<context: string, dimensions: record>, chart_id2: record<context: string, dimensions: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "baseline_after" $baseline_after "scalar") (serialize-qp "baseline_before" $baseline_before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "points" $points "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "options" $options "multi") (serialize-qp "group" $group "scalar") (serialize-qp "group_options" $group_options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/metric_correlations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# |  **Security & Access Control:** - 📊 **Public Data API** - Bearer token optional, IP-based ACL restrictions apply - **Default Access:** Public (no authentication required) - **Bearer Protection:** When enabled via `/api/v3/bearer_protection`, requires bearer token - **IP Restrictions:** Subject to `allow dashboard from` in netdata.conf - **Access Methods:** Direct HTTP/HTTPS, Netdata Cloud, external tools
#
# GET /api/v1/function
# DEPRECATED
# operationId: function1
@deprecated
export def "function function1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --function: string # The name of the function, as returned by the collector.
  --timeout: float # Specify a timeout value in seconds after which the Agent will abort the query and return a 504 error. A value of 0 indicates no timeout, but some endpoints, like `weights`, do not accept infinite timeouts (they have a predefined default), so to disable the timeout it must be set to a really high value.  (format: integer, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "function" $function "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/function" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all registered collector functions.
#
# GET /api/v1/functions
# DEPRECATED
# operationId: functions1
@deprecated
export def "functions functions1" [
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
  let full_url = (build-url $base "/api/v1/functions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of active or raised alarms on the server
#
# GET /api/v1/alarms
# DEPRECATED
# operationId: alerts1
@deprecated
export def "alarms alerts1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If passed, all enabled alarms are returned. (allows empty value)
  --active: oneof<nothing, bool> # If passed, the raised alarms in state WARNING or CRITICAL are returned. (allows empty value)
]: nothing -> record<hostname: string, latest_alarm_log_unique_id: int, status: bool, now: int, alarms: record<chart_name_alarm_name: record<id: int, name: string, chart: string, family: string, active: bool, disabled: bool, silenced: bool, exec: string, recipient: string, source: string, units: string, info: string, status: string, last_status_change: int, last_updated: int, next_update: int, update_every: int, delay_up_duration: int, delay_down_duration: int, delay_max_duration: int, delay_multiplier: int, delay: int, delay_up_to_timestamp: int, value_string: string, no_clear_notification: bool, lookup_dimensions: string, db_after: int, db_before: int, lookup_method: string, lookup_after: int, lookup_before: int, lookup_options: string, calc: string, calc_parsed: string, warn: string, warn_parsed: string, crit: string, crit_parsed: string, warn_repeat_every: int, crit_repeat_every: int, green: string, red: string, value: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alarms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of active or raised alarms on the server
#
# GET /api/v1/alarms_values
# DEPRECATED
# operationId: alertValues1
@deprecated
export def "alarms-values alertValues1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If passed, all enabled alarms are returned. (allows empty value)
  --active: oneof<nothing, bool> # If passed, the raised alarms in state WARNING or CRITICAL are returned. (allows empty value)
]: nothing -> record<hostname: string, alarms: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alarms_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the entries of the alarm log
#
# GET /api/v1/alarm_log
# DEPRECATED
# operationId: alertsLog1
@deprecated
export def "alarm-log alertsLog1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: int # Passing the parameter after=UNIQUEID returns all the events in the alarm log that occurred after UNIQUEID. An automated series of calls would call the interface once without after=, store the last UNIQUEID of the returned set, and give it back to get incrementally the next events.
]: nothing -> table<hostname: string, unique_id: int, alarm_id: int, alarm_event_id: int, name: string, chart: string, family: string, processed: bool, updated: bool, exec_run: int, exec_failed: bool, exec: string, recipient: string, exec_code: int, source: string, units: string, when: int, duration: int, non_clear_duration: int, status: string, old_status: string, delay: int, delay_up_to_timestamp: int, updated_by_id: int, updates_id: int, value_string: string, old_value_string: string, silenced: string, info: string, value: float, old_value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alarm_log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an overall status of the chart
#
# GET /api/v1/alarm_count
# DEPRECATED
# operationId: alertsCount1
@deprecated
export def "alarm-count alertsCount1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # The context of the chart as returned by the /charts call. (format: as returned by /charts)
  --status: string@status-completer # Specify alarm status to count. (default: RAISED, allows empty value)
]: nothing -> list<float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context" $context "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alarm_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List variables available to configure alarms for a chart
#
# GET /api/v1/alarm_variables
# DEPRECATED
# operationId: getNodeAlertVariables1
@deprecated
export def "alarm-variables get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # The id of the chart as returned by the /charts call. (format: as returned by /charts, default: system.cpu)
]: nothing -> record<chart: string, chart_name: string, cnart_context: string, family: string, host: string, chart_variables: record, family_variables: record<varname1: float, varname2: float>, host_variables: record<varname1: float, varname2: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alarm_variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accesses the health management API to control health checks and notifications at runtime.
#
# GET /api/v1/manage/health
# DEPRECATED
# operationId: health1
@deprecated
export def "manage-health health1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer # DISABLE ALL: No alarm criteria are evaluated, nothing is written in the alarm log. SILENCE ALL: No notifications are sent. RESET: Return to the default state. DISABLE/SILENCE: Set the mode to be used for the alarms matching the criteria of the alarm selectors. LIST: Show active configuration.
  --alarm: string # The expression provided will match both `alarm` and `template` names.
  --chart: string # Chart ids/names, as shown on the dashboard. These will match the `on` entry of a configured `alarm`.
  --context: string # Chart context, as shown on the dashboard. These will match the `on` entry of a configured `template`.
  --hosts: string # The hostnames that will need to match.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "alarm" $alarm "scalar") (serialize-qp "chart" $chart "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "hosts" $hosts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/manage/health" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about current ACLK state
#
# GET /api/v1/aclk
# DEPRECATED
# operationId: aclk1
@deprecated
export def "aclk aclk1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aclk_available: string, aclk_version: int, protocols_supported: list<string>, Agent_claimed: bool, claimed_id: string, online: bool, used_cloud_protocol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/aclk")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Get a chart variable value
#
# GET /api/v1/variable
# DEPRECATED
# operationId: variable1
@deprecated
export def "variable variable1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chart: string # Chart ID for which to retrieve the variable. This is the full chart ID as shown in the dashboard.  **Examples:** - `system.cpu` - System CPU usage chart - `disk.sda.io` - Disk I/O for sda - `nginx_local.connections` - Nginx connections  (e.g. system.cpu)
  --variable: string # Variable name to retrieve. Each chart has different variables available depending on its configuration and alert definitions.  **Common Variables:** - `used` - Used value (for utilization charts) - `free` - Free value (for utilization charts) - `value` - Current value - `avg` - Average value - `sum` - Sum of all dimensions - Custom variable names defined in alert configurations  (e.g. used)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chart" $chart "scalar") (serialize-qp "variable" $variable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/variable" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Registry operations for tracking dashboard access
#
# GET /api/v1/registry
# DEPRECATED
# operationId: registry1
@deprecated
export def "registry registry1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # Registry action to perform.  **Available Actions:** - `hello` - Initial contact with registry - `access` - Record dashboard access to agent - `delete` - Remove agent URL from dashboard history - `search` - Find all agents accessed by dashboard - `switch` - Migrate dashboard identity to new person_guid  (e.g. access)
  --machine: string # Machine GUID of the dashboard making the request. This is typically stored in browser cookies and identifies the specific browser/client.  (format: uuid, e.g. 12345678-1234-1234-1234-123456789012)
  --name: string # Human-readable name for the dashboard/machine (typically hostname). Used for display purposes in registry listings.  (e.g. my-laptop)
  --qp-url: string # URL of the Netdata agent being accessed. This is the full URL including protocol and port.  (format: uri, e.g. http://netdata.example.com:19999)
  --delete-url: string # URL to delete from the registry (used with action=delete). Must match a previously registered URL.  (format: uri, e.g. http://old-server.example.com:19999)
  --qp-for: string # Machine GUID to search for (used with action=search). Returns all agents accessed by this machine.  (format: uuid, e.g. 12345678-1234-1234-1234-123456789012)
  --qp-to: string # New person_guid to switch to (used with action=switch). Migrates the dashboard identity to a new person_guid.  (format: uuid, e.g. 87654321-4321-4321-4321-210987654321)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "machine" $machine "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "delete_url" $delete_url "scalar") (serialize-qp "for" $qp_for "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/registry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Get DBEngine storage statistics
#
# GET /api/v1/dbengine_stats
# DEPRECATED
# operationId: dbengine_stats1
@deprecated
export def "dbengine-stats stats1" [
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
  let full_url = (build-url $base "/api/v1/dbengine_stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Get machine learning detection information
#
# GET /api/v1/ml_info
# DEPRECATED
# operationId: ml_info1
@deprecated
export def "ml-info info1" [
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
  let full_url = (build-url $base "/api/v1/ml_info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
