# Auto-generated client for Sandbox API vv1
# Source: https://api.apis.guru/v2/specs/getsandbox.com/v1/swagger.json
# Auth: --token flag or $env.SANDBOX_API_TOKEN

const BASE_URL = "https://getsandbox.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SANDBOX_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "api_key" => { {scheme: $scheme, headers: {API_Key: $token_val}, query: "", location: "header"} }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://getsandbox.com/api"] }
def auth-scheme-completer [] { ["api_key"] }

# Completers for enum parameters
def transport-type-completer [] { ["HTTP"] }
def api-definition-completer [] { ["Apiary" "None" "RAML_V08" "Swagger_V2_Json" "WSDL"] }
def proxy-status-completer [] { ["STARTED" "STOPPED"] }
def runtime-version-completer [] { ["VERSION_1" "VERSION_2"] }
def stack-type-completer [] { ["JavaScript"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "1-activity-search get-sandboxes" } } | get name | first)
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

# searchActivity
#
# GET /1/activity/search
# operationId: getSandboxesActivity
export def "1-activity-search get-sandboxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-timestamp: int # Timestamp to start search from, epoch time in milliseconds. (format: int64)
  --source-sandboxes: string # Comma-separated list of Sandbox names to search.
  --keyword: string # A keyword to search activities by, will match any part of the ActivityMessage.
  --all-types: oneof<nothing, bool> # Flag to return all types of activity, defaults to just Requests
  --max-results: int # Maximum number of results to return (format: int32)
]: nothing -> table<createdTimestamp: int, message: string, messageObject: record<request: record, responses: list, sandboxName: string>, messageType: string, sandboxId: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTimestamp" $from_timestamp "scalar") (serialize-qp "sourceSandboxes" $source_sandboxes "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "allTypes" $all_types "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/activity/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromTimestamp": $from_timestamp, "sourceSandboxes": $source_sandboxes, "keyword": $keyword, "allTypes": $all_types, "maxResults": $max_results} | compact), body: null}
}

# getSandboxes
#
# GET /1/sandboxes
# operationId: getSandboxes
export def "1-sandboxes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-type: string
]: nothing -> table<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: list<record>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterType" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/sandboxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterType": $filter_type} | compact), body: null}
}

# createSandbox
#
# POST /1/sandboxes
# operationId: createSandbox
export def "1-sandboxes create-sandbox" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit-base-template: oneof<nothing, bool> # Whether to commit the example Sandbox definition upon creation.
  --description: string # Text describing this Sandbox.
  --name: string # Optional name to give the Sandbox, will be generated if omitted.
  --owner-organisation-name: string # Name of the team this Sandbox should be created under.
  --parent-sandbox-name: string # Name of the Sandbox this should be created under, if exists will be a 'clone'.
  --transport-type: string@transport-type-completer
]: any -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/sandboxes")
  let req_body = {"commitBaseTemplate": $commit_base_template, "description": $description, "name": $name, "ownerOrganisationName": $owner_organisation_name, "parentSandboxName": $parent_sandbox_name, "transportType": $transport_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteSandbox
#
# DELETE /1/sandboxes/{sandboxName}
# operationId: deleteSandbox
export def "1-sandboxes delete-sandbox" [
  sandbox_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSandbox
#
# GET /1/sandboxes/{sandboxName}
# operationId: getSandbox
export def "1-sandboxes get-sandbox" [
  sandbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateSandbox
#
# PUT /1/sandboxes/{sandboxName}
# operationId: updateSandbox
# --childSandboxes item shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list<string>, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
# --configuredRoutes item shape: {activeErrorOverride?: bool, activeLatency?: bool, defaultLatency?: int, errorOverrideType: "NONE"|"TIMEOUT"|"SERVICE_DOWN", loadLatency?: int, loadThreshold?: int, method?: string, path?: string, properties?: record, routeConfig?: record, transport?: string}
# --parentSandbox shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list<string>, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
export def "1-sandboxes update-sandbox" [
  sandbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-definition: string@api-definition-completer # The import source of this Sandbox.
  --child-sandboxes: list # Clones of this Sandbox. — item shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list<string>, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
  --configured-routes: list # Extra configuration applied to some routes, delays, overrides etc. — item shape: {activeErrorOverride?: bool, activeLatency?: bool, defaultLatency?: int, errorOverrideType: "NONE"|"TIMEOUT"|"SERVICE_DOWN", loadLatency?: int, loadThreshold?: int, method?: string, path?: string, properties?: record, routeConfig?: record, transport?: string}
  --description: string
  --git-access-token: string
  --git-url: string # The git clone URL.
  --has-repository: oneof<nothing, bool> # Whether this Sandbox has a git repository or not.
  --id: string # The ID of the Sandbox.
  --ip-whitelist: list<string> # The list of IPs allowed to make requests, all allowed if omitted.
  name: string
  --parent-sandbox: record # shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list<string>, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
  --properties: record
  --proxy-status: string@proxy-status-completer # The listener status.
  --runtime-version: string@runtime-version-completer # The library version of this Sandbox.
  --sandbox-url: string # The request URL for this Sandbox.
  --stack-type: string@stack-type-completer
  --transport-type: string@transport-type-completer # The listener transport.
]: any -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}"))
  let req_body = {"apiDefinition": $api_definition, "childSandboxes": $child_sandboxes, "configuredRoutes": $configured_routes, "description": $description, "gitAccessToken": $git_access_token, "gitUrl": $git_url, "hasRepository": $has_repository, "id": $id, "ipWhitelist": $ip_whitelist, "name": $name, "parentSandbox": $parent_sandbox, "properties": $properties, "proxyStatus": $proxy_status, "runtimeVersion": $runtime_version, "sandboxUrl": $sandbox_url, "stackType": $stack_type, "transportType": $transport_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# forkSandbox
#
# GET /1/sandboxes/{sandboxName}/fork
# operationId: forkSandbox
export def "1-sandboxes-fork get-sandbox" [
  sandbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/fork"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# deleteSandboxState
#
# DELETE /1/sandboxes/{sandboxName}/state
# operationId: deleteSandboxState
export def "1-sandboxes-state delete-sandbox" [
  sandbox_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSandboxState
#
# GET /1/sandboxes/{sandboxName}/state
# operationId: getSandboxState
export def "1-sandboxes-state get-sandbox" [
  sandbox_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_name | is-empty) { error make --unspanned { msg: "path parameter 'sandboxName' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
