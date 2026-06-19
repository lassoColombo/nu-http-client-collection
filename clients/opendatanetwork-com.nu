# Auto-generated client for ODN API v1.0.0
# Source: https://api.apis.guru/v2/specs/opendatanetwork.com/1.0.0/openapi.json
# Auth: --token flag or $env.ODN_API_TOKEN

const BASE_URL = "http://api.opendatanetwork.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ODN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://api.opendatanetwork.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["google"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "data-availability find-list-available-for-some-entities" } } | get name | first)
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

# Find all available data for some entities
#
# GET /data/v1/availability/
# operationId: Find all available data for some entities
export def "data-availability find-list-available-for-some-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Comma separated list of entity IDs. (e.g. 0100000US,0400000US53)
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/v1/availability/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "app_token": $app_token} | compact), body: null}
}

# Get constraint permutations for entities
#
# GET /data/v1/constraint/{variable}
# operationId: Get constraint permutations for entities
export def "data-constraint get-permutations-for-entities" [
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Comma separated list of entity IDs. (e.g. 0100000US,0400000US53)
  --constraint: string # Constraint to use. (e.g. year)
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($variable | is-empty) { error make --unspanned { msg: "path parameter 'variable' must be non-empty" } }
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "constraint" $constraint "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({variable: (encode-path-segment $variable)} | format pattern "/data/v1/constraint/{variable}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "constraint": $constraint, "app_token": $app_token} | compact), body: null}
}

# Create a map
#
# GET /data/v1/map/new
# operationId: Create a map
export def "data-map-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --variable: string # A single variable ID. (e.g. demographics.population.count)
  --entity-id: string # A comma separated list of entity IDs. Entities must have the same type and represent geographical regions. (e.g. 0400000US53,0400000US08)
  --constraint: string # Values must be specified for each constraint in the dataset. For example, to generate map data for `demographics.population.count`, you must specify a value for `year` by passing `year=2013`.
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variable" $variable "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "constraint" $constraint "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/v1/map/new" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"variable": $variable, "entity_id": $entity_id, "constraint": $constraint, "app_token": $app_token} | compact), body: null}
}

# Get values for variables
#
# GET /data/v1/values
# operationId: Get values for variables
export def "data-values get-for-variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --variable: string # Comma separated list of variable IDs. Defaults to retrieving all variables. It is also possible to pass in a topic such as `demographics`, or a dataset such as `demographics.population`, which would both be equivalent to specifying `demographics.population.count` and `demographics.population.change`. Note that only variables in the same dataset are allowed. (e.g. demographics.population.count)
  --entity-id: string # Comma separated list of entity IDs. Defaults to retrieving all entities. Note that since there is currently no results pagination, retrieving values for all entities may produce incomplete results. (e.g. 0100000US,0400000US53)
  --forecast: float # Number of steps to forecast. Must be an integer between 0 and 20. Forecasts are produced using linear extrapolation on the data. They are only available when retrieving data for a single variable across many numerical constraint options. + Default `0` (e.g. 3)
  --describe: oneof<nothing, bool> # Whether or not to produce a description of the data. Set to `true` to produce a description. Descriptions are not available if no entities are specified. + Default `false` (e.g. false)
  --format: string@format-completer # If format is set to `google`, the data frame will be formatted as a [Google Visualizations data table](https://developers.google.com/chart/interactive/docs/reference#datatable-class). If the format is not provided or invalid, then the frame will be formatted normally.
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variable" $variable "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "forecast" $forecast "scalar") (serialize-qp "describe" $describe "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/v1/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"variable": $variable, "entity_id": $entity_id, "forecast": $forecast, "describe": $describe, "format": $format, "app_token": $app_token} | compact), body: null}
}

# Get Entities
#
# GET /entity/v1
# operationId: Get Entities
export def "entity get-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # ID of the entity. (e.g. 0400000US53)
  --entity-name: string # Name of the entity. (e.g. washington)
  --entity-type: string # Type of the entity. (e.g. region.state)
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "entity_name" $entity_name "scalar") (serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entity/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "entity_name": $entity_name, "entity_type": $entity_type, "app_token": $app_token} | compact), body: null}
}

# Find the relatives of an entity
#
# GET /entity/v1/{relation}
# operationId: Find the relatives of an entity
export def "entity find-relatives" [
  relation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # ID of the target entity. (e.g. 0400000US53)
  --variable-id: string # If this parameter is included, only entities with data for the given variable will be returned. Note that this may cause the number of entities returned to be less than the specified `limit`. (e.g. demographics.population.seattle)
  --limit: float # Maximum number of entities in each group. Must be an integer from 1 to 1000. (default: 10)
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($relation | is-empty) { error make --unspanned { msg: "path parameter 'relation' must be non-empty" } }
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "variable_id" $variable_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({relation: (encode-path-segment $relation)} | format pattern "/entity/v1/{relation}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "variable_id": $variable_id, "limit": $limit, "app_token": $app_token} | compact), body: null}
}

# Get datasets
#
# GET /search/v1/dataset
# operationId: Get datasets
export def "search-dataset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entities to use in formulating the query. (e.g. 0100000US)
  --dataset-id: string # If included, the search terms of the dataset will be used in the query. (e.g. demographics.population)
  --limit: float # Maximum number of results to return. Must be an integer from 0 to 50000. (default: 10)
  --offset: float # Number of results to skip. Used for pagination.
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "dataset_id" $dataset_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/v1/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "dataset_id": $dataset_id, "limit": $limit, "offset": $offset, "app_token": $app_token} | compact), body: null}
}

# Get questions
#
# GET /search/v1/question
# operationId: Get questions
export def "search-question get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # String to search against. (e.g. seattle)
  --limit: float # Maximum number of results to return. Must be an integer from 0 to 50000. (default: 10)
  --offset: float # Number of results to skip. Used for pagination.
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/v1/question" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "limit": $limit, "offset": $offset, "app_token": $app_token} | compact), body: null}
}

# Get suggestions
#
# GET /suggest/v1/{type}
# operationId: Get suggestions
export def "suggest get-suggestions" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to match. (e.g. seattl)
  --limit: float # Maximum number of results to return. Must be an integer from 0 to 100. (default: 5)
  --variable-id: string # This parameter is only available when suggesting entities with `type=entity`. If it is provided, suggestions will be filtered to include only entities that have data for the given variable. If the variable provided is invalid, no entities will be returned. Note that this filtering will increase response time significantly, so it should only be used when necessary. (e.g. demographics.population.count)
  --app-token: string # The [Socrata App Token](https://dev.socrata.com/docs/app-tokens.html) to be used with your request. The `app_token` parameter is required if an app token is not passed via the `X-App-Token` HTTP header. Clients must [register for their own app tokens](https://dev.socrata.com/docs/app-tokens.html). (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
  --x-app-token: string # e.g. cQovpGcdUT1CSzgYk0KPYdAI0 (e.g. cQovpGcdUT1CSzgYk0KPYdAI0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "variable_id" $variable_id "scalar") (serialize-qp "app_token" $app_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/suggest/v1/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-App-Token": $x_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "limit": $limit, "variable_id": $variable_id, "app_token": $app_token} | compact), body: null}
}
