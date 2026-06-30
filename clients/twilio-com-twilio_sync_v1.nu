# Auto-generated client for Twilio - Sync v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_sync_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_SYNC_TOKEN

const BASE_URL = "https://sync.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_SYNC_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://sync.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def bounds-completer [] { ["exclusive" "inclusive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "services list" } } | get name | first)
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

# GET /v1/Services
#
# operationId: ListService
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services
#
# operationId: CreateService
export def "services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-enabled: oneof<nothing, bool> # Whether token identities in the Service must be granted access to Sync objects by using the [Permissions](https://www.twilio.com/docs/sync/api/sync-permissions) resource.
  --friendly-name: string # A string that you assign to describe the resource.
  --reachability-debouncing-enabled: oneof<nothing, bool> # Whether every `endpoint_disconnected` event should occur after a configurable delay. The default is `false`, where the `endpoint_disconnected` event occurs immediately after disconnection. When `true`, intervening reconnections can prevent the `endpoint_disconnected` event.
  --reachability-debouncing-window: int # The reachability event delay in milliseconds if `reachability_debouncing_enabled` = `true`. Must be between 1,000 and 30,000 and defaults to 5,000. This is the number of milliseconds after the last running client disconnects, and a Sync identity is declared offline, before the `webhook_url` is called if all endpoints remain offline. A reconnection from the same identity by any endpoint during this interval prevents the call to `webhook_url`.
  --reachability-webhooks-enabled: oneof<nothing, bool> # Whether the service instance should call `webhook_url` when client endpoints connect to Sync. The default is `false`.
  --webhook-url: string # The URL we should call when Sync objects are manipulated. (format: uri)
  --webhooks-from-rest-enabled: oneof<nothing, bool> # Whether the Service instance should call `webhook_url` when the REST API is used to update Sync objects. The default is `false`.
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  let full_url = (build-url $base "/v1/Services" $auth.query)
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityDebouncingEnabled": $reachability_debouncing_enabled, "ReachabilityDebouncingWindow": $reachability_debouncing_window, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url, "WebhooksFromRestEnabled": $webhooks_from_rest_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# GET /v1/Services/{ServiceSid}/Documents
#
# operationId: ListDocument
export def "services-documents list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Documents") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services/{ServiceSid}/Documents
#
# operationId: CreateDocument
export def "services-documents create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Sync Document stores. Can be up to 16 KiB in length.
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Document expires and is deleted (the Sync Document's time-to-live).
  --unique-name: string # An application-defined string that uniquely identifies the Sync Document
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Documents") $auth.query)
  let req_body = {"Data": $data, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Retrieve a list of all Permissions applying to a Sync Document.
#
# GET /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions
# operationId: ListDocumentPermission
export def "services-documents-permissions list" [
  service_sid: string
  document_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specific Sync Document Permission.
#
# DELETE /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: DeleteDocumentPermission
export def "services-documents-permissions delete" [
  service_sid: string
  document_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}") $auth.query)
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

# Fetch a specific Sync Document Permission.
#
# GET /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: FetchDocumentPermission
export def "services-documents-permissions get" [
  service_sid: string
  document_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}") $auth.query)
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

# Update an identity's access to a specific Sync Document.
#
# POST /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: UpdateDocumentPermission
export def "services-documents-permissions update" [
  service_sid: string
  document_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync Document. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync Document. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can update the Sync Document. Default value is `false`.
]: any -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}") $auth.query)
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# DELETE /v1/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: DeleteDocument
export def "services-documents delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}") $auth.query)
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

# GET /v1/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: FetchDocument
export def "services-documents get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}") $auth.query)
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

# POST /v1/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: UpdateDocument
export def "services-documents update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The If-Match HTTP request header
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Sync Document stores. Can be up to 16 KiB in length.
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Document expires and is deleted (time-to-live).
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}") $auth.query)
  let req_body = {"Data": $data, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/Services/{ServiceSid}/Lists
#
# operationId: ListSyncList
export def "services-lists sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<lists: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Lists") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services/{ServiceSid}/Lists
#
# operationId: CreateSyncList
export def "services-lists create-sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync List expires (time-to-live) and is deleted.
  --ttl: int # Alias for collection_ttl. If both are provided, this value is ignored.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within its Service and it can be up to 320 characters long. The `unique_name` value can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Lists") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: ListSyncListItem
export def "services-lists-items sync" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # How to order the List Items returned by their `index` value. Can be: `asc` (ascending) or `desc` (descending) and the default is ascending.
  --qp-from: string # The `index` of the first Sync List Item resource to read. See also `bounds`.
  --bounds: string@bounds-completer # Whether to include the List Item referenced by the `from` parameter. Can be: `inclusive` to include the List Item referenced by the `from` parameter or `exclusive` to start with the next List Item. The default value is `inclusive`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "Bounds" $bounds "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: CreateSyncListItem
export def "services-lists-items create-sync" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item's parent Sync List expires (time-to-live) and is deleted.
  data: any # A JSON string that represents an arbitrary, schema-less object that the List Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: DeleteSyncListItem
export def "services-lists-items delete-sync" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: FetchSyncListItem
export def "services-lists-items get-sync" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}") $auth.query)
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

# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: UpdateSyncListItem
export def "services-lists-items update-sync" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item's parent Sync List expires (time-to-live) and is deleted. This parameter can only be used when the List Item's `data` or `ttl` is updated in the same request.
  --data: any # A JSON string that represents an arbitrary, schema-less object that the List Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Permissions applying to a Sync List.
#
# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions
# operationId: ListSyncListPermission
export def "services-lists-permissions sync" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specific Sync List Permission.
#
# DELETE /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: DeleteSyncListPermission
export def "services-lists-permissions delete-sync" [
  service_sid: string
  list_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}") $auth.query)
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

# Fetch a specific Sync List Permission.
#
# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: FetchSyncListPermission
export def "services-lists-permissions get-sync" [
  service_sid: string
  list_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}") $auth.query)
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

# Update an identity's access to a specific Sync List.
#
# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: UpdateSyncListPermission
export def "services-lists-permissions update-sync" [
  service_sid: string
  list_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync List. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync List and its Items. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can create, update, and delete Items in the Sync List. Default value is `false`.
]: any -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}") $auth.query)
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# DELETE /v1/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: DeleteSyncList
export def "services-lists delete-sync" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}") $auth.query)
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

# GET /v1/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: FetchSyncList
export def "services-lists get-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}") $auth.query)
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

# POST /v1/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: UpdateSyncList
export def "services-lists update-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync List expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/Services/{ServiceSid}/Maps
#
# operationId: ListSyncMap
export def "services-maps list-sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<maps: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Maps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services/{ServiceSid}/Maps
#
# operationId: CreateSyncMap
export def "services-maps create-sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Map expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both parameters are provided, this value is ignored.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Maps") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: ListSyncMapItem
export def "services-maps-items list-sync" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # How to order the Map Items returned by their `key` value. Can be: `asc` (ascending) or `desc` (descending) and the default is ascending. Map Items are [ordered lexicographically](https://en.wikipedia.org/wiki/Lexicographical_order) by Item key.
  --qp-from: string # The `key` of the first Sync Map Item resource to read. See also `bounds`.
  --bounds: string@bounds-completer # Whether to include the Map Item referenced by the `from` parameter. Can be: `inclusive` to include the Map Item referenced by the `from` parameter or `exclusive` to start with the next Map Item. The default value is `inclusive`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "Bounds" $bounds "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: CreateSyncMapItem
export def "services-maps-items create-sync" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item's parent Sync Map expires (time-to-live) and is deleted.
  data: any # A JSON string that represents an arbitrary, schema-less object that the Map Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item expires (time-to-live) and is deleted.
  key: string # The unique, user-defined key for the Map Item. Can be up to 320 characters long.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Key": $key, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: DeleteSyncMapItem
export def "services-maps-items delete-sync" [
  service_sid: string
  map_sid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: FetchSyncMapItem
export def "services-maps-items get-sync" [
  service_sid: string
  map_sid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}") $auth.query)
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

# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: UpdateSyncMapItem
export def "services-maps-items update-sync" [
  service_sid: string
  map_sid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item's parent Sync Map expires (time-to-live) and is deleted. This parameter can only be used when the Map Item's `data` or `ttl` is updated in the same request.
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Map Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Permissions applying to a Sync Map.
#
# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions
# operationId: ListSyncMapPermission
export def "services-maps-permissions list-sync" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specific Sync Map Permission.
#
# DELETE /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: DeleteSyncMapPermission
export def "services-maps-permissions delete-sync" [
  service_sid: string
  map_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}") $auth.query)
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

# Fetch a specific Sync Map Permission.
#
# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: FetchSyncMapPermission
export def "services-maps-permissions get-sync" [
  service_sid: string
  map_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}") $auth.query)
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

# Update an identity's access to a specific Sync Map.
#
# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: UpdateSyncMapPermission
export def "services-maps-permissions update-sync" [
  service_sid: string
  map_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync Map. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync Map and its Items. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can create, update, and delete Items in the Sync Map. Default value is `false`.
]: any -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}") $auth.query)
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# DELETE /v1/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: DeleteSyncMap
export def "services-maps delete-sync" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}") $auth.query)
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

# GET /v1/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: FetchSyncMap
export def "services-maps get-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}") $auth.query)
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

# POST /v1/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: UpdateSyncMap
export def "services-maps update-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Map expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both parameters are provided, this value is ignored.
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}") $auth.query)
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Streams in a Service Instance.
#
# GET /v1/Services/{ServiceSid}/Streams
# operationId: ListSyncStream
export def "services-streams list-sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, streams: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Streams") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new Stream.
#
# POST /v1/Services/{ServiceSid}/Streams
# operationId: CreateSyncStream
export def "services-streams create-sync" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Stream expires and is deleted (time-to-live).
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within its Service and it can be up to 320 characters long. The `unique_name` value can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Streams") $auth.query)
  let req_body = {"Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete a specific Stream.
#
# DELETE /v1/Services/{ServiceSid}/Streams/{Sid}
# operationId: DeleteSyncStream
export def "services-streams delete-sync" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}") $auth.query)
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

# Fetch a specific Stream.
#
# GET /v1/Services/{ServiceSid}/Streams/{Sid}
# operationId: FetchSyncStream
export def "services-streams get-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}") $auth.query)
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

# Update a specific Stream.
#
# POST /v1/Services/{ServiceSid}/Streams/{Sid}
# operationId: UpdateSyncStream
export def "services-streams update-sync" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Stream expires and is deleted (time-to-live).
]: any -> record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}") $auth.query)
  let req_body = {"Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create a new Stream Message.
#
# POST /v1/Services/{ServiceSid}/Streams/{StreamSid}/Messages
# operationId: CreateStreamMessage
export def "services-streams-messages create" [
  service_sid: string
  stream_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any # A JSON string that represents an arbitrary, schema-less object that makes up the Stream Message body. Can be up to 4 KiB in length.
]: any -> record<data: any, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($stream_sid | is-empty) { error make --unspanned { msg: "path parameter 'StreamSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), stream_sid: (encode-path-segment $stream_sid)} | format pattern "/v1/Services/{service_sid}/Streams/{stream_sid}/Messages") $auth.query)
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Services/{Sid}
#
# operationId: DeleteService
export def "services delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}") $auth.query)
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

# GET /v1/Services/{Sid}
#
# operationId: FetchService
export def "services get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}") $auth.query)
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

# POST /v1/Services/{Sid}
#
# operationId: UpdateService
export def "services update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-enabled: oneof<nothing, bool> # Whether token identities in the Service must be granted access to Sync objects by using the [Permissions](https://www.twilio.com/docs/sync/api/sync-permissions) resource.
  --friendly-name: string # A string that you assign to describe the resource.
  --reachability-debouncing-enabled: oneof<nothing, bool> # Whether every `endpoint_disconnected` event should occur after a configurable delay. The default is `false`, where the `endpoint_disconnected` event occurs immediately after disconnection. When `true`, intervening reconnections can prevent the `endpoint_disconnected` event.
  --reachability-debouncing-window: int # The reachability event delay in milliseconds if `reachability_debouncing_enabled` = `true`. Must be between 1,000 and 30,000 and defaults to 5,000. This is the number of milliseconds after the last running client disconnects, and a Sync identity is declared offline, before the webhook is called if all endpoints remain offline. A reconnection from the same identity by any endpoint during this interval prevents the webhook from being called.
  --reachability-webhooks-enabled: oneof<nothing, bool> # Whether the service instance should call `webhook_url` when client endpoints connect to Sync. The default is `false`.
  --webhook-url: string # The URL we should call when Sync objects are manipulated. (format: uri)
  --webhooks-from-rest-enabled: oneof<nothing, bool> # Whether the Service instance should call `webhook_url` when the REST API is used to update Sync objects. The default is `false`.
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://sync.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}") $auth.query)
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityDebouncingEnabled": $reachability_debouncing_enabled, "ReachabilityDebouncingWindow": $reachability_debouncing_window, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url, "WebhooksFromRestEnabled": $webhooks_from_rest_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
