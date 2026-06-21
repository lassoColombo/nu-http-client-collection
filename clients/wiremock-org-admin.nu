# Auto-generated client for WireMock v2.35.0
# Source: https://api.apis.guru/v2/specs/wiremock.org/admin/2.35.0/openapi.json
# Auth: --token flag or $env.WIREMOCK_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WIREMOCK_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return (e.g. 10)
  --offset: int # The start index of the results to return (e.g. 0)
]: nothing -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/__admin/mappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a new stub mapping
#
# POST /__admin/mappings
# --request shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-mappings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # This stub mapping's unique identifier
  --metadata: record # Arbitrary metadata to be used for e.g. tagging, documentation. Can also be used to find and remove stubs.
  --name: string # The stub mapping's name
  --new-scenario-state: string # The new state for the scenario to be updated to after this stub is served.
  --persistent: oneof<nothing, bool> # Indicates that the stub mapping should be persisted immediately on create/update/delete and survive resets to default.
  --post-serve-actions: record # A map of the names of post serve action extensions to trigger and their parameters.
  --priority: int # This stub mapping's priority relative to others. 1 is highest.
  --request: record # e.g. {bodyPatterns: [{equalToJson: { "numbers": [1, 2, 3] }}], headers: {Content-Type: {equalTo: application/json}}, method: POST, url: /some/thing} — shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
  --required-scenario-state: string # The required state of the scenario in order for this stub to be matched.
  --response: any
  --scenario-name: string # The name of the scenario that this stub mapping is part of
  --uuid: string # Alias for the id
]: any -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings")
  let req_body = {"id": $id, "metadata": $metadata, "name": $name, "newScenarioState": $new_scenario_state, "persistent": $persistent, "postServeActions": $post_serve_actions, "priority": $priority, "request": $request, "requiredScenarioState": $required_scenario_state, "response": $response, "scenarioName": $scenario_name, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find stubs by matching on their metadata
#
# POST /__admin/mappings/find-by-metadata
export def "admin-mappings-find-by-metadata create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-insensitive: oneof<nothing, bool>
  --equal-to: oneof<nothing, bool>
  --contains: string
  --matches: string
  --does-not-match: string
  --equal-to-json: string
  --ignore-array-order: oneof<nothing, bool>
  --ignore-extra-elements: oneof<nothing, bool>
  --matches-json-path: string
  --equal-to-xml: string
  --matches-xpath: string
  --namespaces: record
  --value-pattern: record
]: any -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/find-by-metadata")
  let req_body = {"caseInsensitive": $case_insensitive, "equalTo": $equal_to, "contains": $contains, "matches": $matches, "doesNotMatch": $does_not_match, "equalToJson": $equal_to_json, "ignoreArrayOrder": $ignore_array_order, "ignoreExtraElements": $ignore_extra_elements, "matchesJsonPath": $matches_json_path, "equalToXml": $equal_to_xml, "matchesXpath": $matches_xpath, "namespaces": $namespaces, "valuePattern": $value_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Import stub mappings
#
# POST /__admin/mappings/import
export def "admin-mappings-import create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/import")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete stub mappings matching metadata
#
# POST /__admin/mappings/remove-by-metadata
export def "admin-mappings-remove-by-metadata create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-insensitive: oneof<nothing, bool>
  --equal-to: oneof<nothing, bool>
  --contains: string
  --matches: string
  --does-not-match: string
  --equal-to-json: string
  --ignore-array-order: oneof<nothing, bool>
  --ignore-extra-elements: oneof<nothing, bool>
  --matches-json-path: string
  --equal-to-xml: string
  --matches-xpath: string
  --namespaces: record
  --value-pattern: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/remove-by-metadata")
  let req_body = {"caseInsensitive": $case_insensitive, "equalTo": $equal_to, "contains": $contains, "matches": $matches, "doesNotMatch": $does_not_match, "equalToJson": $equal_to_json, "ignoreArrayOrder": $ignore_array_order, "ignoreExtraElements": $ignore_extra_elements, "matchesJsonPath": $matches_json_path, "equalToXml": $equal_to_xml, "matchesXpath": $matches_xpath, "namespaces": $namespaces, "valuePattern": $value_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reset stub mappings
#
# POST /__admin/mappings/reset
export def "admin-mappings-reset create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Persist stub mappings
#
# POST /__admin/mappings/save
export def "admin-mappings-save create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/mappings/save")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a stub mapping
#
# DELETE /__admin/mappings/{stubMappingId}
export def "admin-mappings delete-by-stub-mapping-id" [
  stub_mapping_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stub_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'stubMappingId' must be non-empty" } }
  let full_url = (build-url $base ({stub_mapping_id: (encode-path-segment $stub_mapping_id)} | format pattern "/__admin/mappings/{stub_mapping_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get stub mapping by ID
#
# GET /__admin/mappings/{stubMappingId}
export def "admin-mappings get" [
  stub_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stub_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'stubMappingId' must be non-empty" } }
  let full_url = (build-url $base ({stub_mapping_id: (encode-path-segment $stub_mapping_id)} | format pattern "/__admin/mappings/{stub_mapping_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a stub mapping
#
# PUT /__admin/mappings/{stubMappingId}
# --request shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-mappings update" [
  stub_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # This stub mapping's unique identifier
  --metadata: record # Arbitrary metadata to be used for e.g. tagging, documentation. Can also be used to find and remove stubs.
  --name: string # The stub mapping's name
  --new-scenario-state: string # The new state for the scenario to be updated to after this stub is served.
  --persistent: oneof<nothing, bool> # Indicates that the stub mapping should be persisted immediately on create/update/delete and survive resets to default.
  --post-serve-actions: record # A map of the names of post serve action extensions to trigger and their parameters.
  --priority: int # This stub mapping's priority relative to others. 1 is highest.
  --request: record # e.g. {bodyPatterns: [{equalToJson: { "numbers": [1, 2, 3] }}], headers: {Content-Type: {equalTo: application/json}}, method: POST, url: /some/thing} — shape: {basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
  --required-scenario-state: string # The required state of the scenario in order for this stub to be matched.
  --response: any
  --scenario-name: string # The name of the scenario that this stub mapping is part of
  --uuid: string # Alias for the id
]: any -> record<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record<basicAuthCredentials: record<password: string, username: string>, bodyPatterns: list<record>, cookies: record, headers: record, method: string, queryParameters: record, url: string, urlPath: string, urlPathPattern: string, urlPattern: string>, requiredScenarioState: string, response: record<additionalProxyRequestHeaders: record, base64Body: string, body: string, bodyFileName: string, delayDistribution: any, fault: string, fixedDelayMilliseconds: int, fromConfiguredStub: bool, headers: record, jsonBody: record, proxyBaseUrl: string, status: int, statusMessage: string, transformerParameters: record, transformers: list<string>>, scenarioName: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stub_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'stubMappingId' must be non-empty" } }
  let full_url = (build-url $base ({stub_mapping_id: (encode-path-segment $stub_mapping_id)} | format pattern "/__admin/mappings/{stub_mapping_id}"))
  let req_body = {"id": $id, "metadata": $metadata, "name": $name, "newScenarioState": $new_scenario_state, "persistent": $persistent, "postServeActions": $post_serve_actions, "priority": $priority, "request": $request, "requiredScenarioState": $required_scenario_state, "response": $response, "scenarioName": $scenario_name, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find near misses matching specific request
#
# POST /__admin/near-misses/request
export def "admin-near-misses-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --absolute-url: string # The full URL to match against (e.g. http://localhost:56738/received-request/2)
  --body: string # Body string to match against (e.g. Hello world)
  --cookies: record # Cookie patterns to match against in the : { "": "" } form (e.g. {})
  --headers: record # Header patterns to match against in the : { "": "" } form (e.g. {Connection: keep-alive, Host: localhost:56738, User-Agent: Apache-HttpClient/4.5.1 (Java/1.7.0_51)})
  --method: string # The HTTP request method (e.g. GET)
  --url: string # The path and query to match exactly against (e.g. /received-request/2)
]: any -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/near-misses/request")
  let req_body = {"absoluteUrl": $absolute_url, "body": $body, "cookies": $cookies, "headers": $headers, "method": $method, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find near misses matching request pattern
#
# POST /__admin/near-misses/request-pattern
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-near-misses-request-pattern create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth-credentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --body-patterns: list # Request body patterns to match against in the : { "": "" } form
  --cookies: record # Cookie patterns to match against in the : { "": "" } form
  --headers: record # Header patterns to match against in the : { "": "" } form
  --method: string # The HTTP request method e.g. GET
  --query-parameters: record # Query parameter patterns to match against in the : { "": "" } form
  --url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path-pattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-pattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/near-misses/request-pattern")
  let req_body = {"basicAuthCredentials": $basic_auth_credentials, "bodyPatterns": $body_patterns, "cookies": $cookies, "headers": $headers, "method": $method, "queryParameters": $query_parameters, "url": $url, "urlPath": $url_path, "urlPathPattern": $url_path_pattern, "urlPattern": $url_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Take a snapshot recording
#
# POST /__admin/recordings/snapshot
# --extractBodyCriteria shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
# --requestBodyPattern shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
# --filters shape: {ids?: list<string>, basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
export def "admin-recordings-snapshot create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capture-headers: record # Headers from the request to include in the generated stub mappings, mapped to parameter objects. The only parameter available is "caseInsensitive", which defaults to false (e.g. {Accept: {}, Content-Type: {caseInsensitive: true}})
  --extract-body-criteria: record # Criteria for extracting response bodies to a separate file instead of including it in the stub mapping (e.g. [{binarySizeThreshold: 1 Mb, textSizeThreshold: 2 kb}]) — shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
  --persist: oneof<nothing, bool> # Whether to save stub mappings to the file system or just return them (default: true)
  --repeats-as-scenarios: oneof<nothing, bool> # When true, duplicate requests will be added to a Scenario. When false, duplicates are discarded (default: true)
  --request-body-pattern: record # Control the request body matcher used in generated stub mappings — shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
  --transformer-parameters: record # List of names of stub mappings transformers to apply to generated stubs
  --transformers: list<string> # Parameters to pass to stub mapping transformers
  --filters: record # shape: {ids?: list<string>, basicAuthCredentials?: record, bodyPatterns?: list, cookies?: record, headers?: record, method?: string, queryParameters?: record, url?: string, urlPath?: string, urlPathPattern?: string, urlPattern?: string}
]: any -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/snapshot")
  let req_body = {"captureHeaders": $capture_headers, "extractBodyCriteria": $extract_body_criteria, "persist": $persist, "repeatsAsScenarios": $repeats_as_scenarios, "requestBodyPattern": $request_body_pattern, "transformerParameters": $transformer_parameters, "transformers": $transformers, "filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Start recording
#
# POST /__admin/recordings/start
# --extractBodyCriteria shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
# --requestBodyPattern shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
export def "admin-recordings-start create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capture-headers: record # Headers from the request to include in the generated stub mappings, mapped to parameter objects. The only parameter available is "caseInsensitive", which defaults to false (e.g. {Accept: {}, Content-Type: {caseInsensitive: true}})
  --extract-body-criteria: record # Criteria for extracting response bodies to a separate file instead of including it in the stub mapping (e.g. [{binarySizeThreshold: 1 Mb, textSizeThreshold: 2 kb}]) — shape: {binarySizeThreshold?: string, textSizeThreshold?: string}
  --persist: oneof<nothing, bool> # Whether to save stub mappings to the file system or just return them (default: true)
  --repeats-as-scenarios: oneof<nothing, bool> # When true, duplicate requests will be added to a Scenario. When false, duplicates are discarded (default: true)
  --request-body-pattern: record # Control the request body matcher used in generated stub mappings — shape: {caseInsensitive?: bool, ignoreArrayOrder?: bool, ignoreExtraElements?: bool, matcher?: "auto"}
  --transformer-parameters: record # List of names of stub mappings transformers to apply to generated stubs
  --transformers: list<string> # Parameters to pass to stub mapping transformers
  --filters: any
  --target-base-url: string # Target URL when using the record and playback API (e.g. http://example.mocklab.io)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/start")
  let req_body = {"captureHeaders": $capture_headers, "extractBodyCriteria": $extract_body_criteria, "persist": $persist, "repeatsAsScenarios": $repeats_as_scenarios, "requestBodyPattern": $request_body_pattern, "transformerParameters": $transformer_parameters, "transformers": $transformers, "filters": $filters, "targetBaseUrl": $target_base_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop recording
#
# POST /__admin/recordings/stop
export def "admin-recordings-stop create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mappings: table<id: string, metadata: record, name: string, newScenarioState: string, persistent: bool, postServeActions: record, priority: int, request: record, requiredScenarioState: string, response: record, scenarioName: string, uuid: string>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/recordings/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # The maximum number of results to return (e.g. 10)
  --since: string # Only return logged requests after this date (e.g. 2016-10-05T12:33:01.000Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/__admin/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since} | compact), body: null}
}

# Count requests by criteria
#
# POST /__admin/requests/count
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-count create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth-credentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --body-patterns: list # Request body patterns to match against in the : { "": "" } form
  --cookies: record # Cookie patterns to match against in the : { "": "" } form
  --headers: record # Header patterns to match against in the : { "": "" } form
  --method: string # The HTTP request method e.g. GET
  --query-parameters: record # Query parameter patterns to match against in the : { "": "" } form
  --url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path-pattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-pattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/count")
  let req_body = {"basicAuthCredentials": $basic_auth_credentials, "bodyPatterns": $body_patterns, "cookies": $cookies, "headers": $headers, "method": $method, "queryParameters": $query_parameters, "url": $url, "urlPath": $url_path, "urlPathPattern": $url_path_pattern, "urlPattern": $url_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find requests by criteria
#
# POST /__admin/requests/find
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-find create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth-credentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --body-patterns: list # Request body patterns to match against in the : { "": "" } form
  --cookies: record # Cookie patterns to match against in the : { "": "" } form
  --headers: record # Header patterns to match against in the : { "": "" } form
  --method: string # The HTTP request method e.g. GET
  --query-parameters: record # Query parameter patterns to match against in the : { "": "" } form
  --url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path-pattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-pattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/find")
  let req_body = {"basicAuthCredentials": $basic_auth_credentials, "bodyPatterns": $body_patterns, "cookies": $cookies, "headers": $headers, "method": $method, "queryParameters": $query_parameters, "url": $url, "urlPath": $url_path, "urlPathPattern": $url_path_pattern, "urlPattern": $url_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove requests by criteria
#
# POST /__admin/requests/remove
# --basicAuthCredentials shape: {password: string, username: string}
export def "admin-requests-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth-credentials: record # Pre-emptive basic auth credentials to match against — shape: {password: string, username: string}
  --body-patterns: list # Request body patterns to match against in the : { "": "" } form
  --cookies: record # Cookie patterns to match against in the : { "": "" } form
  --headers: record # Header patterns to match against in the : { "": "" } form
  --method: string # The HTTP request method e.g. GET
  --query-parameters: record # Query parameter patterns to match against in the : { "": "" } form
  --url: string # The path and query to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path: string # The path to match exactly against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-path-pattern: string # The path regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
  --url-pattern: string # The path and query regex to match against. Only one of url, urlPattern, urlPath or urlPathPattern may be specified.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/remove")
  let req_body = {"basicAuthCredentials": $basic_auth_credentials, "bodyPatterns": $body_patterns, "cookies": $cookies, "headers": $headers, "method": $method, "queryParameters": $query_parameters, "url": $url, "urlPath": $url_path, "urlPathPattern": $url_path_pattern, "urlPattern": $url_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete requests mappings matching metadata
#
# POST /__admin/requests/remove-by-metadata
export def "admin-requests-remove-by-metadata create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-insensitive: oneof<nothing, bool>
  --equal-to: oneof<nothing, bool>
  --contains: string
  --matches: string
  --does-not-match: string
  --equal-to-json: string
  --ignore-array-order: oneof<nothing, bool>
  --ignore-extra-elements: oneof<nothing, bool>
  --matches-json-path: string
  --equal-to-xml: string
  --matches-xpath: string
  --namespaces: record
  --value-pattern: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/remove-by-metadata")
  let req_body = {"caseInsensitive": $case_insensitive, "equalTo": $equal_to, "contains": $contains, "matches": $matches, "doesNotMatch": $does_not_match, "equalToJson": $equal_to_json, "ignoreArrayOrder": $ignore_array_order, "ignoreExtraElements": $ignore_extra_elements, "matchesJsonPath": $matches_json_path, "equalToXml": $equal_to_xml, "matchesXpath": $matches_xpath, "namespaces": $namespaces, "valuePattern": $value_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Empty the request journal
#
# POST /__admin/requests/reset
# DEPRECATED
@deprecated
export def "admin-requests-reset create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/unmatched")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nearMisses: table<absoluteUrl: string, body: string, cookies: record, headers: record, method: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/requests/unmatched/near-misses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete request by ID
#
# DELETE /__admin/requests/{requestId}
export def "admin-requests delete-by-request-id" [
  request_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($request_id | is-empty) { error make --unspanned { msg: "path parameter 'requestId' must be non-empty" } }
  let full_url = (build-url $base ({request_id: (encode-path-segment $request_id)} | format pattern "/__admin/requests/{request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get request by ID
#
# GET /__admin/requests/{requestId}
export def "admin-requests get" [
  request_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($request_id | is-empty) { error make --unspanned { msg: "path parameter 'requestId' must be non-empty" } }
  let full_url = (build-url $base ({request_id: (encode-path-segment $request_id)} | format pattern "/__admin/requests/{request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reset mappings and request journal
#
# POST /__admin/reset
export def "admin-reset create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<scenarios: table<id: string, name: string, possibleStates: list, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/scenarios")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reset the state of all scenarios
#
# POST /__admin/scenarios/reset
export def "admin-scenarios-reset create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/scenarios/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update global settings
#
# POST /__admin/settings
export def "admin-settings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fixed-delay: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/settings")
  let req_body = {"fixedDelay": $fixed_delay} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Shutdown the WireMock server
#
# POST /__admin/shutdown
export def "admin-shutdown create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__admin/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
