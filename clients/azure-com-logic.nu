# Auto-generated client for LogicManagementClient v2019-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/logic/2019-05-01/swagger.json
# Auth: --token flag or $env.LOGICMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LOGICMANAGEMENTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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
def key-type-completer [] { ["NotSpecified" "Primary" "Secondary"] }
def track-events-options-completer [] { ["DisableSourceInfoEnrich" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "integration-accounts-list-by-subscription" "integration-service-environments-list-by-subscription" "workflows-list-by-subscription" "integration-accounts-list-by-resource-group" "integration-accounts-delete" "integration-accounts-get" "integration-accounts-update" "integration-accounts-create-or-update" "integration-account-agreements-list" "integration-account-agreements-delete" "integration-account-agreements-get" "integration-account-agreements-create-or-update" "integration-account-agreements-list-content-callback-url" "integration-account-assemblies-list" "integration-account-assemblies-delete" "integration-account-assemblies-get" "integration-account-assemblies-create-or-update" "integration-account-assemblies-list-content-callback-url" "integration-account-batch-configurations-list" "integration-account-batch-configurations-delete" "integration-account-batch-configurations-get" "integration-account-batch-configurations-create-or-update" "integration-account-certificates-list" "integration-account-certificates-delete" "integration-account-certificates-get" "integration-account-certificates-create-or-update" "integration-accounts-list-callback-url" "integration-accounts-list-key-vault-keys" "integration-accounts-log-tracking-events" "integration-account-maps-list" "integration-account-maps-delete" "integration-account-maps-get" "integration-account-maps-create-or-update" "integration-account-maps-list-content-callback-url" "integration-account-partners-list" "integration-account-partners-delete" "integration-account-partners-get" "integration-account-partners-create-or-update" "integration-account-partners-list-content-callback-url" "integration-accounts-regenerate-access-key" "integration-account-schemas-list" "integration-account-schemas-delete" "integration-account-schemas-get" "integration-account-schemas-create-or-update" "integration-account-schemas-list-content-callback-url" "integration-account-sessions-list" "integration-account-sessions-delete" "integration-account-sessions-get" "integration-account-sessions-create-or-update" "workflows-validate-by-location" "workflows-list-by-resource-group" "workflows-delete" "workflows-get" "workflows-update" "workflows-create-or-update" "workflows-disable" "workflows-enable" "workflows-generate-upgraded-definition" "workflows-list-callback-url" "workflows-list-swagger" "workflows-move" "workflows-regenerate-access-key" "workflow-runs-list" "workflow-runs-get" "workflow-run-actions-list" "workflow-run-actions-get" "workflow-run-actions-list-expression-traces" "workflow-run-action-repetitions-list" "workflow-run-action-repetitions-get" "workflow-run-action-repetitions-list-expression-traces" "workflow-run-action-repetitions-request-histories-list" "workflow-run-action-repetitions-request-histories-get" "workflow-run-action-request-histories-list" "workflow-run-action-request-histories-get" "workflow-run-action-scope-repetitions-list" "workflow-run-action-scope-repetitions-get" "workflow-runs-cancel" "workflow-run-operations-get" "workflow-triggers-list" "workflow-triggers-get" "workflow-trigger-histories-list" "workflow-trigger-histories-get" "workflow-trigger-histories-resubmit" "workflow-triggers-list-callback-url" "workflow-triggers-reset" "workflow-triggers-run" "workflow-triggers-get-schema-json" "workflow-triggers-set-state" "workflows-validate-by-resource-group" "workflow-versions-list" "workflow-versions-get" "workflow-version-triggers-list-callback-url" "integration-service-environments-list-by-resource-group" "integration-service-environments-delete" "integration-service-environments-get" "integration-service-environments-update" "integration-service-environments-create-or-update" "integration-service-environment-network-health-get" "integration-service-environment-managed-apis-list" "integration-service-environment-managed-apis-delete" "integration-service-environment-managed-apis-get" "integration-service-environment-managed-apis-put" "integration-service-environment-managed-api-operations-list" "integration-service-environments-restart" "integration-service-environment-skus-list" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Lists all of the available Logic REST API operations.
#
# GET /providers/Microsoft.Logic/operations
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<display: record, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Logic/operations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration accounts by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationAccounts
# operationId: IntegrationAccounts_ListBySubscription
export def "integration-accounts-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/integrationAccounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of integration service environments by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationServiceEnvironments
# operationId: IntegrationServiceEnvironments_ListBySubscription
export def "integration-service-environments-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/integrationServiceEnvironments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of workflows by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/workflows
# operationId: Workflows_ListBySubscription
export def "workflows-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/workflows") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of integration accounts by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts
# operationId: IntegrationAccounts_ListByResourceGroup
export def "integration-accounts-list-by-resource-group" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Delete
export def "integration-accounts-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Get
export def "integration-accounts-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates an integration account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Update
export def "integration-accounts-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_CreateOrUpdate
export def "integration-accounts-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account agreements.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements
# operationId: IntegrationAccountAgreements_List
export def "integration-account-agreements-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: AgreementType.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account agreement.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_Delete
export def "integration-account-agreements-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($agreement_name | is-empty) { error make --unspanned { msg: "path parameter 'agreementName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account agreement.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_Get
export def "integration-account-agreements-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($agreement_name | is-empty) { error make --unspanned { msg: "path parameter 'agreementName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account agreement.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_CreateOrUpdate
export def "integration-account-agreements-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account agreement properties. — shape: {agreementType: "NotSpecified"|"AS2"|"X12"|"Edifact", content: record, guestIdentity: record, guestPartner: string, hostIdentity: record, hostPartner: string, metadata?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($agreement_name | is-empty) { error make --unspanned { msg: "path parameter 'agreementName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}/listContentCallbackUrl
# operationId: IntegrationAccountAgreements_ListContentCallbackUrl
export def "integration-account-agreements-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($agreement_name | is-empty) { error make --unspanned { msg: "path parameter 'agreementName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}/listContentCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List the assemblies for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies
# operationId: IntegrationAccountAssemblies_List
export def "integration-account-assemblies-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete an assembly for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_Delete
export def "integration-account-assemblies-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($assembly_artifact_name | is-empty) { error make --unspanned { msg: "path parameter 'assemblyArtifactName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get an assembly for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_Get
export def "integration-account-assemblies-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($assembly_artifact_name | is-empty) { error make --unspanned { msg: "path parameter 'assemblyArtifactName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create or update an assembly for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_CreateOrUpdate
export def "integration-account-assemblies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The assembly properties definition. — shape: {assemblyCulture?: string, assemblyName: string, assemblyPublicKeyToken?: string, assemblyVersion?: string, content?: any, contentLink?: record, contentType?: string, changedTime?: string, createdTime?: string, metadata?: any}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($assembly_artifact_name | is-empty) { error make --unspanned { msg: "path parameter 'assemblyArtifactName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the content callback url for an integration account assembly.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}/listContentCallbackUrl
# operationId: IntegrationAccountAssemblies_ListContentCallbackUrl
export def "integration-account-assemblies-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($assembly_artifact_name | is-empty) { error make --unspanned { msg: "path parameter 'assemblyArtifactName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}/listContentCallbackUrl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List the batch configurations for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations
# operationId: IntegrationAccountBatchConfigurations_List
export def "integration-account-batch-configurations-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete a batch configuration for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_Delete
export def "integration-account-batch-configurations-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($batch_configuration_name | is-empty) { error make --unspanned { msg: "path parameter 'batchConfigurationName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get a batch configuration for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_Get
export def "integration-account-batch-configurations-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($batch_configuration_name | is-empty) { error make --unspanned { msg: "path parameter 'batchConfigurationName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create or update a batch configuration for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_CreateOrUpdate
export def "integration-account-batch-configurations-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The batch configuration properties definition. — shape: {batchGroupName: string, changedTime?: string, createdTime?: string, releaseCriteria: record, metadata?: any}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($batch_configuration_name | is-empty) { error make --unspanned { msg: "path parameter 'batchConfigurationName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account certificates.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates
# operationId: IntegrationAccountCertificates_List
export def "integration-account-certificates-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_Delete
export def "integration-account-certificates-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificateName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_Get
export def "integration-account-certificates-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificateName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account certificate.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_CreateOrUpdate
export def "integration-account-certificates-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account certificate properties. — shape: {key?: record, metadata?: record, publicCertificate?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificateName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets the integration account callback URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listCallbackUrl
# operationId: IntegrationAccounts_ListCallbackUrl
export def "integration-accounts-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/listCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets the integration account's Key Vault keys.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listKeyVaultKeys
# operationId: IntegrationAccounts_ListKeyVaultKeys
export def "integration-accounts-list-key-vault-keys" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  key_vault: record # The key vault reference. — shape: {id?: string}
  --skip-token: string # The skip token.
]: any -> oneof<record<skipToken: string, value: table<attributes: record, kid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/listKeyVaultKeys") $qp $auth.query)
  let req_body = {"keyVault": $key_vault, "skipToken": $skip_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Logs the integration account's tracking events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/logTrackingEvents
# operationId: IntegrationAccounts_LogTrackingEvents
export def "integration-accounts-log-tracking-events" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  events: list # The events. — item shape: {error?: record, eventLevel: "LogAlways"|"Critical"|"Error"|"Warning"|"Informational"|"Verbose", eventTime: string, ... (1 more fields)}
  source_type: string # The source type.
  --track-events-options: string@track-events-options-completer # The track events operation options.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/logTrackingEvents") $qp $auth.query)
  let req_body = {"events": $events, "sourceType": $source_type, "trackEventsOptions": $track_events_options} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account maps.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps
# operationId: IntegrationAccountMaps_List
export def "integration-account-maps-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: MapType.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account map.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_Delete
export def "integration-account-maps-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'mapName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account map.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_Get
export def "integration-account-maps-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'mapName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account map.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_CreateOrUpdate
export def "integration-account-maps-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account map. — shape: {content?: string, contentLink?: record, contentType?: string, mapType: "NotSpecified"|"Xslt"|"Xslt20"|"Xslt30"|"Liquid", metadata?: record, parametersSchema?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'mapName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}/listContentCallbackUrl
# operationId: IntegrationAccountMaps_ListContentCallbackUrl
export def "integration-account-maps-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'mapName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}/listContentCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account partners.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners
# operationId: IntegrationAccountPartners_List
export def "integration-account-partners-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: PartnerType.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account partner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_Delete
export def "integration-account-partners-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($partner_name | is-empty) { error make --unspanned { msg: "path parameter 'partnerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account partner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_Get
export def "integration-account-partners-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($partner_name | is-empty) { error make --unspanned { msg: "path parameter 'partnerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account partner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_CreateOrUpdate
export def "integration-account-partners-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account partner properties. — shape: {content: record, metadata?: record, partnerType: "NotSpecified"|"B2B"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($partner_name | is-empty) { error make --unspanned { msg: "path parameter 'partnerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}/listContentCallbackUrl
# operationId: IntegrationAccountPartners_ListContentCallbackUrl
export def "integration-account-partners-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($partner_name | is-empty) { error make --unspanned { msg: "path parameter 'partnerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}/listContentCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Regenerates the integration account access key.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/regenerateAccessKey
# operationId: IntegrationAccounts_RegenerateAccessKey
export def "integration-accounts-regenerate-access-key" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
]: any -> oneof<record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/regenerateAccessKey") $qp $auth.query)
  let req_body = {"keyType": $key_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account schemas.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas
# operationId: IntegrationAccountSchemas_List
export def "integration-account-schemas-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: SchemaType.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account schema.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_Delete
export def "integration-account-schemas-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account schema.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_Get
export def "integration-account-schemas-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account schema.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_CreateOrUpdate
export def "integration-account-schemas-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account schema properties. — shape: {content?: string, contentLink?: record, contentType?: string, documentName?: string, fileName?: string, metadata?: record, schemaType: "NotSpecified"|"Xml", targetNamespace?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}/listContentCallbackUrl
# operationId: IntegrationAccountSchemas_ListContentCallbackUrl
export def "integration-account-schemas-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}/listContentCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration account sessions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions
# operationId: IntegrationAccountSessions_List
export def "integration-account-sessions-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: ChangedTime.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration account session.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_Delete
export def "integration-account-sessions-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($session_name | is-empty) { error make --unspanned { msg: "path parameter 'sessionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration account session.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_Get
export def "integration-account-sessions-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($session_name | is-empty) { error make --unspanned { msg: "path parameter 'sessionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration account session.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_CreateOrUpdate
export def "integration-account-sessions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account session properties. — shape: {content?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($integration_account_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationAccountName' must be non-empty" } }
  if ($session_name | is-empty) { error make --unspanned { msg: "path parameter 'sessionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Validates the workflow definition.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/locations/{location}/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByLocation
export def "workflows-validate-by-location" [
  subscription_id: string
  resource_group_name: string
  location: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), location: (encode-path-segment $location), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/locations/{location}/workflows/{workflow_name}/validate") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflows by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows
# operationId: Workflows_ListByResourceGroup
export def "workflows-list-by-resource-group" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a workflow.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Delete
export def "workflows-delete" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets a workflow.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Get
export def "workflows-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates a workflow.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Update
export def "workflows-update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates a workflow.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_CreateOrUpdate
export def "workflows-create-or-update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Disables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/disable
# operationId: Workflows_Disable
export def "workflows-disable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/disable") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Enables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/enable
# operationId: Workflows_Enable
export def "workflows-enable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/enable") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Generates the upgraded definition for a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/generateUpgradedDefinition
# operationId: Workflows_GenerateUpgradedDefinition
export def "workflows-generate-upgraded-definition" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --target-schema-version: string # The target schema version.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/generateUpgradedDefinition") $qp $auth.query)
  let req_body = {"targetSchemaVersion": $target_schema_version} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the workflow callback Url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listCallbackUrl
# operationId: Workflows_ListCallbackUrl
export def "workflows-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/listCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets an OpenAPI definition for the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listSwagger
# operationId: Workflows_ListSwagger
export def "workflows-list-swagger" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/listSwagger") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Moves an existing workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/move
# operationId: Workflows_Move
export def "workflows-move" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/move") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Regenerates the callback URL access key for request triggers.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/regenerateAccessKey
# operationId: Workflows_RegenerateAccessKey
export def "workflows-regenerate-access-key" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/regenerateAccessKey") $qp $auth.query)
  let req_body = {"keyType": $key_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflow runs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs
# operationId: WorkflowRuns_List
export def "workflow-runs-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> oneof<record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a workflow run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}
# operationId: WorkflowRuns_Get
export def "workflow-runs-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflow run actions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions
# operationId: WorkflowRunActions_List
export def "workflow-run-actions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status.
]: nothing -> oneof<record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a workflow run action.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}
# operationId: WorkflowRunActions_Get
export def "workflow-run-actions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, startTime: string, status: string, trackedProperties: record, trackingId: string>, type: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/listExpressionTraces
# operationId: WorkflowRunActions_ListExpressionTraces
export def "workflow-run-actions-list-expression-traces" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/listExpressionTraces") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get all of a workflow run action repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions
# operationId: WorkflowRunActionRepetitions_List
export def "workflow-run-action-repetitions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get a workflow run action repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}
# operationId: WorkflowRunActionRepetitions_Get
export def "workflow-run-action-repetitions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($repetition_name | is-empty) { error make --unspanned { msg: "path parameter 'repetitionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/listExpressionTraces
# operationId: WorkflowRunActionRepetitions_ListExpressionTraces
export def "workflow-run-action-repetitions-list-expression-traces" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($repetition_name | is-empty) { error make --unspanned { msg: "path parameter 'repetitionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/listExpressionTraces") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories
# operationId: WorkflowRunActionRepetitionsRequestHistories_List
export def "workflow-run-action-repetitions-request-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($repetition_name | is-empty) { error make --unspanned { msg: "path parameter 'repetitionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/requestHistories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories/{requestHistoryName}
# operationId: WorkflowRunActionRepetitionsRequestHistories_Get
export def "workflow-run-action-repetitions-request-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($repetition_name | is-empty) { error make --unspanned { msg: "path parameter 'repetitionName' must be non-empty" } }
  if ($request_history_name | is-empty) { error make --unspanned { msg: "path parameter 'requestHistoryName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name), request_history_name: (encode-path-segment $request_history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/requestHistories/{request_history_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories
# operationId: WorkflowRunActionRequestHistories_List
export def "workflow-run-action-request-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/requestHistories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories/{requestHistoryName}
# operationId: WorkflowRunActionRequestHistories_Get
export def "workflow-run-action-request-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($request_history_name | is-empty) { error make --unspanned { msg: "path parameter 'requestHistoryName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), request_history_name: (encode-path-segment $request_history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/requestHistories/{request_history_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List the workflow run action scoped repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions
# operationId: WorkflowRunActionScopeRepetitions_List
export def "workflow-run-action-scope-repetitions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/scopeRepetitions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get a workflow run action scoped repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions/{repetitionName}
# operationId: WorkflowRunActionScopeRepetitions_Get
export def "workflow-run-action-scope-repetitions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  if ($repetition_name | is-empty) { error make --unspanned { msg: "path parameter 'repetitionName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/scopeRepetitions/{repetition_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Cancels a workflow run.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/cancel
# operationId: WorkflowRuns_Cancel
export def "workflow-runs-cancel" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/cancel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets an operation for a run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/operations/{operationId}
# operationId: WorkflowRunOperations_Get
export def "workflow-run-operations-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($run_name | is-empty) { error make --unspanned { msg: "path parameter 'runName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/operations/{operation_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflow triggers.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers
# operationId: WorkflowTriggers_List
export def "workflow-triggers-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation.
]: nothing -> oneof<record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a workflow trigger.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}
# operationId: WorkflowTriggers_Get
export def "workflow-triggers-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<name: string, properties: record<changedTime: string, createdTime: string, lastExecutionTime: string, nextExecutionTime: string, provisioningState: string, recurrence: record<endTime: string, frequency: string, interval: int, schedule: record, startTime: string, timeZone: string>, state: string, status: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflow trigger histories.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories
# operationId: WorkflowTriggerHistories_List
export def "workflow-trigger-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> oneof<record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a workflow trigger history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}
# operationId: WorkflowTriggerHistories_Get
export def "workflow-trigger-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, fired: bool, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, run: record<id: string, name: string, type: string>, startTime: string, status: string, trackingId: string>, type: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($history_name | is-empty) { error make --unspanned { msg: "path parameter 'historyName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name), history_name: (encode-path-segment $history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories/{history_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Resubmits a workflow run based on the trigger history.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}/resubmit
# operationId: WorkflowTriggerHistories_Resubmit
export def "workflow-trigger-histories-resubmit" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($history_name | is-empty) { error make --unspanned { msg: "path parameter 'historyName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name), history_name: (encode-path-segment $history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories/{history_name}/resubmit") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Get the callback URL for a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/listCallbackUrl
# operationId: WorkflowTriggers_ListCallbackUrl
export def "workflow-triggers-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/listCallbackUrl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Resets a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/reset
# operationId: WorkflowTriggers_Reset
export def "workflow-triggers-reset" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/reset") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Runs a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/run
# operationId: WorkflowTriggers_Run
export def "workflow-triggers-run" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/run") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
}

# Get the trigger schema as JSON.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/schemas/json
# operationId: WorkflowTriggers_GetSchemaJson
export def "workflow-triggers-get-schema-json" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<content: string, title: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/schemas/json") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Sets the state of a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/setState
# operationId: WorkflowTriggers_SetState
export def "workflow-triggers-set-state" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  source: record # The workflow trigger. — shape: {properties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/setState") $qp $auth.query)
  let req_body = {"source": $source} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Validates the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByResourceGroup
export def "workflows-validate-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/validate") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of workflow versions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions
# operationId: WorkflowVersions_List
export def "workflow-versions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a workflow version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}
# operationId: WorkflowVersions_Get
export def "workflow-versions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, integrationAccount: record<id: string, name: string, type: string>, parameters: record, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), version_id: (encode-path-segment $version_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions/{version_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get the callback url for a trigger of a workflow version.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}/triggers/{triggerName}/listCallbackUrl
# operationId: WorkflowVersionTriggers_ListCallbackUrl
export def "workflow-version-triggers-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  version_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workflow_name | is-empty) { error make --unspanned { msg: "path parameter 'workflowName' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), version_id: (encode-path-segment $version_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions/{version_id}/triggers/{trigger_name}/listCallbackUrl") $qp $auth.query)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration service environments by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments
# operationId: IntegrationServiceEnvironments_ListByResourceGroup
export def "integration-service-environments-list-by-resource-group" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an integration service environment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Delete
export def "integration-service-environments-delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets an integration service environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Get
export def "integration-service-environments-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates an integration service environment.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Update
export def "integration-service-environments-update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Creates or updates an integration service environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_CreateOrUpdate
export def "integration-service-environments-create-or-update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets the integration service environment network health.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/health/network
# operationId: IntegrationServiceEnvironmentNetworkHealth_Get
export def "integration-service-environment-network-health-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/health/network") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets the integration service environment managed Apis.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis
# operationId: IntegrationServiceEnvironmentManagedApis_List
export def "integration-service-environment-managed-apis-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Deletes the integration service environment managed Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Delete
export def "integration-service-environment-managed-apis-delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_name | is-empty) { error make --unspanned { msg: "path parameter 'apiName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Gets the integration service environment managed Api.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Get
export def "integration-service-environment-managed-apis-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_name | is-empty) { error make --unspanned { msg: "path parameter 'apiName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Puts the integration service environment managed Api.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Put
export def "integration-service-environment-managed-apis-put" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_name | is-empty) { error make --unspanned { msg: "path parameter 'apiName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}

# Gets the managed Api operations.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}/apiOperations
# operationId: IntegrationServiceEnvironmentManagedApiOperations_List
export def "integration-service-environment-managed-api-operations-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_name | is-empty) { error make --unspanned { msg: "path parameter 'apiName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}/apiOperations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Restarts an integration service environment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/restart
# operationId: IntegrationServiceEnvironments_Restart
export def "integration-service-environments-restart" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/restart") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets a list of integration service environment Skus.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/skus
# operationId: IntegrationServiceEnvironmentSkus_List
export def "integration-service-environment-skus-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($integration_service_environment_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationServiceEnvironmentName' must be non-empty" } }
  if ($api_version == null) { error make --unspanned { msg: "required query parameter 'api-version' missing: pass --api-version" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/skus") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
