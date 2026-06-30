# Auto-generated client for Sandbox API vv1
# Source: https://api.apis.guru/v2/specs/getsandbox.com/v1/swagger.json
# Auth: --token flag or $env.SANDBOX_API_TOKEN

const BASE_URL = "https://getsandbox.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SANDBOX_API_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base "/1/activity/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fromTimestamp": $from_timestamp, "sourceSandboxes": $source_sandboxes, "keyword": $keyword, "allTypes": $all_types, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/1/sandboxes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filterType": $filter_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/1/sandboxes" $auth.query)
  let req_body = {"commitBaseTemplate": $commit_base_template, "description": $description, "name": $name, "ownerOrganisationName": $owner_organisation_name, "parentSandboxName": $parent_sandbox_name, "transportType": $transport_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full []
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}") $auth.query)
  let req_body = {"apiDefinition": $api_definition, "childSandboxes": $child_sandboxes, "configuredRoutes": $configured_routes, "description": $description, "gitAccessToken": $git_access_token, "gitUrl": $git_url, "hasRepository": $has_repository, "id": $id, "ipWhitelist": $ip_whitelist, "name": $name, "parentSandbox": $parent_sandbox, "properties": $properties, "proxyStatus": $proxy_status, "runtimeVersion": $runtime_version, "sandboxUrl": $sandbox_url, "stackType": $stack_type, "transportType": $transport_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/fork") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/state") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full []
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
  let full_url = (build-url $base ({sandbox_name: (encode-path-segment $sandbox_name)} | format pattern "/1/sandboxes/{sandbox_name}/state") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}
