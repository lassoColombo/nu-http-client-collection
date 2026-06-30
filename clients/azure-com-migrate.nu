# Auto-generated client for Azure Migrate v2018-02-02
# Source: https://api.apis.guru/v2/specs/azure.com/migrate/2018-02-02/swagger.json
# Auth: --token flag or $env.AZURE_MIGRATE_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZURE_MIGRATE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["2018-02-02"] }
def type-completer [] { ["Microsoft.Migrate/projects"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-migrate-operations list" } } | get name | first)
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

# Get list of operations supported in the API.
#
# GET /providers/Microsoft.Migrate/operations
# operationId: Operations_List
export def "providers-microsoft-migrate-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/providers/Microsoft.Migrate/operations" $auth.query)
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

# Get the assessment options.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/locations/{locationName}/assessmentOptions
# operationId: AssessmentOptions_Get
export def "subscriptions-providers-microsoft-migrate-locations-assessment-options get" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<reservedInstanceVmFamilies: list<string>, vmFamilies: table<category: list, familyName: string, targetLocations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_name | is-empty) { error make --unspanned { msg: "path parameter 'locationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Migrate/locations/{location_name}/assessmentOptions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Checks whether the project name is available in the specified region.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/locations/{locationName}/checkNameAvailability
# operationId: Location_CheckNameAvailability
export def "subscriptions-providers-microsoft-migrate-locations-check-name-availability check" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.Migrate/projects
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_name | is-empty) { error make --unspanned { msg: "path parameter 'locationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Migrate/locations/{location_name}/checkNameAvailability") $qp $auth.query)
  let req_body = {"name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all projects.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/projects
# operationId: Projects_ListBySubscription
export def "subscriptions-providers-microsoft-migrate-projects list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, location: string, name: string, properties: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Migrate/projects") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all assessments created in the project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/assessments
# operationId: Assessments_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-assessments list" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/assessments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all groups
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups
# operationId: Groups_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups list" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the group
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Delete
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups delete" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get a specific group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<assessments: list<string>, createdTimestamp: string, machines: list<string>, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new group with specified settings. If group with the name provided already exists, then the existing group is updated.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Create
# --properties shape: {machines: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups create" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # For optimistic concurrency control.
  properties: record # Properties of group resource. — shape: {machines: list<string>}
]: any -> record<eTag: string, id: string, name: string, properties: record<assessments: list<string>, createdTimestamp: string, machines: list<string>, updatedTimestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}") $qp $auth.query)
  let req_body = {"eTag": $e_tag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Get all assessments created for the specified group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments
# operationId: Assessments_ListByGroup
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments list" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an assessment from the project.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Delete
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments delete" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get an assessment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<azureHybridUseBenefit: string, azureLocation: string, azureOfferCode: string, azurePricingTier: string, azureStorageRedundancy: string, confidenceRatingInPercentage: float, createdTimestamp: string, currency: string, discountPercentage: float, monthlyBandwidthCost: float, monthlyComputeCost: float, monthlyStorageCost: float, numberOfMachines: int, percentile: string, pricesTimestamp: string, scalingFactor: float, sizingCriterion: string, stage: string, status: string, timeRange: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or Update assessment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Create
# --properties shape: {azureHybridUseBenefit: "Unknown"|"Yes"|"No", azureLocation: "Unknown"|"EastAsia"|"SoutheastAsia"|"AustraliaEast"|"AustraliaSoutheast"|"BrazilSouth"|"CanadaCentral"|"CanadaEast"|"WestEurope"|"NorthEurope"|"CentralIndia"|"SouthIndia"|"WestIndia"|"JapanEast"|"JapanWest"|"KoreaCentral"|"KoreaSouth"|"UkWest"|"UkSouth"|"NorthCentralUs"|"EastUs"|"WestUs2"|"SouthCentralUs"|"CentralUs"|"EastUs2"|"WestUs"|"WestCentralUs"|"GermanyCentral"|"GermanyNortheast"|"ChinaNorth"|"ChinaEast", ... (10 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments create" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # For optimistic concurrency control.
  properties: record # Properties of an assessment. — shape: {azureHybridUseBenefit: "Unknown"|"Yes"|"No", azureLocation: "Unknown"|"EastAsia"|"SoutheastAsia"|"AustraliaEast"|"AustraliaSoutheast"|"BrazilSouth"|"CanadaCentral"|"CanadaEast"|"WestEurope"|"NorthEurope"|"CentralIndia"|"SouthIndia"|"WestIndia"|"JapanEast"|"JapanWest"|"KoreaCentral"|"KoreaSouth"|"UkWest"|"UkSouth"|"NorthCentralUs"|"EastUs"|"WestUs2"|"SouthCentralUs"|"CentralUs"|"EastUs2"|"WestUs"|"WestCentralUs"|"GermanyCentral"|"GermanyNortheast"|"ChinaNorth"|"ChinaEast", ... (10 more fields)}
]: any -> record<eTag: string, id: string, name: string, properties: record<azureHybridUseBenefit: string, azureLocation: string, azureOfferCode: string, azurePricingTier: string, azureStorageRedundancy: string, confidenceRatingInPercentage: float, createdTimestamp: string, currency: string, discountPercentage: float, monthlyBandwidthCost: float, monthlyComputeCost: float, monthlyStorageCost: float, numberOfMachines: int, percentile: string, pricesTimestamp: string, scalingFactor: float, sizingCriterion: string, stage: string, status: string, timeRange: string, updatedTimestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}") $qp $auth.query)
  let req_body = {"eTag": $e_tag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Get assessed machines for assessment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/assessedMachines
# operationId: AssessedMachines_ListByAssessment
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-assessed-machines list" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}/assessedMachines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an assessed machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/assessedMachines/{assessedMachineName}
# operationId: AssessedMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-assessed-machines get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  assessed_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<bootType: string, createdTimestamp: string, datacenterContainer: string, datacenterMachineId: string, datacenterManagementServer: string, datacenterManagementServerId: string, description: string, discoveredTimestamp: string, disks: record, displayName: string, groups: list<string>, megabytesOfMemory: float, megabytesOfMemoryForRecommendedSize: float, monthlyBandwidthCost: float, monthlyComputeCostForRecommendedSize: float, monthlyStorageCost: float, networkAdapters: record, numberOfCores: int, numberOfCoresForRecommendedSize: int, operatingSystem: string, percentageCoresUtilization: float, percentageCoresUtilizationDataPointsExpected: int, percentageCoresUtilizationDataPointsReceived: int, percentageMemoryUtilization: float, percentageMemoryUtilizationDataPointsExpected: int, percentageMemoryUtilizationDataPointsReceived: int, recommendedSize: string, suitability: string, suitabilityExplanation: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  if ($assessed_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'assessedMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name), assessed_machine_name: (encode-path-segment $assessed_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}/assessedMachines/{assessed_machine_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get download URL for the assessment report.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/downloadUrl
# operationId: Assessments_GetReportDownloadUrl
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-download-url get-report" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  group_name: string
  assessment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<assessmentReportUrl: string, expirationTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($assessment_name | is-empty) { error make --unspanned { msg: "path parameter 'assessmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), group_name: (encode-path-segment $group_name), assessment_name: (encode-path-segment $assessment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/groups/{group_name}/assessments/{assessment_name}/downloadUrl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get all machines in the project
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/machines
# operationId: Machines_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-machines list" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/machines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/machines/{machineName}
# operationId: Machines_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-machines get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<bootType: string, createdTimestamp: string, datacenterContainer: string, datacenterMachineId: string, datacenterManagementServer: string, datacenterManagementServerId: string, description: string, discoveredTimestamp: string, disks: record, displayName: string, groups: list<string>, megabytesOfMemory: float, networkAdapters: record, numberOfCores: int, operatingSystem: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/machines/{machine_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all projects.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects
# operationId: Projects_ListByResourceGroup
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects list-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, location: string, name: string, properties: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the project
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Delete
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects delete" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the specified project.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Get
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update project.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Update
# --properties shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects update" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # For optimistic concurrency control.
  --location: string # Azure location in which project is created.
  --properties: record # Properties of a project. — shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
  --tags: record # Tags provided by Azure Tagging service.
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}") $qp $auth.query)
  let req_body = {"eTag": $e_tag, "location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create or update project.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Create
# --properties shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects create" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # For optimistic concurrency control.
  --location: string # Azure location in which project is created.
  --properties: record # Properties of a project. — shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
  --tags: record # Tags provided by Azure Tagging service.
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}") $qp $auth.query)
  let req_body = {"eTag": $e_tag, "location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Get shared keys for the project.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/keys
# operationId: Projects_GetKeys
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects-keys get" [
  subscription_id: string
  resource_group_name: string
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<workspaceId: string, workspaceKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), project_name: (encode-path-segment $project_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Migrate/projects/{project_name}/keys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
