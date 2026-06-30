# Auto-generated client for Custom Workflow Actions vv4
# Source: https://api.apis.guru/v2/specs/hubapi.com/automation/v4/openapi.json
# Auth: --token flag or $env.CUSTOM_WORKFLOW_ACTIONS_TOKEN

const BASE_URL = "https://api.hubapi.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_WORKFLOW_ACTIONS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-hapikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "hapikey")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "private-app-legacy" => { {scheme: $scheme, headers: {private-app-legacy: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "automation-actions-callbacks-complete create-batch" } } | get name | first)
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

# Complete a batch of callbacks
#
# POST /automation/v4/actions/callbacks/complete
# operationId: post-/automation/v4/actions/callbacks/complete_completeBatch
# --inputs item shape: {callbackId: string, outputFields: record}
export def "automation-actions-callbacks-complete create-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: list # item shape: {callbackId: string, outputFields: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automation/v4/actions/callbacks/complete" $auth.query)
  let req_body = {"inputs": $inputs} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Complete a callback
#
# POST /automation/v4/actions/callbacks/{callbackId}/complete
# operationId: post-/automation/v4/actions/callbacks/{callbackId}/complete_complete
export def "automation-actions-callbacks-complete create" [
  callback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output_fields: record # A map of action output names and values.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($callback_id | is-empty) { error make --unspanned { msg: "path parameter 'callbackId' must be non-empty" } }
  let full_url = (build-url $base ({callback_id: (encode-path-segment $callback_id)} | format pattern "/automation/v4/actions/callbacks/{callback_id}/complete") $auth.query)
  let req_body = {"outputFields": $output_fields} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get all custom actions
#
# GET /automation/v4/actions/{appId}
# operationId: get-/automation/v4/actions/{appId}_getPage
export def "automation-actions get-app-page" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results per page. (format: int32)
  --after: string # The paging cursor token of the last successfully read resource will be returned as the `paging.next.after` JSON property of a paged response containing more results.
  --archived: oneof<nothing, bool> # Whether to include archived custom actions. (default: false)
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: table<actionUrl: string, archivedAt: int, functions: list, id: string, inputFieldDependencies: list, inputFields: list, labels: record, objectRequestOptions: record, objectTypes: list, published: bool, revisionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/automation/v4/actions/{app_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "after": $after, "archived": $archived} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new custom action
#
# POST /automation/v4/actions/{appId}
# operationId: post-/automation/v4/actions/{appId}_create
# --functions item shape: {functionSource: string, functionType: "PRE_ACTION_EXECUTION"|"PRE_FETCH_OPTIONS"|"POST_FETCH_OPTIONS", id?: string}
# --inputFields item shape: {isRequired: bool, supportedValueTypes?: list<string>, typeDefinition: record}
# --objectRequestOptions shape: {properties: list<string>}
export def "automation-actions create-app" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action_url: string # The URL that will accept an HTTPS request each time workflows executes the custom action.
  --archived-at: int # The date that this custom action was archived, if the custom action is archived. (format: int64)
  functions: list # A list of functions associated with the custom workflow action. — item shape: {functionSource: string, functionType: "PRE_ACTION_EXECUTION"|"PRE_FETCH_OPTIONS"|"POST_FETCH_OPTIONS", id?: string}
  --input-field-dependencies: list # A list of dependencies between the input fields. These configure when the input fields should be visible.
  input_fields: list # The list of input fields to display in this custom action. — item shape: {isRequired: bool, supportedValueTypes?: list<string>, typeDefinition: record}
  labels: record # The user-facing labels for the custom action.
  --object-request-options: record # Configures what properties of the enrolled CRM object are included in the action execution request — shape: {properties: list<string>}
  object_types: list<string> # The object types that this custom action supports.
  --published: oneof<nothing, bool> # Whether this custom action is published to customers.
]: any -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/automation/v4/actions/{app_id}") $auth.query)
  let req_body = {"actionUrl": $action_url, "archivedAt": $archived_at, "functions": $functions, "inputFieldDependencies": $input_field_dependencies, "inputFields": $input_fields, "labels": $labels, "objectRequestOptions": $object_request_options, "objectTypes": $object_types, "published": $published} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Archive a custom action
#
# DELETE /automation/v4/actions/{appId}/{definitionId}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}_archive
export def "automation-actions delete-app-definition-archive" [
  app_id: int
  definition_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}_getById
export def "automation-actions get-app-definition" [
  app_id: int
  definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Whether to include archived custom actions. (default: false)
]: nothing -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  let qp = [(serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"archived": $archived} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a custom action
#
# PATCH /automation/v4/actions/{appId}/{definitionId}
# operationId: patch-/automation/v4/actions/{appId}/{definitionId}_update
# --inputFields item shape: {isRequired: bool, supportedValueTypes?: list<string>, typeDefinition: record}
# --objectRequestOptions shape: {properties: list<string>}
export def "automation-actions update-app-definition" [
  app_id: int
  definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-url: string # The URL that will accept an HTTPS request each time workflows executes the custom action.
  --input-field-dependencies: list # A list of dependencies between the input fields. These configure when the input fields should be visible.
  --input-fields: list # The list of input fields to display in this custom action. — item shape: {isRequired: bool, supportedValueTypes?: list<string>, typeDefinition: record}
  --labels: record # The user-facing labels for the custom action.
  --object-request-options: record # Configures what properties of the enrolled CRM object are included in the action execution request — shape: {properties: list<string>}
  --object-types: list<string> # The object types that this custom action supports.
  --published: oneof<nothing, bool> # Whether this custom action is published to customers.
]: any -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}") $auth.query)
  let req_body = {"actionUrl": $action_url, "inputFieldDependencies": $input_field_dependencies, "inputFields": $input_fields, "labels": $labels, "objectRequestOptions": $object_request_options, "objectTypes": $object_types, "published": $published} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all custom action functions
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions_getPage
export def "automation-actions-functions get-app-definition-page" [
  app_id: int
  definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<functionType: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions") $auth.query)
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

# Delete a custom action function
#
# DELETE /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_archiveByFunctionType
export def "automation-actions-functions delete-app-definition-type-archive-by-type" [
  app_id: int
  definition_id: string
  function_type: string
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
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a custom action function
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_getByFunctionType
export def "automation-actions-functions get-app-definition-type-by-type" [
  app_id: int
  definition_id: string
  function_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<functionSource: string, functionType: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}") $auth.query)
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

# Create or replace a custom action function
#
# PUT /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: put-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_createOrReplaceByFunctionType
export def "automation-actions-functions update-app-definition-type-create-or-by-type" [
  app_id: int
  definition_id: string
  function_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<functionType: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a custom action function
#
# DELETE /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_archive
export def "automation-actions-functions delete-app-definition-type-archive" [
  app_id: int
  definition_id: string
  function_type: string
  function_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  if ($function_id | is-empty) { error make --unspanned { msg: "path parameter 'functionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type), function_id: (encode-path-segment $function_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}/{function_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a custom action function
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_getById
export def "automation-actions-functions get-app-definition-type" [
  app_id: int
  definition_id: string
  function_type: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<functionSource: string, functionType: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  if ($function_id | is-empty) { error make --unspanned { msg: "path parameter 'functionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type), function_id: (encode-path-segment $function_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}/{function_id}") $auth.query)
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

# Create or replace a custom action function
#
# PUT /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: put-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_createOrReplace
export def "automation-actions-functions update-app-definition-type-create-or" [
  app_id: int
  definition_id: string
  function_type: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<functionType: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($function_type | is-empty) { error make --unspanned { msg: "path parameter 'functionType' must be non-empty" } }
  if ($function_id | is-empty) { error make --unspanned { msg: "path parameter 'functionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), function_type: (encode-path-segment $function_type), function_id: (encode-path-segment $function_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/functions/{function_type}/{function_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all revisions for a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}/revisions
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/revisions_getPage
export def "automation-actions-revisions get-app-definition-page" [
  app_id: int
  definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results per page. (format: int32)
  --after: string # The paging cursor token of the last successfully read resource will be returned as the `paging.next.after` JSON property of a paged response containing more results.
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: table<createdAt: string, definition: record, id: string, revisionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/revisions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "after": $after} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a revision for a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}/revisions/{revisionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/revisions/{revisionId}_getById
export def "automation-actions-revisions get-app-definition" [
  app_id: int
  definition_id: string
  revision_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, definition: record<actionUrl: string, archivedAt: int, functions: list<record>, id: string, inputFieldDependencies: list<any>, inputFields: list<record>, labels: record, objectRequestOptions: record<properties: list>, objectTypes: list<string>, published: bool, revisionId: string>, id: string, revisionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($definition_id | is-empty) { error make --unspanned { msg: "path parameter 'definitionId' must be non-empty" } }
  if ($revision_id | is-empty) { error make --unspanned { msg: "path parameter 'revisionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), definition_id: (encode-path-segment $definition_id), revision_id: (encode-path-segment $revision_id)} | format pattern "/automation/v4/actions/{app_id}/{definition_id}/revisions/{revision_id}") $auth.query)
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
