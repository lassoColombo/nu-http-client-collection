# Auto-generated client for App Center Client vv0.1
# Source: https://api.apis.guru/v2/specs/appcenter.ms/v0.1/openapi.json
# Auth: --token flag or $env.APP_CENTER_CLIENT_TOKEN

const BASE_URL = "https://api.appcenter.ms"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APP_CENTER_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-token" => { {scheme: $scheme, headers: {X-API-Token: $token_val}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.appcenter.ms"] }
def auth-scheme-completer [] { ["x-api-token" "basic" "basic-credentials"] }

# Completers for enum parameters
def order-by-completer [] { ["display_name" "name"] }
def os-completer [] { ["Android" "Custom" "Linux" "Tizen" "Windows" "iOS" "macOS" "tvOS"] }
def platform-completer [] { ["Cordova" "Custom" "Electron" "Java" "Objective-C-Swift" "React-Native" "UWP" "Unity" "WPF" "WinForms" "Xamarin"] }
def inlinecount-completer [] { ["allpages" "none"] }
def service-completer [] { ["Build" "Test"] }
def period-completer [] { ["Current" "Next" "Previous"] }
def trigger-completer [] { ["continous" "continuous" "manual"] }
def format-completer [] { ["json" "yaml"] }
def os-completer-1 [] { ["Android" "Windows" "iOS" "macOS"] }
def platform-completer-1 [] { ["Java" "Objective-C-Swift" "React-Native" "UWP" "Xamarin"] }
def status-completer [] { ["cancelling"] }
def group-type-completer [] { ["GroupType1" "GroupType2"] }
def group-status-completer [] { ["closed" "ignored" "open"] }
def orderby-completer [] { ["count asc" "count desc" "display_id asc" "display_id desc" "impacted_users asc" "impacted_users desc" "last_occurrence asc" "last_occurrence desc"] }
def status-completer-1 [] { ["closed" "ignored" "open"] }
def error-type-completer [] { ["CrashingErrors" "HandledErrors"] }
def track-completer [] { ["alpha" "beta" "production" "testflight-external" "testflight-internal"] }
def type-completer [] { ["apple" "googleplay" "intune"] }
def error-type-completer-1 [] { ["all" "handledError" "unhandledError"] }
def error-type-completer-2 [] { ["handledError" "unhandledError"] }
def order-completer [] { ["asc" "desc"] }
def sort-completer [] { ["exceptionClassName" "exceptionMessage" "exceptionMethod" "lastOccurrence" "matchingReportsCount"] }
def state-completer [] { ["closed" "ignored" "open"] }
def format-completer-1 [] { ["json" "txt"] }
def sort-completer-1 [] { ["deviceName" "errorGroupId" "exceptionClassName" "exceptionFile" "exceptionLine" "exceptionMessage" "exceptionMethod" "osVersion" "timestamp" "userId"] }
def type-completer-1 [] { ["application_insights_instrumentation_key" "application_insights_linked_subscription" "blob_storage_connection_string" "blob_storage_linked_subscription"] }
def role-completer [] { ["admin" "collaborator" "member"] }
def form-completer [] { ["full" "lite"] }
def status-completer-2 [] { ["all" "processed" "uploaded"] }
def symbol-type-completer [] { ["AndroidProguard" "Apple" "Breakpad" "JavaScript" "UWP"] }
def status-completer-3 [] { ["aborted" "committed"] }
def file-type-completer [] { ["app-file" "dsym-file" "test-file"] }
def tools-completer [] { ["node" "xamarin" "xcode"] }
def upload-status-completer [] { ["uploadCanceled" "uploadFinished"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v0-1-account-test-export test-gdpr" } } | get name | first)
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

# Lists all the endpoints available for Test accounts data
#
# GET /v0.1/account/test/export
# operationId: test_gdprExportAccounts
export def "v0-1-account-test-export test-gdpr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<resources: table<path: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/account/test/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists account data
#
# GET /v0.1/account/test/export/accounts
# operationId: test_gdprExportAccount
export def "v0-1-account-test-export-accounts test-gdpr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/account/test/export/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists feature flag data
#
# GET /v0.1/account/test/export/featureFlags
# operationId: test_gdprExportFeatureFlag
export def "v0-1-account-test-export-feature-flags test-gdpr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, target_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/account/test/export/featureFlags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list organizations in which the requesting user is an admin
#
# GET /v0.1/administeredOrgs
# operationId: organizations_listAdministered
export def "v0-1-administered-orgs list-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organizations: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/administeredOrgs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns api tokens for the authenticated user
#
# GET /v0.1/api_tokens
# operationId: userApiTokens_list
export def "v0-1-api-tokens list-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, description: string, id: string, scope: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/api_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new User API token
#
# POST /v0.1/api_tokens
# operationId: userApiTokens_new
export def "v0-1-api-tokens create-user-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the token
  --scope: list<string> # The scope for this token.
]: any -> record<api_token: string, created_at: string, description: string, id: string, scope: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/api_tokens")
  let req_body = {"description": $description, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the user api_token object with the specific id
#
# DELETE /v0.1/api_tokens/{api_token_id}
# operationId: userApiTokens_delete
export def "v0-1-api-tokens delete-user" [
  api_token_id: string
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
  let base = ($base_url | default $BASE_URL)
  if ($api_token_id | is-empty) { error make --unspanned { msg: "path parameter 'api_token_id' must be non-empty" } }
  let full_url = (build-url $base ({api_token_id: (encode-path-segment $api_token_id)} | format pattern "/v0.1/api_tokens/{api_token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of apps
#
# GET /v0.1/apps
# operationId: apps_list
export def "v0-1-apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer # The name of the attribute by which to order the response by. By default, apps are in order of creation. All results are ordered in ascending order.
]: nothing -> table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0.1/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$orderBy": $order_by} | compact), body: null}
}

# Creates a new app and returns it to the caller
#
# POST /v0.1/apps
# operationId: apps_create
export def "v0-1-apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  display_name: string # The descriptive name of the app. This can contain any characters
  --name: string # The name of the app used in URLs
  os: string@os-completer # The OS the app will be running on
  platform: string@platform-completer # The platform of the app
  --release-type: string # A one-word descriptive release-type value that starts with a capital letter but is otherwise lowercase
]: any -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/apps")
  let req_body = {"description": $description, "display_name": $display_name, "name": $name, "os": $os, "platform": $platform, "release_type": $release_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}
# operationId: apps_delete
export def "v0-1-apps delete" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return a specific app with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}
# operationId: apps_get
export def "v0-1-apps get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Partially updates a single app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}
# operationId: apps_update
export def "v0-1-apps update" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  --display-name: string # The display name of the app
  --icon-asset-id: string # The uuid for the icon's asset id from ACFUS (format: uuid)
  --icon-url: string # The string representation of the URL pointing to the app's icon
  --name: string # The name of the app used in URLs
  --release-type: string # A one-word descriptive release type value that starts with a capital letter but is otherwise lowercase
]: any -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}"))
  let req_body = {"description": $description, "display_name": $display_name, "icon_asset_id": $icon_asset_id, "icon_url": $icon_url, "name": $name, "release_type": $release_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Count of active devices by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/active_device_counts
# operationId: Analytics_DeviceCounts
export def "v0-1-apps-analytics-active-device-counts get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --app-build: string # Application build number. If build number is specified than multiple versions are not allowed. (format: string)
]: nothing -> record<daily: table<count: int, datetime: string>, monthly: table<count: int, datetime: string>, weekly: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes") (serialize-qp "app_build" $app_build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/active_device_counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions, "app_build": $app_build} | compact), body: null}
}

# Get list of audiences.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences
# operationId: Analytics_ListAudiences
export def "v0-1-apps-analytics-audiences list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-disabled: oneof<nothing, bool> # Include disabled audience definitions
]: nothing -> record<nextLink: string, values: table<definition: string, description: string, estimated_count: int, name: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "include_disabled" $include_disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_disabled": $include_disabled} | compact), body: null}
}

# Tests audience definition.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/definition/test
# operationId: Analytics_TestAudience
export def "v0-1-apps-analytics-audiences-definition-test test" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: record # Custom properties used in the definition.
  definition: string # Audience definition in OData format.
  --description: string # Audience description.
  --enabled: oneof<nothing, bool> # default: true
]: any -> record<custom_properties: record, definition: string, estimated_count: int, estimated_total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/definition/test"))
  let req_body = {"custom_properties": $custom_properties, "definition": $definition, "description": $description, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of custom properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/custom_properties
# operationId: Analytics_ListCustomProperties
export def "v0-1-apps-analytics-audiences-metadata-custom-properties list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<values: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/custom_properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of device properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties
# operationId: Analytics_ListDeviceProperties
export def "v0-1-apps-analytics-audiences-metadata-device-properties list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<values: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of device property values.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties/{property_name}/values
# operationId: Analytics_ListDevicePropertyValues
export def "v0-1-apps-analytics-audiences-metadata-device-properties-values list" [
  owner_name: string
  app_name: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contains: string # Contains string
]: nothing -> record<values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let qp = [(serialize-qp "contains" $contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), property_name: (encode-path-segment $property_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties/{property_name}/values") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contains": $contains} | compact), body: null}
}

# Deletes audience definition.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# operationId: Analytics_DeleteAudience
export def "v0-1-apps-analytics-audiences delete" [
  owner_name: string
  app_name: string
  audience_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($audience_name | is-empty) { error make --unspanned { msg: "path parameter 'audience_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), audience_name: (encode-path-segment $audience_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets audience definition.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# operationId: Analytics_GetAudience
export def "v0-1-apps-analytics-audiences get" [
  owner_name: string
  app_name: string
  audience_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($audience_name | is-empty) { error make --unspanned { msg: "path parameter 'audience_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), audience_name: (encode-path-segment $audience_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns whether audience definition exists.
#
# HEAD /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# operationId: Analytics_AudienceNameExists
export def "v0-1-apps-analytics-audiences head-exists" [
  owner_name: string
  app_name: string
  audience_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($audience_name | is-empty) { error make --unspanned { msg: "path parameter 'audience_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), audience_name: (encode-path-segment $audience_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates or updates audience definition.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# operationId: Analytics_CreateOrUpdateAudience
export def "v0-1-apps-analytics-audiences create-or-update" [
  owner_name: string
  app_name: string
  audience_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: record # Custom properties used in the definition.
  definition: string # Audience definition in OData format.
  --description: string # Audience description.
  --enabled: oneof<nothing, bool> # default: true
]: any -> record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($audience_name | is-empty) { error make --unspanned { msg: "path parameter 'audience_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), audience_name: (encode-path-segment $audience_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"))
  let req_body = {"custom_properties": $custom_properties, "definition": $definition, "description": $description, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_counts
# DEPRECATED
# operationId: Analytics_CrashCounts
@deprecated
export def "v0-1-apps-analytics-crash-counts get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<count: int, crashes: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Overall crashes and affected users count of the selected crash groups with selected versions.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups
# operationId: Analytics_CrashGroupsTotals
# --crash_groups item shape: {app_version?: string, crash_group_id?: string}
export def "v0-1-apps-analytics-crash-groups create-totals" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  crash_groups: list # item shape: {app_version?: string, crash_group_id?: string}
]: any -> table<app_version: string, crash_group_id: string, overall: record<crash_count: int, device_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups"))
  let req_body = {"crash_groups": $crash_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/crash_counts
# DEPRECATED
# operationId: Analytics_CrashGroupCounts
@deprecated
export def "v0-1-apps-analytics-crash-groups-crash-counts get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
]: nothing -> record<count: int, crashes: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/crash_counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "start": $start, "end": $end} | compact), body: null}
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/models
# DEPRECATED
# operationId: Analytics_CrashGroupModelCounts
@deprecated
export def "v0-1-apps-analytics-crash-groups-models get-counts" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
]: nothing -> record<crash_count: int, models: table<crash_count: int, model_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "$top": $top} | compact), body: null}
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/operating_systems
# DEPRECATED
# operationId: Analytics_CrashGroupOperatingSystemCounts
@deprecated
export def "v0-1-apps-analytics-crash-groups-operating-systems get-counts" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
]: nothing -> record<crash_count: int, operating_systems: table<crash_count: int, operating_system_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/operating_systems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "$top": $top} | compact), body: null}
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/overall
# DEPRECATED
# operationId: Analytics_CrashGroupTotals
@deprecated
export def "v0-1-apps-analytics-crash-groups-overall get-totals" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
]: nothing -> record<crash_count: int, device_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/overall") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Percentage of crash-free device by day in the time range based on the selected versions. Api will return -1 if crash devices is greater than active devices.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crashfree_device_percentages
# DEPRECATED
# operationId: Analytics_CrashFreeDevicePercentages
@deprecated
export def "v0-1-apps-analytics-crashfree-device-percentages get-crash-free" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --version: string # format: string
]: nothing -> record<average_percentage: float, daily_percentages: table<datetime: string, percentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/crashfree_device_percentages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "version": $version} | compact), body: null}
}

# Count of total downloads for the provided distribution releases.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/distribution/release_counts
# operationId: Analytics_DistributionReleaseCounts
# --releases item shape: {distribution_group?: string, release: string}
export def "v0-1-apps-analytics-distribution-release-counts create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  releases: list # item shape: {distribution_group?: string, release: string}
]: any -> record<counts: table<distribution_group: string, release_id: string, total_count: int, unique_count: int>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/distribution/release_counts"))
  let req_body = {"releases": $releases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the set of Events with the specified event names.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/event_logs/{event_name}
# operationId: Analytics_EventsDeleteLogs
export def "v0-1-apps-analytics-event-logs delete" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: int, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/event_logs/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Count of active events in the time range ordered by event.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events
# operationId: Analytics_Events
export def "v0-1-apps-analytics-events get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --event-name: list<string> # To select the specific events.
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
  --inlinecount: string@inlinecount-completer # Controls whether or not to include a count of all the items across all pages. (default: none)
  --orderby: string # controls the sorting order and sorting based on which column (default: count desc)
]: nothing -> record<events: table<count: int, count_per_device: float, count_per_session: float, device_count: int, id: string, name: string, previous_count: int, previous_device_count: int>, total: int, total_devices: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes") (serialize-qp "event_name" $event_name "pipes") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$inlinecount" $inlinecount "scalar") (serialize-qp "$orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions, "event_name": $event_name, "$top": $top, "$skip": $skip, "$inlinecount": $inlinecount, "$orderby": $orderby} | compact), body: null}
}

# Delete the set of Events with the specified event names.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}
# operationId: Analytics_EventsDelete
export def "v0-1-apps-analytics-events delete" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: int, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Count of events per device by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_device
# operationId: Analytics_EventPerDeviceCount
export def "v0-1-apps-analytics-events-count-per-device get" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<avg_count_per_device: float, count_per_device: table<count: float, datetime: string>, previous_avg_count_per_device: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_device") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Count of events per session by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_session
# operationId: Analytics_EventPerSessionCount
export def "v0-1-apps-analytics-events-count-per-session get" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<avg_count_per_session: float, count_per_session: table<count: float, datetime: string>, previous_avg_count_per_session: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_session") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Count of devices for an event by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/device_count
# operationId: Analytics_EventDeviceCount
export def "v0-1-apps-analytics-events-device-count get" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<devices_count: table<count: int, datetime: string>, previous_total_devices_with_event: int, total_devices: int, total_devices_with_event: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/device_count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Count of events by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/event_count
# operationId: Analytics_EventCount
export def "v0-1-apps-analytics-events-event-count get" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<count: table<count: int, datetime: string>, previous_total_count: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/event_count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Event properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties
# operationId: Analytics_EventProperties
export def "v0-1-apps-analytics-events-properties get" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<event_properties: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Event properties value counts during the time range in descending order.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties/{event_property_name}/counts
# operationId: Analytics_EventPropertyCounts
export def "v0-1-apps-analytics-events-properties-counts get" [
  owner_name: string
  app_name: string
  event_name: string
  event_property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --top: int # The number of property values to return. Set to 0 in order to fetch all results available. (format: int64, default: 10)
]: nothing -> record<total: int, values: table<count: int, name: string, previous_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'event_name' must be non-empty" } }
  if ($event_property_name | is-empty) { error make --unspanned { msg: "path parameter 'event_property_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), event_name: (encode-path-segment $event_name), event_property_name: (encode-path-segment $event_property_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties/{event_property_name}/counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions, "$top": $top} | compact), body: null}
}

# Logs received between the specified start time and the current time. The API will return a maximum of 100 logs per call.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/generic_log_flow
# operationId: Analytics_GenericLogFlow
export def "v0-1-apps-analytics-generic-log-flow get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. It must be within the current day in the UTC timezone. The default value is the start time of the current day in UTC timezone. (format: date-time)
]: nothing -> record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/generic_log_flow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start} | compact), body: null}
}

# Languages in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/languages
# operationId: Analytics_LanguageCounts
export def "v0-1-apps-analytics-languages get-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> record<languages: table<count: int, language_name: string, previous_count: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/languages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "versions": $versions} | compact), body: null}
}

# Logs received between the specified start time and the current time. The API will return a maximum of 100 logs per call.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/log_flow
# operationId: Analytics_LogFlow
export def "v0-1-apps-analytics-log-flow get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. It must be within the current day in the UTC timezone. The default value is the start time of the current day in UTC timezone. (format: date-time)
]: nothing -> record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, install_id: string, timestamp: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/log_flow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start} | compact), body: null}
}

# Models in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/models
# operationId: Analytics_ModelCounts
export def "v0-1-apps-analytics-models get-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> record<models: table<count: int, model_name: string, previous_count: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "versions": $versions} | compact), body: null}
}

# OSes in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/oses
# operationId: Analytics_OperatingSystemCounts
export def "v0-1-apps-analytics-oses get-operating-system-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> record<oses: table<count: int, os_name: string, previous_count: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/oses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "versions": $versions} | compact), body: null}
}

# Places in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/places
# operationId: Analytics_PlaceCounts
export def "v0-1-apps-analytics-places get-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> record<places: table<code: string, count: int, previous_count: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/places") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "versions": $versions} | compact), body: null}
}

# Count of sessions in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/session_counts
# operationId: Analytics_SessionCounts
export def "v0-1-apps-analytics-session-counts get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> table<count: int, datetime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/session_counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Gets session duration.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/session_durations_distribution
# operationId: Analytics_SessionDurationsDistribution
export def "v0-1-apps-analytics-session-durations-distribution get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<average_duration: string, distribution: table<bucket: string, count: int>, previous_average_duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/session_durations_distribution") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Count of sessions per device in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/sessions_per_device
# operationId: Analytics_PerDeviceCounts
export def "v0-1-apps-analytics-sessions-per-device get-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> record<average_sessions_per_user: float, previous_average_sessions_per_user: float, previous_total_count: int, sessions_per_user: table<count: float, datetime: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/sessions_per_device") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions} | compact), body: null}
}

# Count of active versions in the time range ordered by version.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/versions
# operationId: Analytics_Versions
export def "v0-1-apps-analytics-versions get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> record<total: int, versions: table<count: int, previous_count: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "versions" $versions "pipes")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/analytics/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "versions": $versions} | compact), body: null}
}

# Returns App API tokens for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/api_tokens
# operationId: appApiTokens_list
export def "v0-1-apps-api-tokens list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, description: string, id: string, scope: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/api_tokens"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new App API token
#
# POST /v0.1/apps/{owner_name}/{app_name}/api_tokens
# operationId: appApiTokens_new
export def "v0-1-apps-api-tokens create-new" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the token
  --scope: list<string> # The scope for this token.
]: any -> record<api_token: string, created_at: string, description: string, id: string, scope: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/api_tokens"))
  let req_body = {"description": $description, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the App Api Token object with the specific ID
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/api_tokens/{api_token_id}
# operationId: appApiTokens_delete
export def "v0-1-apps-api-tokens delete" [
  owner_name: string
  app_name: string
  api_token_id: string
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
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($api_token_id | is-empty) { error make --unspanned { msg: "path parameter 'api_token_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), api_token_id: (encode-path-segment $api_token_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/api_tokens/{api_token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete mapping of apple app to an existing app in apple store.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# operationId: appleMapping_delete
export def "v0-1-apps-apple-mapping delete" [
  owner_name: string
  app_name: string
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
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get mapping of apple app to an existing app in apple store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# operationId: appleMapping_get
export def "v0-1-apps-apple-mapping get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a mapping for an existing app in apple store for the specified application.
#
# POST /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# operationId: appleMapping_create
export def "v0-1-apps-apple-mapping create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apple-id: string # ID of the apple application in apple store, takes precedence over bundle_identifier when both are provided
  --bundle-identifier: string # Bundle Identifier of the apple package
  service_connection_id: string # Id for the shared service connection. In case of Apple AppStore, this connection will be used to create and connect to the Apple AppStore in Mobile Center.
  team_identifier: string # ID of the Team associated with the app in apple store
]: any -> record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"))
  let req_body = {"apple_id": $apple_id, "bundle_identifier": $bundle_identifier, "service_connection_id": $service_connection_id, "team_identifier": $team_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch all apple test flight groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/apple_test_flight_groups
# DEPRECATED
# operationId: appleMapping_TestFlightGroups
@deprecated
export def "v0-1-apps-apple-test-flight-groups test-mapping" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appleId: float, id: string, name: string, providerId: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/apple_test_flight_groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the uploaded app avatar
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/avatar
# operationId: apps_deleteAvatar
export def "v0-1-apps-avatar delete" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/avatar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the app avatar
#
# POST /v0.1/apps/{owner_name}/{app_name}/avatar
# operationId: apps_updateAvatar
export def "v0-1-apps-avatar update" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The image for an app avatar to upload. (format: binary)
]: any -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/avatar"))
  let req_body = {"avatar": $avatar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Returns a list of azure subscriptions for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions
# operationId: azureSubscription_listForApp
export def "v0-1-apps-azure-subscriptions list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Link azure subscription to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions
# operationId: azureSubscription_linkForApp
export def "v0-1-apps-azure-subscriptions create-link" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  subscription_id: string # The azure subscription id (format: uuid)
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions"))
  let req_body = {"subscription_id": $subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the azure subscriptions for the app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions/{azure_subscription_id}
# operationId: azureSubscription_deleteForApp
export def "v0-1-apps-azure-subscriptions delete" [
  owner_name: string
  app_name: string
  azure_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($azure_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'azure_subscription_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), azure_subscription_id: (encode-path-segment $azure_subscription_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions/{azure_subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Aggregated Billing Information for owner of a given app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/billing/aggregated
# operationId: billingAggregatedInformation_getByApp
export def "v0-1-apps-billing-aggregated get-information" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "showOriginalPlans" $show_original_plans "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/billing/aggregated") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"service": $service, "period": $period, "showOriginalPlans": $show_original_plans} | compact), body: null}
}

# Returns the list of Git branches for this application
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches
# operationId: builds_listBranches
export def "v0-1-apps-branches list-builds" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<configured: bool, lastBuild: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the list of builds for the branch
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds
# operationId: builds_listByBranch
export def "v0-1-apps-branches-builds list" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a build
#
# POST /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds
# operationId: builds_create
export def "v0-1-apps-branches-builds create" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --debug: oneof<nothing, bool> # Run build in debug mode
  --source-version: string # Version to build which represents the full Git commit reference
]: any -> record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds"))
  let req_body = {"debug": $debug, "sourceVersion": $source_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the branch build configuration
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# operationId: branchConfigurations_delete
export def "v0-1-apps-branches-config delete-configurations" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the branch configuration
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# operationId: branchConfigurations_get
export def "v0-1-apps-branches-config get-configurations" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Configures the branch for build
#
# POST /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# operationId: branchConfigurations_create
# --artifactVersioning shape: {buildNumberFormat?: "buildId"|"timestamp"}
# --toolsets shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
export def "v0-1-apps-branches-config create-configurations" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-versioning: record # The versioning configuration for artifacts built for this branch — shape: {buildNumberFormat?: "buildId"|"timestamp"}
  --badge-is-enabled: oneof<nothing, bool>
  --clone-from-branch: string # A configured branch name to clone from. If provided, all other parameters will be ignored. Only supported in POST requests.
  --signed: oneof<nothing, bool>
  --tests-enabled: oneof<nothing, bool>
  --toolsets: any # The branch build configuration for each toolset — shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
  --trigger: string@trigger-completer
]: any -> record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"))
  let req_body = {"artifactVersioning": $artifact_versioning, "badgeIsEnabled": $badge_is_enabled, "cloneFromBranch": $clone_from_branch, "signed": $signed, "testsEnabled": $tests_enabled, "toolsets": $toolsets, "trigger": $trigger} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reconfigures the branch for build
#
# PUT /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# operationId: branchConfigurations_update
# --artifactVersioning shape: {buildNumberFormat?: "buildId"|"timestamp"}
# --toolsets shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
export def "v0-1-apps-branches-config update-configurations" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-versioning: record # The versioning configuration for artifacts built for this branch — shape: {buildNumberFormat?: "buildId"|"timestamp"}
  --badge-is-enabled: oneof<nothing, bool>
  --clone-from-branch: string # A configured branch name to clone from. If provided, all other parameters will be ignored. Only supported in POST requests.
  --signed: oneof<nothing, bool>
  --tests-enabled: oneof<nothing, bool>
  --toolsets: any # The branch build configuration for each toolset — shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
  --trigger: string@trigger-completer
]: any -> record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"))
  let req_body = {"artifactVersioning": $artifact_versioning, "badgeIsEnabled": $badge_is_enabled, "cloneFromBranch": $clone_from_branch, "signed": $signed, "testsEnabled": $tests_enabled, "toolsets": $toolsets, "trigger": $trigger} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the build configuration in Azure pipeline YAML format
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/export_config
# operationId: buildConfigurations_get
export def "v0-1-apps-branches-export-config build-configurations-get" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Configuration format (default: yaml)
]: nothing -> record<yaml: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/export_config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
}

# Returns the projects in the repository for the branch, for all toolsets
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/toolset_projects
# operationId: builds_listToolsetProjects
export def "v0-1-apps-branches-toolset-projects list-builds" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --os: string@os-completer-1 # The desired OS for the project scan; normally the same as the app OS
  --platform: string@platform-completer-1 # The desired platform for the project scan
  --max-search-depth: int # The depth of the repository to search for project files
]: nothing -> record<android: record<androidModules: list<record>, gradleWrapperPath: string>, buildscripts: any, commit: string, javascript: record<javascriptSolutions: list<record>, packageJsonPaths: list<string>>, testcloud: record<projects: list<record>>, uwp: record<uwpSolutions: list<record>>, xamarin: record<xamarinSolutions: list<record>>, xcode: record<xcodeSchemeContainers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let qp = [(serialize-qp "os" $os "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "maxSearchDepth" $max_search_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), branch: (encode-path-segment $branch)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/toolset_projects") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"os": $os, "platform": $platform, "maxSearchDepth": $max_search_depth} | compact), body: null}
}

# Get bug tracker settings for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/bugtracker
# operationId: bugtracker_getSettings
export def "v0-1-apps-bugtracker get-settings" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<event_types: list<string>, settings: record<callback_url: string, owner_name: string, type: string>, state: string, token_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/bugtracker"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get project issue related to a crash group
#
# GET /v0.1/apps/{owner_name}/{app_name}/bugtracker/crashGroup/{crash_group_id}
# operationId: bugTracker_getRepoIssueFromCrash
export def "v0-1-apps-bugtracker-crash-group get-bug-tracker-repo-issue" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bug_tracker_type: string, event_type: string, id: string, mobile_center_id: string, repo_name: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/bugtracker/crashGroup/{crash_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Application specific build service status
#
# GET /v0.1/apps/{owner_name}/{app_name}/build_service_status
# operationId: builds_getStatusByAppId
export def "v0-1-apps-build-service-status get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, os: string, service: string, status: string, url: string, valid_until: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/build_service_status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the build detail for the given build ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}
# operationId: builds_get
export def "v0-1-apps-builds get" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), build_id: (encode-path-segment $build_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancels a build
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}
# operationId: builds_update
export def "v0-1-apps-builds update" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The build status; used to cancel builds
]: any -> record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), build_id: (encode-path-segment $build_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Distribute a build
#
# POST /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/distribute
# operationId: builds_distribute
# --destinations item shape: {id: string, type: "store"|"group"|"tester"}
export def "v0-1-apps-builds-distribute create" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinations: list # Array of objects {id:string, type:string} with "id" being the distribution group ID, store ID, or tester email, and "type" being "group", "store", or "tester" — item shape: {id: string, type: "store"|"group"|"tester"}
  --mandatory-update: oneof<nothing, bool>
  --notify-testers: oneof<nothing, bool> # default: true
  --release-notes: string # The release notes
]: any -> record<status: string, upload_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), build_id: (encode-path-segment $build_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/distribute"))
  let req_body = {"destinations": $destinations, "mandatoryUpdate": $mandatory_update, "notifyTesters": $notify_testers, "releaseNotes": $release_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the download URI
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/downloads/{download_type}
# operationId: builds_getDownloadUri
export def "v0-1-apps-builds-downloads get-uri" [
  owner_name: string
  app_name: string
  build_id: int
  download_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  if ($download_type | is-empty) { error make --unspanned { msg: "path parameter 'download_type' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), build_id: (encode-path-segment $build_id), download_type: (encode-path-segment $download_type)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/downloads/{download_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the build log
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/logs
# operationId: builds_getLog
export def "v0-1-apps-builds-logs get" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), build_id: (encode-path-segment $build_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns commit information for a batch of shas
#
# GET /v0.1/apps/{owner_name}/{app_name}/commits/batch
# operationId: commits_listByShaList
export def "v0-1-apps-commits-batch list-by-sha" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hashes: list<string> # A collection of commit SHAs comma-delimited
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "hashes" $hashes "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/commits/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hashes": $hashes} | compact), body: null}
}

# Gets a list of crash groups and whether the list contains all available groups.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups
# DEPRECATED
# operationId: crashGroups_list
@deprecated
export def "v0-1-apps-crash-groups list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-occurrence-from: string # Earliest date when the last time a crash occured in a crash group (format: date-time)
  --last-occurrence-to: string # Latest date when the last time a crash occured in a crash group (format: date-time)
  --app-version: string # version
  --group-type: string@group-type-completer
  --group-status: string@group-status-completer
  --group-text-search: string # A freetext search that matches in crash, crash types, crash stack_traces and crash user
  --orderby: string@orderby-completer # the OData-like $orderby argument (default: last_occurrence desc, allows empty value)
  --continuation-token: string # Cassandra request continuation token. The token is used for pagination.
]: nothing -> record<continuation_token: string, crash_groups: table<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record, status: string>, limited_result_set: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "last_occurrence_from" $last_occurrence_from "scalar") (serialize-qp "last_occurrence_to" $last_occurrence_to "scalar") (serialize-qp "app_version" $app_version "scalar") (serialize-qp "group_type" $group_type "scalar") (serialize-qp "group_status" $group_status "scalar") (serialize-qp "group_text_search" $group_text_search "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "continuation_token" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"last_occurrence_from": $last_occurrence_from, "last_occurrence_to": $last_occurrence_to, "app_version": $app_version, "group_type": $group_type, "group_status": $group_status, "group_text_search": $group_text_search, "$orderby": $orderby, "continuation_token": $continuation_token} | compact), body: null}
}

# Gets a specific group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}
# DEPRECATED
# operationId: crashGroups_get
@deprecated
export def "v0-1-apps-crash-groups get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a group.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}
# DEPRECATED
# operationId: crashGroups_update
@deprecated
export def "v0-1-apps-crash-groups update" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotation: string
  --status: any@status-completer-1
]: any -> record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}"))
  let req_body = {"annotation": $annotation, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all crashes of a group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes
# DEPRECATED
# operationId: crashes_list
@deprecated
export def "v0-1-apps-crash-groups-crashes list" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-report: oneof<nothing, bool> # true if the crash should include the raw crash report. Default is false (default: false)
  --include-log: oneof<nothing, bool> # true if the crash should include the custom log report. Default is false (default: false)
  --date-from: string # format: date-time
  --date-to: string # format: date-time
  --app-version: string # version
  --error-type: string@error-type-completer
]: nothing -> table<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record, reason: string, threads: list, title: string>, timestamp: string, user_email: string, user_name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "include_report" $include_report "scalar") (serialize-qp "include_log" $include_log "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "app_version" $app_version "scalar") (serialize-qp "error_type" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_report": $include_report, "include_log": $include_log, "date_from": $date_from, "date_to": $date_to, "app_version": $app_version, "error_type": $error_type} | compact), body: null}
}

# Delete a specific crash and related attachments and blobs for an app.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}
# DEPRECATED
# operationId: crashes_delete
@deprecated
export def "v0-1-apps-crash-groups-crashes delete" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --retention-delete: oneof<nothing, bool> # true in that case if the method should skip update counts (default: false)
]: nothing -> record<app_id: string, attachments_deleted: int, blobs_failed: int, blobs_succeeded: int, crash_group_id: string, crash_id: string, crashes_deleted: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let qp = [(serialize-qp "retention_delete" $retention_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"retention_delete": $retention_delete} | compact), body: null}
}

# Gets a specific crash for an app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}
# DEPRECATED
# operationId: crashes_get
@deprecated
export def "v0-1-apps-crash-groups-crashes get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-report: oneof<nothing, bool> # true if the crash should include the raw crash report. Default is false (default: false)
  --include-log: oneof<nothing, bool> # true if the crash should include the custom log report. Default is false (default: false)
  --include-details: oneof<nothing, bool> # true if the crash should include in depth crash details (default: false)
  --include-stacktrace: oneof<nothing, bool> # true if the crash should include the stacktrace information (default: false)
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> record<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record<frames: list, inner_exceptions: list, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: list<record>, title: string>, timestamp: string, user_email: string, user_name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let qp = [(serialize-qp "include_report" $include_report "scalar") (serialize-qp "include_log" $include_log "scalar") (serialize-qp "include_details" $include_details "scalar") (serialize-qp "include_stacktrace" $include_stacktrace "scalar") (serialize-qp "grouping_only" $grouping_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_report": $include_report, "include_log": $include_log, "include_details": $include_details, "include_stacktrace": $include_stacktrace, "grouping_only": $grouping_only} | compact), body: null}
}

# Gets the native log of a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native
# DEPRECATED
# operationId: crashes_getNativeCrash
@deprecated
export def "v0-1-apps-crash-groups-crashes-native get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the native log of a specific crash as a text attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native/download
# DEPRECATED
# operationId: crashes_getNativeCrashDownload
@deprecated
export def "v0-1-apps-crash-groups-crashes-native-download get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the URI location to download json of a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/raw/location
# DEPRECATED
# operationId: crashes_getRawCrashLocation
@deprecated
export def "v0-1-apps-crash-groups-crashes-raw-location get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/raw/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a stacktrace for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/stacktrace
# DEPRECATED
# operationId: crashes_getStacktrace
@deprecated
export def "v0-1-apps-crash-groups-crashes-stacktrace get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let qp = [(serialize-qp "grouping_only" $grouping_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/stacktrace") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"grouping_only": $grouping_only} | compact), body: null}
}

# Gets a stacktrace for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/stacktrace
# DEPRECATED
# operationId: crashGroups_getStacktrace
@deprecated
export def "v0-1-apps-crash-groups-stacktrace get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_group_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_group_id' must be non-empty" } }
  let qp = [(serialize-qp "grouping_only" $grouping_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_group_id: (encode-path-segment $crash_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/stacktrace") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"grouping_only": $grouping_only} | compact), body: null}
}

# Gets all attachments for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments
# DEPRECATED
# operationId: crashes_listAttachments
@deprecated
export def "v0-1-apps-crashes-attachments list" [
  owner_name: string
  app_name: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<app_id: string, attachment_id: string, blob_location: string, content_type: string, crash_id: string, created_time: string, file_name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the URI location to download crash attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/location
# DEPRECATED
# operationId: crashes_getCrashAttachmentLocation
@deprecated
export def "v0-1-apps-crashes-attachments-location get" [
  owner_name: string
  app_name: string
  crash_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_id: (encode-path-segment $crash_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets content of the text attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/text
# DEPRECATED
# operationId: crashes_getCrashTextAttachmentContent
@deprecated
export def "v0-1-apps-crashes-attachments-text get-content" [
  owner_name: string
  app_name: string
  crash_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_id: (encode-path-segment $crash_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/text"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get session logs by crash ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/session_logs
# operationId: Crashes_ListSessionLogs
export def "v0-1-apps-crashes-session-logs list" [
  owner_name: string
  app_name: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of data requested (format: date-time)
]: nothing -> record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($crash_id | is-empty) { error make --unspanned { msg: "path parameter 'crash_id' must be non-empty" } }
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), crash_id: (encode-path-segment $crash_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/session_logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date} | compact), body: null}
}

# Gets whether the application has any crashes.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes_info
# DEPRECATED
# operationId: crashes_getAppCrashesInfo
@deprecated
export def "v0-1-apps-crashes-info get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<features: record<crash_download_raw: bool, crashgroup_analytics_crashfreeusers: bool, crashgroup_analytics_impactedusers: bool, crashgroup_modify_annotation: bool, crashgroup_modify_status: bool, search: bool>, has_crashes: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/crashes_info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a list of CodePush deployments for the given app
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments
# operationId: codePushDeployments_list
export def "v0-1-apps-deployments push-code-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a CodePush Deployment for the given app
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments
# operationId: codePushDeployments_create
export def "v0-1-apps-deployments push-code-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --latest-release: any
  name: string
]: any -> record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments"))
  let req_body = {"key": $key, "latest_release": $latest_release, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a CodePush Deployment for the given app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# operationId: codePushDeployments_delete
export def "v0-1-apps-deployments push-code-delete" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a CodePush Deployment for the given app
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# operationId: codePushDeployments_get
export def "v0-1-apps-deployments push-code-get" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modifies a CodePush Deployment for the given app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# operationId: codePushDeployments_update
export def "v0-1-apps-deployments push-code-update" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all releases metrics for specified Deployment
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/metrics
# operationId: codePushDeploymentMetrics_get
export def "v0-1-apps-deployments-metrics push-code-get" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: int, downloaded: int, failed: int, installed: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/metrics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Promote one release (default latest one) from one deployment to another
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/promote_release/{promote_deployment_name}
# operationId: codePushDeployments_promote
export def "v0-1-apps-deployments-promote-release push-code" [
  owner_name: string
  app_name: string
  deployment_name: string
  promote_deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-disabled: oneof<nothing, bool>
  --is-mandatory: oneof<nothing, bool>
  --rollout: int
  --target-binary-range: string
  --label: string
]: any -> record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  if ($promote_deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'promote_deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name), promote_deployment_name: (encode-path-segment $promote_deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/promote_release/{promote_deployment_name}"))
  let req_body = {"description": $description, "is_disabled": $is_disabled, "is_mandatory": $is_mandatory, "rollout": $rollout, "target_binary_range": $target_binary_range, "label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Clears a Deployment of releases
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# operationId: codePushDeploymentReleases_delete
export def "v0-1-apps-deployments-releases push-code-delete" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the history of releases on a Deployment
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# operationId: codePushDeploymentReleases_get
export def "v0-1-apps-deployments-releases push-code-get" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new CodePush release for the specified deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# operationId: codePushDeploymentReleases_create
# --release_upload shape: {id: string, token: string, upload_domain: string}
export def "v0-1-apps-deployments-releases push-code-create" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-deployment-name: string # This specifies which deployment you want to release the update to. Default is Staging.
  --description: string # This provides an optional "change log" for the deployment.
  --disabled: oneof<nothing, bool> # This specifies whether an update should be downloadable by end users or not.
  --mandatory: oneof<nothing, bool> # This specifies whether the update should be considered mandatory or not (e.g. it includes a critical security fix).
  --no-duplicate-release-error: oneof<nothing, bool> # This specifies that if the update is identical to the latest release on the deployment, the CLI should generate a warning instead of an error.
  release_upload: any # The upload metadata from the release initialization step. — shape: {id: string, token: string, upload_domain: string}
  --rollout: int # This specifies the percentage of users (as an integer between 1 and 100) that should be eligible to receive this update.
  target_binary_version: string # the binary version of the application
]: any -> record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"))
  let req_body = {"deployment_name": $body_deployment_name, "description": $description, "disabled": $disabled, "mandatory": $mandatory, "no_duplicate_release_error": $no_duplicate_release_error, "release_upload": $release_upload, "rollout": $rollout, "target_binary_version": $target_binary_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Modifies a CodePush release metadata under the given Deployment
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases/{release_label}
# operationId: deploymentReleases_update
export def "v0-1-apps-deployments-releases update" [
  owner_name: string
  app_name: string
  deployment_name: string
  release_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-disabled: oneof<nothing, bool>
  --is-mandatory: oneof<nothing, bool>
  --rollout: int
  --target-binary-range: string
]: any -> record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  if ($release_label | is-empty) { error make --unspanned { msg: "path parameter 'release_label' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name), release_label: (encode-path-segment $release_label)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases/{release_label}"))
  let req_body = {"description": $description, "is_disabled": $is_disabled, "is_mandatory": $is_mandatory, "rollout": $rollout, "target_binary_range": $target_binary_range} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Rollback the latest or a specific release for an app deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/rollback_release
# operationId: codePushDeploymentRelease_rollback
export def "v0-1-apps-deployments-rollback-release push-code" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string
]: any -> record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/rollback_release"))
  let req_body = {"label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new CodePush release upload for the specified deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/uploads
# operationId: codePushDeploymentUpload_create
export def "v0-1-apps-deployments-uploads push-code-create" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, token: string, upload_domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deployment_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/uploads"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of available devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/device_configurations
# operationId: test_getDeviceConfigurations
export def "v0-1-apps-device-configurations test-get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-upload-id: string # The ID of the test run (format: uuid)
]: nothing -> table<id: string, image: record<full: string, thumb: string>, marketShare: float, model: record<availabilityCount: float, cpu: record, deviceFrame: record, dimensions: record, formFactor: string, manufacturer: string, memory: record, model: string, name: string, platform: string, releaseDate: string, resolution: record, screenRotation: float, screenSize: record>, name: string, os: string, osName: string, tier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "app_upload_id" $app_upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/device_configurations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app_upload_id": $app_upload_id} | compact), body: null}
}

# Creates a short ID for a list of devices
#
# POST /v0.1/apps/{owner_name}/{app_name}/device_selection
# operationId: test_createDeviceSelection
export def "v0-1-apps-device-selection test-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string>
]: any -> record<shortId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/device_selection"))
  let req_body = {"devices": $devices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# **Warning, this operation is not reversible.** A successful call to this API will permanently stop ingesting any logs received via SDK by app_id, and cannot be restored. We advise caution when using this API, it is designed to permanently disable an app_id.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/devices/block_logs
# operationId: App_BlockLogs
export def "v0-1-apps-devices-block-logs logs-by-owner-name-app-name" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/devices/block_logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# **Warning, this operation is not reversible.** A successful call to this API will permanently stop ingesting any logs received via SDK for the given installation ID, and cannot be restored. We advise caution when using this API, it is designed to permanently disable collection from a specific installation of the app on a device, usually following the request from a user.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/devices/block_logs/{install_id}
# operationId: Devices_BlockLogs
export def "v0-1-apps-devices-block-logs logs-by-owner-name-app-name-install-id" [
  owner_name: string
  app_name: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($install_id | is-empty) { error make --unspanned { msg: "path parameter 'install_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), install_id: (encode-path-segment $install_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/devices/block_logs/{install_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets top N (ordered by crash count) of crash groups by missing symbol
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups
# operationId: missingSymbolGroups_list
export def "v0-1-apps-diagnostics-symbol-groups list-missing" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # top N elements
]: nothing -> record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"top": $top} | compact), body: null}
}

# Gets missing symbol crash group by its id
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups/{symbol_group_id}
# operationId: missingSymbolGroups_get
export def "v0-1-apps-diagnostics-symbol-groups get-missing" [
  owner_name: string
  app_name: string
  symbol_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_group_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_group_id: (encode-path-segment $symbol_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups/{symbol_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets application level statistics for all missing symbol groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups_info
# operationId: missingSymbolGroups_info
export def "v0-1-apps-diagnostics-symbol-groups-info get-missing" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total_crash_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups_info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of distribution groups in the app specified
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups
# operationId: distributionGroups_list
export def "v0-1-apps-distribution-groups list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new distribution group and returns it to the caller
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups
# operationId: distributionGroups_create
export def "v0-1-apps-distribution-groups create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the distribution group. If not specified, the name will be used.
  name: string # The name of the distribution group
]: any -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups"))
  let req_body = {"display_name": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a distribution group
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_delete
export def "v0-1-apps-distribution-groups delete" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single distribution group for a given distribution group name
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_get
export def "v0-1-apps-distribution-groups get" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the attributes of distribution group
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_update
export def "v0-1-apps-distribution-groups update" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-public: oneof<nothing, bool> # Whether the distribution group is public
  --name: string # The name of the distribution group
]: any -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"))
  let req_body = {"is_public": $is_public, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns all devices associated with the given distribution group
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices
# operationId: devices_list
export def "v0-1-apps-distribution-groups-devices list" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-id: float # when provided, gets the provisioning state of the devices owned by users of this distribution group when compared to the provided release.
]: nothing -> table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let qp = [(serialize-qp "release_id" $release_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"release_id": $release_id} | compact), body: null}
}

# Returns all devices associated with the given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices/download_devices_list
# operationId: devices_listCsvFormat
export def "v0-1-apps-distribution-groups-devices-download-devices-list list-csv-format" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unprovisioned-only: oneof<nothing, bool> # when true, filters out provisioned devices (default: false)
  --udids: list<string> # multiple UDIDs which should be part of the resulting CSV.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let qp = [(serialize-qp "unprovisioned_only" $unprovisioned_only "scalar") (serialize-qp "udids" $udids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices/download_devices_list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"unprovisioned_only": $unprovisioned_only, "udids": $udids} | compact), body: null}
}

# Returns a list of member details in the distribution group specified
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members
# operationId: distributionGroups_listUsers
export def "v0-1-apps-distribution-groups-members list-users" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-pending-invitations: oneof<nothing, bool> # Whether to exclude pending invitations in the response
]: nothing -> table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let qp = [(serialize-qp "exclude_pending_invitations" $exclude_pending_invitations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"exclude_pending_invitations": $exclude_pending_invitations} | compact), body: null}
}

# Adds the members to the specified distribution group
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members
# operationId: distributionGroups_addUser
export def "v0-1-apps-distribution-groups-members create-user" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> table<code: string, invite_pending: bool, message: string, status: int, user_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove the users from the distribution group
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members/bulk_delete
# operationId: distributionGroups_removeUser
export def "v0-1-apps-distribution-groups-members-bulk-delete delete-user" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> table<code: string, message: int, status: int, user_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members/bulk_delete"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return basic information about distributed releases in a given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases
# operationId: releases_listByDistributionGroup
export def "v0-1-apps-distribution-groups-releases list" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<enabled: bool, id: int, is_external_build: bool, mandatory_update: bool, origin: string, short_version: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a release with id 'release_id' in a given distribution group.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}
# operationId: releases_deleteWithDistributionGroupId
export def "v0-1-apps-distribution-groups-releases delete" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  release_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return detailed information about a distributed release in a given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}
# operationId: releases_getLatestByDistributionGroup
export def "v0-1-apps-distribution-groups-releases get-latest" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let qp = [(serialize-qp "is_install_page" $is_install_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"is_install_page": $is_install_page} | compact), body: null}
}

# Resend distribution group app invite notification to previously invited testers
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/resend_invite
# operationId: distributionGroups_resendInvite
export def "v0-1-apps-distribution-groups-resend-invite resend" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/resend_invite"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the store details from Storage store table for a particular application.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores
# operationId: stores_list
export def "v0-1-apps-distribution-stores list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record, target_audience: record>, name: string, service_connection_id: string, track: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new external store for the specified application.
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_stores
# operationId: stores_create
# --intune_details shape: {app_category?: any, secret_json?: any, target_audience?: any, tenant_id?: string}
export def "v0-1-apps-distribution-stores create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --intune-details: any # shape: {app_category?: any, secret_json?: any, target_audience?: any, tenant_id?: string}
  --name: string # name of the store. In case of googleplay, and Apple store this is fixed to Production.
  --service-connection-id: string # Id for the shared service connection. In case of Apple AppStore, this connection will be used to create and connect to the Apple AppStore in Mobile Center.
  --track: string@track-completer # track of the store. Can be production, alpha & beta for googleplay. Can be production, testflight-internal & testflight-external for Apple Store.
  --type: string@type-completer # store Type
]: any -> record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores"))
  let req_body = {"intune_details": $intune_details, "name": $name, "service_connection_id": $service_connection_id, "track": $track, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# delete the store based on specific store name.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# operationId: stores_delete
export def "v0-1-apps-distribution-stores delete" [
  owner_name: string
  app_name: string
  store_name: string
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
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return the store details for specified store name.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# operationId: stores_get
export def "v0-1-apps-distribution-stores get" [
  owner_name: string
  app_name: string
  store_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the store.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# operationId: stores_patch
export def "v0-1-apps-distribution-stores update" [
  owner_name: string
  app_name: string
  store_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  service_connection_id: string # Service connection id to updated.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"))
  let req_body = {"service_connection_id": $service_connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the latest release published in a store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/latest_release
# operationId: storeReleases_getLatest
export def "v0-1-apps-distribution-stores-latest-release get" [
  owner_name: string
  app_name: string
  store_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/latest_release"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return all releases published in a store
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases
# operationId: storeReleases_list
export def "v0-1-apps-distribution-stores-releases list" [
  owner_name: string
  app_name: string
  store_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<destination_type: string, distribution_stores: list<record>, id: float, short_version: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# delete the release with release Id
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}
# operationId: storeReleases_delete
export def "v0-1-apps-distribution-stores-releases delete" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
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
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return releases published in a store for releaseId and storeId
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}
# operationId: storeReleases_get
export def "v0-1-apps-distribution-stores-releases get" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return the Error Details of release which failed in publishing.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_error_details
# operationId: storeReleases_getPublishError
export def "v0-1-apps-distribution-stores-releases-publish-error-details get" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_log_available: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_error_details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns publish logs for a particular release published to a particular store
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_logs
# operationId: storeReleasePublishLogs_get
export def "v0-1-apps-distribution-stores-releases-publish-logs get" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return the Real time Status publishing of release from store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/realtimestatus
# operationId: storeReleases_getRealTimeStatusByReleaseId
export def "v0-1-apps-distribution-stores-releases-realtimestatus get-real-time-status" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_id: string, release_id: string, status: record<status: string, storetype: string, track: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($store_name | is-empty) { error make --unspanned { msg: "path parameter 'store_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), store_name: (encode-path-segment $store_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/realtimestatus"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of app builds
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/availableAppBuilds
# operationId: Errors_AppBuildsList
export def "v0-1-apps-errors-available-app-builds list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> record<appBuilds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "errorType" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/availableAppBuilds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "start": $start, "end": $end, "$top": $top, "errorType": $error_type} | compact), body: null}
}

# Get all available versions in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/available_versions
# operationId: Errors_AvailableVersions
export def "v0-1-apps-errors-available-versions get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
  --filter: string # A filter as specified in https://github.com/Microsoft/api-guidelines/blob/master/Guidelines.md#97-filtering. (format: string)
  --inlinecount: string@inlinecount-completer # Controls whether or not to include a count of all the items across all pages. (default: none)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> record<total_count: int, versions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$inlinecount" $inlinecount "scalar") (serialize-qp "errorType" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/available_versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "$skip": $skip, "$filter": $filter, "$inlinecount": $inlinecount, "errorType": $error_type} | compact), body: null}
}

# Count of crashes or errors by day in the time range based the selected versions. If SingleErrorTypeParameter is not provided, defaults to handlederror.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorCountsPerDay
# operationId: Errors_CountsPerDay
export def "v0-1-apps-errors-error-counts-per-day get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --app-build: string # app build (format: string)
  --error-type: string@error-type-completer-2 # Type of error (handled vs unhandled), excluding All
]: nothing -> record<count: int, errors: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "app_build" $app_build "scalar") (serialize-qp "errorType" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorCountsPerDay") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "start": $start, "end": $end, "app_build": $app_build, "errorType": $error_type} | compact), body: null}
}

# List of error groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups
# operationId: Errors_GroupList
export def "v0-1-apps-errors-error-groups list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --app-build: string # app build (format: string)
  --group-state: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --orderby: string # controls the sorting order and sorting based on which column (default: count desc)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> record<errorGroups: list<record>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "app_build" $app_build "scalar") (serialize-qp "groupState" $group_state "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "errorType" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "app_build": $app_build, "groupState": $group_state, "start": $start, "end": $end, "$orderby": $orderby, "$top": $top, "errorType": $error_type} | compact), body: null}
}

# Error groups list based on search parameters
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/search
# operationId: Errors_ErrorGroupsSearch
export def "v0-1-apps-errors-error-groups-search list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter as specified in OData notation (format: string)
  --q: string # A query string (format: string)
  --order: string@order-completer # It controls the order of sorting (default: desc)
  --qp-sort: string@sort-completer # It controls the sort based on specified field (default: matchingReportsCount)
  --top: int # The maximum number of results to return (format: int64, default: 100)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
]: nothing -> record<errorGroups: list<record>, hasMoreResults: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "q": $q, "order": $order, "sort": $qp_sort, "$top": $top, "$skip": $skip} | compact), body: null}
}

# Error group details
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}
# operationId: Errors_GroupDetails
export def "v0-1-apps-errors-error-groups get-details" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update error group state
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}
# operationId: Errors_UpdateState
export def "v0-1-apps-errors-error-groups update-state" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotation: string
  state: string@state-completer
]: any -> record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}"))
  let req_body = {"annotation": $annotation, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Count of errors by day in the time range of the selected error group with selected version
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorCountsPerDay
# operationId: Errors_GroupCountsPerDay
export def "v0-1-apps-errors-error-groups-error-counts-per-day get" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
]: nothing -> record<count: int, errors: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errorCountsPerDay") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version, "start": $start, "end": $end} | compact), body: null}
}

# Percentage of error-free devices by day in the time range. Api will return -1 if crash devices is greater than active devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorfreeDevicePercentages
# operationId: Errors_GroupErrorFreeDevicePercentages
export def "v0-1-apps-errors-error-groups-errorfree-device-percentages get-free" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
]: nothing -> record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errorfreeDevicePercentages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end} | compact), body: null}
}

# Get all errors for group
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors
# operationId: Errors_ListForGroup
export def "v0-1-apps-errors-error-groups-errors list" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --model: string # format: string
  --os: string # format: string
]: nothing -> record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "os" $os "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "$top": $top, "model": $model, "os": $os} | compact), body: null}
}

# Latest error details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/latest
# operationId: Errors_LatestErrorDetails
export def "v0-1-apps-errors-error-groups-errors-latest get-details" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/latest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a specific error and related attachments and blobs for an app. Searchable data will not be deleted immediately and may take up to 30 days.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}
# operationId: Errors_DeleteError
export def "v0-1-apps-errors-error-groups-errors delete" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appId: string, attachmentsDeleted: int, blobsFailed: int, blobsSucceeded: int, errorGroupId: string, errorId: string, errorsDeleted: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/{error_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Error details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}
# operationId: Errors_GetErrorDetails
export def "v0-1-apps-errors-error-groups-errors get-details" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/{error_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download details for a specific error.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/download
# operationId: Errors_ErrorDownload
export def "v0-1-apps-errors-error-groups-errors-download download" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # the format of the crash log
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/{error_id}/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
}

# Error location.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/location
# operationId: Errors_ErrorLocation
export def "v0-1-apps-errors-error-groups-errors-location get" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/{error_id}/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Error Stacktrace details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/stacktrace
# operationId: Errors_ErrorStackTrace
export def "v0-1-apps-errors-error-groups-errors-stacktrace get-stack-trace" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/errors/{error_id}/stacktrace"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Top models of the selected error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/models
# operationId: Errors_GroupModelCounts
export def "v0-1-apps-errors-error-groups-models get-counts" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
]: nothing -> record<errorCount: int, models: table<errorCount: int, modelCode: string, modelName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top} | compact), body: null}
}

# Top OSes of the selected error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/operatingSystems
# operationId: Errors_GroupOperatingSystemCounts
export def "v0-1-apps-errors-error-groups-operating-systems get-counts" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
]: nothing -> record<errorCount: int, operatingSystems: table<errorCount: int, operatingSystemName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/operatingSystems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top} | compact), body: null}
}

# Gets the stack trace for the error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/stacktrace
# operationId: Errors_GroupErrorStackTrace
export def "v0-1-apps-errors-error-groups-stacktrace get-stack-trace" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_group_id | is-empty) { error make --unspanned { msg: "path parameter 'errorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_group_id: (encode-path-segment $error_group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{error_group_id}/stacktrace"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Percentage of error-free devices by day in the time range based on the selected versions. If SingleErrorTypeParameter is not provided, defaults to handlederror. API will return -1 if crash devices is greater than active devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorfreeDevicePercentages
# operationId: Errors_ErrorFreeDevicePercentages
export def "v0-1-apps-errors-errorfree-device-percentages get-free" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --versions: list<string>
  --app-build: string # app build (format: string)
  --error-type: string@error-type-completer-2 # Type of error (handled vs unhandled), excluding All
]: nothing -> record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "versions" $versions "pipes") (serialize-qp "app_build" $app_build "scalar") (serialize-qp "errorType" $error_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/errorfreeDevicePercentages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "versions": $versions, "app_build": $app_build, "errorType": $error_type} | compact), body: null}
}

# gets the retention settings in days
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/retention_settings
# operationId: errors_getRetentionSettings
export def "v0-1-apps-errors-retention-settings get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<retention_in_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/retention_settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Errors list based on search parameters
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/search
# operationId: Errors_ErrorSearch
export def "v0-1-apps-errors-search list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter as specified in OData notation (format: string)
  --q: string # A query string (format: string)
  --order: string@order-completer # It controls the order of sorting (default: desc)
  --qp-sort: string@sort-completer-1 # It controls the sort based on specified field (default: timestamp)
  --top: int # The maximum number of results to return (format: int64, default: 100)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
]: nothing -> record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, hasMoreResults: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "q": $q, "order": $order, "sort": $qp_sort, "$top": $top, "$skip": $skip} | compact), body: null}
}

# List error attachments.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments
# operationId: Errors_ErrorAttachments
export def "v0-1-apps-errors-attachments get" [
  owner_name: string
  app_name: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appId: string, attachmentId: string, blobLocation: string, contentType: string, crashId: string, createdTime: string, fileName: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/{error_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Error attachment location.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/location
# operationId: Errors_ErrorAttachmentLocation
export def "v0-1-apps-errors-attachments-location get" [
  owner_name: string
  app_name: string
  error_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_id: (encode-path-segment $error_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/{error_id}/attachments/{attachment_id}/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Error attachment text.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/text
# operationId: Errors_ErrorAttachmentText
export def "v0-1-apps-errors-attachments-text get" [
  owner_name: string
  app_name: string
  error_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_id: (encode-path-segment $error_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/{error_id}/attachments/{attachment_id}/text"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get session logs by error ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/sessionLogs
# operationId: Errors_ListSessionLogs
export def "v0-1-apps-errors-session-logs list" [
  owner_name: string
  app_name: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of data requested (format: date-time)
]: nothing -> record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($error_id | is-empty) { error make --unspanned { msg: "path parameter 'errorId' must be non-empty" } }
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), error_id: (encode-path-segment $error_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/errors/{error_id}/sessionLogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date} | compact), body: null}
}

# List export configurations.
#
# GET /v0.1/apps/{owner_name}/{app_name}/export_configurations
# operationId: ExportConfigurations_List
export def "v0-1-apps-export-configurations list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, total: int, values: table<creation_time: string, export_configuration: record, export_entities: list, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create new export configuration
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations
# Discriminator (request): type
# operationId: ExportConfigurations_Create
export def "v0-1-apps-export-configurations create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backfill: oneof<nothing, bool> # Field to determine if backfilling should occur. The default value is true. If set to false export starts from date and time of config creation.
  --export-entities: list<string>
  --resource-group: string # The resource group name on azure
  --resource-name: string # The resource name on azure
  type: string@type-completer-1 # Type of export configuration
]: any -> record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations"))
  let req_body = {"backfill": $backfill, "export_entities": $export_entities, "resource_group": $resource_group, "resource_name": $resource_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete export configuration.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# operationId: ExportConfigurations_Delete
export def "v0-1-apps-export-configurations delete" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($export_configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'export_configuration_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), export_configuration_id: (encode-path-segment $export_configuration_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get export configuration.
#
# GET /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# operationId: ExportConfigurations_Get
export def "v0-1-apps-export-configurations get" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($export_configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'export_configuration_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), export_configuration_id: (encode-path-segment $export_configuration_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Partially update export configuration.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# Discriminator (request): type
# operationId: ExportConfigurations_PartialUpdate
export def "v0-1-apps-export-configurations update" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backfill: oneof<nothing, bool> # Field to determine if backfilling should occur. The default value is true. If set to false export starts from date and time of config creation.
  --export-entities: list<string>
  --resource-group: string # The resource group name on azure
  --resource-name: string # The resource name on azure
  type: string@type-completer-1 # Type of export configuration
]: any -> record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($export_configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'export_configuration_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), export_configuration_id: (encode-path-segment $export_configuration_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"))
  let req_body = {"backfill": $backfill, "export_entities": $export_entities, "resource_group": $resource_group, "resource_name": $resource_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disable export configuration.
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/disable
# operationId: ExportConfigurations_Disable
export def "v0-1-apps-export-configurations-disable export" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($export_configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'export_configuration_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), export_configuration_id: (encode-path-segment $export_configuration_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enable export configuration.
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/enable
# operationId: ExportConfigurations_Enable
export def "v0-1-apps-export-configurations-enable export" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($export_configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'export_configuration_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), export_configuration_id: (encode-path-segment $export_configuration_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new asset to upload a file
#
# POST /v0.1/apps/{owner_name}/{app_name}/file_asset
# operationId: fileAssets_create
export def "v0-1-apps-file-asset create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<id: string, location: string, token: string, uploadDomain: string, uploadWindowLocation: string, urlEncodedToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/file_asset"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the pending invitations for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/invitations
# operationId: appInvitations_list
export def "v0-1-apps-invitations list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>, app_count: float, distribution_group: record<owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>>, email: string, id: string, invite_type: string, invited_by: record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>, is_existing_user: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/invitations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Invites a new or existing user to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/invitations
# operationId: appInvitations_create
export def "v0-1-apps-invitations create-by-owner-name-app-name" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role
  user_email: string # The user's email address
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/invitations"))
  let req_body = {"role": $role, "user_email": $user_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a user's invitation to an app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# operationId: appInvitations_delete
export def "v0-1-apps-invitations delete" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($user_email | is-empty) { error make --unspanned { msg: "path parameter 'user_email' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), user_email: (encode-path-segment $user_email)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update pending invitation permission
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# operationId: appInvitations_updatePermissions
export def "v0-1-apps-invitations update-permissions" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions the user has for the app in the invitation
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($user_email | is-empty) { error make --unspanned { msg: "path parameter 'user_email' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), user_email: (encode-path-segment $user_email)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"))
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Invites a new or existing user to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# DEPRECATED
# operationId: appInvitations_createByEmail
@deprecated
export def "v0-1-apps-invitations create-by-owner-name-app-name-user-email" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The role of the user to be added
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($user_email | is-empty) { error make --unspanned { msg: "path parameter 'user_email' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), user_email: (encode-path-segment $user_email)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Email notification settings of user for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/notifications/emailSettings
# operationId: notifications_getAppEmailSettings
export def "v0-1-apps-notifications-email-settings get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/notifications/emailSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists device sets belonging to the owner
#
# GET /v0.1/apps/{owner_name}/{app_name}/owner/device_sets
# operationId: test_listDeviceSetsOfOwner
export def "v0-1-apps-owner-device-sets test-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a device set belonging to the owner
#
# POST /v0.1/apps/{owner_name}/{app_name}/owner/device_sets
# operationId: test_createDeviceSetOfOwner
export def "v0-1-apps-owner-device-sets test-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets"))
  let req_body = {"devices": $devices, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a device set belonging to the owner
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# operationId: test_deleteDeviceSetOfOwner
export def "v0-1-apps-owner-device-sets test-delete" [
  owner_name: string
  app_name: string
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a device set belonging to the owner
#
# GET /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# operationId: test_getDeviceSetOfOwner
export def "v0-1-apps-owner-device-sets test-get" [
  owner_name: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a device set belonging to the owner
#
# PUT /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# operationId: test_updateDeviceSetOfOwner
export def "v0-1-apps-owner-device-sets test-update" [
  owner_name: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"))
  let req_body = {"devices": $devices, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the latest release from every distribution group associated with an application.
#
# GET /v0.1/apps/{owner_name}/{app_name}/recent_releases
# operationId: releases_listLatest
export def "v0-1-apps-recent-releases list-latest" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/recent_releases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return basic information about releases.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases
# operationId: releases_list
export def "v0-1-apps-releases list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --published-only: oneof<nothing, bool> # When *true*, filters out releases that were uploaded but were never distributed. Releases that under deleted distribution groups will not be filtered out.
  --scope: string # When the scope is 'tester', only includes releases that have been distributed to groups that the user belongs to.
  --top: float # The number of releases to return
  --release-id: float # The id of a release
]: nothing -> table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "published_only" $published_only "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "releaseId" $release_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"published_only": $published_only, "scope": $scope, "top": $top, "releaseId": $release_id} | compact), body: null}
}

# Return detailed information about releases avaiable to a tester.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/filter_by_tester
# DEPRECATED
# operationId: releases_availableToTester
@deprecated
export def "v0-1-apps-releases-filter-by-tester get-available" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --published-only: oneof<nothing, bool> # when *true*, filters out releases that were uploaded but were never distributed. Releases that under deleted distribution groups will not be filtered out.
]: nothing -> table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "published_only" $published_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/filter_by_tester") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"published_only": $published_only} | compact), body: null}
}

# Deletes a release.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# operationId: releases_delete
export def "v0-1-apps-releases delete" [
  owner_name: string
  app_name: string
  release_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a release with id `release_id`. If `release_id` is `latest`, return the latest release that was distributed to the current user (from all the distribution groups).
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# operationId: releases_getLatestByUser
export def "v0-1-apps-releases get-latest-by-user" [
  owner_name: string
  app_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # when supplied, this call will also check if the given UDID is provisioned. Will be ignored for non-iOS platforms. The value will be returned in the property is_udid_provisioned.
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let qp = [(serialize-qp "udid" $udid "scalar") (serialize-qp "is_install_page" $is_install_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"udid": $udid, "is_install_page": $is_install_page} | compact), body: null}
}

# Updates a release.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# operationId: releases_update
export def "v0-1-apps-releases update" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<release_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/plain" $req_body {query: {}, body: $req_body}
}

# Update details of a release.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# operationId: releases_updateDetails
# --build shape: {branch_name?: string, commit_hash?: string, commit_message?: string}
export def "v0-1-apps-releases update-details" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: record # Contains metadata about the build that produced the release being uploaded — shape: {branch_name?: string, commit_hash?: string, commit_message?: string}
  --enabled: oneof<nothing, bool> # Toggle this release to be enable distribute/download or not.
  --release-notes: string # Release notes for this release.
]: any -> record<destinations: table<id: string, name: string>, enabled: bool, mandatory_update: bool, provisioning_status_url: string, release_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"))
  let req_body = {"build": $build, "enabled": $enabled, "release_notes": $release_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Distributes a release to a group
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups
# operationId: releases_addDistributionGroup
export def "v0-1-apps-releases-groups create-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique id of the release destination (format: uuid)
  --mandatory-update: oneof<nothing, bool> # Flag to mark the release for the provided destinations as mandatory
  --notify-testers: oneof<nothing, bool> # Flag to enable or disable notifications to testers (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups"))
  let req_body = {"id": $id, "mandatory_update": $mandatory_update, "notify_testers": $notify_testers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the given distribution group from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}
# operationId: releases_deleteDistributionGroup
export def "v0-1-apps-releases-groups delete-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  group_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), group_id: (encode-path-segment $group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update details about the specified distribution group associated with the release
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}
# operationId: releases_putDistributionGroup
export def "v0-1-apps-releases-groups update-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandatory-update: oneof<nothing, bool> # Whether a release is mandatory for the given destination
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), group_id: (encode-path-segment $group_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}"))
  let req_body = {"mandatory_update": $mandatory_update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return information about the provisioning profile. Only available for iOS.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/provisioning_profile
# operationId: provisioning_profile
export def "v0-1-apps-releases-provisioning-profile get" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appex_profiles: list<any>, provisioning_bundle_id: string, provisioning_profile_name: string, provisioning_profile_type: string, team_identifier: string, udids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/provisioning_profile"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Distributes a release to a store
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores
# operationId: releases_addStore
export def "v0-1-apps-releases-stores create" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique id of the release destination (format: uuid)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores"))
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the given distribution store from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores/{store_id}
# operationId: releases_deleteDistributionStore
export def "v0-1-apps-releases-stores delete-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  store_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($store_id | is-empty) { error make --unspanned { msg: "path parameter 'store_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), store_id: (encode-path-segment $store_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores/{store_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Distributes a release to a user
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers
# operationId: releases_addTesters
export def "v0-1-apps-releases-testers create" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Tester's email address
  --mandatory-update: oneof<nothing, bool> # Flag to mark the release for the provided destinations as mandatory
  --notify-testers: oneof<nothing, bool> # Flag to enable or disable notifications to testers (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers"))
  let req_body = {"email": $email, "mandatory_update": $mandatory_update, "notify_testers": $notify_testers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the given tester from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}
# operationId: releases_deleteDistributionTester
export def "v0-1-apps-releases-testers delete-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  tester_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($tester_id | is-empty) { error make --unspanned { msg: "path parameter 'tester_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), tester_id: (encode-path-segment $tester_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update details about the specified tester associated with the release
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}
# operationId: releases_putDistributionTester
export def "v0-1-apps-releases-testers update-distribution" [
  owner_name: string
  app_name: string
  release_id: int
  tester_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandatory-update: oneof<nothing, bool> # Whether a release is mandatory for the given destination
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($tester_id | is-empty) { error make --unspanned { msg: "path parameter 'tester_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), tester_id: (encode-path-segment $tester_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}"))
  let req_body = {"mandatory_update": $mandatory_update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the resign status to the caller
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/update_devices/{resign_id}
# operationId: devices_getReleaseUpdateDevicesStatus
export def "v0-1-apps-releases-update-devices get-status" [
  owner_name: string
  app_name: string
  release_id: string
  resign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-provisioning-profile: oneof<nothing, bool> # A boolean value that indicates if the provisioning profile should be return in addition to the status. When set to true, the provisioning profile will be returned only when status is 'complete' or 'preparing_for_testers'.
]: nothing -> record<error_code: string, error_message: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  if ($resign_id | is-empty) { error make --unspanned { msg: "path parameter 'resign_id' must be non-empty" } }
  let qp = [(serialize-qp "include_provisioning_profile" $include_provisioning_profile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), release_id: (encode-path-segment $release_id), resign_id: (encode-path-segment $resign_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/update_devices/{resign_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_provisioning_profile": $include_provisioning_profile} | compact), body: null}
}

# Removes the configuration for the repository
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/repo_config
# operationId: repositoryConfigurations_delete
export def "v0-1-apps-repo-config delete-repository-configurations" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/repo_config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the repository build configuration status of the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/repo_config
# operationId: repositoryConfigurations_list
export def "v0-1-apps-repo-config list-repository-configurations" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-inactive: oneof<nothing, bool> # Include inactive configurations if none are active
]: nothing -> table<id: string, state: string, type: string, user_email: string, installation_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "includeInactive" $include_inactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/repo_config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeInactive": $include_inactive} | compact), body: null}
}

# Configures the repository for build
#
# POST /v0.1/apps/{owner_name}/{app_name}/repo_config
# operationId: repositoryConfigurations_createOrUpdate
export def "v0-1-apps-repo-config create-repository-configurations-or-update" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --installation-id: string # The GitHub App Installation id. Required for repositories connected from GitHub App
  --external-user-id: string # The external user id from the repository provider. Required for GitLab.com repositories
  --repo-id: string # The repository id from the repository provider. Required for repositories connected from GitHub App and GitLab.com
  repo_url: string # The repository's git url, must be a HTTPS URL (e.g. https://github.com/foo/bar.git)
  --service-connection-id: string # The id of the service connection (private). Required for GitLab self-hosted repositories
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/repo_config"))
  let req_body = {"installation_id": $installation_id, "external_user_id": $external_user_id, "repo_id": $repo_id, "repo_url": $repo_url, "service_connection_id": $service_connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the repositories available from the source code host
#
# GET /v0.1/apps/{owner_name}/{app_name}/source_hosts/{source_host}/repositories
# operationId: repositories_list
export def "v0-1-apps-source-hosts-repositories list" [
  owner_name: string
  app_name: string
  source_host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vsts-account-name: string # Filter repositories only for specified account and project, "vstsProjectId" is required
  --vsts-project-id: string # Filter repositories only for specified account and project, "vstsAccountName" is required
  --service-connection-id: string # The id of the service connection (private). Required for GitLab self-hosted repositories
  --form: string@form-completer # The selected form of the object
]: nothing -> table<clone_url: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($source_host | is-empty) { error make --unspanned { msg: "path parameter 'source_host' must be non-empty" } }
  let qp = [(serialize-qp "vstsAccountName" $vsts_account_name "scalar") (serialize-qp "vstsProjectId" $vsts_project_id "scalar") (serialize-qp "service_connection_id" $service_connection_id "scalar") (serialize-qp "form" $form "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), source_host: (encode-path-segment $source_host)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/source_hosts/{source_host}/repositories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"vstsAccountName": $vsts_account_name, "vstsProjectId": $vsts_project_id, "service_connection_id": $service_connection_id, "form": $form} | compact), body: null}
}

# Application specific store service status
#
# GET /v0.1/apps/{owner_name}/{app_name}/store_service_status
# operationId: storeNotifications_getNotificationByAppId
export def "v0-1-apps-store-service-status get-notifications-notification" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service: string, status: string, valid_until: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/store_service_status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about the currently active subscriptions, if any
#
# GET /v0.1/apps/{owner_name}/{app_name}/subscriptions
# operationId: test_getSubscriptions
export def "v0-1-apps-subscriptions test-get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accept a free trial subscription
#
# POST /v0.1/apps/{owner_name}/{app_name}/subscriptions
# operationId: test_createSubscription
export def "v0-1-apps-subscriptions test-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a list of all uploads for the specified application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads
# operationId: symbolUploads_list
export def "v0-1-apps-symbol-uploads list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (format: int64, default: 30)
  --status: string@status-completer-2 # Filter results by the current status of a symbol upload: * all: all states in the symbol upload process. Includes created, aborted, committed, processing, indexed and failed states * uploaded: all states after package is uploaded. Includes committed, processing, indexed and failed states * processed: symbol upload processing is completed. Includes indexed and failed states.
  --symbol-type: string@symbol-type-completer # The type of symbols
]: nothing -> table<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: list<record>, timestamp: string, user: record<display_name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "symbol_type" $symbol_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"top": $top, "status": $status, "symbol_type": $symbol_type} | compact), body: null}
}

# Begins the symbol upload process for a new set of symbols for the specified application
#
# POST /v0.1/apps/{owner_name}/{app_name}/symbol_uploads
# operationId: symbolUploads_create
export def "v0-1-apps-symbol-uploads create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: string # The build number. Optional for Apple. Required for Android.
  --client-callback: string # The callback URL that the client can optionally provide to get status updates for the current symbol upload
  --file-name: string # The file name for the symbol upload
  symbol_type: string@symbol-type-completer # The type of the symbol for the current symbol upload
  --version: string # The version number. Optional for Apple. Required for Android.
]: any -> record<expiration_date: string, symbol_upload_id: string, upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads"))
  let req_body = {"build": $build, "client_callback": $client_callback, "file_name": $file_name, "symbol_type": $symbol_type, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a symbol upload by id for the specified application
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# operationId: symbolUploads_delete
export def "v0-1-apps-symbol-uploads delete" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_upload_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_upload_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_upload_id: (encode-path-segment $symbol_upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a symbol upload by id for the specified application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# operationId: symbolUploads_get
export def "v0-1-apps-symbol-uploads get" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_upload_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_upload_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_upload_id: (encode-path-segment $symbol_upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Commits or aborts the symbol upload process for a new set of symbols for the specified application
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# operationId: symbolUploads_complete
export def "v0-1-apps-symbol-uploads complete" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-3 # The desired operation for the symbol upload
]: any -> record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_upload_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_upload_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_upload_id: (encode-path-segment $symbol_upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the URL to download the symbol upload
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}/location
# operationId: symbolUploads_getLocation
export def "v0-1-apps-symbol-uploads-location get" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_upload_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_upload_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_upload_id: (encode-path-segment $symbol_upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the list of all symbols for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols
# operationId: symbols_list
export def "v0-1-apps-symbols list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbols"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a particular symbol by id (uuid) for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}
# operationId: symbols_get
export def "v0-1-apps-symbols get" [
  owner_name: string
  app_name: string
  symbol_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_id: (encode-path-segment $symbol_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Marks a symbol by id (uuid) as ignored
#
# POST /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/ignore
# operationId: symbols_ignore
export def "v0-1-apps-symbols-ignore create" [
  owner_name: string
  app_name: string
  symbol_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_id: (encode-path-segment $symbol_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/ignore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the URL to download the symbol
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/location
# operationId: symbols_getLocation
export def "v0-1-apps-symbols-location get" [
  owner_name: string
  app_name: string
  symbol_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_id: (encode-path-segment $symbol_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/location"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a particular symbol by id (uuid) for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/status
# operationId: symbols_getStatus
export def "v0-1-apps-symbols-status get" [
  owner_name: string
  app_name: string
  symbol_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_id: string, status: string, symbol_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($symbol_id | is-empty) { error make --unspanned { msg: "path parameter 'symbol_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), symbol_id: (encode-path-segment $symbol_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the details of all teams that have access to the app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/teams
# operationId: apps_getTeams
export def "v0-1-apps-teams get" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, display_name: string, id: string, name: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists all the endpoints available for Test apps data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export
# operationId: test_gdprExportApps
export def "v0-1-apps-test-export test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<resources: table<path: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists app data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/apps
# operationId: test_gdprExportApp
export def "v0-1-apps-test-export-apps test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hash_files_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists file set file data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/fileSetFiles
# operationId: test_gdprExportFileSetFile
export def "v0-1-apps-test-export-file-set-files test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_upload_id: string, hash_file_id: string, hash_file_url: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export/fileSetFiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists hash file data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/hashFiles
# operationId: test_gdprExportHashFile
export def "v0-1-apps-test-export-hash-files test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filename: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export/hashFiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists pipeline test data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/pipelineTests
# operationId: test_gdprExportPipelineTest
export def "v0-1-apps-test-export-pipeline-tests test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_upload_id: string, test_parameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export/pipelineTests"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists test run data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/testRuns
# operationId: test_gdprExportTestRun
export def "v0-1-apps-test-export-test-runs test-gdpr" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_hash_file_id: string, app_hash_file_url: string, app_icon_url: string, dsym_hash_file_id: string, dsym_hash_file_url: string, id: string, locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test/export/testRuns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of test runs
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs
# operationId: test_getTestRuns
export def "v0-1-apps-test-runs list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs
# operationId: test_createTestRun
export def "v0-1-apps-test-runs create" [
  owner_name: string
  app_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Logically deletes a test run
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}
# operationId: test_archiveTestRun
export def "v0-1-apps-test-runs archive" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single test runs
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}
# operationId: test_getTestRun
export def "v0-1-apps-test-runs get" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Uploads file for a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/files
# operationId: test_startUploadingFile
export def "v0-1-apps-test-runs-files start-uploading" [
  owner_name: string
  app_name: string
  test_run_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds file with the given hash to a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes
# operationId: test_uploadHash
export def "v0-1-apps-test-runs-hashes upload-hash" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --byte-range: string # Range of bytes required to verify ownership of the file
  checksum: string # SHA256 hash of the file
  file_type: string@file-type-completer # Type of the file
  relative_path: string # Relative path of the file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes"))
  let req_body = {"byte_range": $byte_range, "checksum": $checksum, "file_type": $file_type, "relative_path": $relative_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds file with the given hash to a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes/batch
# operationId: test_uploadHashesBatch
export def "v0-1-apps-test-runs-hashes-batch upload" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<checksum: string, fileType: string, relativePath: string, uploadStatus: record<location: string, statusCode: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes/batch"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a single test report
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/report
# operationId: test_getTestReport
export def "v0-1-apps-test-runs-report get" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_upload_id: string, date: string, date_finished: string, device_logs: table<appium_log: string, device_log: string, device_snapshot_id: string, test_log: string>, errorMessage: string, features: table<failed: float, name: string, peakDuration: float, peakMemory: float, skipped: float, tests: list>, finished_device_snapshots: list<string>, id: string, platform: string, revision: float, schema_version: float, snapshot_fatal_errors: table<device_snapshot_id: string, error_message: string, error_title: string>, stats: record<artifacts: record, devices: float, devices_failed: float, devices_finished: float, devices_not_runned: float, devices_skipped: float, failed: float, filesize: float, os: float, passed: float, skipped: float, step_count: float, total: float, totalDeviceMinutes: float>, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/report"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Starts test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/start
# operationId: test_startTestRun
export def "v0-1-apps-test-runs-start test" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_selection: string # Device selection string.
  --language: string # Language that should be used to run tests.
  --locale: string # Locale that should be used to run tests.
  test_framework: string # Test framework used by tests.
  --test-parameters: record # A JSON dictionary with additional test parameters
  --test-series: string # Name of the test series.
]: any -> record<accepted_devices: list<string>, rejected_devices: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/start"))
  let req_body = {"device_selection": $device_selection, "language": $language, "locale": $locale, "test_framework": $test_framework, "test_parameters": $test_parameters, "test_series": $test_series} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets state of the test run
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/state
# operationId: test_getTestRunState
export def "v0-1-apps-test-runs-state get" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exit_code: int, message: list<string>, wait_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop a test run execution
#
# PUT /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/stop
# operationId: test_stopTestRun
export def "v0-1-apps-test-runs-stop test" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_run_id | is-empty) { error make --unspanned { msg: "path parameter 'test_run_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_run_id: (encode-path-segment $test_run_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns list of all test series for an application
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_series
# operationId: test_getAllTestSeries
export def "v0-1-apps-test-series get-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string to filter test series
]: nothing -> table<mostRecentActivity: string, name: string, slug: string, testRuns: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_series") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query} | compact), body: null}
}

# Creates new test series for an application
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_series
# operationId: test_createTestSeries
export def "v0-1-apps-test-series create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the new test series
]: any -> record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_series"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a single test series
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}
# operationId: test_deleteTestSeries
export def "v0-1-apps-test-series delete" [
  owner_name: string
  app_name: string
  test_series_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_series_slug | is-empty) { error make --unspanned { msg: "path parameter 'test_series_slug' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_series_slug: (encode-path-segment $test_series_slug)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates name and slug of a test series
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}
# operationId: test_patchTestSeries
export def "v0-1-apps-test-series update" [
  owner_name: string
  app_name: string
  test_series_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the new test series
]: any -> record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_series_slug | is-empty) { error make --unspanned { msg: "path parameter 'test_series_slug' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_series_slug: (encode-path-segment $test_series_slug)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns list of all test runs for a given test series
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}/test_runs
# operationId: test_getAllTestRunsForSeries
export def "v0-1-apps-test-series-test-runs get-list" [
  owner_name: string
  app_name: string
  test_series_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($test_series_slug | is-empty) { error make --unspanned { msg: "path parameter 'test_series_slug' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), test_series_slug: (encode-path-segment $test_series_slug)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}/test_runs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the testers associated with the app specified with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}/testers
# operationId: apps_listTesters
export def "v0-1-apps-testers list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/testers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete the given tester from the all releases
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/testers/{tester_id}
# operationId: releases_deleteTesterFromDestinations
export def "v0-1-apps-testers delete-releases-from-destinations" [
  owner_name: string
  app_name: string
  tester_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($tester_id | is-empty) { error make --unspanned { msg: "path parameter 'tester_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), tester_id: (encode-path-segment $tester_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/testers/{tester_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns available toolsets for application
#
# GET /v0.1/apps/{owner_name}/{app_name}/toolsets
# operationId: builds_listToolsets
export def "v0-1-apps-toolsets list-builds" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tools: string@tools-completer # Toolset name
]: nothing -> record<node: table<current: bool, name: string>, xamarin: table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list>, xcode: table<current: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let qp = [(serialize-qp "tools" $tools "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/toolsets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tools": $tools} | compact), body: null}
}

# Transfers ownership of an app to a different user or organization
#
# POST /v0.1/apps/{owner_name}/{app_name}/transfer/{destination_owner_name}
# operationId: apps_transferOwnership
export def "v0-1-apps-transfer create-ownership" [
  owner_name: string
  app_name: string
  destination_owner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($destination_owner_name | is-empty) { error make --unspanned { msg: "path parameter 'destination_owner_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), destination_owner_name: (encode-path-segment $destination_owner_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/transfer/{destination_owner_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transfers ownership of an app to a new organization
#
# POST /v0.1/apps/{owner_name}/{app_name}/transfer_to_org
# operationId: apps_transferToOrg
export def "v0-1-apps-transfer-to-org create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/transfer_to_org"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiate a new release upload. This API is part of multi-step upload process.
#
# POST /v0.1/apps/{owner_name}/{app_name}/uploads/releases
# operationId: releases_createReleaseUpload
export def "v0-1-apps-uploads-releases create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-number: string # User defined build number
  --build-version: string # User defined build version
]: any -> record<id: string, package_asset_id: string, token: string, upload_domain: string, url_encoded_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/uploads/releases"))
  let req_body = {"build_number": $build_number, "build_version": $build_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the current status of the release upload.
#
# GET /v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}
# operationId: releases_getReleaseUploadStatus
export def "v0-1-apps-uploads-releases get-status" [
  owner_name: string
  app_name: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error_details: string, id: string, release_distinct_id: float, release_url: any, upload_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'upload_id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the current status of the release upload.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}
# operationId: releases_updateReleaseUploadStatus
export def "v0-1-apps-uploads-releases update-status" [
  owner_name: string
  app_name: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extract: oneof<nothing, bool> # A flag that indicates to extract release or not, true by default
  upload_status: string@upload-status-completer # The new status of the release upload
]: any -> record<id: string, upload_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'upload_id' must be non-empty" } }
  let qp = [(serialize-qp "extract" $extract "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}") $qp)
  let req_body = {"upload_status": $upload_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"extract": $extract} | compact), body: $req_body}
}

# Lists device sets belonging to the user
#
# GET /v0.1/apps/{owner_name}/{app_name}/user/device_sets
# operationId: test_listDeviceSetsOfUser
export def "v0-1-apps-user-device-sets test-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/user/device_sets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a device set belonging to the user
#
# POST /v0.1/apps/{owner_name}/{app_name}/user/device_sets
# operationId: test_createDeviceSetOfUser
export def "v0-1-apps-user-device-sets test-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/user/device_sets"))
  let req_body = {"devices": $devices, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a device set belonging to the user
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# operationId: test_deleteDeviceSetOfUser
export def "v0-1-apps-user-device-sets test-delete" [
  owner_name: string
  app_name: string
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a device set belonging to the user
#
# GET /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# operationId: test_getDeviceSetOfUser
export def "v0-1-apps-user-device-sets test-get" [
  owner_name: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a device set belonging to the user
#
# PUT /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# operationId: test_updateDeviceSetOfUser
export def "v0-1-apps-user-device-sets test-update" [
  owner_name: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"))
  let req_body = {"devices": $devices, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the users associated with the app specified with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}/users
# operationId: users_list
export def "v0-1-apps-users list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes the user from the app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/users/{user_email}
# operationId: apps_removeUser
export def "v0-1-apps-users delete" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($user_email | is-empty) { error make --unspanned { msg: "path parameter 'user_email' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), user_email: (encode-path-segment $user_email)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/users/{user_email}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update user permission for the app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/users/{user_email}
# operationId: apps_updateUserPermissions
export def "v0-1-apps-users update-permissions" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions the user has for the app
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  if ($user_email | is-empty) { error make --unspanned { msg: "path parameter 'user_email' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name), user_email: (encode-path-segment $user_email)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/users/{user_email}"))
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of application versions.
#
# GET /v0.1/apps/{owner_name}/{app_name}/versions
# DEPRECATED
# operationId: crashes_getAppVersions
@deprecated
export def "v0-1-apps-versions get-crashes" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<app_id: string, app_version: string, app_version_id: string, build_number: string, display_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get web hooks configured for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/webhooks
# operationId: webhooks_list
export def "v0-1-apps-webhooks list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<values: table<enabled: bool, event_types: list, id: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the Xamarin SDK bundles available to this app
#
# GET /v0.1/apps/{owner_name}/{app_name}/xamarin_sdk_bundles
# DEPRECATED
# operationId: builds_listXamarinSDKBundles
@deprecated
export def "v0-1-apps-xamarin-sdk-bundles list-builds" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/xamarin_sdk_bundles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the Xcode versions available to this app
#
# GET /v0.1/apps/{owner_name}/{app_name}/xcode_versions
# DEPRECATED
# operationId: builds_listXcodeVersions
@deprecated
export def "v0-1-apps-xcode-versions list-builds" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<current: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/apps/{owner_name}/{app_name}/xcode_versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of azure subscriptions for the user
#
# GET /v0.1/azure_subscriptions
# operationId: azureSubscription_listForUser
export def "v0-1-azure-subscriptions list-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/azure_subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Aggregated Billing Information for the requesting user and the organizations in which the user is an admin.
#
# GET /v0.1/billing/allAccountsAggregated
# operationId: billingAggregatedInformation_getAll
export def "v0-1-billing-all-accounts-aggregated get-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> record<aggregatedBillings: record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record, testService: record>, id: string, timestamp: string, usage: record<buildService: record, testService: record>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "showOriginalPlans" $show_original_plans "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0.1/billing/allAccountsAggregated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"service": $service, "period": $period, "showOriginalPlans": $show_original_plans} | compact), body: null}
}

# Returns all invitations sent by the caller
#
# GET /v0.1/invitations/sent
# operationId: invitations_sent
export def "v0-1-invitations-sent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record, release_type: string, app_secret: string, azure_subscription: record, created_at: string, member_permissions: list, origin: string, platform: string, updated_at: string>, invitation_id: string, organization: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/invitations/sent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Report deploy of specified release
#
# POST /v0.1/legacy/reportStatus/deploy
# operationId: legacyCodePushAcquisition_updateInstallsStatus
export def "v0-1-legacy-report-status-deploy push-code-acquisition-update-installs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  --deployment-key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/legacy/reportStatus/deploy")
  let req_body = {"appVersion": $app_version, "clientUniqueId": $client_unique_id, "deploymentKey": $deployment_key, "label": $label, "previousDeploymentKey": $previous_deployment_key, "previousLabelOrAppVersion": $previous_label_or_app_version, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Report download of specified release
#
# POST /v0.1/legacy/reportStatus/download
# operationId: legacyCodePushAcquisition_updateDownloadStatus
export def "v0-1-legacy-report-status-download push-code-acquisition-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  --deployment-key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/legacy/reportStatus/download")
  let req_body = {"appVersion": $app_version, "clientUniqueId": $client_unique_id, "deploymentKey": $deployment_key, "label": $label, "previousDeploymentKey": $previous_deployment_key, "previousLabelOrAppVersion": $previous_label_or_app_version, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check for updates
#
# GET /v0.1/legacy/updateCheck
# operationId: legacyCodePushAcquisition_updateCheck
export def "v0-1-legacy-update-check push-code-acquisition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-key: string
  --app-version: string
  --package-hash: string
  --label: string
  --client-unique-id: string
  --is-companion: string
]: nothing -> record<updateInfo: record<appVersion: string, description: string, isDisabled: bool, isMandatory: bool, rollout: int, downloadURL: string, isAvailable: bool, label: string, packageHash: string, packageSize: float, shouldRunBinaryVersion: bool, updateAppVersion: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploymentKey" $deployment_key "scalar") (serialize-qp "appVersion" $app_version "scalar") (serialize-qp "packageHash" $package_hash "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "clientUniqueId" $client_unique_id "scalar") (serialize-qp "isCompanion" $is_companion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0.1/legacy/updateCheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deploymentKey": $deployment_key, "appVersion": $app_version, "packageHash": $package_hash, "label": $label, "clientUniqueId": $client_unique_id, "isCompanion": $is_companion} | compact), body: null}
}

# Returns a list of organizations the requesting user has access to
#
# GET /v0.1/orgs
# operationId: organizations_list
export def "v0-1-orgs list-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_name: string, name: string, origin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/orgs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new organization and returns it to the caller
#
# POST /v0.1/orgs
# operationId: organizations_createOrUpdate
export def "v0-1-orgs create-organizations-or-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the organization
  --name: string # The name of the organization used in URLs
]: any -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/orgs")
  let req_body = {"display_name": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Aggregated Billing Information for a given Organization.
#
# GET /v0.1/orgs/{orgName}/billing/aggregated
# operationId: billingAggregatedInformation_getForOrg
export def "v0-1-orgs-billing-aggregated get-information" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'orgName' must be non-empty" } }
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "showOriginalPlans" $show_original_plans "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/billing/aggregated") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"service": $service, "period": $period, "showOriginalPlans": $show_original_plans} | compact), body: null}
}

# Deletes a single organization
#
# DELETE /v0.1/orgs/{org_name}
# operationId: organizations_delete
export def "v0-1-orgs delete-organizations" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the details of a single organization
#
# GET /v0.1/orgs/{org_name}
# operationId: organizations_get
export def "v0-1-orgs get-organizations" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of organizations the requesting user has access to
#
# PATCH /v0.1/orgs/{org_name}
# operationId: organizations_update
export def "v0-1-orgs update-organizations" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The full (friendly) name of the organization.
  --name: string # The name of the organization used in URLs
]: any -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}"))
  let req_body = {"display_name": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of apps for the organization
#
# GET /v0.1/orgs/{org_name}/apps
# operationId: apps_listForOrg
export def "v0-1-orgs-apps list" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new app for the organization and returns it to the caller
#
# POST /v0.1/orgs/{org_name}/apps
# operationId: apps_createForOrg
export def "v0-1-orgs-apps create" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  display_name: string # The descriptive name of the app. This can contain any characters
  --name: string # The name of the app used in URLs
  os: string@os-completer # The OS the app will be running on
  platform: string@platform-completer # The platform of the app
  --release-type: string # A one-word descriptive release-type value that starts with a capital letter but is otherwise lowercase
]: any -> record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/apps"))
  let req_body = {"description": $description, "display_name": $display_name, "name": $name, "os": $os, "platform": $platform, "release_type": $release_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the uploaded organization avatar
#
# DELETE /v0.1/orgs/{org_name}/avatar
# operationId: organization_deleteAvatar
export def "v0-1-orgs-avatar delete-organization" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/avatar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the organization avatar
#
# POST /v0.1/orgs/{org_name}/avatar
# operationId: organization_updateAvatar
export def "v0-1-orgs-avatar update-organization" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The image for an Organization avatar to upload. (format: binary)
]: any -> record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/avatar"))
  let req_body = {"avatar": $avatar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Returns a list of azure subscriptions for the organization
#
# GET /v0.1/orgs/{org_name}/azure_subscriptions
# operationId: azureSubscription_listForOrg
export def "v0-1-orgs-azure-subscriptions list" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/azure_subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of distribution groups in the org specified
#
# GET /v0.1/orgs/{org_name}/distribution_groups
# operationId: distributionGroups_listForOrg
export def "v0-1-orgs-distribution-groups list" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a disribution goup which can be shared across apps under an organization
#
# POST /v0.1/orgs/{org_name}/distribution_groups
# operationId: distributionGroups_createForOrg
export def "v0-1-orgs-distribution-groups create" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the distribution group. If not specified, the name will be used.
  name: string # The name of the distribution group
]: any -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups"))
  let req_body = {"display_name": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a single distribution group from an org with a given distribution group name
#
# DELETE /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_deleteForOrg
export def "v0-1-orgs-distribution-groups delete" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single distribution group in org for a given distribution group name
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_getForOrg
export def "v0-1-orgs-distribution-groups get" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update one given distribution group name in an org
#
# PATCH /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_patchForOrg
export def "v0-1-orgs-distribution-groups update" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-public: oneof<nothing, bool> # Whether the distribution group is public
  --name: string # The name of the distribution group
]: any -> record<display_name: string, id: string, is_public: bool, name: string, origin: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"))
  let req_body = {"is_public": $is_public, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get apps from a distribution group in an org
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps
# operationId: distributionGroups_getApps
export def "v0-1-orgs-distribution-groups-apps get" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, origin: string, platform: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add apps to distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps
# operationId: distributionGroups_addApps
# --apps item shape: {name: string}
export def "v0-1-orgs-distribution-groups-apps create" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps: list # The list of apps to add to distribution group — item shape: {name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps"))
  let req_body = {"apps": $apps} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete apps from distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps/bulk_delete
# operationId: distributionGroups_bulkDeleteApps
# --apps item shape: {name: string}
export def "v0-1-orgs-distribution-groups-apps-bulk-delete delete" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps: list # The list of apps to delete from the distribution group — item shape: {name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps/bulk_delete"))
  let req_body = {"apps": $apps} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of member in the distribution group specified
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members
# operationId: distributionGroups_listUsersForOrg
export def "v0-1-orgs-distribution-groups-members list-users" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accepts an array of user email addresses to get added to the specified group
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members
# operationId: distributionGroups_addUsersForOrg
export def "v0-1-orgs-distribution-groups-members create-users" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> table<code: string, invite_pending: bool, message: string, status: int, user_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete testers from distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members/bulk_delete
# operationId: distributionGroups_bulkDeleteUsers
export def "v0-1-orgs-distribution-groups-members-bulk-delete delete-users" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members/bulk_delete"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend shared distribution group invite notification to previously invited testers
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/resend_invite
# operationId: distributionGroups_resendSharedInvite
export def "v0-1-orgs-distribution-groups-resend-invite resend-shared" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($distribution_group_name | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), distribution_group_name: (encode-path-segment $distribution_group_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/resend_invite"))
  let req_body = {"user_emails": $user_emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of distribution groups with details for an organization
#
# GET /v0.1/orgs/{org_name}/distribution_groups_details
# operationId: distributionGroups_detailsForOrg
export def "v0-1-orgs-distribution-groups-details get" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps-limit: float # The max number of apps to include in the response
]: nothing -> table<display_name: string, id: string, is_public: bool, name: string, origin: string, apps: list<record>, total_apps_count: float, total_users_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let qp = [(serialize-qp "apps_limit" $apps_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/distribution_groups_details") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"apps_limit": $apps_limit} | compact), body: null}
}

# Removes a user's invitation to an organization
#
# DELETE /v0.1/orgs/{org_name}/invitations
# operationId: orgInvitations_delete
export def "v0-1-orgs-invitations delete" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_email: string # The user's email address
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/invitations"))
  let req_body = {"user_email": $user_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the pending invitations for the organization
#
# GET /v0.1/orgs/{org_name}/invitations
# operationId: orgInvitations_listPending
export def "v0-1-orgs-invitations list-pending" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<email: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/invitations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Invites a new or existing user to an organization
#
# POST /v0.1/orgs/{org_name}/invitations
# operationId: orgInvitations_create
export def "v0-1-orgs-invitations create" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role
  user_email: string # The user's email address
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/invitations"))
  let req_body = {"role": $role, "user_email": $user_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Allows the role of an invited user to be changed
#
# PATCH /v0.1/orgs/{org_name}/invitations/{email}
# operationId: orgInvitations_update
export def "v0-1-orgs-invitations update" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role in the organizatiion
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), email: (encode-path-segment $email)} | format pattern "/v0.1/orgs/{org_name}/invitations/{email}"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancels an existing organization invitation for the user and sends a new one
#
# POST /v0.1/orgs/{org_name}/invitations/{email}/resend
# operationId: orgInvitations_sendNewInvitation
export def "v0-1-orgs-invitations-resend send-new" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The role of the user to be added
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), email: (encode-path-segment $email)} | format pattern "/v0.1/orgs/{org_name}/invitations/{email}/resend"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a user's invitation to an organization
#
# POST /v0.1/orgs/{org_name}/invitations/{email}/revoke
# operationId: orgInvitations_
export def "v0-1-orgs-invitations-revoke create" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), email: (encode-path-segment $email)} | format pattern "/v0.1/orgs/{org_name}/invitations/{email}/revoke"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the list of all teams in this org
#
# GET /v0.1/orgs/{org_name}/teams
# operationId: teams_listAll
export def "v0-1-orgs-teams list" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, display_name: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a team and returns it
#
# POST /v0.1/orgs/{org_name}/teams
# operationId: teams_createTeam
export def "v0-1-orgs-teams create" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the team
  display_name: string # The display name of the team
  --name: string # The name of the team
]: any -> table<description: string, display_name: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/teams"))
  let req_body = {"description": $description, "display_name": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a single team
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}
# operationId: teams_delete
export def "v0-1-orgs-teams delete" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the details of a single team
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}
# operationId: teams_getTeam
export def "v0-1-orgs-teams get" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, display_name: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a single team
#
# PATCH /v0.1/orgs/{org_name}/teams/{team_name}
# operationId: teams_update
export def "v0-1-orgs-teams update" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string # The new display name of the team
]: any -> record<description: string, display_name: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}"))
  let req_body = {"display_name": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the apps a team has access to
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}/apps
# operationId: teams_listApps
export def "v0-1-orgs-teams-apps list" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<team_permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds an app to a team
#
# POST /v0.1/orgs/{org_name}/teams/{team_name}/apps
# operationId: teams_addApp
export def "v0-1-orgs-teams-apps create" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the app to be added to the distribution group
]: any -> record<team_permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/apps"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes an app from a team
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}
# operationId: teams_removeApp
export def "v0-1-orgs-teams-apps delete" [
  org_name: string
  team_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the permissions the team has to the app
#
# PATCH /v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}
# operationId: teams_updatePermissions
export def "v0-1-orgs-teams-apps update-permissions" [
  org_name: string
  team_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions all members of the team have on the app
]: any -> record<team_permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}"))
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the users of a team which is owned by an organization
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}/users
# operationId: teams_getUsers
export def "v0-1-orgs-teams-users get" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, email: string, name: string, role: any> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a new user to a team that is owned by an organization
#
# POST /v0.1/orgs/{org_name}/teams/{team_name}/users
# operationId: teams_addUser
export def "v0-1-orgs-teams-users create" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_email: string # The user's email address
]: any -> record<display_name: string, email: string, name: string, role: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/users"))
  let req_body = {"user_email": $user_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a user from a team that is owned by an organization
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}/users/{user_name}
# operationId: teams_removeUser
export def "v0-1-orgs-teams-users delete" [
  org_name: string
  team_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'team_name' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'user_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), team_name: (encode-path-segment $team_name), user_name: (encode-path-segment $user_name)} | format pattern "/v0.1/orgs/{org_name}/teams/{team_name}/users/{user_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a unique list of users including the whole organization members plus testers in any shared group of that org
#
# GET /v0.1/orgs/{org_name}/testers
# operationId: distributionGroups_listAllTestersForOrg
export def "v0-1-orgs-testers list-distribution-groups" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_name: string, email: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/testers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of users that belong to an organization
#
# GET /v0.1/orgs/{org_name}/users
# operationId: users_listForOrg
export def "v0-1-orgs-users list" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_name: string, email: string, joined_at: string, name: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name)} | format pattern "/v0.1/orgs/{org_name}/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes a user from an organization.
#
# DELETE /v0.1/orgs/{org_name}/users/{user_name}
# operationId: users_removeFromOrg
export def "v0-1-orgs-users delete" [
  org_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'user_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), user_name: (encode-path-segment $user_name)} | format pattern "/v0.1/orgs/{org_name}/users/{user_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user information from an organization by name - if there is explicit permission return it, if not if not return highest implicit permission
#
# GET /v0.1/orgs/{org_name}/users/{user_name}
# operationId: users_getForOrg
export def "v0-1-orgs-users get" [
  org_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, email: string, joined_at: string, name: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'user_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), user_name: (encode-path-segment $user_name)} | format pattern "/v0.1/orgs/{org_name}/users/{user_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the given organization user
#
# PATCH /v0.1/orgs/{org_name}/users/{user_name}
# operationId: users_updateOrgRole
export def "v0-1-orgs-users update-role" [
  org_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role in the organizatiion
]: any -> record<display_name: string, email: string, joined_at: string, name: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'user_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), user_name: (encode-path-segment $user_name)} | format pattern "/v0.1/orgs/{org_name}/users/{user_name}"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a user apps information from an organization by name
#
# GET /v0.1/orgs/{org_name}/users/{user_name}/apps
# operationId: apps_getForOrgUser
export def "v0-1-orgs-users-apps get" [
  org_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($org_name | is-empty) { error make --unspanned { msg: "path parameter 'org_name' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'user_name' must be non-empty" } }
  let full_url = (build-url $base ({org_name: (encode-path-segment $org_name), user_name: (encode-path-segment $user_name)} | format pattern "/v0.1/orgs/{org_name}/users/{user_name}/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the manifest.plist in XML format for installing the release on a device. Only available for iOS.
#
# GET /v0.1/public/apps/{app_id}/releases/{release_id}/ios_manifest
# operationId: releases_getIosManifest
export def "v0-1-public-apps-releases-ios-manifest get" [
  app_id: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # A hash that authorizes the download if it matches the release info.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'release_id' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), release_id: (encode-path-segment $release_id)} | format pattern "/v0.1/public/apps/{app_id}/releases/{release_id}/ios_manifest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"token": $qp_token} | compact), body: null}
}

# Notify download(s) for the provided distribution release(s).
#
# POST /v0.1/public/apps/{owner_name}/{app_name}/install_analytics
# operationId: distibutionReleases_installAnalytics
# --releases item shape: {distribution_group_id: string, release_id: int, user_id: string}
export def "v0-1-public-apps-install-analytics create-distibution-releases" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --releases: list # item shape: {distribution_group_id: string, release_id: int, user_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'owner_name' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'app_name' must be non-empty" } }
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name), app_name: (encode-path-segment $app_name)} | format pattern "/v0.1/public/apps/{owner_name}/{app_name}/install_analytics"))
  let req_body = {"releases": $releases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Report Deployment status metric
#
# POST /v0.1/public/codepush/report_status/deploy
# operationId: codePushAcquisition_updateDeployStatus
export def "v0-1-public-codepush-report-status-deploy push-code-acquisition-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  deployment_key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/public/codepush/report_status/deploy")
  let req_body = {"app_version": $app_version, "client_unique_id": $client_unique_id, "deployment_key": $deployment_key, "label": $label, "previous_deployment_key": $previous_deployment_key, "previous_label_or_app_version": $previous_label_or_app_version, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Report download of specified release
#
# POST /v0.1/public/codepush/report_status/download
# operationId: codePushAcquisition_updateDownloadStatus
export def "v0-1-public-codepush-report-status-download push-code-acquisition-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  deployment_key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/public/codepush/report_status/download")
  let req_body = {"app_version": $app_version, "client_unique_id": $client_unique_id, "deployment_key": $deployment_key, "label": $label, "previous_deployment_key": $previous_deployment_key, "previous_label_or_app_version": $previous_label_or_app_version, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the acquisition service status to the caller
#
# GET /v0.1/public/codepush/status
# operationId: codePushAcquisition_getAcquisitionStatus
export def "v0-1-public-codepush-status push-code-acquisition-get-acquisition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/public/codepush/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check for updates
#
# GET /v0.1/public/codepush/update_check
# operationId: codePushAcquisition_updateCheck
export def "v0-1-public-codepush-update-check push-code-acquisition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-key: string
  --app-version: string
  --package-hash: string
  --label: string
  --client-unique-id: string
  --is-companion: oneof<nothing, bool>
  --previous-label-or-app-version: string
  --previous-deployment-key: string
]: nothing -> record<update_info: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, download_url: string, is_available: bool, label: string, package_hash: string, package_size: float, should_run_binary_version: bool, update_app_version: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment_key" $deployment_key "scalar") (serialize-qp "app_version" $app_version "scalar") (serialize-qp "package_hash" $package_hash "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "client_unique_id" $client_unique_id "scalar") (serialize-qp "is_companion" $is_companion "scalar") (serialize-qp "previous_label_or_app_version" $previous_label_or_app_version "scalar") (serialize-qp "previous_deployment_key" $previous_deployment_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0.1/public/codepush/update_check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deployment_key": $deployment_key, "app_version": $app_version, "package_hash": $package_hash, "label": $label, "client_unique_id": $client_unique_id, "is_companion": $is_companion, "previous_label_or_app_version": $previous_label_or_app_version, "previous_deployment_key": $previous_deployment_key} | compact), body: null}
}

# Public webhook sink
#
# POST /v0.1/public/hooks
# operationId: builds_webhook
export def "v0-1-public-hooks create-builds-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/public/hooks")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a release with 'latest' for the given public group.
#
# GET /v0.1/public/sdk/apps/{app_secret}/distribution_groups/{distribution_group_id}/releases/latest
# operationId: releases_getLatestByPublicDistributionGroup
export def "v0-1-public-sdk-apps-distribution-groups-releases-latest get" [
  app_secret: string
  distribution_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  if ($distribution_group_id | is-empty) { error make --unspanned { msg: "path parameter 'distribution_group_id' must be non-empty" } }
  let qp = [(serialize-qp "is_install_page" $is_install_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret), distribution_group_id: (encode-path-segment $distribution_group_id)} | format pattern "/v0.1/public/sdk/apps/{app_secret}/distribution_groups/{distribution_group_id}/releases/latest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"is_install_page": $is_install_page} | compact), body: null}
}

# Get the latest public release for the given app.
#
# GET /v0.1/public/sdk/apps/{app_secret}/releases/latest
# DEPRECATED
# operationId: releases_getLatestPublicRelease
@deprecated
export def "v0-1-public-sdk-apps-releases-latest get" [
  app_secret: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret)} | format pattern "/v0.1/public/sdk/apps/{app_secret}/releases/latest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all public distribution groups that a given release has been distributed to
#
# GET /v0.1/public/sdk/apps/{app_secret}/releases/{release_hash}/public_distribution_groups
# operationId: releases_getPublicGroupsForReleaseByHash
export def "v0-1-public-sdk-apps-releases-public-distribution-groups get-for" [
  app_secret: string
  release_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  if ($release_hash | is-empty) { error make --unspanned { msg: "path parameter 'release_hash' must be non-empty" } }
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret), release_hash: (encode-path-segment $release_hash)} | format pattern "/v0.1/public/sdk/apps/{app_secret}/releases/{release_hash}/public_distribution_groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the sparkle feed of the releases that are distributed to all the public distribution groups.
#
# GET /v0.1/public/sparkle/apps/{app_secret}
# operationId: releases_getSparkleFeed
export def "v0-1-public-sparkle-apps get-releases-feed" [
  app_secret: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret)} | format pattern "/v0.1/public/sparkle/apps/{app_secret}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the latest release distributed to a private group the given user is a member of for the given app.
#
# GET /v0.1/sdk/apps/{app_secret}/releases/private/latest
# operationId: releases_getLatestPrivateRelease
export def "v0-1-sdk-apps-releases-private-latest get" [
  app_secret: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # When passing `udid` in the query string, a provisioning check for the given device ID will be done. Will be ignored for non-iOS platforms.
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  let qp = [(serialize-qp "udid" $udid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret)} | format pattern "/v0.1/sdk/apps/{app_secret}/releases/private/latest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"udid": $udid} | compact), body: null}
}

# If 'latest' is not specified then it will return the specified release if it's enabled. If 'latest' is specified, regardless of whether a release hash is provided, the latest enabled release is returned.
#
# GET /v0.1/sdk/apps/{app_secret}/releases/{release_hash}
# operationId: releases_getLatestByHash
export def "v0-1-sdk-apps-releases get-latest" [
  app_secret: string
  release_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # When passing `udid` in the query string, a provisioning check for the given device ID will be done. Will be ignored for non-iOS platforms.
]: nothing -> record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($app_secret | is-empty) { error make --unspanned { msg: "path parameter 'app_secret' must be non-empty" } }
  if ($release_hash | is-empty) { error make --unspanned { msg: "path parameter 'release_hash' must be non-empty" } }
  let qp = [(serialize-qp "udid" $udid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_secret: (encode-path-segment $app_secret), release_hash: (encode-path-segment $release_hash)} | format pattern "/v0.1/sdk/apps/{app_secret}/releases/{release_hash}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"udid": $udid} | compact), body: null}
}

# Returns the user profile data
#
# GET /v0.1/user
# operationId: users_get
export def "v0-1-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the user profile and returns the updated user data
#
# PATCH /v0.1/user
# operationId: users_update
export def "v0-1-user update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The full name of the user. Might for example be first and last name
]: any -> record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user")
  let req_body = {"display_name": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns all devices associated with the given user.
#
# GET /v0.1/user/devices
# operationId: devices_userDevicesList
export def "v0-1-user-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes an existing device from a user
#
# DELETE /v0.1/user/devices/{device_udid}
# operationId: devices_removeUserDevice
export def "v0-1-user-devices delete" [
  device_udid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_udid | is-empty) { error make --unspanned { msg: "path parameter 'device_udid' must be non-empty" } }
  let full_url = (build-url $base ({device_udid: (encode-path-segment $device_udid)} | format pattern "/v0.1/user/devices/{device_udid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the device details.
#
# GET /v0.1/user/devices/{device_udid}
# operationId: devices_deviceDetails
export def "v0-1-user-devices get-details" [
  device_udid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_udid | is-empty) { error make --unspanned { msg: "path parameter 'device_udid' must be non-empty" } }
  let full_url = (build-url $base ({device_udid: (encode-path-segment $device_udid)} | format pattern "/v0.1/user/devices/{device_udid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v0.1/user/dsr/delete
#
# operationId: DataSubjectRight_DeleteRequest
export def "v0-1-user-dsr-delete request-data-subject-right" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/dsr/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v0.1/user/dsr/delete/{token}
#
# operationId: DataSubjectRight_DeleteStatusRequest
export def "v0-1-user-dsr-delete request-data-subject-right-status" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email used for delete with x-authz-bypass headers
]: nothing -> record<message: string, sasUrl: string, sasUrlExpired: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/v0.1/user/dsr/delete/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email} | compact), body: null}
}

# POST /v0.1/user/dsr/delete/{token}/cancel
#
# operationId: DataSubjectRight_CancelDeleteRequest
export def "v0-1-user-dsr-delete-cancel request-data-subject-right" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email used for cancel delete with x-authz-bypass headers
]: any -> record<createdAt: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/v0.1/user/dsr/delete/{token_arg}/cancel"))
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /v0.1/user/dsr/export
#
# operationId: DataSubjectRight_ExportRequest
export def "v0-1-user-dsr-export request-data-subject-right" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/dsr/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v0.1/user/dsr/export/{token}
#
# operationId: DataSubjectRight_ExportStatusRequest
export def "v0-1-user-dsr-export request-data-subject-right-status" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, sasUrl: string, sasUrlExpired: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/v0.1/user/dsr/export/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v0.1/user/dsr/export/{token}/cancel
#
# operationId: DataSubjectRight_CancelExportRequest
export def "v0-1-user-dsr-export-cancel request-data-subject-right" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/v0.1/user/dsr/export/{token_arg}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all service connections of the service type for GDPR export.
#
# GET /v0.1/user/export/serviceConnections
# operationId: sharedconnection_Connections
export def "v0-1-user-export-service-connections get-sharedconnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<credentialType: string, displayName: string, serviceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/export/serviceConnections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accepts a pending invitation for the specified user
#
# POST /v0.1/user/invitations/apps/{invitation_token}/accept
# operationId: appInvitations_accept
export def "v0-1-user-invitations-apps-accept create" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invitation_token | is-empty) { error make --unspanned { msg: "path parameter 'invitation_token' must be non-empty" } }
  let full_url = (build-url $base ({invitation_token: (encode-path-segment $invitation_token)} | format pattern "/v0.1/user/invitations/apps/{invitation_token}/accept"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Rejects a pending invitation for the specified user
#
# POST /v0.1/user/invitations/apps/{invitation_token}/reject
# operationId: appInvitations_reject
export def "v0-1-user-invitations-apps-reject reject" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invitation_token | is-empty) { error make --unspanned { msg: "path parameter 'invitation_token' must be non-empty" } }
  let full_url = (build-url $base ({invitation_token: (encode-path-segment $invitation_token)} | format pattern "/v0.1/user/invitations/apps/{invitation_token}/reject"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Accepts all pending invitations to distribution groups for the specified user
#
# POST /v0.1/user/invitations/distribution_groups/accept
# operationId: distributionGroupInvitations_acceptAll
export def "v0-1-user-invitations-distribution-groups-accept list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/invitations/distribution_groups/accept")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Accepts a pending organization invitation for the specified user
#
# POST /v0.1/user/invitations/orgs/{invitation_token}/accept
# operationId: orgInvitations_accept
export def "v0-1-user-invitations-orgs-accept create" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invitation_token | is-empty) { error make --unspanned { msg: "path parameter 'invitation_token' must be non-empty" } }
  let full_url = (build-url $base ({invitation_token: (encode-path-segment $invitation_token)} | format pattern "/v0.1/user/invitations/orgs/{invitation_token}/accept"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Rejects a pending organization invitation
#
# POST /v0.1/user/invitations/orgs/{invitation_token}/reject
# operationId: orgInvitations_reject
export def "v0-1-user-invitations-orgs-reject reject" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invitation_token | is-empty) { error make --unspanned { msg: "path parameter 'invitation_token' must be non-empty" } }
  let full_url = (build-url $base ({invitation_token: (encode-path-segment $invitation_token)} | format pattern "/v0.1/user/invitations/orgs/{invitation_token}/reject"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /v0.1/user/metadata/optimizely
#
# operationId: Users_getUserMetadata
export def "v0-1-user-metadata-optimizely get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: record, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/metadata/optimizely")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Default email notification settings for the user
#
# GET /v0.1/user/notifications/emailSettings
# operationId: notifications_getUserEmailSettings
export def "v0-1-user-notifications-email-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.1/user/notifications/emailSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Registers a user for an existing device
#
# POST /v0.1/users/{user_id}/devices/register
# operationId: devices_registerUserForDevice
export def "v0-1-users-devices-register create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --imei: string # The device's International Mobile Equipment Identity number. Always empty or undefined at present.
  model: string # The model identifier of the device, in the format iDeviceM,N
  --os-build: string # The build number of the last known OS version running on the device
  --os-version: string # The last known OS version running on the device
  --owner-id: string # The user ID of the device owner.
  --serial: string # The device's serial number. Always empty or undefined at present.
  udid: string # The Unique Device IDentifier of the device
]: any -> record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v0.1/users/{user_id}/devices/register"))
  let req_body = {"imei": $imei, "model": $model, "os_build": $os_build, "os_version": $os_version, "owner_id": $owner_id, "serial": $serial, "udid": $udid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
