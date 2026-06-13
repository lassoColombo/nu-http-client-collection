# Auto-generated client for Sandbox API vv1
# Source: https://api.apis.guru/v2/specs/getsandbox.com/v1/swagger.json
# Auth: --token flag or $env.SANDBOX_API_TOKEN

const BASE_URL = "https://getsandbox.com/api"
const DEFAULT_AUTH = "api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SANDBOX_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api_key" => { {headers: {API_Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://getsandbox.com/api"] }
def auth-scheme-completer [] { ["api_key"] }

# Completers for enum parameters
def transportType-completer [] { ["HTTP"] }
def apiDefinition-completer [] { ["Apiary" "None" "RAML_V08" "Swagger_V2_Json" "WSDL"] }
def proxyStatus-completer [] { ["STARTED" "STOPPED"] }
def runtimeVersion-completer [] { ["VERSION_1" "VERSION_2"] }
def stackType-completer [] { ["JavaScript"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "1-activity-search get" } } | get name | first)
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
export def "1-activity-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromTimestamp: int # Timestamp to start search from, epoch time in milliseconds. (format: int64)
  --sourceSandboxes: string # Comma-separated list of Sandbox names to search.
  --keyword: string # A keyword to search activities by, will match any part of the ActivityMessage.
  --allTypes: oneof<nothing, bool> # Flag to return all types of activity, defaults to just Requests
  --maxResults: int # Maximum number of results to return (format: int32)
]: nothing -> table<createdTimestamp: int, message: string, messageObject: record<request: record, responses: list, sandboxName: string>, messageType: string, sandboxId: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTimestamp" $fromTimestamp "scalar") (serialize-qp "sourceSandboxes" $sourceSandboxes "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "allTypes" $allTypes "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/activity/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSandboxes
#
# GET /1/sandboxes
# operationId: getSandboxes
export def "1-sandboxes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterType: string
]: nothing -> table<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: list<record>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterType" $filterType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/sandboxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createSandbox
#
# POST /1/sandboxes
# operationId: createSandbox
export def "1-sandboxes createSandbox" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commitBaseTemplate: oneof<nothing, bool> # Whether to commit the example Sandbox definition upon creation.
  --description: string # Text describing this Sandbox.
  --name: string # Optional name to give the Sandbox, will be generated if omitted.
  --ownerOrganisationName: string # Name of the team this Sandbox should be created under.
  --parentSandboxName: string # Name of the Sandbox this should be created under, if exists will be a 'clone'.
  --transportType: string@transportType-completer
]: any -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/sandboxes")
  let body = {commitBaseTemplate: $commitBaseTemplate, description: $description, name: $name, ownerOrganisationName: $ownerOrganisationName, parentSandboxName: $parentSandboxName, transportType: $transportType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteSandbox
#
# DELETE /1/sandboxes/{sandboxName}
# operationId: deleteSandbox
export def "1-sandboxes delete" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSandbox
#
# GET /1/sandboxes/{sandboxName}
# operationId: getSandbox
export def "1-sandboxes get" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateSandbox
#
# PUT /1/sandboxes/{sandboxName}
# operationId: updateSandbox
# --childSandboxes item shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
# --configuredRoutes item shape: {activeErrorOverride?: bool, activeLatency?: bool, defaultLatency?: int, errorOverrideType: "NONE"|"TIMEOUT"|"SERVICE_DOWN", loadLatency?: int, loadThreshold?: int, method?: string, path?: string, properties?: record, routeConfig?: record, transport?: string}
# --parentSandbox shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
export def "1-sandboxes updateSandbox" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiDefinition: string@apiDefinition-completer # The import source of this Sandbox.
  --childSandboxes: list # Clones of this Sandbox. — item shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
  --configuredRoutes: list # Extra configuration applied to some routes, delays, overrides etc. — item shape: {activeErrorOverride?: bool, activeLatency?: bool, defaultLatency?: int, errorOverrideType: "NONE"|"TIMEOUT"|"SERVICE_DOWN", loadLatency?: int, loadThreshold?: int, method?: string, path?: string, properties?: record, routeConfig?: record, transport?: string}
  --description: string
  --gitAccessToken: string
  --gitUrl: string # The git clone URL.
  --hasRepository: oneof<nothing, bool> # Whether this Sandbox has a git repository or not.
  --id: string # The ID of the Sandbox.
  --ipWhitelist: list # The list of IPs allowed to make requests, all allowed if omitted.
  name: string
  --parentSandbox: record # shape: {apiDefinition?: "None"|"Apiary"|"Swagger_V2_Json"|"RAML_V08"|"WSDL", childSandboxes?: list, configuredRoutes?: list, description?: string, gitAccessToken?: string, gitUrl?: string, hasRepository?: bool, id?: string, ipWhitelist?: list, name: string, parentSandbox?: record, properties?: record, proxyStatus?: "STARTED"|"STOPPED", runtimeVersion?: "VERSION_1"|"VERSION_2", sandboxUrl?: string, stackType?: "JavaScript", transportType?: "HTTP"}
  --properties: record
  --proxyStatus: string@proxyStatus-completer # The listener status.
  --runtimeVersion: string@runtimeVersion-completer # The library version of this Sandbox.
  --sandboxUrl: string # The request URL for this Sandbox.
  --stackType: string@stackType-completer
  --transportType: string@transportType-completer # The listener transport.
]: any -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)")
  let body = {apiDefinition: $apiDefinition, childSandboxes: $childSandboxes, configuredRoutes: $configuredRoutes, description: $description, gitAccessToken: $gitAccessToken, gitUrl: $gitUrl, hasRepository: $hasRepository, id: $id, ipWhitelist: $ipWhitelist, name: $name, parentSandbox: $parentSandbox, properties: $properties, proxyStatus: $proxyStatus, runtimeVersion: $runtimeVersion, sandboxUrl: $sandboxUrl, stackType: $stackType, transportType: $transportType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# forkSandbox
#
# GET /1/sandboxes/{sandboxName}/fork
# operationId: forkSandbox
export def "1-sandboxes-fork forkSandbox" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiDefinition: string, childSandboxes: list<any>, configuredRoutes: table<activeErrorOverride: bool, activeLatency: bool, defaultLatency: int, errorOverrideType: string, loadLatency: int, loadThreshold: int, method: string, path: string, properties: record, routeConfig: record, transport: string>, description: string, gitAccessToken: string, gitUrl: string, hasRepository: bool, id: string, ipWhitelist: list<string>, name: string, parentSandbox: any, properties: record, proxyStatus: string, runtimeVersion: string, sandboxUrl: string, stackType: string, transportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)/fork")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deleteSandboxState
#
# DELETE /1/sandboxes/{sandboxName}/state
# operationId: deleteSandboxState
export def "1-sandboxes-state delete" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSandboxState
#
# GET /1/sandboxes/{sandboxName}/state
# operationId: getSandboxState
export def "1-sandboxes-state get" [
  sandboxName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/sandboxes/($sandboxName)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
