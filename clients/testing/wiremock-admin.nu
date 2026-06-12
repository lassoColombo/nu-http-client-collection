# Auto-generated client for WireMock v2.35.0
# Source: https://api.apis.guru/v2/specs/wiremock.org/admin/2.35.0/openapi.json
# Auth: --token flag or $env.WIREMOCK_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WIREMOCK_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-mappings delete" } } | get name | first)
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

# Delete all stub mappings
#
# DELETE /__admin/mappings
export def "admin-mappings delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all stub mappings
#
# GET /__admin/mappings
export def "admin-mappings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return (e.g. 10)
  --offset: int # The start index of the results to return (e.g. 0)
]: nothing -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/__admin/mappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new stub mapping
#
# POST /__admin/mappings
# --request shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-mappings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # This stub mapping's unique identifier
  --metadata: record # Arbitrary metadata to be used for e.g. tagging, documentation. Can also be used to find and remove stubs.
  --name: string # The stub mapping's name
  --newScenarioState: string # The new state for the scenario to be updated to after this stub is served.
  --persistent: oneof<nothing, bool> # Indicates that the stub mapping should be persisted immediately on create/update/delete and survive resets to default.
  --postServeActions: record # A map of the names of post serve action extensions to trigger and their parameters.
  --priority: int # This stub mapping's priority relative to others. 1 is highest.
  --request: record # e.g. {bodyPatterns: [{equalToJson: { "numbers": [1, 2, 3] }}], headers: {Content-Type: {equalTo: application/json}}, method: POST, url: /some/thing} — shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
  --requiredScenarioState: string # The required state of the scenario in order for this stub to be matched.
  --response: any
  --scenarioName: string # The name of the scenario that this stub mapping is part of
  --uuid: string # Alias for the id
]: any -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings")
  let body = {id: $id, metadata: $metadata, name: $name, newScenarioState: $newScenarioState, persistent: $persistent, postServeActions: $postServeActions, priority: $priority, request: $request, requiredScenarioState: $requiredScenarioState, response: $response, scenarioName: $scenarioName, uuid: $uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find stubs by matching on their metadata
#
# POST /__admin/mappings/find-by-metadata
export def "admin-mappings-find-by-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --caseInsensitive: oneof<nothing, bool>
  --equalTo: oneof<nothing, bool>
  --contains: string
  --matches: string
  --doesNotMatch: string
  --equalToJson: string
  --ignoreArrayOrder: oneof<nothing, bool>
  --ignoreExtraElements: oneof<nothing, bool>
  --matchesJsonPath: string
  --equalToXml: string
  --matchesXpath: string
  --namespaces: record
  --valuePattern: record
]: any -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/find-by-metadata")
  let body = {caseInsensitive: $caseInsensitive, equalTo: $equalTo, contains: $contains, matches: $matches, doesNotMatch: $doesNotMatch, equalToJson: $equalToJson, ignoreArrayOrder: $ignoreArrayOrder, ignoreExtraElements: $ignoreExtraElements, matchesJsonPath: $matchesJsonPath, equalToXml: $equalToXml, matchesXpath: $matchesXpath, namespaces: $namespaces, valuePattern: $valuePattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import stub mappings
#
# POST /__admin/mappings/import
export def "admin-mappings-import post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/import")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete stub mappings matching metadata
#
# POST /__admin/mappings/remove-by-metadata
export def "admin-mappings-remove-by-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --caseInsensitive: oneof<nothing, bool>
  --equalTo: oneof<nothing, bool>
  --contains: string
  --matches: string
  --doesNotMatch: string
  --equalToJson: string
  --ignoreArrayOrder: oneof<nothing, bool>
  --ignoreExtraElements: oneof<nothing, bool>
  --matchesJsonPath: string
  --equalToXml: string
  --matchesXpath: string
  --namespaces: record
  --valuePattern: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/remove-by-metadata")
  let body = {caseInsensitive: $caseInsensitive, equalTo: $equalTo, contains: $contains, matches: $matches, doesNotMatch: $doesNotMatch, equalToJson: $equalToJson, ignoreArrayOrder: $ignoreArrayOrder, ignoreExtraElements: $ignoreExtraElements, matchesJsonPath: $matchesJsonPath, equalToXml: $equalToXml, matchesXpath: $matchesXpath, namespaces: $namespaces, valuePattern: $valuePattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset stub mappings
#
# POST /__admin/mappings/reset
export def "admin-mappings-reset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Persist stub mappings
#
# POST /__admin/mappings/save
export def "admin-mappings-save post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/save")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a stub mapping
#
# DELETE /__admin/mappings/{stubMappingId}
export def "admin-mappings delete-by-stubMappingId" [
  stubMappingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/__admin/mappings/($stubMappingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stub mapping by ID
#
# GET /__admin/mappings/{stubMappingId}
export def "admin-mappings get" [
  stubMappingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/__admin/mappings/($stubMappingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a stub mapping
#
# PUT /__admin/mappings/{stubMappingId}
# --request shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-mappings put" [
  stubMappingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # This stub mapping's unique identifier
  --metadata: record # Arbitrary metadata to be used for e.g. tagging, documentation. Can also be used to find and remove stubs.
  --name: string # The stub mapping's name
  --newScenarioState: string # The new state for the scenario to be updated to after this stub is served.
  --persistent: oneof<nothing, bool> # Indicates that the stub mapping should be persisted immediately on create/update/delete and survive resets to default.
  --postServeActions: record # A map of the names of post serve action extensions to trigger and their parameters.
  --priority: int # This stub mapping's priority relative to others. 1 is highest.
  --request: record # e.g. {bodyPatterns: [{equalToJson: { "numbers": [1, 2, 3] }}], headers: {Content-Type: {equalTo: application/json}}, method: POST, url: /some/thing} — shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
  --requiredScenarioState: string # The required state of the scenario in order for this stub to be matched.
  --response: any
  --scenarioName: string # The name of the scenario that this stub mapping is part of
  --uuid: string # Alias for the id
]: any -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/__admin/mappings/($stubMappingId)")
  let body = {id: $id, metadata: $metadata, name: $name, newScenarioState: $newScenarioState, persistent: $persistent, postServeActions: $postServeActions, priority: $priority, request: $request, requiredScenarioState: $requiredScenarioState, response: $response, scenarioName: $scenarioName, uuid: $uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find near misses matching specific request
#
# POST /__admin/near-misses/request
export def "admin-near-misses-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --absoluteUrl: string # The full URL to match against (e.g. http://localhost:56738/received-request/2)
  --body-body: string # Body string to match against (e.g. Hello world)
  --cookies: record # Cookie patterns to match against in the <key>: { "<predicate>": "<value>" } form (e.g. {})
  --headers: record # Header patterns to match against in the <key>: { "<predicate>": "<value>" } form (e.g. {Connection: keep-alive, Host: localhost:56738, User-Agent: Apache-HttpClient/4.5.1 (Java/1.7.0_51)})
  --method: string # The HTTP request method (e.g. GET)
  --body-url: string # The path and query to match exactly against (e.g. /received-request/2)
]: any -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/near-misses/request")
  let body = {absoluteUrl: $absoluteUrl, body: $body_body, cookies: $cookies, headers: $headers, method: $method, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find near misses matching request pattern
#
# POST /__admin/near-misses/request-pattern
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-near-misses-request-pattern post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthCredentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --bodyPatterns: list # Request body patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --cookies: record # Cookie patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --headers: record # Header patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --method: string # The HTTP request method e.g. GET
  --queryParameters: record # Query parameter patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --body-url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPath: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPathPattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/near-misses/request-pattern")
  let body = {basicAuthCredentials: $basicAuthCredentials, bodyPatterns: $bodyPatterns, cookies: $cookies, headers: $headers, method: $method, queryParameters: $queryParameters, url: $body_url, urlPath: $urlPath, urlPathPattern: $urlPathPattern, urlPattern: $urlPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Take a snapshot recording
#
# POST /__admin/recordings/snapshot
# --extractBodyCriteria shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
# --requestBodyPattern shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
# --filters shape: {ids?: list, basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-recordings-snapshot post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --captureHeaders: record # Headers from the request to include in the generated stub mappings, mapped to parameter objects. The only parameter available is "caseInsensitive", which defaults to false (e.g. {Accept: {}, Content-Type: {caseInsensitive: true}})
  --extractBodyCriteria: record # Criteria for extracting response bodies to a separate file instead of including it in the stub mapping (e.g. [{binarySizeThreshold: 1 Mb, textSizeThreshold: 2 kb}]) — shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
  --persist: oneof<nothing, bool> # Whether to save stub mappings to the file system or just return them (default: true)
  --repeatsAsScenarios: oneof<nothing, bool> # When true, duplicate requests will be added to a Scenario. When false, duplicates are discarded (default: true)
  --requestBodyPattern: record # Control the request body matcher used in generated stub mappings — shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
  --transformerParameters: record # List of names of stub mappings transformers to apply to generated stubs
  --transformers: list # Parameters to pass to stub mapping transformers
  --filters: record # shape: {ids?: list, basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
]: any -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/snapshot")
  let body = {captureHeaders: $captureHeaders, extractBodyCriteria: $extractBodyCriteria, persist: $persist, repeatsAsScenarios: $repeatsAsScenarios, requestBodyPattern: $requestBodyPattern, transformerParameters: $transformerParameters, transformers: $transformers, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start recording
#
# POST /__admin/recordings/start
# --extractBodyCriteria shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
# --requestBodyPattern shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
export def "admin-recordings-start post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --captureHeaders: record # Headers from the request to include in the generated stub mappings, mapped to parameter objects. The only parameter available is "caseInsensitive", which defaults to false (e.g. {Accept: {}, Content-Type: {caseInsensitive: true}})
  --extractBodyCriteria: record # Criteria for extracting response bodies to a separate file instead of including it in the stub mapping (e.g. [{binarySizeThreshold: 1 Mb, textSizeThreshold: 2 kb}]) — shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
  --persist: oneof<nothing, bool> # Whether to save stub mappings to the file system or just return them (default: true)
  --repeatsAsScenarios: oneof<nothing, bool> # When true, duplicate requests will be added to a Scenario. When false, duplicates are discarded (default: true)
  --requestBodyPattern: record # Control the request body matcher used in generated stub mappings — shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
  --transformerParameters: record # List of names of stub mappings transformers to apply to generated stubs
  --transformers: list # Parameters to pass to stub mapping transformers
  --filters: any
  --targetBaseUrl: string # Target URL when using the record and playback API (e.g. http://example.mocklab.io)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/start")
  let body = {captureHeaders: $captureHeaders, extractBodyCriteria: $extractBodyCriteria, persist: $persist, repeatsAsScenarios: $repeatsAsScenarios, requestBodyPattern: $requestBodyPattern, transformerParameters: $transformerParameters, transformers: $transformers, filters: $filters, targetBaseUrl: $targetBaseUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get recording status
#
# GET /__admin/recordings/status
export def "admin-recordings-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop recording
#
# POST /__admin/recordings/stop
export def "admin-recordings-stop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all requests in journal
#
# DELETE /__admin/requests
export def "admin-requests delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all requests in journal
#
# GET /__admin/requests
export def "admin-requests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # The maximum number of results to return (e.g. 10)
  --since: string # Only return logged requests after this date (e.g. 2016-10-05T12:33:01.000Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/__admin/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count requests by criteria
#
# POST /__admin/requests/count
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-count post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthCredentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --bodyPatterns: list # Request body patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --cookies: record # Cookie patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --headers: record # Header patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --method: string # The HTTP request method e.g. GET
  --queryParameters: record # Query parameter patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --body-url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPath: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPathPattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/count")
  let body = {basicAuthCredentials: $basicAuthCredentials, bodyPatterns: $bodyPatterns, cookies: $cookies, headers: $headers, method: $method, queryParameters: $queryParameters, url: $body_url, urlPath: $urlPath, urlPathPattern: $urlPathPattern, urlPattern: $urlPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find requests by criteria
#
# POST /__admin/requests/find
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-find post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthCredentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --bodyPatterns: list # Request body patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --cookies: record # Cookie patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --headers: record # Header patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --method: string # The HTTP request method e.g. GET
  --queryParameters: record # Query parameter patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --body-url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPath: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPathPattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/find")
  let body = {basicAuthCredentials: $basicAuthCredentials, bodyPatterns: $bodyPatterns, cookies: $cookies, headers: $headers, method: $method, queryParameters: $queryParameters, url: $body_url, urlPath: $urlPath, urlPathPattern: $urlPathPattern, urlPattern: $urlPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove requests by criteria
#
# POST /__admin/requests/remove
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthCredentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --bodyPatterns: list # Request body patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --cookies: record # Cookie patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --headers: record # Header patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --method: string # The HTTP request method e.g. GET
  --queryParameters: record # Query parameter patterns to match against in the <key>: { "<predicate>": "<value>" } form
  --body-url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPath: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPathPattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --urlPattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/remove")
  let body = {basicAuthCredentials: $basicAuthCredentials, bodyPatterns: $bodyPatterns, cookies: $cookies, headers: $headers, method: $method, queryParameters: $queryParameters, url: $body_url, urlPath: $urlPath, urlPathPattern: $urlPathPattern, urlPattern: $urlPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete requests mappings matching metadata
#
# POST /__admin/requests/remove-by-metadata
export def "admin-requests-remove-by-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --caseInsensitive: oneof<nothing, bool>
  --equalTo: oneof<nothing, bool>
  --contains: string
  --matches: string
  --doesNotMatch: string
  --equalToJson: string
  --ignoreArrayOrder: oneof<nothing, bool>
  --ignoreExtraElements: oneof<nothing, bool>
  --matchesJsonPath: string
  --equalToXml: string
  --matchesXpath: string
  --namespaces: record
  --valuePattern: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/remove-by-metadata")
  let body = {caseInsensitive: $caseInsensitive, equalTo: $equalTo, contains: $contains, matches: $matches, doesNotMatch: $doesNotMatch, equalToJson: $equalToJson, ignoreArrayOrder: $ignoreArrayOrder, ignoreExtraElements: $ignoreExtraElements, matchesJsonPath: $matchesJsonPath, equalToXml: $equalToXml, matchesXpath: $matchesXpath, namespaces: $namespaces, valuePattern: $valuePattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Empty the request journal
#
# POST /__admin/requests/reset
# DEPRECATED
@deprecated
export def "admin-requests-reset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find unmatched requests
#
# GET /__admin/requests/unmatched
export def "admin-requests-unmatched get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/unmatched")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve near-misses for all unmatched requests
#
# GET /__admin/requests/unmatched/near-misses
export def "admin-requests-unmatched-near-misses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/unmatched/near-misses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete request by ID
#
# DELETE /__admin/requests/{requestId}
export def "admin-requests delete-by-requestId" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/__admin/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request by ID
#
# GET /__admin/requests/{requestId}
export def "admin-requests get" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/__admin/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset mappings and request journal
#
# POST /__admin/reset
export def "admin-reset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scenarios
#
# GET /__admin/scenarios
export def "admin-scenarios get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarios: table<id: string, name: string, possibleStates: list, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/scenarios")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the state of all scenarios
#
# POST /__admin/scenarios/reset
export def "admin-scenarios-reset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/scenarios/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update global settings
#
# POST /__admin/settings
export def "admin-settings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixedDelay: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/settings")
  let body = {fixedDelay: $fixedDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Shutdown the WireMock server
#
# POST /__admin/shutdown
export def "admin-shutdown post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
