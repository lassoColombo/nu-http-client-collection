# Auto-generated client for Twilio - Sync v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_sync_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_SYNC_TOKEN

const BASE_URL = "https://sync.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_SYNC_TOKEN | default "" }
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
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base "/v1/Services")
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityDebouncingEnabled": $reachability_debouncing_enabled, "ReachabilityDebouncingWindow": $reachability_debouncing_window, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url, "WebhooksFromRestEnabled": $webhooks_from_rest_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Documents"))
  let req_body = {"Data": $data, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Documents/{sid}"))
  let req_body = {"Data": $data, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Lists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Lists"))
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items"))
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Lists/{sid}"))
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Maps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Maps"))
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items"))
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Key": $key, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let req_body = {"CollectionTtl": $collection_ttl, "Data": $data, "ItemTtl": $item_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/v1/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Maps/{sid}"))
  let req_body = {"CollectionTtl": $collection_ttl, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Streams") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Streams"))
  let req_body = {"Ttl": $ttl, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Streams/{sid}"))
  let req_body = {"Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), stream_sid: (encode-path-segment $stream_sid)} | format pattern "/v1/Services/{service_sid}/Streams/{stream_sid}/Messages"))
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityDebouncingEnabled": $reachability_debouncing_enabled, "ReachabilityDebouncingWindow": $reachability_debouncing_window, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url, "WebhooksFromRestEnabled": $webhooks_from_rest_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
