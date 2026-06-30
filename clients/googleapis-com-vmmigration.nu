# Auto-generated client for VM Migration API vv1alpha1
# Source: https://api.apis.guru/v2/specs/googleapis.com/vmmigration/v1alpha1/openapi.json
# Auth: --token flag or $env.VM_MIGRATION_API_TOKEN

const BASE_URL = "https://vmmigration.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VM_MIGRATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

def base-url-completer [] { ["https://vmmigration.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def view-completer [] { ["BASIC" "FULL" "UTILIZATION_REPORT_VIEW_UNSPECIFIED"] }
def view-completer-1 [] { ["MIGRATING_VM_VIEW_BASIC" "MIGRATING_VM_VIEW_FULL" "MIGRATING_VM_VIEW_UNSPECIFIED"] }
def time-frame-completer [] { ["MONTH" "TIME_FRAME_UNSPECIFIED" "WEEK" "YEAR"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1alpha1 create-upgrade-appliance" } } | get name | first)
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

# Upgrades the appliance relate to this DatacenterConnector to the in-place updateable version.
#
# POST /v1alpha1/{datacenterConnector}:upgradeAppliance
# operationId: vmmigration.projects.locations.sources.datacenterConnectors.upgradeAppliance
export def "v1alpha1 create-upgrade-appliance" [
  datacenter_connector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes after the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($datacenter_connector | is-empty) { error make --unspanned { msg: "path parameter 'datacenterConnector' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({datacenter_connector: (encode-path-segment $datacenter_connector)} | format pattern "/v1alpha1/{datacenter_connector}:upgradeAppliance") $qp $auth.query)
  let req_body = {"requestId": $request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds a MigratingVm to a Group.
#
# POST /v1alpha1/{group}:addGroupMigration
# operationId: vmmigration.projects.locations.groups.addGroupMigration
export def "v1alpha1 create-migration" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --migrating-vm: string # The full path name of the MigratingVm to add.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group: (encode-path-segment $group)} | format pattern "/v1alpha1/{group}:addGroupMigration") $qp $auth.query)
  let req_body = {"migratingVm": $migrating_vm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a MigratingVm from a Group.
#
# POST /v1alpha1/{group}:removeGroupMigration
# operationId: vmmigration.projects.locations.groups.removeGroupMigration
export def "v1alpha1 delete-migration" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --migrating-vm: string # The MigratingVm to remove.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group: (encode-path-segment $group)} | format pattern "/v1alpha1/{group}:removeGroupMigration") $qp $auth.query)
  let req_body = {"migratingVm": $migrating_vm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Marks a migration as completed, deleting migration resources that are no longer being used. Only applicable after cutover is done.
#
# POST /v1alpha1/{migratingVm}:finalizeMigration
# operationId: vmmigration.projects.locations.sources.migratingVms.finalizeMigration
export def "v1alpha1 finalize-migration" [
  migrating_vm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($migrating_vm | is-empty) { error make --unspanned { msg: "path parameter 'migratingVm' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({migrating_vm: (encode-path-segment $migrating_vm)} | format pattern "/v1alpha1/{migrating_vm}:finalizeMigration") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Pauses a migration for a VM. If cycle tasks are running they will be cancelled, preserving source task data. Further replication cycles will not be triggered while the VM is paused.
#
# POST /v1alpha1/{migratingVm}:pauseMigration
# operationId: vmmigration.projects.locations.sources.migratingVms.pauseMigration
export def "v1alpha1 pause-migration" [
  migrating_vm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($migrating_vm | is-empty) { error make --unspanned { msg: "path parameter 'migratingVm' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({migrating_vm: (encode-path-segment $migrating_vm)} | format pattern "/v1alpha1/{migrating_vm}:pauseMigration") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Resumes a migration for a VM. When called on a paused migration, will start the process of uploading data and creating snapshots; when called on a completed cut-over migration, will update the migration to active state and start the process of uploading data and creating snapshots.
#
# POST /v1alpha1/{migratingVm}:resumeMigration
# operationId: vmmigration.projects.locations.sources.migratingVms.resumeMigration
export def "v1alpha1 create-resume-migration" [
  migrating_vm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($migrating_vm | is-empty) { error make --unspanned { msg: "path parameter 'migratingVm' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({migrating_vm: (encode-path-segment $migrating_vm)} | format pattern "/v1alpha1/{migrating_vm}:resumeMigration") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts migration for a VM. Starts the process of uploading data and creating snapshots, in replication cycles scheduled by the policy.
#
# POST /v1alpha1/{migratingVm}:startMigration
# operationId: vmmigration.projects.locations.sources.migratingVms.startMigration
export def "v1alpha1 start-migration" [
  migrating_vm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($migrating_vm | is-empty) { error make --unspanned { msg: "path parameter 'migratingVm' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({migrating_vm: (encode-path-segment $migrating_vm)} | format pattern "/v1alpha1/{migrating_vm}:startMigration") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a single TargetProject. NOTE: TargetProject is a global resource; hence the only supported value for location is `global`.
#
# DELETE /v1alpha1/{name}
# operationId: vmmigration.projects.locations.targetProjects.delete
export def "v1alpha1 delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # Optional. A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes after the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets details of a single TargetProject. NOTE: TargetProject is a global resource; hence the only supported value for location is `global`.
#
# GET /v1alpha1/{name}
# operationId: vmmigration.projects.locations.targetProjects.get
export def "v1alpha1 get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer # Optional. The level of details of the report. Defaults to FULL
]: nothing -> record<createTime: string, description: string, name: string, project: string, updateTime: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the parameters of a single TargetProject. NOTE: TargetProject is a global resource; hence the only supported value for location is `global`.
#
# PATCH /v1alpha1/{name}
# operationId: vmmigration.projects.locations.targetProjects.patch
export def "v1alpha1 update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --update-mask: string # Field mask is used to specify the fields to be overwritten in the TargetProject resource by the update. The fields specified in the update_mask are relative to the resource, not the full request. A field will be overwritten if it is in the mask. If the user does not provide a mask then all fields will be overwritten.
  --description: string # The target project's description.
  --project: string # The target project ID (number) or project name.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}") $qp $auth.query)
  let req_body = {"description": $description, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id, "updateMask": $update_mask} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists information about the supported locations for this service.
#
# GET /v1alpha1/{name}/locations
# operationId: vmmigration.projects.locations.list
export def "v1alpha1-locations list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like `"displayName=tokyo"`, and is documented in more detail in [AIP-160](https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the `next_page_token` field in the response. Send that page token to receive the subsequent page.
]: nothing -> record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}/locations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1alpha1/{name}/operations
# operationId: vmmigration.projects.locations.operations.list
export def "v1alpha1-operations list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}/operations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiates the cancellation of a running cutover job.
#
# POST /v1alpha1/{name}:cancel
# operationId: vmmigration.projects.locations.sources.migratingVms.cutoverJobs.cancel
export def "v1alpha1 cancel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1alpha1/{name}:cancel") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists CloneJobs of a given migrating VM.
#
# GET /v1alpha1/{parent}/cloneJobs
# operationId: vmmigration.projects.locations.sources.migratingVms.cloneJobs.list
export def "v1alpha1-clone-jobs list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of clone jobs to return. The service may return fewer than this value. If unspecified, at most 500 clone jobs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListCloneJobs` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListCloneJobs` must match the call that provided the page token.
]: nothing -> record<cloneJobs: table<computeEngineTargetDetails: record, computeEngineVmDetails: record, createTime: string, endTime: string, error: record, name: string, state: string, stateTime: string, steps: list, targetDetails: record>, nextPageToken: string, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/cloneJobs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiates a Clone of a specific migrating VM.
#
# POST /v1alpha1/{parent}/cloneJobs
# operationId: vmmigration.projects.locations.sources.migratingVms.cloneJobs.create
# --computeEngineTargetDetails shape: {additionalLicenses?: list<string>, appliedLicense?: record, bootOption?: "COMPUTE_ENGINE_BOOT_OPTION_UNSPECIFIED"|"COMPUTE_ENGINE_BOOT_OPTION_EFI"|"COMPUTE_ENGINE_BOOT_OPTION_BIOS", computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, ... (11 more fields)}
# --computeEngineVmDetails shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
# --error shape: {code?: int, details?: list, message?: string}
# --steps item shape: {adaptingOs?: record, endTime?: string, instantiatingMigratedVm?: record, preparingVmDisks?: record, startTime?: string}
# --targetDetails shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
export def "v1alpha1-clone-jobs create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clone-job-id: string # Required. The clone job identifier.
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --compute-engine-target-details: record # ComputeEngineTargetDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {additionalLicenses?: list<string>, appliedLicense?: record, bootOption?: "COMPUTE_ENGINE_BOOT_OPTION_UNSPECIFIED"|"COMPUTE_ENGINE_BOOT_OPTION_EFI"|"COMPUTE_ENGINE_BOOT_OPTION_BIOS", computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, ... (11 more fields)}
  --compute-engine-vm-details: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --target-details: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "cloneJobId" $clone_job_id "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/cloneJobs") $qp $auth.query)
  let req_body = {"computeEngineTargetDetails": $compute_engine_target_details, "computeEngineVmDetails": $compute_engine_vm_details, "error": $body_error, "targetDetails": $target_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "cloneJobId": $clone_job_id, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists CutoverJobs of a given migrating VM.
#
# GET /v1alpha1/{parent}/cutoverJobs
# operationId: vmmigration.projects.locations.sources.migratingVms.cutoverJobs.list
export def "v1alpha1-cutover-jobs list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of cutover jobs to return. The service may return fewer than this value. If unspecified, at most 500 cutover jobs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListCutoverJobs` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListCutoverJobs` must match the call that provided the page token.
]: nothing -> record<cutoverJobs: table<computeEngineTargetDetails: record, computeEngineVmDetails: record, createTime: string, endTime: string, error: record, name: string, progress: int, progressPercent: int, state: string, stateMessage: string, stateTime: string, steps: list, targetDetails: record>, nextPageToken: string, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/cutoverJobs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiates a Cutover of a specific migrating VM. The returned LRO is completed when the cutover job resource is created and the job is initiated.
#
# POST /v1alpha1/{parent}/cutoverJobs
# operationId: vmmigration.projects.locations.sources.migratingVms.cutoverJobs.create
# --computeEngineTargetDetails shape: {additionalLicenses?: list<string>, appliedLicense?: record, bootOption?: "COMPUTE_ENGINE_BOOT_OPTION_UNSPECIFIED"|"COMPUTE_ENGINE_BOOT_OPTION_EFI"|"COMPUTE_ENGINE_BOOT_OPTION_BIOS", computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, ... (11 more fields)}
# --computeEngineVmDetails shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
# --error shape: {code?: int, details?: list, message?: string}
# --steps item shape: {endTime?: string, finalSync?: record, instantiatingMigratedVm?: record, preparingVmDisks?: record, previousReplicationCycle?: record, shuttingDownSourceVm?: record, startTime?: string}
# --targetDetails shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
export def "v1alpha1-cutover-jobs create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cutover-job-id: string # Required. The cutover job identifier.
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --compute-engine-target-details: record # ComputeEngineTargetDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {additionalLicenses?: list<string>, appliedLicense?: record, bootOption?: "COMPUTE_ENGINE_BOOT_OPTION_UNSPECIFIED"|"COMPUTE_ENGINE_BOOT_OPTION_EFI"|"COMPUTE_ENGINE_BOOT_OPTION_BIOS", computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, ... (11 more fields)}
  --compute-engine-vm-details: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --target-details: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "cutoverJobId" $cutover_job_id "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/cutoverJobs") $qp $auth.query)
  let req_body = {"computeEngineTargetDetails": $compute_engine_target_details, "computeEngineVmDetails": $compute_engine_vm_details, "error": $body_error, "targetDetails": $target_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "cutoverJobId": $cutover_job_id, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists DatacenterConnectors in a given Source.
#
# GET /v1alpha1/{parent}/datacenterConnectors
# operationId: vmmigration.projects.locations.sources.datacenterConnectors.list
export def "v1alpha1-datacenter-connectors list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of connectors to return. The service may return fewer than this value. If unspecified, at most 500 sources will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListDatacenterConnectors` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListDatacenterConnectors` must match the call that provided the page token.
]: nothing -> record<datacenterConnectors: table<applianceInfrastructureVersion: string, applianceSoftwareVersion: string, availableVersions: record, bucket: string, createTime: string, error: record, name: string, registrationId: string, serviceAccount: string, state: string, stateTime: string, updateTime: string, upgradeStatus: record, version: string>, nextPageToken: string, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/datacenterConnectors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DatacenterConnector in a given Source.
#
# POST /v1alpha1/{parent}/datacenterConnectors
# operationId: vmmigration.projects.locations.sources.datacenterConnectors.create
# --availableVersions shape: {inPlaceUpdate?: record, newDeployableAppliance?: record}
# --error shape: {code?: int, details?: list, message?: string}
# --upgradeStatus shape: {error?: record, previousVersion?: string, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"FAILED"|"SUCCEEDED", version?: string}
export def "v1alpha1-datacenter-connectors create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --datacenter-connector-id: string # Required. The datacenterConnector identifier.
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --available-versions: record # Holds informatiom about the available versions for upgrade. — shape: {inPlaceUpdate?: record, newDeployableAppliance?: record}
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --registration-id: string # Immutable. A unique key for this connector. This key is internal to the OVA connector and is supplied with its creation during the registration process and can not be modified.
  --service-account: string # The service account to use in the connector when communicating with the cloud.
  --upgrade-status: record # UpgradeStatus contains information about upgradeAppliance operation. — shape: {error?: record, previousVersion?: string, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"FAILED"|"SUCCEEDED", version?: string}
  --version: string # The version running in the DatacenterConnector. This is supplied by the OVA connector during the registration process and can not be modified.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "datacenterConnectorId" $datacenter_connector_id "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/datacenterConnectors") $qp $auth.query)
  let req_body = {"availableVersions": $available_versions, "error": $body_error, "registrationId": $registration_id, "serviceAccount": $service_account, "upgradeStatus": $upgrade_status, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "datacenterConnectorId": $datacenter_connector_id, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists Groups in a given project and location.
#
# GET /v1alpha1/{parent}/groups
# operationId: vmmigration.projects.locations.groups.list
export def "v1alpha1-groups list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of groups to return. The service may return fewer than this value. If unspecified, at most 500 groups will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListGroups` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListGroups` must match the call that provided the page token.
]: nothing -> record<groups: table<createTime: string, description: string, displayName: string, name: string, updateTime: string>, nextPageToken: string, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/groups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Group in a given project and location.
#
# POST /v1alpha1/{parent}/groups
# operationId: vmmigration.projects.locations.groups.create
export def "v1alpha1-groups create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --group-id: string # Required. The group identifier.
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --description: string # User-provided description of the group.
  --display-name: string # Display name is a user defined name for this group which can be updated.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/groups") $qp $auth.query)
  let req_body = {"description": $description, "displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "groupId": $group_id, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists MigratingVms in a given Source.
#
# GET /v1alpha1/{parent}/migratingVms
# operationId: vmmigration.projects.locations.sources.migratingVms.list
export def "v1alpha1-migrating-vms list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of migrating VMs to return. The service may return fewer than this value. If unspecified, at most 500 migrating VMs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListMigratingVms` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListMigratingVms` must match the call that provided the page token.
  --view: string@view-completer-1 # Optional. The level of details of each migrating VM.
]: nothing -> record<migratingVms: table<awsSourceVmDetails: record, computeEngineTargetDefaults: record, computeEngineVmDefaults: record, createTime: string, currentSyncInfo: record, cutoverForecast: record, description: string, displayName: string, error: record, group: string, labels: record, lastReplicationCycle: record, lastSync: record, name: string, policy: record, recentCloneJobs: list, recentCutoverJobs: list, sourceVmId: string, state: string, stateTime: string, targetDefaults: record, updateTime: string>, nextPageToken: string, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/migratingVms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new MigratingVm in a given Source.
#
# POST /v1alpha1/{parent}/migratingVms
# operationId: vmmigration.projects.locations.sources.migratingVms.create
# --awsSourceVmDetails shape: {committedStorageBytes?: string, firmware?: "FIRMWARE_UNSPECIFIED"|"EFI"|"BIOS"}
# --computeEngineTargetDefaults shape: {additionalLicenses?: list<string>, appliedLicense?: record, computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, licenseType?: "COMPUTE_ENGINE_LICENSE_TYPE_DEFAULT"|"COMPUTE_ENGINE_LICENSE_TYPE_PAYG"|"COMPUTE_ENGINE_LICENSE_TYPE_BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, networkInterfaces?: list, ... (6 more fields)}
# --computeEngineVmDefaults shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
# --currentSyncInfo shape: {cycleNumber?: int, endTime?: string, error?: record, name?: string, progress?: int, progressPercent?: int, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"PAUSED"|"FAILED"|"SUCCEEDED", steps?: list, totalPauseDuration?: string}
# --error shape: {code?: int, details?: list, message?: string}
# --lastReplicationCycle shape: {cycleNumber?: int, endTime?: string, error?: record, name?: string, progress?: int, progressPercent?: int, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"PAUSED"|"FAILED"|"SUCCEEDED", steps?: list, totalPauseDuration?: string}
# --lastSync shape: {lastSyncTime?: string}
# --policy shape: {idleDuration?: string, skipOsAdaptation?: bool}
# --recentCloneJobs item shape: {computeEngineTargetDetails?: record, computeEngineVmDetails?: record, error?: record, targetDetails?: record}
# --recentCutoverJobs item shape: {computeEngineTargetDetails?: record, computeEngineVmDetails?: record, error?: record, targetDetails?: record}
# --targetDefaults shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
export def "v1alpha1-migrating-vms create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --migrating-vm-id: string # Required. The migratingVm identifier.
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --aws-source-vm-details: record # Represent the source AWS VM details. — shape: {committedStorageBytes?: string, firmware?: "FIRMWARE_UNSPECIFIED"|"EFI"|"BIOS"}
  --compute-engine-target-defaults: record # ComputeEngineTargetDefaults is a collection of details for creating a VM in a target Compute Engine project. — shape: {additionalLicenses?: list<string>, appliedLicense?: record, computeScheduling?: record, diskType?: "COMPUTE_ENGINE_DISK_TYPE_UNSPECIFIED"|"COMPUTE_ENGINE_DISK_TYPE_STANDARD"|"COMPUTE_ENGINE_DISK_TYPE_SSD"|"COMPUTE_ENGINE_DISK_TYPE_BALANCED", hostname?: string, labels?: record, licenseType?: "COMPUTE_ENGINE_LICENSE_TYPE_DEFAULT"|"COMPUTE_ENGINE_LICENSE_TYPE_PAYG"|"COMPUTE_ENGINE_LICENSE_TYPE_BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, networkInterfaces?: list, ... (6 more fields)}
  --compute-engine-vm-defaults: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
  --current-sync-info: record # ReplicationCycle contains information about the current replication cycle status. — shape: {cycleNumber?: int, endTime?: string, error?: record, name?: string, progress?: int, progressPercent?: int, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"PAUSED"|"FAILED"|"SUCCEEDED", steps?: list, totalPauseDuration?: string}
  --cutover-forecast: record # CutoverForecast holds information about future CutoverJobs of a MigratingVm.
  --description: string # The description attached to the migrating VM by the user.
  --display-name: string # The display name attached to the MigratingVm by the user.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --labels: record # The labels of the migrating VM.
  --last-replication-cycle: record # ReplicationCycle contains information about the current replication cycle status. — shape: {cycleNumber?: int, endTime?: string, error?: record, name?: string, progress?: int, progressPercent?: int, startTime?: string, state?: "STATE_UNSPECIFIED"|"RUNNING"|"PAUSED"|"FAILED"|"SUCCEEDED", steps?: list, totalPauseDuration?: string}
  --last-sync: record # ReplicationSync contain information about the last replica sync to the cloud. — shape: {lastSyncTime?: string}
  --policy: record # A policy for scheduling replications. — shape: {idleDuration?: string, skipOsAdaptation?: bool}
  --source-vm-id: string # The unique ID of the VM in the source. The VM's name in vSphere can be changed, so this is not the VM's name but rather its moRef id. This id is of the form vm-.
  --target-defaults: record # TargetVMDetails is a collection of details for creating a VM in a target Compute Engine project. — shape: {appliedLicense?: record, computeScheduling?: record, diskType?: "DISK_TYPE_UNSPECIFIED"|"STANDARD"|"BALANCED"|"SSD", externalIp?: string, internalIp?: string, labels?: record, licenseType?: "DEFAULT"|"PAYG"|"BYOL", machineType?: string, machineTypeSeries?: string, metadata?: record, name?: string, network?: string, networkInterfaces?: list, networkTags?: list<string>, secureBoot?: bool, serviceAccount?: string, subnetwork?: string, targetProject?: string, zone?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "migratingVmId" $migrating_vm_id "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/migratingVms") $qp $auth.query)
  let req_body = {"awsSourceVmDetails": $aws_source_vm_details, "computeEngineTargetDefaults": $compute_engine_target_defaults, "computeEngineVmDefaults": $compute_engine_vm_defaults, "currentSyncInfo": $current_sync_info, "cutoverForecast": $cutover_forecast, "description": $description, "displayName": $display_name, "error": $body_error, "labels": $labels, "lastReplicationCycle": $last_replication_cycle, "lastSync": $last_sync, "policy": $policy, "sourceVmId": $source_vm_id, "targetDefaults": $target_defaults} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "migratingVmId": $migrating_vm_id, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists ReplicationCycles in a given MigratingVM.
#
# GET /v1alpha1/{parent}/replicationCycles
# operationId: vmmigration.projects.locations.sources.migratingVms.replicationCycles.list
export def "v1alpha1-replication-cycles list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of replication cycles to return. The service may return fewer than this value. If unspecified, at most 100 migrating VMs will be returned. The maximum value is 100; values above 100 will be coerced to 100.
  --page-token: string # Required. A page token, received from a previous `ListReplicationCycles` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListReplicationCycles` must match the call that provided the page token.
]: nothing -> record<nextPageToken: string, replicationCycles: table<cycleNumber: int, endTime: string, error: record, name: string, progress: int, progressPercent: int, startTime: string, state: string, steps: list, totalPauseDuration: string, warnings: list>, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/replicationCycles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists Sources in a given project and location.
#
# GET /v1alpha1/{parent}/sources
# operationId: vmmigration.projects.locations.sources.list
export def "v1alpha1-sources list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of sources to return. The service may return fewer than this value. If unspecified, at most 500 sources will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListSources` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListSources` must match the call that provided the page token.
]: nothing -> record<nextPageToken: string, sources: table<aws: record, createTime: string, description: string, error: record, labels: record, name: string, updateTime: string, vmware: record>, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/sources") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Source in a given project and location.
#
# POST /v1alpha1/{parent}/sources
# operationId: vmmigration.projects.locations.sources.create
# --aws shape: {accessKeyCreds?: record, awsRegion?: string, error?: record, inventorySecurityGroupNames?: list<string>, inventoryTagList?: list, migrationResourcesUserTags?: record}
# --error shape: {code?: int, details?: list, message?: string}
# --vmware shape: {password?: string, thumbprint?: string, username?: string, vcenterIp?: string}
export def "v1alpha1-sources create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --source-id: string # Required. The source identifier.
  --aws: record # AwsSourceDetails message describes a specific source details for the AWS source type. — shape: {accessKeyCreds?: record, awsRegion?: string, error?: record, inventorySecurityGroupNames?: list<string>, inventoryTagList?: list, migrationResourcesUserTags?: record}
  --description: string # User-provided description of the source.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --labels: record # The labels of the source.
  --vmware: record # VmwareSourceDetails message describes a specific source details for the vmware source type. — shape: {password?: string, thumbprint?: string, username?: string, vcenterIp?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "sourceId" $source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/sources") $qp $auth.query)
  let req_body = {"aws": $aws, "description": $description, "error": $body_error, "labels": $labels, "vmware": $vmware} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id, "sourceId": $source_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists TargetProjects in a given project. NOTE: TargetProject is a global resource; hence the only supported value for location is `global`.
#
# GET /v1alpha1/{parent}/targetProjects
# operationId: vmmigration.projects.locations.targetProjects.list
export def "v1alpha1-target-projects list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of targets to return. The service may return fewer than this value. If unspecified, at most 500 targets will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListTargets` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListTargets` must match the call that provided the page token.
]: nothing -> record<nextPageToken: string, targetProjects: table<createTime: string, description: string, name: string, project: string, updateTime: string>, unreachable: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/targetProjects") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new TargetProject in a given project. NOTE: TargetProject is a global resource; hence the only supported value for location is `global`.
#
# POST /v1alpha1/{parent}/targetProjects
# operationId: vmmigration.projects.locations.targetProjects.create
export def "v1alpha1-target-projects create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --target-project-id: string # Required. The target_project identifier.
  --description: string # The target project's description.
  --project: string # The target project ID (number) or project name.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "targetProjectId" $target_project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/targetProjects") $qp $auth.query)
  let req_body = {"description": $description, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id, "targetProjectId": $target_project_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists Utilization Reports of the given Source.
#
# GET /v1alpha1/{parent}/utilizationReports
# operationId: vmmigration.projects.locations.sources.utilizationReports.list
export def "v1alpha1-utilization-reports list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. The filter request.
  --order-by: string # Optional. the order by fields for the result.
  --page-size: int # Optional. The maximum number of reports to return. The service may return fewer than this value. If unspecified, at most 500 reports will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Required. A page token, received from a previous `ListUtilizationReports` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListUtilizationReports` must match the call that provided the page token.
  --view: string@view-completer # Optional. The level of details of each report. Defaults to BASIC.
]: nothing -> record<nextPageToken: string, unreachable: list<string>, utilizationReports: table<createTime: string, displayName: string, error: record, frameEndTime: string, name: string, state: string, stateTime: string, timeFrame: string, vmCount: int, vms: list, vmsCount: int>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/utilizationReports") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new UtilizationReport.
#
# POST /v1alpha1/{parent}/utilizationReports
# operationId: vmmigration.projects.locations.sources.utilizationReports.create
# --error shape: {code?: int, details?: list, message?: string}
# --vms item shape: {utilization?: record, vmId?: string, vmwareVmDetails?: record}
export def "v1alpha1-utilization-reports create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --request-id: string # A request ID to identify requests. Specify a unique request ID so that if you must retry your request, the server will know to ignore the request if it has already been completed. The server will guarantee that for at least 60 minutes since the first request. For example, consider a situation where you make an initial request and the request times out. If you make the request again with the same request ID, the server can check if original operation with the same request ID was received, and if so, will ignore the second request. This prevents clients from accidentally creating duplicate commitments. The request ID must be a valid UUID with the exception that zero UUID is not supported (00000000-0000-0000-0000-000000000000).
  --utilization-report-id: string # Required. The ID to use for the report, which will become the final component of the reports's resource name. This value maximum length is 63 characters, and valid characters are /a-z-/. It must start with an english letter and must not end with a hyphen.
  --display-name: string # The report display name, as assigned by the user.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details. You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, details?: list, message?: string}
  --time-frame: string@time-frame-completer # Time frame of the report.
  --vms: list # List of utilization information per VM. When sent as part of the request, the "vm_id" field is used in order to specify which VMs to include in the report. In that case all other fields are ignored. — item shape: {utilization?: record, vmId?: string, vmwareVmDetails?: record}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "utilizationReportId" $utilization_report_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1alpha1/{parent}/utilizationReports") $qp $auth.query)
  let req_body = {"displayName": $display_name, "error": $body_error, "timeFrame": $time_frame, "vms": $vms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id, "utilizationReportId": $utilization_report_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List remote source's inventory of VMs. The remote source is the onprem vCenter (remote in the sense it's not in Compute Engine). The inventory describes the list of existing VMs in that source. Note that this operation lists the VMs on the remote source, as opposed to listing the MigratingVms resources in the vmmigration service.
#
# GET /v1alpha1/{source}:fetchInventory
# operationId: vmmigration.projects.locations.sources.fetchInventory
export def "v1alpha1 get-inventory" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --force-refresh: oneof<nothing, bool> # If this flag is set to true, the source will be queried instead of using cached results. Using this flag will make the call slower.
  --page-size: int # The maximum number of VMs to return. The service may return fewer than this value. For AWS source: If unspecified, at most 500 VMs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000. For VMWare source: If unspecified, all VMs will be returned. There is no limit for maximum value.
  --page-token: string # A page token, received from a previous `FetchInventory` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `FetchInventory` must match the call that provided the page token.
]: nothing -> record<awsVms: record<details: list<record>>, nextPageToken: string, updateTime: string, vmwareVms: record<details: list<record>>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o VM_MIGRATION_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o VM_MIGRATION_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "forceRefresh" $force_refresh "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source: (encode-path-segment $source)} | format pattern "/v1alpha1/{source}:fetchInventory") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "forceRefresh": $force_refresh, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
