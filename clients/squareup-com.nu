# Auto-generated client for Square Connect API v2.0
# Source: https://api.apis.guru/v2/specs/squareup.com/2.0/openapi.json
# Auth: --token flag or $env.SQUARE_CONNECT_API_TOKEN

const BASE_URL = "https://connect.squareup.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SQUARE_CONNECT_API_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://connect.squareup.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "mobile-authorization-code create" } } | get name | first)
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

# CreateMobileAuthorizationCode
#
# POST /mobile/authorization-code
# operationId: CreateMobileAuthorizationCode
export def "mobile-authorization-code create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The Square location ID the authorization code should be tied to.
]: any -> record<authorization_code: string, error: record<category: string, code: string, detail: string, field: string>, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mobile/authorization-code" $auth.query)
  let req_body = {"location_id": $location_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RenewToken
#
# POST /oauth2/clients/{client_id}/access-token/renew
# operationId: RenewToken
export def "oauth2-clients-access-token-renew create" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The token you want to renew.
]: any -> record<access_token: string, expires_at: string, merchant_id: string, plan_id: string, subscription_id: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'client_id' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/oauth2/clients/{client_id}/access-token/renew") $auth.query)
  let req_body = {"access_token": $access_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RevokeToken
#
# POST /oauth2/revoke
# operationId: RevokeToken
export def "oauth2-revoke delete-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token of the merchant whose token you want to revoke. Do not provide a value for merchant_id if you provide this parameter.
  --client-id: string # The Square issued ID for your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  --merchant-id: string # The ID of the merchant whose token you want to revoke. Do not provide a value for access_token if you provide this parameter.
  --revoke-only-access-token: oneof<nothing, bool> # If `true`, terminate the given single access token, but do not terminate the entire authorization. Default: `false`
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/revoke" $auth.query)
  let req_body = {"access_token": $access_token, "client_id": $client_id, "merchant_id": $merchant_id, "revoke_only_access_token": $revoke_only_access_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ObtainToken
#
# POST /oauth2/token
# operationId: ObtainToken
export def "oauth2-token create-obtain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The Square-issued ID of your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  client_secret: string # The Square-issued application secret for your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  --code: string # The authorization code to exchange. This is required if `grant_type` is set to `authorization_code`, to indicate that the application wants to exchange an authorization code for an OAuth access token.
  grant_type: string # Specifies the method to request an OAuth access token. Valid values are: `authorization_code`, `refresh_token`, and `migration_token`
  --migration-token: string # Legacy OAuth access token obtained using a Connect API version prior to 2019-03-13. This parameter is required if `grant_type` is set to `migration_token` to indicate that the application wants to get a replacement OAuth access token. The response also returns a refresh token. For more information, see [Migrate to Using Refresh Tokens](https://developer.squareup.com/docs/oauth-api/migrate-to-refresh-tokens).
  --redirect-uri: string # The redirect URL assigned in the [developer dashboard](https://developer.squareup.com/apps).
  --refresh-token: string # A valid refresh token for generating a new OAuth access token. A valid refresh token is required if `grant_type` is set to `refresh_token` , to indicate the application wants a replacement for an expired OAuth access token.
  --scopes: list<string> # A JSON list of strings representing the permissions the application is requesting. For example: "`["MERCHANT_PROFILE_READ","PAYMENTS_READ","BANK_ACCOUNTS_READ"]`" The access token returned in the response is granted the permissions that comprise the intersection between the requested list of permissions, and those that belong to the provided refresh token.
  --short-lived: oneof<nothing, bool> # A boolean indicating a request for a short-lived access token. The short-lived access token returned in the response will expire in 24 hours.
]: any -> record<access_token: string, expires_at: string, id_token: string, merchant_id: string, plan_id: string, refresh_token: string, short_lived: bool, subscription_id: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token" $auth.query)
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "code": $code, "grant_type": $grant_type, "migration_token": $migration_token, "redirect_uri": $redirect_uri, "refresh_token": $refresh_token, "scopes": $scopes, "short_lived": $short_lived} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListEmployees
#
# GET /v1/me/employees
# operationId: ListEmployees
export def "me-employees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which employees are listed in the response, based on their created_at field. Default value: ASC
  --begin-updated-at: string # If filtering results by their updated_at field, the beginning of the requested reporting period, in ISO 8601 format
  --end-updated-at: string # If filtering results by there updated_at field, the end of the requested reporting period, in ISO 8601 format.
  --begin-created-at: string # If filtering results by their created_at field, the beginning of the requested reporting period, in ISO 8601 format.
  --end-created-at: string # If filtering results by their created_at field, the end of the requested reporting period, in ISO 8601 format.
  --status: string # If provided, the endpoint returns only employee entities with the specified status (ACTIVE or INACTIVE).
  --external-id: string # If provided, the endpoint returns only employee entities with the specified external_id.
  --limit: int # The maximum integer number of employee entities to return in a single response. Default 100, maximum 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "begin_updated_at" $begin_updated_at "scalar") (serialize-qp "end_updated_at" $end_updated_at "scalar") (serialize-qp "begin_created_at" $begin_created_at "scalar") (serialize-qp "end_created_at" $end_created_at "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/employees" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "begin_updated_at": $begin_updated_at, "end_updated_at": $end_updated_at, "begin_created_at": $begin_created_at, "end_created_at": $end_created_at, "status": $status, "external_id": $external_id, "limit": $limit, "batch_token": $batch_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateEmployee
#
# POST /v1/me/employees
# operationId: CreateEmployee
export def "me-employees create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-location-ids: list<string> # The IDs of the locations the employee is allowed to clock in at.
  --created-at: string # The time when the employee entity was created, in ISO 8601 format.
  --email: string # The employee's email address.
  --external-id: string # An ID the merchant can set to associate the employee with an entity in another system.
  first_name: string # The employee's first name.
  --id: string # The employee's unique ID.
  last_name: string # The employee's last name.
  --role-ids: list<string> # The ids of the employee's associated roles. Currently, you can specify only one or zero roles per employee.
  --status: string # Whether the employee is ACTIVE or INACTIVE. Inactive employees cannot sign in to Square Register.Merchants update this field from the Square Dashboard.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format.
]: any -> record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/employees" $auth.query)
  let req_body = {"authorized_location_ids": $authorized_location_ids, "created_at": $created_at, "email": $email, "external_id": $external_id, "first_name": $first_name, "id": $id, "last_name": $last_name, "role_ids": $role_ids, "status": $status, "updated_at": $updated_at} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveEmployee
#
# GET /v1/me/employees/{employee_id}
# operationId: RetrieveEmployee
export def "me-employees get" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employee_id' must be non-empty" } }
  let full_url = (build-url $base ({employee_id: (encode-path-segment $employee_id)} | format pattern "/v1/me/employees/{employee_id}") $auth.query)
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

# UpdateEmployee
#
# PUT /v1/me/employees/{employee_id}
# operationId: UpdateEmployee
export def "me-employees update" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-location-ids: list<string> # The IDs of the locations the employee is allowed to clock in at.
  --created-at: string # The time when the employee entity was created, in ISO 8601 format.
  --email: string # The employee's email address.
  --external-id: string # An ID the merchant can set to associate the employee with an entity in another system.
  first_name: string # The employee's first name.
  --id: string # The employee's unique ID.
  last_name: string # The employee's last name.
  --role-ids: list<string> # The ids of the employee's associated roles. Currently, you can specify only one or zero roles per employee.
  --status: string # Whether the employee is ACTIVE or INACTIVE. Inactive employees cannot sign in to Square Register.Merchants update this field from the Square Dashboard.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format.
]: any -> record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employee_id' must be non-empty" } }
  let full_url = (build-url $base ({employee_id: (encode-path-segment $employee_id)} | format pattern "/v1/me/employees/{employee_id}") $auth.query)
  let req_body = {"authorized_location_ids": $authorized_location_ids, "created_at": $created_at, "email": $email, "external_id": $external_id, "first_name": $first_name, "id": $id, "last_name": $last_name, "role_ids": $role_ids, "status": $status, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListEmployeeRoles
#
# GET /v1/me/roles
# operationId: ListEmployeeRoles
export def "me-roles list-employee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which employees are listed in the response, based on their created_at field.Default value: ASC
  --limit: int # The maximum integer number of employee entities to return in a single response. Default 100, maximum 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/roles" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "limit": $limit, "batch_token": $batch_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateEmployeeRole
#
# POST /v1/me/roles
# operationId: CreateEmployeeRole
export def "me-roles create-employee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The time when the employee entity was created, in ISO 8601 format. Is set by Square when the Role is created.
  --id: string # The role's unique ID, Can only be set by Square.
  --is-owner: oneof<nothing, bool> # If true, employees with this role have all permissions, regardless of the values indicated in permissions.
  name: string # The role's merchant-defined name.
  permissions: list<string> # The role's permissions.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format. Is set by Square when the Role updated.
]: any -> record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/roles" $auth.query)
  let req_body = {"created_at": $created_at, "id": $id, "is_owner": $is_owner, "name": $name, "permissions": $permissions, "updated_at": $updated_at} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveEmployeeRole
#
# GET /v1/me/roles/{role_id}
# operationId: RetrieveEmployeeRole
export def "me-roles get-employee" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role_id' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/v1/me/roles/{role_id}") $auth.query)
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

# UpdateEmployeeRole
#
# PUT /v1/me/roles/{role_id}
# operationId: UpdateEmployeeRole
export def "me-roles update-employee" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The time when the employee entity was created, in ISO 8601 format. Is set by Square when the Role is created.
  --id: string # The role's unique ID, Can only be set by Square.
  --is-owner: oneof<nothing, bool> # If true, employees with this role have all permissions, regardless of the values indicated in permissions.
  name: string # The role's merchant-defined name.
  permissions: list<string> # The role's permissions.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format. Is set by Square when the Role updated.
]: any -> record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role_id' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/v1/me/roles/{role_id}") $auth.query)
  let req_body = {"created_at": $created_at, "id": $id, "is_owner": $is_owner, "name": $name, "permissions": $permissions, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListOrders
#
# GET /v1/{location_id}/orders
# operationId: ListOrders
export def "orders list" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --limit: int # The maximum number of payments to return in a single response. This value cannot exceed 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: list<record>, expires_at: string, id: string, order_history: list<record>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/{location_id}/orders") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "limit": $limit, "batch_token": $batch_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveOrder
#
# GET /v1/{location_id}/orders/{order_id}
# operationId: RetrieveOrder
export def "orders get" [
  location_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), order_id: (encode-path-segment $order_id)} | format pattern "/v1/{location_id}/orders/{order_id}") $auth.query)
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

# UpdateOrder
#
# PUT /v1/{location_id}/orders/{order_id}
# operationId: UpdateOrder
export def "orders update-by-location-id-order-id" [
  location_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # The action to perform on the order (COMPLETE, CANCEL, or REFUND).
  --canceled-note: string # A merchant-specified note about the canceling of the order. Only valid if action is CANCEL.
  --completed-note: string # A merchant-specified note about the completion of the order. Only valid if action is COMPLETE.
  --refunded-note: string # A merchant-specified note about the refunding of the order. Only valid if action is REFUND.
  --shipped-tracking-number: string # The tracking number of the shipment associated with the order. Only valid if action is COMPLETE.
]: any -> record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), order_id: (encode-path-segment $order_id)} | format pattern "/v1/{location_id}/orders/{order_id}") $auth.query)
  let req_body = {"action": $action, "canceled_note": $canceled_note, "completed_note": $completed_note, "refunded_note": $refunded_note, "shipped_tracking_number": $shipped_tracking_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListPayments
#
# GET /v1/{location_id}/payments
# operationId: ListPayments
export def "payments list" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The maximum number of payments to return in a single response. This value cannot exceed 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
  --include-partial: oneof<nothing, bool> # Indicates whether or not to include partial payments in the response. Partial payments will have the tenders collected so far, but the itemizations will be empty until the payment is completed.
]: nothing -> table<additive_tax: list<record>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: list<record>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: list<record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: list<record>, surcharge_money: record<amount: int, currency_code: string>, surcharges: list<record>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: list<record>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar") (serialize-qp "include_partial" $include_partial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/{location_id}/payments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "begin_time": $begin_time, "end_time": $end_time, "limit": $limit, "batch_token": $batch_token, "include_partial": $include_partial} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrievePayment
#
# GET /v1/{location_id}/payments/{payment_id}
# operationId: RetrievePayment
export def "payments get-by-location-id-payment-id" [
  location_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: table<discount_money: record, discounts: list, gross_sales_money: record, item_detail: record, item_variation_name: string, itemization_type: string, modifiers: list, name: string, net_sales_money: record, notes: string, quantity: float, single_quantity_money: record, taxes: list, total_money: record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list, refunded_additive_tax_money: record, refunded_discount_money: record, refunded_inclusive_tax: list, refunded_inclusive_tax_money: record, refunded_money: record, refunded_processing_fee_money: record, refunded_surcharge_money: record, refunded_surcharges: list, refunded_tax_money: record, refunded_tip_money: record, type: string>, surcharge_money: record<amount: int, currency_code: string>, surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: table<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{location_id}/payments/{payment_id}") $auth.query)
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

# ListRefunds
#
# GET /v1/{location_id}/refunds
# operationId: ListRefunds
export def "refunds list" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The approximate number of refunds to return in a single response. Default: 100. Max: 200. Response may contain more results than the prescribed limit when refunds are made simultaneously to multiple tenders in a payment or when refunds are generated in an exchange to account for the value of returned goods.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list<record>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: list<record>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: list<record>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/{location_id}/refunds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "begin_time": $begin_time, "end_time": $end_time, "limit": $limit, "batch_token": $batch_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateRefund
#
# POST /v1/{location_id}/refunds
# operationId: CreateRefund
# --refunded_money shape: {amount?: int, currency_code?: string}
export def "refunds create" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payment_id: string # The ID of the payment to refund. If you are creating a `PARTIAL` refund for a split tender payment, instead provide the id of the particular tender you want to refund.
  reason: string # The reason for the refund.
  --refunded-money: record # shape: {amount?: int, currency_code?: string}
  --request-idempotence-key: string # An optional key to ensure idempotence if you issue the same PARTIAL refund request more than once.
  type: string # The type of refund (FULL or PARTIAL).
]: any -> record<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/{location_id}/refunds") $auth.query)
  let req_body = {"payment_id": $payment_id, "reason": $reason, "refunded_money": $refunded_money, "request_idempotence_key": $request_idempotence_key, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListSettlements
#
# GET /v1/{location_id}/settlements
# operationId: ListSettlements
export def "settlements list" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which settlements are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The maximum number of settlements to return in a single response. This value cannot exceed 200.
  --status: string # Provide this parameter to retrieve only settlements with a particular status (SENT or FAILED).
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<bank_account_id: string, entries: list<record>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/{location_id}/settlements") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order, "begin_time": $begin_time, "end_time": $end_time, "limit": $limit, "status": $status, "batch_token": $batch_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveSettlement
#
# GET /v1/{location_id}/settlements/{settlement_id}
# operationId: RetrieveSettlement
export def "settlements get" [
  location_id: string
  settlement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bank_account_id: string, entries: table<amount_money: record, fee_money: record, payment_id: string, type: string>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($settlement_id | is-empty) { error make --unspanned { msg: "path parameter 'settlement_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), settlement_id: (encode-path-segment $settlement_id)} | format pattern "/v1/{location_id}/settlements/{settlement_id}") $auth.query)
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

# RegisterDomain
#
# POST /v2/apple-pay/domains
# operationId: RegisterDomain
export def "apple-pay-domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  domain_name: string # A domain name as described in RFC-1034 that will be registered with ApplePay.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apple-pay/domains" $auth.query)
  let req_body = {"domain_name": $domain_name} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListBankAccounts
#
# GET /v2/bank-accounts
# operationId: ListBankAccounts
export def "bank-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The pagination cursor returned by a previous call to this endpoint. Use it in the next `ListBankAccounts` request to retrieve the next set of results. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --limit: int # Upper limit on the number of bank accounts to return in the response. Currently, 1000 is the largest supported limit. You can specify a limit of up to 1000 bank accounts. This is also the default limit.
  --location-id: string # Location ID. You can specify this optional filter to retrieve only the linked bank accounts belonging to a specific location.
]: nothing -> record<bank_accounts: table<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bank-accounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit, "location_id": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GetBankAccountByV1Id
#
# GET /v2/bank-accounts/by-v1-id/{v1_bank_account_id}
# operationId: GetBankAccountByV1Id
export def "bank-accounts-by-v1-id get" [
  v1_bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($v1_bank_account_id | is-empty) { error make --unspanned { msg: "path parameter 'v1_bank_account_id' must be non-empty" } }
  let full_url = (build-url $base ({v1_bank_account_id: (encode-path-segment $v1_bank_account_id)} | format pattern "/v2/bank-accounts/by-v1-id/{v1_bank_account_id}") $auth.query)
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

# GetBankAccount
#
# GET /v2/bank-accounts/{bank_account_id}
# operationId: GetBankAccount
export def "bank-accounts get" [
  bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bank_account_id | is-empty) { error make --unspanned { msg: "path parameter 'bank_account_id' must be non-empty" } }
  let full_url = (build-url $base ({bank_account_id: (encode-path-segment $bank_account_id)} | format pattern "/v2/bank-accounts/{bank_account_id}") $auth.query)
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

# CreateBooking
#
# POST /v2/bookings
# operationId: CreateBooking
# --booking shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
export def "bookings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings" $auth.query)
  let req_body = {"booking": $booking, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchAvailability
#
# POST /v2/bookings/availability/search
# operationId: SearchAvailability
# --query shape: {filter: record}
export def "bookings-availability-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  query: record # Query conditions to search for availabilities of bookings. — shape: {filter: record}
]: any -> record<availabilities: table<appointment_segments: list, location_id: string, start_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/availability/search" $auth.query)
  let req_body = {"query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveBusinessBookingProfile
#
# GET /v2/bookings/business-booking-profile
# operationId: RetrieveBusinessBookingProfile
export def "bookings-business-booking-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<business_booking_profile: record<allow_user_cancel: bool, booking_enabled: bool, booking_policy: string, business_appointment_settings: record<alignment_time: string, any_team_member_booking_enabled: bool, cancellation_fee_money: record, cancellation_policy: string, cancellation_policy_text: string, cancellation_window_seconds: int, location_types: list, max_appointments_per_day_limit: int, max_appointments_per_day_limit_type: string, max_booking_lead_time_seconds: int, min_booking_lead_time_seconds: int, multiple_service_booking_enabled: bool, skip_booking_flow_staff_selection: bool>, created_at: string, customer_timezone_choice: string, seller_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/business-booking-profile" $auth.query)
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

# ListTeamMemberBookingProfiles
#
# GET /v2/bookings/team-member-booking-profiles
# operationId: ListTeamMemberBookingProfiles
export def "bookings-team-member-booking-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bookable-only: oneof<nothing, bool> # Indicates whether to include only bookable team members in the returned result (`true`) or not (`false`).
  --limit: int # The maximum number of results to return.
  --cursor: string # The cursor for paginating through the results.
  --location-id: string # Indicates whether to include only team members enabled at the given location in the returned result.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profiles: table<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookable_only" $bookable_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings/team-member-booking-profiles" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"bookable_only": $bookable_only, "limit": $limit, "cursor": $cursor, "location_id": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveTeamMemberBookingProfile
#
# GET /v2/bookings/team-member-booking-profiles/{team_member_id}
# operationId: RetrieveTeamMemberBookingProfile
export def "bookings-team-member-booking-profiles get" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profile: record<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_member_id | is-empty) { error make --unspanned { msg: "path parameter 'team_member_id' must be non-empty" } }
  let full_url = (build-url $base ({team_member_id: (encode-path-segment $team_member_id)} | format pattern "/v2/bookings/team-member-booking-profiles/{team_member_id}") $auth.query)
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

# RetrieveBooking
#
# GET /v2/bookings/{booking_id}
# operationId: RetrieveBooking
export def "bookings get" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($booking_id | is-empty) { error make --unspanned { msg: "path parameter 'booking_id' must be non-empty" } }
  let full_url = (build-url $base ({booking_id: (encode-path-segment $booking_id)} | format pattern "/v2/bookings/{booking_id}") $auth.query)
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

# UpdateBooking
#
# PUT /v2/bookings/{booking_id}
# operationId: UpdateBooking
# --booking shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
export def "bookings update" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($booking_id | is-empty) { error make --unspanned { msg: "path parameter 'booking_id' must be non-empty" } }
  let full_url = (build-url $base ({booking_id: (encode-path-segment $booking_id)} | format pattern "/v2/bookings/{booking_id}") $auth.query)
  let req_body = {"booking": $booking, "idempotency_key": $idempotency_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CancelBooking
#
# POST /v2/bookings/{booking_id}/cancel
# operationId: CancelBooking
export def "bookings-cancel cancel" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --booking-version: int # The revision number for the booking used for optimistic concurrency.
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($booking_id | is-empty) { error make --unspanned { msg: "path parameter 'booking_id' must be non-empty" } }
  let full_url = (build-url $base ({booking_id: (encode-path-segment $booking_id)} | format pattern "/v2/bookings/{booking_id}/cancel") $auth.query)
  let req_body = {"booking_version": $booking_version, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListCards
#
# GET /v2/cards
# operationId: ListCards
export def "cards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --customer-id: string # Limit results to cards associated with the customer supplied. By default, all cards owned by the merchant are returned.
  --include-disabled: oneof<nothing, bool> # Includes disabled cards. By default, all enabled cards owned by the merchant are returned.
  --reference-id: string # Limit results to cards associated with the reference_id supplied.
  --sort-order: string # Sorts the returned list by when the card was created with the specified order. This field defaults to ASC.
]: nothing -> record<cards: table<billing_address: record, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "include_disabled" $include_disabled "scalar") (serialize-qp "reference_id" $reference_id "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cards" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "customer_id": $customer_id, "include_disabled": $include_disabled, "reference_id": $reference_id, "sort_order": $sort_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateCard
#
# POST /v2/cards
# operationId: CreateCard
# --card shape: {billing_address?: record, bin?: string, card_brand?: string, card_type?: string, cardholder_name?: string, customer_id?: string, enabled?: bool, exp_month?: int, exp_year?: int, fingerprint?: string, id?: string, last_4?: string, prepaid_type?: string, reference_id?: string, version?: int}
export def "cards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card: record # Represents the payment details of a card to be used for payments. These details are determined by the payment token generated by Web Payments SDK. — shape: {billing_address?: record, bin?: string, card_brand?: string, card_type?: string, cardholder_name?: string, customer_id?: string, enabled?: bool, exp_month?: int, exp_year?: int, fingerprint?: string, id?: string, last_4?: string, prepaid_type?: string, reference_id?: string, version?: int}
  idempotency_key: string # A unique string that identifies this CreateCard request. Keys can be any valid string and must be unique for every request. Max: 45 characters See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  source_id: string # The ID of the source which represents the card information to be stored. This can be a card nonce or a payment id.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity. See the [SCA Overview](https://developer.squareup.com/docs/sca-overview).
]: any -> record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cards" $auth.query)
  let req_body = {"card": $card, "idempotency_key": $idempotency_key, "source_id": $source_id, "verification_token": $verification_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveCard
#
# GET /v2/cards/{card_id}
# operationId: RetrieveCard
export def "cards get" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'card_id' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/v2/cards/{card_id}") $auth.query)
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

# DisableCard
#
# POST /v2/cards/{card_id}/disable
# operationId: DisableCard
export def "cards-disable disable" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'card_id' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/v2/cards/{card_id}/disable") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# ListCashDrawerShifts
#
# GET /v2/cash-drawers/shifts
# operationId: ListCashDrawerShifts
export def "cash-drawers-shifts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to query for a list of cash drawer shifts.
  --sort-order: string # The order in which cash drawer shifts are listed in the response, based on their opened_at field. Default value: ASC
  --begin-time: string # The inclusive start time of the query on opened_at, in ISO 8601 format.
  --end-time: string # The exclusive end date of the query on opened_at, in ISO 8601 format.
  --limit: int # Number of cash drawer shift events in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<closed_at: string, closed_cash_money: record, description: string, ended_at: string, expected_cash_money: record, id: string, opened_at: string, opened_cash_money: record, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cash-drawers/shifts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id, "sort_order": $sort_order, "begin_time": $begin_time, "end_time": $end_time, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveCashDrawerShift
#
# GET /v2/cash-drawers/shifts/{shift_id}
# operationId: RetrieveCashDrawerShift
export def "cash-drawers-shifts get" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to retrieve cash drawer shifts from.
]: nothing -> record<cash_drawer_shift: record<cash_paid_in_money: record<amount: int, currency: string>, cash_paid_out_money: record<amount: int, currency: string>, cash_payment_money: record<amount: int, currency: string>, cash_refunds_money: record<amount: int, currency: string>, closed_at: string, closed_cash_money: record<amount: int, currency: string>, closing_employee_id: string, description: string, device: record<id: string, name: string>, employee_ids: list<string>, ended_at: string, ending_employee_id: string, expected_cash_money: record<amount: int, currency: string>, id: string, opened_at: string, opened_cash_money: record<amount: int, currency: string>, opening_employee_id: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shift_id | is-empty) { error make --unspanned { msg: "path parameter 'shift_id' must be non-empty" } }
  let qp = [(serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shift_id: (encode-path-segment $shift_id)} | format pattern "/v2/cash-drawers/shifts/{shift_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# ListCashDrawerShiftEvents
#
# GET /v2/cash-drawers/shifts/{shift_id}/events
# operationId: ListCashDrawerShiftEvents
export def "cash-drawers-shifts-events list" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to list cash drawer shifts for.
  --limit: int # Number of resources to be returned in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<created_at: string, description: string, employee_id: string, event_money: record, event_type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shift_id | is-empty) { error make --unspanned { msg: "path parameter 'shift_id' must be non-empty" } }
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shift_id: (encode-path-segment $shift_id)} | format pattern "/v2/cash-drawers/shifts/{shift_id}/events") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# BatchDeleteCatalogObjects
#
# POST /v2/catalog/batch-delete
# operationId: BatchDeleteCatalogObjects
export def "catalog-batch-delete delete-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-ids: list<string> # The IDs of the CatalogObjects to be deleted. When an object is deleted, other objects in the graph that depend on that object will be deleted as well (for example, deleting a CatalogItem will delete its CatalogItemVariation.
]: any -> record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-delete" $auth.query)
  let req_body = {"object_ids": $object_ids} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchRetrieveCatalogObjects
#
# POST /v2/catalog/batch-retrieve
# operationId: BatchRetrieveCatalogObjects
export def "catalog-batch-retrieve get-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-version: int # The specific version of the catalog objects to be included in the response. This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s' `version` attribute. (format: int64)
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested objects, as follows: If the `objects` field of the response contains a CatalogItem, its associated CatalogCategory objects, CatalogTax objects, CatalogImage objects and CatalogModifierLists will be returned in the `related_objects` field of the response. If the `objects` field of the response contains a CatalogItemVariation, its parent CatalogItem will be returned in the `related_objects` field of the response.
  object_ids: list<string> # The IDs of the CatalogObjects to be retrieved.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-retrieve" $auth.query)
  let req_body = {"catalog_version": $catalog_version, "include_related_objects": $include_related_objects, "object_ids": $object_ids} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchUpsertCatalogObjects
#
# POST /v2/catalog/batch-upsert
# operationId: BatchUpsertCatalogObjects
# --batches item shape: {objects: list}
export def "catalog-batch-upsert update-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  batches: list # A batch of CatalogObjects to be inserted/updated atomically. The objects within a batch will be inserted in an all-or-nothing fashion, i.e., if an error occurs attempting to insert or update an object within a batch, the entire batch will be rejected. However, an error in one batch will not affect other batches within the same request. For each object, its `updated_at` field is ignored and replaced with a current [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), and its `is_deleted` field must not be set to `true`. To modify an existing object, supply its ID. To create a new object, use an ID starting with `#`. These IDs may be used to create relationships between an object and attributes of other objects that reference it. For example, you can create a CatalogItem with ID `#ABC` and a CatalogItemVariation with its `item_id` attribute set to `#ABC` in order to associate the CatalogItemVariation with its parent CatalogItem. Any `#`-prefixed IDs are valid only within a single atomic batch, and will be replaced by server-generated IDs. Each batch may contain up to 1,000 objects. The total number of objects across all batches for a single request may not exceed 10,000. If either of these limits is violated, an error will be returned and no objects will be inserted or updated. — item shape: {objects: list}
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID). If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-upsert" $auth.query)
  let req_body = {"batches": $batches, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# CatalogInfo
#
# GET /v2/catalog/info
# operationId: CatalogInfo
export def "catalog-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, limits: record<batch_delete_max_object_ids: int, batch_retrieve_max_object_ids: int, batch_upsert_max_objects_per_batch: int, batch_upsert_max_total_objects: int, search_max_page_limit: int, update_item_modifier_lists_max_item_ids: int, update_item_modifier_lists_max_modifier_lists_to_disable: int, update_item_modifier_lists_max_modifier_lists_to_enable: int, update_item_taxes_max_item_ids: int, update_item_taxes_max_taxes_to_disable: int, update_item_taxes_max_taxes_to_enable: int>, standard_unit_description_group: record<language_code: string, standard_unit_descriptions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/info" $auth.query)
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

# ListCatalog
#
# GET /v2/catalog/list
# operationId: ListCatalog
export def "catalog-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. The page size is currently set to be 100. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --types: string # An optional case-insensitive, comma-separated list of object types to retrieve. The valid values are defined in the [CatalogObjectType](https://developer.squareup.com/reference/square_2021-08-18/enums/CatalogObjectType) enum, including `ITEM`, `ITEM_VARIATION`, `CATEGORY`, `DISCOUNT`, `TAX`, `MODIFIER`, `MODIFIER_LIST`, or `IMAGE`. If this is unspecified, the operation returns objects of all the types at the version of the Square API used to make the request.
  --catalog-version: int # The specific version of the catalog objects to be included in the response. This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s' `version` attribute. (format: int64)
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "catalog_version" $catalog_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/catalog/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "types": $types, "catalog_version": $catalog_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# UpsertCatalogObject
#
# POST /v2/catalog/object
# operationId: UpsertCatalogObject
# --object shape: {absent_at_location_ids?: list<string>, catalog_v1_ids?: list, category_data?: record, custom_attribute_definition_data?: record, custom_attribute_values?: record, discount_data?: record, id: string, image_data?: record, image_id?: string, is_deleted?: bool, item_data?: record, item_option_data?: record, item_option_value_data?: record, item_variation_data?: record, measurement_unit_data?: record, modifier_data?: record, modifier_list_data?: record, present_at_all_locations?: bool, ... (10 more fields)}
export def "catalog-object update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID). If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  object: record # The wrapper object for the Catalog entries of a given object type. The type of a particular `CatalogObject` is determined by the value of the `type` attribute and only the corresponding data attribute can be set on the `CatalogObject` instance. For example, the following list shows some instances of `CatalogObject` of a given `type` and their corresponding data attribute that can be set: - For a `CatalogObject` of the `ITEM` type, set the `item_data` attribute to yield the `CatalogItem` object. - For a `CatalogObject` of the `ITEM_VARIATION` type, set the `item_variation_data` attribute to yield the `CatalogItemVariation` object. - For a `CatalogObject` of the `MODIFIER` type, set the `modifier_data` attribute to yield the `CatalogModifier` object. - For a `CatalogObject` of the `MODIFIER_LIST` type, set the `modifier_list_data` attribute to yield the `CatalogModifierList` object. - For a `CatalogObject` of the `CATEGORY` type, set the `category_data` attribute to yield the `CatalogCategory` object. - For a `CatalogObject` of the `DISCOUNT` type, set the `discount_data` attribute to yield the `CatalogDiscount` object. - For a `CatalogObject` of the `TAX` type, set the `tax_data` attribute to yield the `CatalogTax` object. - For a `CatalogObject` of the `IMAGE` type, set the `image_data` attribute to yield the `CatalogImageData` object. - For a `CatalogObject` of the `QUICK_AMOUNTS_SETTINGS` type, set the `quick_amounts_settings_data` attribute to yield the `CatalogQuickAmountsSettings` object. - For a `CatalogObject` of the `PRICING_RULE` type, set the `pricing_rule_data` attribute to yield the `CatalogPricingRule` object. - For a `CatalogObject` of the `TIME_PERIOD` type, set the `time_period_data` attribute to yield the `CatalogTimePeriod` object. - For a `CatalogObject` of the `PRODUCT_SET` type, set the `product_set_data` attribute to yield the `CatalogProductSet` object. - For a `CatalogObject` of the `SUBSCRIPTION_PLAN` type, set the `subscription_plan_data` attribute to yield the `CatalogSubscriptionPlan` object. For a more detailed discussion of the Catalog data model, please see the [Design a Catalog](https://developer.squareup.com/docs/catalog-api/design-a-catalog) guide. (e.g. {catalog_object: {absent_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], category_data: {{ CatalogCategory object only if type=CATEGORY }}, connect_v1_ids: {catalog_v1_id: {{ itemID from Catalog v1 }}, location_id: {{ location where v1 ID is used }}}, discount_data: {{ CatalogDiscount object only if type=DISCOUNT }}, id: {{ set by Catalog during object creation }}, is_deleted: {{ [true | false] }}, item_data: {{ CatalogItem object only if type=ITEM }}, item_variation_data: {{ CatalogItemVariation object only if type=ITEM_VARIATION }}, modifier_data: {{ CatalogModifier object only if type=MODIFIER }}, modifier_list_data: {{ CatalogModifierList object only if type=MODIFIER_LIST }}, present_at_all_locations: {{ [true | false] }}, present_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], tax_data: {{ CatalogTax object only if type=TAX }}, type: {{ [ITEM | ITEM_VARIATION | MODIFIER | MODIFIER_LIST | CATEGORY | DISCOUNT | TAX] }}, updated_at: {{ date & time of most recent update }}, version: {{ version of the CatalogObject }}}}) — shape: {absent_at_location_ids?: list<string>, catalog_v1_ids?: list, category_data?: record, custom_attribute_definition_data?: record, custom_attribute_values?: record, discount_data?: record, id: string, image_data?: record, image_id?: string, is_deleted?: bool, item_data?: record, item_option_data?: record, item_option_value_data?: record, item_variation_data?: record, measurement_unit_data?: record, modifier_data?: record, modifier_list_data?: record, present_at_all_locations?: bool, ... (10 more fields)}
]: any -> record<catalog_object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/object" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "object": $object} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteCatalogObject
#
# DELETE /v2/catalog/object/{object_id}
# operationId: DeleteCatalogObject
export def "catalog-object delete" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'object_id' must be non-empty" } }
  let full_url = (build-url $base ({object_id: (encode-path-segment $object_id)} | format pattern "/v2/catalog/object/{object_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveCatalogObject
#
# GET /v2/catalog/object/{object_id}
# operationId: RetrieveCatalogObject
export def "catalog-object get" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested object, as follows: If the `object` field of the response contains a `CatalogItem`, its associated `CatalogCategory`, `CatalogTax`, `CatalogImage` and `CatalogModifierList` objects will be returned in the `related_objects` field of the response. If the `object` field of the response contains a `CatalogItemVariation`, its parent `CatalogItem` will be returned in the `related_objects` field of the response. Default value: `false`
  --catalog-version: int # Requests objects as of a specific version of the catalog. This allows you to retrieve historical versions of objects. The value to retrieve a specific version of an object can be found in the version field of [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s. (format: int64)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'object_id' must be non-empty" } }
  let qp = [(serialize-qp "include_related_objects" $include_related_objects "scalar") (serialize-qp "catalog_version" $catalog_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({object_id: (encode-path-segment $object_id)} | format pattern "/v2/catalog/object/{object_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_related_objects": $include_related_objects, "catalog_version": $catalog_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# SearchCatalogObjects
#
# POST /v2/catalog/search
# operationId: SearchCatalogObjects
# --query shape: {exact_query?: record, item_variations_for_item_option_values_query?: record, items_for_item_options_query?: record, items_for_modifier_list_query?: record, items_for_tax_query?: record, prefix_query?: record, range_query?: record, set_query?: record, sorted_attribute_query?: record, text_query?: record}
export def "catalog-search list-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # Return objects modified after this [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), in RFC 3339 format, e.g., `2016-09-04T23:59:33.123Z`. The timestamp is exclusive - objects with a timestamp equal to `begin_time` will not be included in the response.
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --include-deleted-objects: oneof<nothing, bool> # If `true`, deleted objects will be included in the results. Deleted objects will have their `is_deleted` field set to `true`.
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested object, as follows: If a CatalogItem is returned in the object field of the response, its associated CatalogCategory, CatalogTax objects, CatalogImage objects and CatalogModifierList objects will be included in the `related_objects` field of the response. If a CatalogItemVariation is returned in the object field of the response, its parent CatalogItem will be included in the `related_objects` field of the response.
  --limit: int # A limit on the number of results to be returned in a single page. The limit is advisory - the implementation may return more or fewer results. If the supplied limit is negative, zero, or is higher than the maximum limit of 1,000, it will be ignored.
  --object-types: list<string> # The desired set of object types to appear in the search results.
  --query: record # A query composed of one or more different types of filters to narrow the scope of targeted objects when calling the `SearchCatalogObjects` endpoint. Although a query can have multiple filters, only certain query types can be combined per call to [SearchCatalogObjects](https://developer.squareup.com/reference/square_2021-08-18/catalog-api/search-catalog-objects). Any combination of the following types may be used together: - [exact_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryExact) - [prefix_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryPrefix) - [range_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryRange) - [sorted_attribute_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQuerySortedAttribute) - [text_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryText) All other query types cannot be combined with any others. When a query filter is based on an attribute, the attribute must be searchable. Searchable attributes are listed as follows, along their parent types that can be searched for with applicable query filters. * Searchable attribute and objects queryable by searchable attributes ** - `name`: `CatalogItem`, `CatalogItemVariation`, `CatalogCategory`, `CatalogTax`, `CatalogDiscount`, `CatalogModifier`, 'CatalogModifierList`, `CatalogItemOption`, `CatalogItemOptionValue` - `description`: `CatalogItem`, `CatalogItemOptionValue` - `abbreviation`: `CatalogItem` - `upc`: `CatalogItemVariation` - `sku`: `CatalogItemVariation` - `caption`: `CatalogImage` - `display_name`: `CatalogItemOption` For example, to search for [CatalogItem](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogItem) objects by searchable attributes, you can use the `"name"`, `"description"`, or `"abbreviation"` attribute in an applicable query filter. — shape: {exact_query?: record, item_variations_for_item_option_values_query?: record, items_for_item_options_query?: record, items_for_modifier_list_query?: record, items_for_tax_query?: record, prefix_query?: record, range_query?: record, set_query?: record, sorted_attribute_query?: record, text_query?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, latest_time: string, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/search" $auth.query)
  let req_body = {"begin_time": $begin_time, "cursor": $cursor, "include_deleted_objects": $include_deleted_objects, "include_related_objects": $include_related_objects, "limit": $limit, "object_types": $object_types, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchCatalogItems
#
# POST /v2/catalog/search-catalog-items
# operationId: SearchCatalogItems
# --custom_attribute_filters item shape: {bool_filter?: bool, custom_attribute_definition_id?: string, key?: string, number_filter?: record, selection_uids_filter?: list<string>, string_filter?: string}
export def "catalog-search-catalog-items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: list<string> # The category id query expression to return items containing the specified category IDs.
  --cursor: string # The pagination token, returned in the previous response, used to fetch the next batch of pending results.
  --custom-attribute-filters: list # The customer-attribute filter to return items or item variations matching the specified custom attribute expressions. A maximum number of 10 custom attribute expressions are supported in a single call to the [SearchCatalogItems](https://developer.squareup.com/reference/square_2021-08-18/catalog-api/search-catalog-items) endpoint. — item shape: {bool_filter?: bool, custom_attribute_definition_id?: string, key?: string, number_filter?: record, selection_uids_filter?: list<string>, string_filter?: string}
  --enabled-location-ids: list<string> # The enabled-location query expression to return items and item variations having specified enabled locations.
  --limit: int # The maximum number of results to return per page. The default value is 100.
  --product-types: list<string> # The product types query expression to return items or item variations having the specified product types.
  --sort-order: string # The order to sort the results by item names. The default sort order is ascending (`ASC`).
  --stock-levels: list<string> # The stock-level query expression to return item variations with the specified stock levels.
  --text-filter: string # The text filter expression to return items or item variations containing specified text in the `name`, `description`, or `abbreviation` attribute value of an item, or in the `name`, `sku`, or `upc` attribute value of an item variation.
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, matched_variation_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/search-catalog-items" $auth.query)
  let req_body = {"category_ids": $category_ids, "cursor": $cursor, "custom_attribute_filters": $custom_attribute_filters, "enabled_location_ids": $enabled_location_ids, "limit": $limit, "product_types": $product_types, "sort_order": $sort_order, "stock_levels": $stock_levels, "text_filter": $text_filter} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# UpdateItemModifierLists
#
# POST /v2/catalog/update-item-modifier-lists
# operationId: UpdateItemModifierLists
export def "catalog-update-item-modifier-lists update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  item_ids: list<string> # The IDs of the catalog items associated with the CatalogModifierList objects being updated.
  --modifier-lists-to-disable: list<string> # The IDs of the CatalogModifierList objects to disable for the CatalogItem.
  --modifier-lists-to-enable: list<string> # The IDs of the CatalogModifierList objects to enable for the CatalogItem.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/update-item-modifier-lists" $auth.query)
  let req_body = {"item_ids": $item_ids, "modifier_lists_to_disable": $modifier_lists_to_disable, "modifier_lists_to_enable": $modifier_lists_to_enable} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# UpdateItemTaxes
#
# POST /v2/catalog/update-item-taxes
# operationId: UpdateItemTaxes
export def "catalog-update-item-taxes update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  item_ids: list<string> # IDs for the CatalogItems associated with the CatalogTax objects being updated.
  --taxes-to-disable: list<string> # IDs of the CatalogTax objects to disable.
  --taxes-to-enable: list<string> # IDs of the CatalogTax objects to enable.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/update-item-taxes" $auth.query)
  let req_body = {"item_ids": $item_ids, "taxes_to_disable": $taxes_to_disable, "taxes_to_enable": $taxes_to_enable} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListCustomers
#
# GET /v2/customers
# operationId: ListCustomers
export def "customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 100. The default value is 100. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --sort-field: string # Indicates how customers should be sorted. The default value is `DEFAULT`.
  --sort-order: string # Indicates whether customers should be sorted in ascending (`ASC`) or descending (`DESC`) order. The default value is `ASC`.
]: nothing -> record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit, "sort_field": $sort_field, "sort_order": $sort_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateCustomer
#
# POST /v2/customers
# operationId: CreateCustomer
# --address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
export def "customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --birthday: string # The birthday associated with the customer profile, in RFC 3339 format. The year is optional. The timezone and time are not allowed. For example, `0000-09-21T00:00:00-00:00` represents a birthday on September 21 and `1998-09-21T00:00:00-00:00` represents a birthday on September 21, 1998. You can also specify this value in `YYYY-MM-DD` format.
  --company-name: string # A business name associated with the customer profile.
  --email-address: string # The email address associated with the customer profile.
  --family-name: string # The family name (that is, the last name) associated with the customer profile.
  --given-name: string # The given name (that is, the first name) associated with the customer profile.
  --idempotency-key: string # The idempotency key for the request. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --nickname: string # A nickname for the customer profile.
  --note: string # A custom note associated with the customer profile.
  --phone-number: string # The 11-digit phone number associated with the customer profile.
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.
]: any -> record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers" $auth.query)
  let req_body = {"address": $address, "birthday": $birthday, "company_name": $company_name, "email_address": $email_address, "family_name": $family_name, "given_name": $given_name, "idempotency_key": $idempotency_key, "nickname": $nickname, "note": $note, "phone_number": $phone_number, "reference_id": $reference_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListCustomerGroups
#
# GET /v2/customers/groups
# operationId: ListCustomerGroups
export def "customers-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 50. The default value is 50. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, groups: table<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateCustomerGroup
#
# POST /v2/customers/groups
# operationId: CreateCustomerGroup
# --group shape: {created_at?: string, id?: string, name: string, updated_at?: string}
export def "customers-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # Represents a group of customer profiles. Customer groups can be created, be modified, and have their membership defined using the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {created_at?: string, id?: string, name: string, updated_at?: string}
  --idempotency-key: string # The idempotency key for the request. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/groups" $auth.query)
  let req_body = {"group": $group, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteCustomerGroup
#
# DELETE /v2/customers/groups/{group_id}
# operationId: DeleteCustomerGroup
export def "customers-groups delete-by-group-id" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/v2/customers/groups/{group_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveCustomerGroup
#
# GET /v2/customers/groups/{group_id}
# operationId: RetrieveCustomerGroup
export def "customers-groups get" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/v2/customers/groups/{group_id}") $auth.query)
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

# UpdateCustomerGroup
#
# PUT /v2/customers/groups/{group_id}
# operationId: UpdateCustomerGroup
# --group shape: {created_at?: string, id?: string, name: string, updated_at?: string}
export def "customers-groups update" [
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
  group: record # Represents a group of customer profiles. Customer groups can be created, be modified, and have their membership defined using the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {created_at?: string, id?: string, name: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/v2/customers/groups/{group_id}") $auth.query)
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchCustomers
#
# POST /v2/customers/search
# operationId: SearchCustomers
# --query shape: {filter?: record, sort?: record}
export def "customers-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Include the pagination cursor in subsequent calls to this endpoint to retrieve the next set of results associated with the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than the minimum or greater than the maximum value. The default value is 100. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination). (format: int64)
  --query: record # Represents a query (including filtering criteria, sorting criteria, or both) used to search for customer profiles. — shape: {filter?: record, sort?: record}
]: any -> record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListCustomerSegments
#
# GET /v2/customers/segments
# operationId: ListCustomerSegments
export def "customers-segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by previous calls to `ListCustomerSegments`. This cursor is used to retrieve the next set of query results. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 50. The default value is 50. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, segments: table<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/segments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveCustomerSegment
#
# GET /v2/customers/segments/{segment_id}
# operationId: RetrieveCustomerSegment
export def "customers-segments get" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, segment: record<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment_id' must be non-empty" } }
  let full_url = (build-url $base ({segment_id: (encode-path-segment $segment_id)} | format pattern "/v2/customers/segments/{segment_id}") $auth.query)
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

# DeleteCustomer
#
# DELETE /v2/customers/{customer_id}
# operationId: DeleteCustomer
export def "customers delete" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The current version of the customer profile. As a best practice, you should include this parameter to enable [optimistic concurrency](https://developer.squareup.com/docs/working-with-apis/optimistic-concurrency) control. For more information, see [Delete a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#delete-customer-profile). (format: int64)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveCustomer
#
# GET /v2/customers/{customer_id}
# operationId: RetrieveCustomer
export def "customers get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}") $auth.query)
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

# UpdateCustomer
#
# PUT /v2/customers/{customer_id}
# operationId: UpdateCustomer
# --address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
export def "customers update" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --birthday: string # The birthday associated with the customer profile, in RFC 3339 format. The year is optional. The timezone and time are not allowed. For example, `0000-09-21T00:00:00-00:00` represents a birthday on September 21 and `1998-09-21T00:00:00-00:00` represents a birthday on September 21, 1998. You can also specify this value in `YYYY-MM-DD` format.
  --company-name: string # A business name associated with the customer profile.
  --email-address: string # The email address associated with the customer profile.
  --family-name: string # The family name (that is, the last name) associated with the customer profile.
  --given-name: string # The given name (that is, the first name) associated with the customer profile.
  --nickname: string # A nickname for the customer profile.
  --note: string # A custom note associated with the customer profile.
  --phone-number: string # The 11-digit phone number associated with the customer profile.
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.
  --version: int # The current version of the customer profile. As a best practice, you should include this field to enable [optimistic concurrency](https://developer.squareup.com/docs/working-with-apis/optimistic-concurrency) control. For more information, see [Update a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#update-a-customer-profile). (format: int64)
]: any -> record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}") $auth.query)
  let req_body = {"address": $address, "birthday": $birthday, "company_name": $company_name, "email_address": $email_address, "family_name": $family_name, "given_name": $given_name, "nickname": $nickname, "note": $note, "phone_number": $phone_number, "reference_id": $reference_id, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CreateCustomerCard
#
# POST /v2/customers/{customer_id}/cards
# operationId: CreateCustomerCard
# --billing_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
export def "customers-cards create" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  card_nonce: string # A card nonce representing the credit card to link to the customer. Card nonces are generated by the Square payment form when customers enter their card information. For more information, see [Walkthrough: Integrate Square Payments in a Website](https://developer.squareup.com/docs/web-payments/take-card-payment). __NOTE:__ Card nonces generated by digital wallets (such as Apple Pay) cannot be used to create a customer card.
  --cardholder-name: string # The full name printed on the credit card.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity.
]: any -> record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/cards") $auth.query)
  let req_body = {"billing_address": $billing_address, "card_nonce": $card_nonce, "cardholder_name": $cardholder_name, "verification_token": $verification_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteCustomerCard
#
# DELETE /v2/customers/{customer_id}/cards/{card_id}
# operationId: DeleteCustomerCard
export def "customers-cards delete" [
  customer_id: string
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'card_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), card_id: (encode-path-segment $card_id)} | format pattern "/v2/customers/{customer_id}/cards/{card_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RemoveGroupFromCustomer
#
# DELETE /v2/customers/{customer_id}/groups/{group_id}
# operationId: RemoveGroupFromCustomer
export def "customers-groups delete-by-customer-id-group-id" [
  customer_id: string
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), group_id: (encode-path-segment $group_id)} | format pattern "/v2/customers/{customer_id}/groups/{group_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# AddGroupToCustomer
#
# PUT /v2/customers/{customer_id}/groups/{group_id}
# operationId: AddGroupToCustomer
export def "customers-groups create-by-customer-id-group-id" [
  customer_id: string
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customer_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), group_id: (encode-path-segment $group_id)} | format pattern "/v2/customers/{customer_id}/groups/{group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# ListDeviceCodes
#
# GET /v2/devices/codes
# operationId: ListDeviceCodes
export def "devices-codes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
  --location-id: string # If specified, only returns DeviceCodes of the specified location. Returns DeviceCodes of all locations if empty.
  --product-type: string # If specified, only returns DeviceCodes targeting the specified product type. Returns DeviceCodes of all product types if empty.
  --status: string # If specified, returns DeviceCodes with the specified statuses. Returns DeviceCodes of status `PAIRED` and `UNPAIRED` if empty.
]: nothing -> record<cursor: string, device_codes: table<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "product_type" $product_type "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/devices/codes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "location_id": $location_id, "product_type": $product_type, "status": $status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateDeviceCode
#
# POST /v2/devices/codes
# operationId: CreateDeviceCode
# --device_code shape: {code?: string, created_at?: string, device_id?: string, id?: string, location_id?: string, name?: string, pair_by?: string, paired_at?: string, product_type: string, status?: string, status_changed_at?: string}
export def "devices-codes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_code: record # shape: {code?: string, created_at?: string, device_id?: string, id?: string, location_id?: string, name?: string, pair_by?: string, paired_at?: string, product_type: string, status?: string, status_changed_at?: string}
  idempotency_key: string # A unique string that identifies this CreateDeviceCode request. Keys can be any valid string but must be unique for every CreateDeviceCode request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/devices/codes" $auth.query)
  let req_body = {"device_code": $device_code, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GetDeviceCode
#
# GET /v2/devices/codes/{id}
# operationId: GetDeviceCode
export def "devices-codes get" [
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
]: nothing -> record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/devices/codes/{id}") $auth.query)
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

# ListDisputes
#
# GET /v2/disputes
# operationId: ListDisputes
export def "disputes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --states: string # The dispute states to filter the result. If not specified, the endpoint returns all open disputes (the dispute status is not `INQUIRY_CLOSED`, `WON`, or `LOST`).
  --location-id: string # The ID of the location for which to return a list of disputes. If not specified, the endpoint returns all open disputes (the dispute status is not `INQUIRY_CLOSED`, `WON`, or `LOST`) associated with all locations.
]: nothing -> record<cursor: string, disputes: table<amount_money: record, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record, due_at: string, evidence_ids: list, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/disputes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "states": $states, "location_id": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveDispute
#
# GET /v2/disputes/{dispute_id}
# operationId: RetrieveDispute
export def "disputes get" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id)} | format pattern "/v2/disputes/{dispute_id}") $auth.query)
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

# AcceptDispute
#
# POST /v2/disputes/{dispute_id}/accept
# operationId: AcceptDispute
export def "disputes-accept create" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id)} | format pattern "/v2/disputes/{dispute_id}/accept") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# ListDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence
# operationId: ListDisputeEvidence
export def "disputes-evidence list" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, evidence: table<dispute_id: string, evidence_file: record, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id)} | format pattern "/v2/disputes/{dispute_id}/evidence") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateDisputeEvidenceText
#
# POST /v2/disputes/{dispute_id}/evidence-text
# operationId: CreateDisputeEvidenceText
export def "disputes-evidence-text create" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  evidence_text: string # The evidence string.
  --evidence-type: string # The type of evidence you are uploading.
  idempotency_key: string # The Unique ID. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id)} | format pattern "/v2/disputes/{dispute_id}/evidence-text") $auth.query)
  let req_body = {"evidence_text": $evidence_text, "evidence_type": $evidence_type, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteDisputeEvidence
#
# DELETE /v2/disputes/{dispute_id}/evidence/{evidence_id}
# operationId: DeleteDisputeEvidence
export def "disputes-evidence delete" [
  dispute_id: string
  evidence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  if ($evidence_id | is-empty) { error make --unspanned { msg: "path parameter 'evidence_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id), evidence_id: (encode-path-segment $evidence_id)} | format pattern "/v2/disputes/{dispute_id}/evidence/{evidence_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence/{evidence_id}
# operationId: RetrieveDisputeEvidence
export def "disputes-evidence get" [
  dispute_id: string
  evidence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  if ($evidence_id | is-empty) { error make --unspanned { msg: "path parameter 'evidence_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id), evidence_id: (encode-path-segment $evidence_id)} | format pattern "/v2/disputes/{dispute_id}/evidence/{evidence_id}") $auth.query)
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

# SubmitEvidence
#
# POST /v2/disputes/{dispute_id}/submit-evidence
# operationId: SubmitEvidence
export def "disputes-submit-evidence submit" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({dispute_id: (encode-path-segment $dispute_id)} | format pattern "/v2/disputes/{dispute_id}/submit-evidence") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# ListEmployees
#
# GET /v2/employees
export def "employees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string
  --status: string # Specifies the EmployeeStatus to filter the employee by.
  --limit: int # The number of employees to be returned on each page.
  --cursor: string # The token required to retrieve the specified page of results.
]: nothing -> record<cursor: string, employees: table<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/employees" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id, "status": $status, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveEmployee
#
# GET /v2/employees/{id}
export def "employees get" [
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
]: nothing -> record<employee: record<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list<string>, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/employees/{id}") $auth.query)
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

# ListGiftCards
#
# GET /v2/gift-cards
# operationId: ListGiftCards
export def "gift-cards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # If a type is provided, gift cards of this type are returned (see [GiftCardType](https://developer.squareup.com/reference/square_2021-08-18/enums/GiftCardType)). If no type is provided, it returns gift cards of all types.
  --state: string # If the state is provided, it returns the gift cards in the specified state (see [GiftCardStatus](https://developer.squareup.com/reference/square_2021-08-18/enums/GiftCardStatus)). Otherwise, it returns the gift cards of all states.
  --limit: int # If a value is provided, it returns only that number of results per page. The maximum number of results allowed per page is 50. The default value is 30.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If a cursor is not provided, it returns the first page of the results. For more information, see [Pagination](https://developer.squareup.com/docs/docs/working-with-apis/pagination).
  --customer-id: string # If a value is provided, returns only the gift cards linked to the specified customer
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_cards: table<balance_money: record, created_at: string, customer_ids: list, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/gift-cards" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "state": $state, "limit": $limit, "cursor": $cursor, "customer_id": $customer_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateGiftCard
#
# POST /v2/gift-cards
# operationId: CreateGiftCard
# --gift_card shape: {balance_money?: record, created_at?: string, customer_ids?: list<string>, gan?: string, gan_source?: any, id?: string, state?: any, type: any}
export def "gift-cards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gift_card: record # Represents a Square gift card. — shape: {balance_money?: record, created_at?: string, customer_ids?: list<string>, gan?: string, gan_source?: any, id?: string, state?: any, type: any}
  idempotency_key: string # A unique string that identifies the `CreateGiftCard` request.
  location_id: string # The location ID where the gift card that will be created should be registered.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards" $auth.query)
  let req_body = {"gift_card": $gift_card, "idempotency_key": $idempotency_key, "location_id": $location_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListGiftCardActivities
#
# GET /v2/gift-cards/activities
# operationId: ListGiftCardActivities
export def "gift-cards-activities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gift-card-id: string # If you provide a gift card ID, the endpoint returns activities that belong to the specified gift card. Otherwise, the endpoint returns all gift card activities for the seller.
  --type: string # If you provide a type, the endpoint returns gift card activities of this type. Otherwise, the endpoint returns all types of gift card activities.
  --location-id: string # If you provide a location ID, the endpoint returns gift card activities for that location. Otherwise, the endpoint returns gift card activities for all locations.
  --begin-time: string # The timestamp for the beginning of the reporting period, in RFC 3339 format. Inclusive. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the reporting period, in RFC 3339 format. Inclusive. Default: The current time.
  --limit: int # If you provide a limit value, the endpoint returns the specified number of results (or less) per page. A maximum value is 100. The default value is 50.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If you do not provide the cursor, the call returns the first page of the results.
  --sort-order: string # The order in which the endpoint returns the activities, based on `created_at`. - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_card_activities: table<activate_activity_details: record, adjust_decrement_activity_details: record, adjust_increment_activity_details: record, block_activity_details: record, clear_balance_activity_details: record, created_at: string, deactivate_activity_details: record, gift_card_balance_money: record, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record, import_reversal_activity_details: record, load_activity_details: record, location_id: string, redeem_activity_details: record, refund_activity_details: record, type: any, unblock_activity_details: record, unlinked_activity_refund_activity_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gift_card_id" $gift_card_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/gift-cards/activities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"gift_card_id": $gift_card_id, "type": $type, "location_id": $location_id, "begin_time": $begin_time, "end_time": $end_time, "limit": $limit, "cursor": $cursor, "sort_order": $sort_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateGiftCardActivity
#
# POST /v2/gift-cards/activities
# operationId: CreateGiftCardActivity
# --gift_card_activity shape: {activate_activity_details?: record, adjust_decrement_activity_details?: record, adjust_increment_activity_details?: record, block_activity_details?: record, clear_balance_activity_details?: record, created_at?: string, deactivate_activity_details?: record, gift_card_balance_money?: record, gift_card_gan?: string, gift_card_id?: string, id?: string, import_activity_details?: record, import_reversal_activity_details?: record, load_activity_details?: record, location_id: string, ... (5 more fields)}
export def "gift-cards-activities create-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gift_card_activity: record # Represents an action performed on a gift card that affects its state or balance. — shape: {activate_activity_details?: record, adjust_decrement_activity_details?: record, adjust_increment_activity_details?: record, block_activity_details?: record, clear_balance_activity_details?: record, created_at?: string, deactivate_activity_details?: record, gift_card_balance_money?: record, gift_card_gan?: string, gift_card_id?: string, id?: string, import_activity_details?: record, import_reversal_activity_details?: record, load_activity_details?: record, location_id: string, ... (5 more fields)}
  idempotency_key: string # A unique string that identifies the `CreateGiftCardActivity` request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card_activity: record<activate_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, adjust_decrement_activity_details: record<amount_money: record, reason: any>, adjust_increment_activity_details: record<amount_money: record, reason: any>, block_activity_details: record<reason: any>, clear_balance_activity_details: record<reason: any>, created_at: string, deactivate_activity_details: record<reason: any>, gift_card_balance_money: record<amount: int, currency: string>, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record<amount_money: record>, import_reversal_activity_details: record<amount_money: record>, load_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, location_id: string, redeem_activity_details: record<amount_money: record, payment_id: string, reference_id: string>, refund_activity_details: record<amount_money: record, payment_id: string, redeem_activity_id: string, reference_id: string>, type: any, unblock_activity_details: record<reason: any>, unlinked_activity_refund_activity_details: record<amount_money: record, payment_id: string, reference_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/activities" $auth.query)
  let req_body = {"gift_card_activity": $gift_card_activity, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveGiftCardFromGAN
#
# POST /v2/gift-cards/from-gan
# operationId: RetrieveGiftCardFromGAN
export def "gift-cards-from-gan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gan: string # The gift card account number (GAN) of the gift card to retrieve. The maximum length of a GAN is 255 digits to account for third-party GANs that have been imported. Square-issued gift cards have 16-digit GANs.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/from-gan" $auth.query)
  let req_body = {"gan": $gan} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveGiftCardFromNonce
#
# POST /v2/gift-cards/from-nonce
# operationId: RetrieveGiftCardFromNonce
export def "gift-cards-from-nonce get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  nonce: string # The nonce of the gift card to retrieve.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/from-nonce" $auth.query)
  let req_body = {"nonce": $nonce} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# LinkCustomerToGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/link-customer
# operationId: LinkCustomerToGiftCard
export def "gift-cards-link-customer create" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The ID of the customer to be linked.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'gift_card_id' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/v2/gift-cards/{gift_card_id}/link-customer") $auth.query)
  let req_body = {"customer_id": $customer_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# UnlinkCustomerFromGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/unlink-customer
# operationId: UnlinkCustomerFromGiftCard
export def "gift-cards-unlink-customer create" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'gift_card_id' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/v2/gift-cards/{gift_card_id}/unlink-customer") $auth.query)
  let req_body = {"customer_id": $customer_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveGiftCard
#
# GET /v2/gift-cards/{id}
# operationId: RetrieveGiftCard
export def "gift-cards get" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/gift-cards/{id}") $auth.query)
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

# DeprecatedRetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustment/{adjustment_id}
# operationId: DeprecatedRetrieveInventoryAdjustment
export def "inventory-adjustment get-deprecated" [
  adjustment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($adjustment_id | is-empty) { error make --unspanned { msg: "path parameter 'adjustment_id' must be non-empty" } }
  let full_url = (build-url $base ({adjustment_id: (encode-path-segment $adjustment_id)} | format pattern "/v2/inventory/adjustment/{adjustment_id}") $auth.query)
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

# RetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustments/{adjustment_id}
# operationId: RetrieveInventoryAdjustment
export def "inventory-adjustments get" [
  adjustment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($adjustment_id | is-empty) { error make --unspanned { msg: "path parameter 'adjustment_id' must be non-empty" } }
  let full_url = (build-url $base ({adjustment_id: (encode-path-segment $adjustment_id)} | format pattern "/v2/inventory/adjustments/{adjustment_id}") $auth.query)
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

# DeprecatedBatchChangeInventory
#
# POST /v2/inventory/batch-change
# operationId: DeprecatedBatchChangeInventory
# --changes item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
export def "inventory-batch-change create-deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. — item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) in the [API Development 101](https://developer.squareup.com/docs/basics/api101/overview) section for more information.
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`.
]: any -> record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-change" $auth.query)
  let req_body = {"changes": $changes, "idempotency_key": $idempotency_key, "ignore_unchanged_counts": $ignore_unchanged_counts} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeprecatedBatchRetrieveInventoryChanges
#
# POST /v2/inventory/batch-retrieve-changes
# operationId: DeprecatedBatchRetrieveInventoryChanges
export def "inventory-batch-retrieve-changes get-deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null.
  --states: list<string> # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null.
  --types: list<string> # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-retrieve-changes" $auth.query)
  let req_body = {"catalog_object_ids": $catalog_object_ids, "cursor": $cursor, "location_ids": $location_ids, "states": $states, "types": $types, "updated_after": $updated_after, "updated_before": $updated_before} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeprecatedBatchRetrieveInventoryCounts
#
# POST /v2/inventory/batch-retrieve-counts
# operationId: DeprecatedBatchRetrieveInventoryCounts
export def "inventory-batch-retrieve-counts get-deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is applicable only when set. The default is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null.
  --states: list<string> # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-retrieve-counts" $auth.query)
  let req_body = {"catalog_object_ids": $catalog_object_ids, "cursor": $cursor, "location_ids": $location_ids, "states": $states, "updated_after": $updated_after} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchChangeInventory
#
# POST /v2/inventory/changes/batch-create
# operationId: BatchChangeInventory
# --changes item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
export def "inventory-changes-batch-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. — item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) in the [API Development 101](https://developer.squareup.com/docs/basics/api101/overview) section for more information.
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`.
]: any -> record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/changes/batch-create" $auth.query)
  let req_body = {"changes": $changes, "idempotency_key": $idempotency_key, "ignore_unchanged_counts": $ignore_unchanged_counts} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchRetrieveInventoryChanges
#
# POST /v2/inventory/changes/batch-retrieve
# operationId: BatchRetrieveInventoryChanges
export def "inventory-changes-batch-retrieve get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null.
  --states: list<string> # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null.
  --types: list<string> # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/changes/batch-retrieve" $auth.query)
  let req_body = {"catalog_object_ids": $catalog_object_ids, "cursor": $cursor, "location_ids": $location_ids, "states": $states, "types": $types, "updated_after": $updated_after, "updated_before": $updated_before} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchRetrieveInventoryCounts
#
# POST /v2/inventory/counts/batch-retrieve
# operationId: BatchRetrieveInventoryCounts
export def "inventory-counts-batch-retrieve get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is applicable only when set. The default is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null.
  --states: list<string> # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/counts/batch-retrieve" $auth.query)
  let req_body = {"catalog_object_ids": $catalog_object_ids, "cursor": $cursor, "location_ids": $location_ids, "states": $states, "updated_after": $updated_after} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeprecatedRetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-count/{physical_count_id}
# operationId: DeprecatedRetrieveInventoryPhysicalCount
export def "inventory-physical-count get-deprecated" [
  physical_count_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($physical_count_id | is-empty) { error make --unspanned { msg: "path parameter 'physical_count_id' must be non-empty" } }
  let full_url = (build-url $base ({physical_count_id: (encode-path-segment $physical_count_id)} | format pattern "/v2/inventory/physical-count/{physical_count_id}") $auth.query)
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

# RetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-counts/{physical_count_id}
# operationId: RetrieveInventoryPhysicalCount
export def "inventory-physical-counts get" [
  physical_count_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($physical_count_id | is-empty) { error make --unspanned { msg: "path parameter 'physical_count_id' must be non-empty" } }
  let full_url = (build-url $base ({physical_count_id: (encode-path-segment $physical_count_id)} | format pattern "/v2/inventory/physical-counts/{physical_count_id}") $auth.query)
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

# RetrieveInventoryTransfer
#
# GET /v2/inventory/transfers/{transfer_id}
# operationId: RetrieveInventoryTransfer
export def "inventory-transfers get" [
  transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, transfer: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_location_id: string, id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string, to_location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transfer_id | is-empty) { error make --unspanned { msg: "path parameter 'transfer_id' must be non-empty" } }
  let full_url = (build-url $base ({transfer_id: (encode-path-segment $transfer_id)} | format pattern "/v2/inventory/transfers/{transfer_id}") $auth.query)
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

# RetrieveInventoryCount
#
# GET /v2/inventory/{catalog_object_id}
# operationId: RetrieveInventoryCount
export def "inventory get-count" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-ids: string # The [Location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalog_object_id | is-empty) { error make --unspanned { msg: "path parameter 'catalog_object_id' must be non-empty" } }
  let qp = [(serialize-qp "location_ids" $location_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalog_object_id: (encode-path-segment $catalog_object_id)} | format pattern "/v2/inventory/{catalog_object_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_ids": $location_ids, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveInventoryChanges
#
# GET /v2/inventory/{catalog_object_id}/changes
# operationId: RetrieveInventoryChanges
export def "inventory-changes get" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-ids: string # The [Location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalog_object_id | is-empty) { error make --unspanned { msg: "path parameter 'catalog_object_id' must be non-empty" } }
  let qp = [(serialize-qp "location_ids" $location_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalog_object_id: (encode-path-segment $catalog_object_id)} | format pattern "/v2/inventory/{catalog_object_id}/changes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_ids": $location_ids, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# ListInvoices
#
# GET /v2/invoices
# operationId: ListInvoices
export def "invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location for which to list invoices.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`). If not provided, the server uses a default limit of 100 invoices.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/invoices" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateInvoice
#
# POST /v2/invoices
# operationId: CreateInvoice
# --invoice shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, delivery_method?: any, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
export def "invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies the `CreateInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Manage Invoices Using the Invoices API](https://developer.squareup.com/docs/invoices-api/overview). — shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, delivery_method?: any, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoices" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "invoice": $invoice} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchInvoices
#
# POST /v2/invoices/search
# operationId: SearchInvoices
# --query shape: {filter: record, sort?: record}
export def "invoices-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`). If not provided, the server uses a default limit of 100 invoices.
  query: record # Describes query criteria for searching invoices. — shape: {filter: record, sort?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoices/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteInvoice
#
# DELETE /v2/invoices/{invoice_id}
# operationId: DeleteInvoice
export def "invoices delete" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to delete. If you do not know the version, you can call [GetInvoice](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/get-invoice) or [ListInvoices](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/list-invoices).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v2/invoices/{invoice_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# GetInvoice
#
# GET /v2/invoices/{invoice_id}
# operationId: GetInvoice
export def "invoices get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v2/invoices/{invoice_id}") $auth.query)
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

# UpdateInvoice
#
# PUT /v2/invoices/{invoice_id}
# operationId: UpdateInvoice
# --invoice shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, delivery_method?: any, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
export def "invoices update" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-to-clear: list<string> # The list of fields to clear. For examples, see [Update an invoice](https://developer.squareup.com/docs/invoices-api/overview#update-an-invoice).
  --idempotency-key: string # A unique string that identifies the `UpdateInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Manage Invoices Using the Invoices API](https://developer.squareup.com/docs/invoices-api/overview). — shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, delivery_method?: any, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v2/invoices/{invoice_id}") $auth.query)
  let req_body = {"fields_to_clear": $fields_to_clear, "idempotency_key": $idempotency_key, "invoice": $invoice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CancelInvoice
#
# POST /v2/invoices/{invoice_id}/cancel
# operationId: CancelInvoice
export def "invoices-cancel cancel" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to cancel. If you do not know the version, you can call [GetInvoice](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/get-invoice) or [ListInvoices](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/list-invoices).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v2/invoices/{invoice_id}/cancel") $auth.query)
  let req_body = {"version": $version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# PublishInvoice
#
# POST /v2/invoices/{invoice_id}/publish
# operationId: PublishInvoice
export def "invoices-publish publish" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies the `PublishInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to publish. This must match the current version of the invoice; otherwise, the request is rejected.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v2/invoices/{invoice_id}/publish") $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "version": $version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListBreakTypes
#
# GET /v2/labor/break-types
# operationId: ListBreakTypes
export def "labor-break-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # Filter the returned `BreakType` results to only those that are associated with the specified location.
  --limit: int # The maximum number of `BreakType` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `BreakType` results to fetch.
]: nothing -> record<break_types: table<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/break-types" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"location_id": $location_id, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreateBreakType
#
# POST /v2/labor/break-types
# operationId: CreateBreakType
# --break_type shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
export def "labor-break-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  break_type: record # A defined break template that sets an expectation for possible `Break` instances on a `Shift`. — shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
]: any -> record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/break-types" $auth.query)
  let req_body = {"break_type": $break_type, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteBreakType
#
# DELETE /v2/labor/break-types/{id}
# operationId: DeleteBreakType
export def "labor-break-types delete" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/break-types/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# GetBreakType
#
# GET /v2/labor/break-types/{id}
# operationId: GetBreakType
export def "labor-break-types get" [
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
]: nothing -> record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/break-types/{id}") $auth.query)
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

# UpdateBreakType
#
# PUT /v2/labor/break-types/{id}
# operationId: UpdateBreakType
# --break_type shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
export def "labor-break-types update" [
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
  break_type: record # A defined break template that sets an expectation for possible `Break` instances on a `Shift`. — shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
]: any -> record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/break-types/{id}") $auth.query)
  let req_body = {"break_type": $break_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListEmployeeWages
#
# GET /v2/labor/employee-wages
# operationId: ListEmployeeWages
export def "labor-employee-wages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-id: string # Filter the returned wages to only those that are associated with the specified employee.
  --limit: int # The maximum number of `EmployeeWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> record<cursor: string, employee_wages: table<employee_id: string, hourly_rate: record, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "employee_id" $employee_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/employee-wages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"employee_id": $employee_id, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GetEmployeeWage
#
# GET /v2/labor/employee-wages/{id}
# operationId: GetEmployeeWage
export def "labor-employee-wages get" [
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
]: nothing -> record<employee_wage: record<employee_id: string, hourly_rate: record<amount: int, currency: string>, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/employee-wages/{id}") $auth.query)
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

# CreateShift
#
# POST /v2/labor/shifts
# operationId: CreateShift
# --shift shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
export def "labor-shifts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift. — shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/shifts" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "shift": $shift} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchShifts
#
# POST /v2/labor/shifts/search
# operationId: SearchShifts
# --query shape: {filter?: record, sort?: record}
export def "labor-shifts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # An opaque cursor for fetching the next page.
  --limit: int # The number of resources in a page (200 by default).
  --query: record # The parameters of a `Shift` search query, which includes filter and sort options. — shape: {filter?: record, sort?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, shifts: table<breaks: list, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/shifts/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteShift
#
# DELETE /v2/labor/shifts/{id}
# operationId: DeleteShift
export def "labor-shifts delete" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/shifts/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# GetShift
#
# GET /v2/labor/shifts/{id}
# operationId: GetShift
export def "labor-shifts get" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/shifts/{id}") $auth.query)
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

# UpdateShift
#
# PUT /v2/labor/shifts/{id}
# operationId: UpdateShift
# --shift shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
export def "labor-shifts update" [
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
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift. — shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/shifts/{id}") $auth.query)
  let req_body = {"shift": $shift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListTeamMemberWages
#
# GET /v2/labor/team-member-wages
# operationId: ListTeamMemberWages
export def "labor-team-member-wages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-member-id: string # Filter the returned wages to only those that are associated with the specified team member.
  --limit: int # The maximum number of `TeamMemberWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_wages: table<hourly_rate: record, id: string, team_member_id: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_member_id" $team_member_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/team-member-wages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_member_id": $team_member_id, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GetTeamMemberWage
#
# GET /v2/labor/team-member-wages/{id}
# operationId: GetTeamMemberWage
export def "labor-team-member-wages get" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, team_member_wage: record<hourly_rate: record<amount: int, currency: string>, id: string, team_member_id: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/team-member-wages/{id}") $auth.query)
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

# ListWorkweekConfigs
#
# GET /v2/labor/workweek-configs
# operationId: ListWorkweekConfigs
export def "labor-workweek-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of `WorkweekConfigs` results to return per page.
  --cursor: string # A pointer to the next page of `WorkweekConfig` results to fetch.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, workweek_configs: table<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/workweek-configs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# UpdateWorkweekConfig
#
# PUT /v2/labor/workweek-configs/{id}
# operationId: UpdateWorkweekConfig
# --workweek_config shape: {created_at?: string, id?: string, start_of_day_local_time: string, start_of_week: string, updated_at?: string, version?: int}
export def "labor-workweek-configs update" [
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
  workweek_config: record # Sets the day of the week and hour of the day that a business starts a workweek. This is used to calculate overtime pay. — shape: {created_at?: string, id?: string, start_of_day_local_time: string, start_of_week: string, updated_at?: string, version?: int}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, workweek_config: record<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/labor/workweek-configs/{id}") $auth.query)
  let req_body = {"workweek_config": $workweek_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListLocations
#
# GET /v2/locations
# operationId: ListLocations
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, locations: table<address: record, business_email: string, business_hours: record, business_name: string, capabilities: list, coordinates: record, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record, timezone: string, twitter_username: string, type: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations" $auth.query)
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

# CreateLocation
#
# POST /v2/locations
# operationId: CreateLocation
# --location shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
export def "locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations" $auth.query)
  let req_body = {"location": $location} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveLocation
#
# GET /v2/locations/{location_id}
# operationId: RetrieveLocation
export def "locations get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}") $auth.query)
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

# UpdateLocation
#
# PUT /v2/locations/{location_id}
# operationId: UpdateLocation
# --location shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
export def "locations update" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}") $auth.query)
  let req_body = {"location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CreateCheckout
#
# POST /v2/locations/{location_id}/checkouts
# operationId: CreateCheckout
# --additional_recipients item shape: {amount_money: record, description: string, location_id: string}
# --order shape: {idempotency_key?: string, order?: record}
# --pre_populate_shipping_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
export def "locations-checkouts create" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-recipients: list # The basic primitive of a multi-party transaction. The value is optional. The transaction facilitated by you can be split from here. If you provide this value, the `amount_money` value in your `additional_recipients` field cannot be more than 90% of the `total_money` calculated by Square for your order. The `location_id` must be a valid seller location where the checkout is occurring. This field requires `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` OAuth permission. This field is currently not supported in the Square Sandbox. — item shape: {amount_money: record, description: string, location_id: string}
  --ask-for-shipping-address: oneof<nothing, bool> # If `true`, Square Checkout collects shipping information on your behalf and stores that information with the transaction information in the Square Seller Dashboard. Default: `false`.
  idempotency_key: string # A unique string that identifies this checkout among others you have created. It can be any valid string but must be unique for every order sent to Square Checkout for a given location ID. The idempotency key is used to avoid processing the same order more than once. If you are unsure whether a particular checkout was created successfully, you can attempt it again with the same idempotency key and all the same other parameters without worrying about creating duplicates. You should use a random number/string generator native to the language you are working in to generate strings for your idempotency keys. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --merchant-support-email: string # The email address to display on the Square Checkout confirmation page and confirmation email that the buyer can use to contact the seller. If this value is not set, the confirmation page and email display the primary email address associated with the seller's Square account. Default: none; only exists if explicitly set.
  --note: string # An optional note to associate with the `checkout` object. This value cannot exceed 60 characters.
  order: record # e.g. {request_body: {idempotency_key: 8193148c-9586-11e6-99f9-28cfe92138cf, order: {discounts: [{name: Labor Day Sale, percentage: 5, scope: ORDER, uid: labor-day-sale}, {catalog_object_id: DB7L55ZH2BGWI4H23ULIWOQ7, scope: ORDER, uid: membership-discount}, {amount_money: {amount: 100, currency: USD}, name: Sale - $1.00 off, scope: LINE_ITEM, uid: one-dollar-off}], line_items: [{base_price_money: {amount: 1599, currency: USD}, name: New York Strip Steak, quantity: 1}, {applied_discounts: [{discount_uid: one-dollar-off}], catalog_object_id: BEMYCSMIJL46OCDV4KYIKXIB, modifiers: [{catalog_object_id: CHQX7Y4KY6N5KINJKZCFURPZ}], quantity: 2}], location_id: 057P5VYJ4A5X1, reference_id: my-order-001, taxes: [{name: State Sales Tax, percentage: 9, scope: ORDER, uid: state-sales-tax}]}}} — shape: {idempotency_key?: string, order?: record}
  --pre-populate-buyer-email: string # If provided, the buyer's email is prepopulated on the checkout page as an editable text field. Default: none; only exists if explicitly set.
  --pre-populate-shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --redirect-url: string # The URL to redirect to after the checkout is completed with `checkoutId`, `transactionId`, and `referenceId` appended as URL parameters. For example, if the provided redirect URL is `http://www.example.com/order-complete`, a successful transaction redirects the customer to: http://www.example.com/order-complete?checkoutId=xxxxxx&referenceId=xxxxxx&transactionId=xxxxxx If you do not provide a redirect URL, Square Checkout displays an order confirmation page on your behalf; however, it is strongly recommended that you provide a redirect URL so you can verify the transaction results and finalize the order through your existing/normal confirmation workflow. Default: none; only exists if explicitly set.
]: any -> record<checkout: record<additional_recipients: list<record>, ask_for_shipping_address: bool, checkout_page_url: string, created_at: string, id: string, merchant_support_email: string, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>, pre_populate_buyer_email: string, pre_populate_shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, redirect_url: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}/checkouts") $auth.query)
  let req_body = {"additional_recipients": $additional_recipients, "ask_for_shipping_address": $ask_for_shipping_address, "idempotency_key": $idempotency_key, "merchant_support_email": $merchant_support_email, "note": $note, "order": $order, "pre_populate_buyer_email": $pre_populate_buyer_email, "pre_populate_shipping_address": $pre_populate_shipping_address, "redirect_url": $redirect_url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListRefunds
#
# GET /v2/locations/{location_id}/refunds
export def "locations-refunds get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The beginning of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time.
  --sort-order: string # The order in which results are listed in the response (`ASC` for oldest first, `DESC` for newest first). Default value: `DESC`
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<additional_recipients: list, amount_money: record, created_at: string, id: string, location_id: string, processing_fee_money: record, reason: string, status: string, tender_id: string, transaction_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}/refunds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"begin_time": $begin_time, "end_time": $end_time, "sort_order": $sort_order, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# ListTransactions
#
# GET /v2/locations/{location_id}/transactions
# operationId: ListTransactions
export def "locations-transactions list" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The beginning of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time.
  --sort-order: string # The order in which results are listed in the response (`ASC` for oldest first, `DESC` for newest first). Default value: `DESC`
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, transactions: table<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list, shipping_address: record, tenders: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}/transactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"begin_time": $begin_time, "end_time": $end_time, "sort_order": $sort_order, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Charge
#
# POST /v2/locations/{location_id}/transactions
# operationId: Charge
# --additional_recipients item shape: {amount_money: record, description?: string, location_id: string, receivable_id?: string}
# --amount_money shape: {amount?: int, currency?: string}
# --billing_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
# --shipping_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
export def "locations-transactions create-charge" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-recipients: list # The basic primitive of multi-party transaction. The value is optional. The transaction facilitated by you can be split from here. If you provide this value, the `amount_money` value in your additional_recipients must not be more than 90% of the `amount_money` value in the charge request. The `location_id` must be the valid location of the app owner merchant. This field requires the `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` OAuth permission. This field is currently not supported in sandbox. — item shape: {amount_money: record, description?: string, location_id: string, receivable_id?: string}
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --buyer-email-address: string # The buyer's email address, if available. This value is optional, but this transaction is ineligible for chargeback protection if it is not provided.
  --card-nonce: string # A payment token generated from the [Card.tokenize()](https://developer.squareup.com/reference/sdks/web/payments/objects/Card#Card.tokenize) that represents the card to charge. The application that provides a payment token to this endpoint must be the _same application_ that generated the payment token with the Web Payments SDK. Otherwise, the nonce is invalid. Do not provide a value for this field if you provide a value for `customer_card_id`.
  --customer-card-id: string # The ID of the customer card on file to charge. Do not provide a value for this field if you provide a value for `card_nonce`. If you provide this value, you _must_ also provide a value for `customer_id`.
  --customer-id: string # The ID of the customer to associate this transaction with. This field is required if you provide a value for `customer_card_id`, and optional otherwise.
  --delay-capture: oneof<nothing, bool> # If `true`, the request will only perform an Auth on the provided card. You can then later perform either a Capture (with the [CaptureTransaction](https://developer.squareup.com/reference/square_2021-08-18/transactions-api/capture-transaction) endpoint) or a Void (with the [VoidTransaction](https://developer.squareup.com/reference/square_2021-08-18/transactions-api/void-transaction) endpoint). Default value: `false`
  idempotency_key: string # A value you specify that uniquely identifies this transaction among transactions you've created. If you're unsure whether a particular transaction succeeded, you can reattempt it with the same idempotency key without worrying about double-charging the buyer. See [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency) for more information.
  --note: string # An optional note to associate with the transaction. This value cannot exceed 60 characters.
  --order-id: string # The ID of the order to associate with this transaction. If you provide this value, the `amount_money` value of your request must __exactly match__ the value of the order's `total_money` field.
  --reference-id: string # An optional ID you can associate with the transaction for your own purposes (such as to associate the transaction with an entity ID in your own database). This value cannot exceed 40 characters.
  --shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --verification-token: string # A token generated by SqPaymentForm's verifyBuyer() that represents customer's device info and 3ds challenge result.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}/transactions") $auth.query)
  let req_body = {"additional_recipients": $additional_recipients, "amount_money": $amount_money, "billing_address": $billing_address, "buyer_email_address": $buyer_email_address, "card_nonce": $card_nonce, "customer_card_id": $customer_card_id, "customer_id": $customer_id, "delay_capture": $delay_capture, "idempotency_key": $idempotency_key, "note": $note, "order_id": $order_id, "reference_id": $reference_id, "shipping_address": $shipping_address, "verification_token": $verification_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveTransaction
#
# GET /v2/locations/{location_id}/transactions/{transaction_id}
# operationId: RetrieveTransaction
export def "locations-transactions get" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transaction_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/v2/locations/{location_id}/transactions/{transaction_id}") $auth.query)
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

# CaptureTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/capture
# operationId: CaptureTransaction
export def "locations-transactions-capture create" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transaction_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/v2/locations/{location_id}/transactions/{transaction_id}/capture") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# CreateRefund
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/refund
# --amount_money shape: {amount?: int, currency?: string}
export def "locations-transactions-refund create" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  idempotency_key: string # A value you specify that uniquely identifies this refund among refunds you've created for the tender. If you're unsure whether a particular refund succeeded, you can reattempt it with the same idempotency key without worrying about duplicating the refund. See [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency) for more information.
  --reason: string # A description of the reason for the refund. Default value: `Refund via API`
  tender_id: string # The ID of the tender to refund. A [`Transaction`](https://developer.squareup.com/reference/square_2021-08-18/objects/Transaction) has one or more `tenders` (i.e., methods of payment) associated with it, and you refund each tender separately with the Connect API.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<additional_recipients: list<record>, amount_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, processing_fee_money: record<amount: int, currency: string>, reason: string, status: string, tender_id: string, transaction_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transaction_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/v2/locations/{location_id}/transactions/{transaction_id}/refund") $auth.query)
  let req_body = {"amount_money": $amount_money, "idempotency_key": $idempotency_key, "reason": $reason, "tender_id": $tender_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# VoidTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/void
# operationId: VoidTransaction
export def "locations-transactions-void create" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transaction_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/v2/locations/{location_id}/transactions/{transaction_id}/void") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# CreateLoyaltyAccount
#
# POST /v2/loyalty/accounts
# operationId: CreateLoyaltyAccount
# --loyalty_account shape: {balance?: int, created_at?: string, customer_id?: string, enrolled_at?: string, expiring_point_deadlines?: list, id?: string, lifetime_points?: int, mapping?: record, program_id: string, updated_at?: string}
export def "loyalty-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyAccount` request. Keys can be any valid string, but must be unique for every request.
  loyalty_account: record # Describes a loyalty account. For more information, see [Manage Loyalty Accounts Using the Loyalty API](https://developer.squareup.com/docs/loyalty-api/overview). — shape: {balance?: int, created_at?: string, customer_id?: string, enrolled_at?: string, expiring_point_deadlines?: list, id?: string, lifetime_points?: int, mapping?: record, program_id: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/accounts" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "loyalty_account": $loyalty_account} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchLoyaltyAccounts
#
# POST /v2/loyalty/accounts/search
# operationId: SearchLoyaltyAccounts
# --query shape: {customer_ids?: list<string>, mappings?: list}
export def "loyalty-accounts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to include in the response.
  --query: record # The search criteria for the loyalty accounts. — shape: {customer_ids?: list<string>, mappings?: list}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, loyalty_accounts: table<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list, id: string, lifetime_points: int, mapping: record, program_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/accounts/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveLoyaltyAccount
#
# GET /v2/loyalty/accounts/{account_id}
# operationId: RetrieveLoyaltyAccount
export def "loyalty-accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2/loyalty/accounts/{account_id}") $auth.query)
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

# AccumulateLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/accumulate
# operationId: AccumulateLoyaltyPoints
# --accumulate_points shape: {loyalty_program_id?: string, order_id?: string, points?: int}
export def "loyalty-accounts-accumulate create-points" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  accumulate_points: record # Provides metadata when the event `type` is `ACCUMULATE_POINTS`. — shape: {loyalty_program_id?: string, order_id?: string, points?: int}
  idempotency_key: string # A unique string that identifies the `AccumulateLoyaltyPoints` request. Keys can be any valid string but must be unique for every request.
  location_id: string # The [location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) where the purchase was made.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2/loyalty/accounts/{account_id}/accumulate") $auth.query)
  let req_body = {"accumulate_points": $accumulate_points, "idempotency_key": $idempotency_key, "location_id": $location_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# AdjustLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/adjust
# operationId: AdjustLoyaltyPoints
# --adjust_points shape: {loyalty_program_id?: string, points: int, reason?: string}
export def "loyalty-accounts-adjust create-points" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  adjust_points: record # Provides metadata when the event `type` is `ADJUST_POINTS`. — shape: {loyalty_program_id?: string, points: int, reason?: string}
  idempotency_key: string # A unique string that identifies this `AdjustLoyaltyPoints` request. Keys can be any valid string, but must be unique for every request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2/loyalty/accounts/{account_id}/adjust") $auth.query)
  let req_body = {"adjust_points": $adjust_points, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchLoyaltyEvents
#
# POST /v2/loyalty/events/search
# operationId: SearchLoyaltyEvents
# --query shape: {filter?: record}
export def "loyalty-events-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to include in the response. The last page might contain fewer events. The default is 30 events.
  --query: record # Represents a query used to search for loyalty events. — shape: {filter?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<accumulate_points: record, adjust_points: record, create_reward: record, created_at: string, delete_reward: record, expire_points: record, id: string, location_id: string, loyalty_account_id: string, other_event: record, redeem_reward: record, source: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/events/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListLoyaltyPrograms
#
# GET /v2/loyalty/programs
# operationId: ListLoyaltyPrograms
export def "loyalty-programs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, programs: table<accrual_rules: list, created_at: string, expiration_policy: record, id: string, location_ids: list, reward_tiers: list, status: string, terminology: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/programs" $auth.query)
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

# RetrieveLoyaltyProgram
#
# GET /v2/loyalty/programs/{program_id}
# operationId: RetrieveLoyaltyProgram
export def "loyalty-programs get" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, program: record<accrual_rules: list<record>, created_at: string, expiration_policy: record<expiration_duration: string>, id: string, location_ids: list<string>, reward_tiers: list<record>, status: string, terminology: record<one: string, other: string>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'program_id' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/v2/loyalty/programs/{program_id}") $auth.query)
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

# CalculateLoyaltyPoints
#
# POST /v2/loyalty/programs/{program_id}/calculate
# operationId: CalculateLoyaltyPoints
# --transaction_amount_money shape: {amount?: int, currency?: string}
export def "loyalty-programs-calculate create-points" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The [order](https://developer.squareup.com/reference/square_2021-08-18/objects/Order) ID for which to calculate the points. Specify this field if your application uses the Orders API to process orders. Otherwise, specify the `transaction_amount_money`.
  --transaction-amount-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, points: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'program_id' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/v2/loyalty/programs/{program_id}/calculate") $auth.query)
  let req_body = {"order_id": $order_id, "transaction_amount_money": $transaction_amount_money} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# CreateLoyaltyReward
#
# POST /v2/loyalty/rewards
# operationId: CreateLoyaltyReward
# --reward shape: {created_at?: string, id?: string, loyalty_account_id: string, order_id?: string, points?: int, redeemed_at?: string, reward_tier_id: string, status?: string, updated_at?: string}
export def "loyalty-rewards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyReward` request. Keys can be any valid string, but must be unique for every request.
  reward: record # Represents a contract to redeem loyalty points for a [reward tier](https://developer.squareup.com/reference/square_2021-08-18/objects/LoyaltyProgramRewardTier) discount. Loyalty rewards can be in an ISSUED, REDEEMED, or DELETED state. For more information, see [Redeem loyalty rewards](https://developer.squareup.com/docs/loyalty-api/overview#redeem-loyalty-rewards). — shape: {created_at?: string, id?: string, loyalty_account_id: string, order_id?: string, points?: int, redeemed_at?: string, reward_tier_id: string, status?: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/rewards" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "reward": $reward} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchLoyaltyRewards
#
# POST /v2/loyalty/rewards/search
# operationId: SearchLoyaltyRewards
# --query shape: {loyalty_account_id: string, status?: string}
export def "loyalty-rewards-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to return in the response.
  --query: record # The set of search requirements. — shape: {loyalty_account_id: string, status?: string}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, rewards: table<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/rewards/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DeleteLoyaltyReward
#
# DELETE /v2/loyalty/rewards/{reward_id}
# operationId: DeleteLoyaltyReward
export def "loyalty-rewards delete" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reward_id | is-empty) { error make --unspanned { msg: "path parameter 'reward_id' must be non-empty" } }
  let full_url = (build-url $base ({reward_id: (encode-path-segment $reward_id)} | format pattern "/v2/loyalty/rewards/{reward_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveLoyaltyReward
#
# GET /v2/loyalty/rewards/{reward_id}
# operationId: RetrieveLoyaltyReward
export def "loyalty-rewards get" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reward_id | is-empty) { error make --unspanned { msg: "path parameter 'reward_id' must be non-empty" } }
  let full_url = (build-url $base ({reward_id: (encode-path-segment $reward_id)} | format pattern "/v2/loyalty/rewards/{reward_id}") $auth.query)
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

# RedeemLoyaltyReward
#
# POST /v2/loyalty/rewards/{reward_id}/redeem
# operationId: RedeemLoyaltyReward
export def "loyalty-rewards-redeem create" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `RedeemLoyaltyReward` request. Keys can be any valid string, but must be unique for every request.
  location_id: string # The ID of the [location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) where the reward is redeemed.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reward_id | is-empty) { error make --unspanned { msg: "path parameter 'reward_id' must be non-empty" } }
  let full_url = (build-url $base ({reward_id: (encode-path-segment $reward_id)} | format pattern "/v2/loyalty/rewards/{reward_id}/redeem") $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "location_id": $location_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListMerchants
#
# GET /v2/merchants
# operationId: ListMerchants
export def "merchants list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: int # The cursor generated by the previous response.
]: nothing -> record<cursor: int, errors: table<category: string, code: string, detail: string, field: string>, merchant: table<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/merchants" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RetrieveMerchant
#
# GET /v2/merchants/{merchant_id}
# operationId: RetrieveMerchant
export def "merchants get" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, merchant: record<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($merchant_id | is-empty) { error make --unspanned { msg: "path parameter 'merchant_id' must be non-empty" } }
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/v2/merchants/{merchant_id}") $auth.query)
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

# CreateOrder
#
# POST /v2/orders
# operationId: CreateOrder
# --order shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
export def "orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A value you specify that uniquely identifies this order among orders you have created. If you are unsure whether a particular order was created successfully, you can try it again with the same idempotency key without worrying about creating duplicate orders. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "order": $order} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BatchRetrieveOrders
#
# POST /v2/orders/batch-retrieve
# operationId: BatchRetrieveOrders
export def "orders-batch-retrieve get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location for these orders. This field is optional: omit it to retrieve orders within the scope of the current authorization's merchant ID.
  order_ids: list<string> # The IDs of the orders to retrieve. A maximum of 100 orders can be retrieved per request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/batch-retrieve" $auth.query)
  let req_body = {"location_id": $location_id, "order_ids": $order_ids} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# CalculateOrder
#
# POST /v2/orders/calculate
# operationId: CalculateOrder
# --order shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
# --proposed_rewards item shape: {id: string, reward_tier_id: string}
export def "orders-calculate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
  --proposed-rewards: list # Identifies one or more loyalty reward tiers to apply during the order calculation. The discounts defined by the reward tiers are added to the order only to preview the effect of applying the specified rewards. The rewards do not correspond to actual redemptions; that is, no `reward`s are created. Therefore, the reward `id`s are random strings used only to reference the reward tier. — item shape: {id: string, reward_tier_id: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/calculate" $auth.query)
  let req_body = {"order": $order, "proposed_rewards": $proposed_rewards} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchOrders
#
# POST /v2/orders/search
# operationId: SearchOrders
# --query shape: {filter?: record, sort?: record}
export def "orders-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. Default: `500`
  --location-ids: list<string> # The location IDs for the orders to query. All locations must belong to the same merchant. Min: 1 location ID. Max: 10 location IDs.
  --query: record # Contains query criteria for the search. — shape: {filter?: record, sort?: record}
  --return-entries: oneof<nothing, bool> # A Boolean that controls the format of the search results. If `true`, `SearchOrders` returns [OrderEntry](https://developer.squareup.com/reference/square_2021-08-18/objects/OrderEntry) objects. If `false`, `SearchOrders` returns complete order objects. Default: `false`.
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, order_entries: table<location_id: string, order_id: string, version: int>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "location_ids": $location_ids, "query": $query, "return_entries": $return_entries} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveOrder
#
# GET /v2/orders/{order_id}
export def "orders list-1" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/v2/orders/{order_id}") $auth.query)
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

# UpdateOrder
#
# PUT /v2/orders/{order_id}
# --order shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
export def "orders update-by-order-id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-to-clear: list<string> # The [dot notation paths](https://developer.squareup.com/docs/orders-api/manage-orders#on-dot-notation) fields to clear. For example, `line_items[uid].note`. For more information, see [Deleting fields](https://developer.squareup.com/docs/orders-api/manage-orders#delete-fields).
  --idempotency-key: string # A value you specify that uniquely identifies this update request. If you are unsure whether a particular update was applied to an order successfully, you can reattempt it with the same idempotency key without worrying about creating duplicate updates to the order. The latest order version is returned. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/v2/orders/{order_id}") $auth.query)
  let req_body = {"fields_to_clear": $fields_to_clear, "idempotency_key": $idempotency_key, "order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# PayOrder
#
# POST /v2/orders/{order_id}/pay
# operationId: PayOrder
export def "orders-pay create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A value you specify that uniquely identifies this request among requests you have sent. If you are unsure whether a particular payment request was completed successfully, you can reattempt it with the same idempotency key without worrying about duplicate payments. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --order-version: int # The version of the order being paid. If not supplied, the latest version will be paid.
  --payment-ids: list<string> # The IDs of the [payments](https://developer.squareup.com/reference/square_2021-08-18/objects/Payment) to collect. The payment total must match the order total.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/v2/orders/{order_id}/pay") $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "order_version": $order_version, "payment_ids": $payment_ids} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ListPayments
#
# GET /v2/payments
export def "payments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The timestamp for the beginning of the reporting period, in RFC 3339 format. Inclusive. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the reporting period, in RFC 3339 format. Default: The current time.
  --sort-order: string # The order in which results are listed: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for the default (main) location associated with the seller.
  --total: int # The exact amount in the `total_money` for a payment. (format: int64)
  --last-4: string # The last four digits of a payment card.
  --card-brand: string # The brand of the payment card (for example, VISA).
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. The default value of 100 is also the maximum allowed value. If the provided value is greater than 100, it is ignored and the default value is used instead. Default: `100`
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, payments: table<amount_money: record, app_fee_money: record, approved_money: record, bank_account_details: record, billing_address: record, buyer_email_address: string, capabilities: list, card_details: record, cash_details: record, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record, id: string, location_id: string, note: string, order_id: string, processing_fee: list, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list, refunded_money: record, risk_evaluation: record, shipping_address: record, source_type: string, statement_description_identifier: string, status: string, tip_money: record, total_money: record, updated_at: string, version_token: string, wallet_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "last_4" $last_4 "scalar") (serialize-qp "card_brand" $card_brand "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/payments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"begin_time": $begin_time, "end_time": $end_time, "sort_order": $sort_order, "cursor": $cursor, "location_id": $location_id, "total": $total, "last_4": $last_4, "card_brand": $card_brand, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# CreatePayment
#
# POST /v2/payments
# operationId: CreatePayment
# --amount_money shape: {amount?: int, currency?: string}
# --app_fee_money shape: {amount?: int, currency?: string}
# --billing_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
# --cash_details shape: {buyer_supplied_money: record, change_back_money?: record}
# --external_details shape: {source: string, source_fee_money?: record, source_id?: string, type: string}
# --shipping_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
# --tip_money shape: {amount?: int, currency?: string}
export def "payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-partial-authorization: oneof<nothing, bool> # If set to `true` and charging a Square Gift Card, a payment might be returned with `amount_money` equal to less than what was requested. For example, a request for $20 when charging a Square Gift Card with a balance of $5 results in an APPROVED payment of $5. You might choose to prompt the buyer for an additional payment to cover the remainder or cancel the Gift Card payment. This field cannot be `true` when `autocomplete = true`. For more information, see [Partial amount with Square Gift Cards](https://developer.squareup.com/docs/payments-api/take-payments#partial-payment-gift-card). Default: false
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --autocomplete: oneof<nothing, bool> # If set to `true`, this payment will be completed when possible. If set to `false`, this payment is held in an approved state until either explicitly completed (captured) or canceled (voided). For more information, see [Delayed capture](https://developer.squareup.com/docs/payments-api/take-payments/card-payments#delayed-capture-of-a-card-payment). Default: true
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --buyer-email-address: string # The buyer's email address.
  --cash-details: record # Stores details about a cash payment. Contains only non-confidential information. For more information, see [Take Cash Payments](https://developer.squareup.com/docs/payments-api/take-payments/cash-payments). — shape: {buyer_supplied_money: record, change_back_money?: record}
  --customer-id: string # The [Customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) ID of the customer associated with the payment. This is required if the `source_id` refers to a card on file created using the Customers API.
  --delay-duration: string # The duration of time after the payment's creation when Square automatically cancels the payment. This automatic cancellation applies only to payments that do not reach a terminal state (COMPLETED, CANCELED, or FAILED) before the `delay_duration` time period. This parameter should be specified as a time duration, in RFC 3339 format, with a minimum value of 1 minute. Note: This feature is only supported for card payments. This parameter can only be set for a delayed capture payment (`autocomplete=false`). Default: - Card-present payments: "PT36H" (36 hours) from the creation time. - Card-not-present payments: "P7D" (7 days) from the creation time.
  --external-details: record # Stores details about an external payment. Contains only non-confidential information. For more information, see [Take External Payments](https://developer.squareup.com/docs/payments-api/take-payments/external-payments). — shape: {source: string, source_fee_money?: record, source_id?: string, type: string}
  idempotency_key: string # A unique string that identifies this `CreatePayment` request. Keys can be any valid string but must be unique for every `CreatePayment` request. Max: 45 characters Note: The number of allowed characters might be less than the stated maximum, if multi-byte characters are used. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --location-id: string # The location ID to associate with the payment. If not specified, the default location is used.
  --note: string # An optional note to be entered by the developer when creating a payment. Limit 500 characters.
  --order-id: string # Associates a previously created order with this payment.
  --reference-id: string # A user-defined ID to associate with the payment. You can use this field to associate the payment to an entity in an external system (for example, you might specify an order ID that is generated by a third-party shopping cart). Limit 40 characters.
  --shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  source_id: string # The ID for the source of funds for this payment. This can be a payment token (card nonce) generated by the Square payment form or a card on file made with the Customers API. If recording a payment that the seller received outside of Square, specify either "CASH" or "EXTERNAL". For more information, see [Take Payments](https://developer.squareup.com/docs/payments-api/take-payments).
  --statement-description-identifier: string # Optional additional payment information to include on the customer's card statement as part of the statement description. This can be, for example, an invoice number, ticket number, or short description that uniquely identifies the purchase. Note that the `statement_description_identifier` might get truncated on the statement description to fit the required information including the Square identifier (SQ *) and name of the seller taking the payment.
  --tip-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --verification-token: string # An identifying token generated by [payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity. For more information, see [SCA Overview](https://developer.squareup.com/docs/sca-overview).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments" $auth.query)
  let req_body = {"accept_partial_authorization": $accept_partial_authorization, "amount_money": $amount_money, "app_fee_money": $app_fee_money, "autocomplete": $autocomplete, "billing_address": $billing_address, "buyer_email_address": $buyer_email_address, "cash_details": $cash_details, "customer_id": $customer_id, "delay_duration": $delay_duration, "external_details": $external_details, "idempotency_key": $idempotency_key, "location_id": $location_id, "note": $note, "order_id": $order_id, "reference_id": $reference_id, "shipping_address": $shipping_address, "source_id": $source_id, "statement_description_identifier": $statement_description_identifier, "tip_money": $tip_money, "verification_token": $verification_token} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# CancelPaymentByIdempotencyKey
#
# POST /v2/payments/cancel
# operationId: CancelPaymentByIdempotencyKey
export def "payments-cancel cancel-by-idempotency-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # The `idempotency_key` identifying the payment to be canceled.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments/cancel" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GetPayment
#
# GET /v2/payments/{payment_id}
# operationId: GetPayment
export def "payments get-by-payment-id" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v2/payments/{payment_id}") $auth.query)
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

# UpdatePayment
#
# PUT /v2/payments/{payment_id}
# operationId: UpdatePayment
# --payment shape: {amount_money?: record, app_fee_money?: record, approved_money?: record, bank_account_details?: record, billing_address?: record, buyer_email_address?: string, capabilities?: list<string>, card_details?: record, cash_details?: record, created_at?: string, customer_id?: string, delay_action?: string, delay_duration?: string, delayed_until?: string, employee_id?: string, external_details?: record, id?: string, location_id?: string, note?: string, order_id?: string, processing_fee?: list, ... (15 more fields)}
export def "payments update" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `UpdatePayment` request. Keys can be any valid string but must be unique for every `UpdatePayment` request. The maximum is 45 characters. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --payment: record # Represents a payment processed by the Square API. — shape: {amount_money?: record, app_fee_money?: record, approved_money?: record, bank_account_details?: record, billing_address?: record, buyer_email_address?: string, capabilities?: list<string>, card_details?: record, cash_details?: record, created_at?: string, customer_id?: string, delay_action?: string, delay_duration?: string, delayed_until?: string, employee_id?: string, external_details?: record, id?: string, location_id?: string, note?: string, order_id?: string, processing_fee?: list, ... (15 more fields)}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v2/payments/{payment_id}") $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "payment": $payment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CancelPayment
#
# POST /v2/payments/{payment_id}/cancel
# operationId: CancelPayment
export def "payments-cancel cancel" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v2/payments/{payment_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# CompletePayment
#
# POST /v2/payments/{payment_id}/complete
# operationId: CompletePayment
export def "payments-complete complete" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v2/payments/{payment_id}/complete") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# ListPaymentRefunds
#
# GET /v2/refunds
# operationId: ListPaymentRefunds
export def "refunds list-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The timestamp for the beginning of the requested reporting period, in RFC 3339 format. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the requested reporting period, in RFC 3339 format. Default: The current time.
  --sort-order: string # The order in which results are listed: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for all locations associated with the seller.
  --status: string # If provided, only refunds with the given status are returned. For a list of refund status values, see [PaymentRefund](https://developer.squareup.com/reference/square_2021-08-18/objects/PaymentRefund). Default: If omitted, refunds are returned regardless of their status.
  --source-type: string # If provided, only refunds with the given source type are returned. - `CARD` - List refunds only for payments where `CARD` was specified as the payment source. Default: If omitted, refunds are returned regardless of the source type.
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. If the supplied value is greater than 100, no more than 100 results are returned. Default: 100
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_fee_money: record, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list, reason: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/refunds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"begin_time": $begin_time, "end_time": $end_time, "sort_order": $sort_order, "cursor": $cursor, "location_id": $location_id, "status": $status, "source_type": $source_type, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RefundPayment
#
# POST /v2/refunds
# operationId: RefundPayment
# --amount_money shape: {amount?: int, currency?: string}
# --app_fee_money shape: {amount?: int, currency?: string}
export def "refunds create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  idempotency_key: string # A unique string that identifies this `RefundPayment` request. The key can be any valid string but must be unique for every `RefundPayment` request. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  payment_id: string # The unique ID of the payment being refunded.
  --reason: string # A description of the reason for the refund.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/refunds" $auth.query)
  let req_body = {"amount_money": $amount_money, "app_fee_money": $app_fee_money, "idempotency_key": $idempotency_key, "payment_id": $payment_id, "reason": $reason} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GetPaymentRefund
#
# GET /v2/refunds/{refund_id}
# operationId: GetPaymentRefund
export def "refunds get-payment" [
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($refund_id | is-empty) { error make --unspanned { msg: "path parameter 'refund_id' must be non-empty" } }
  let full_url = (build-url $base ({refund_id: (encode-path-segment $refund_id)} | format pattern "/v2/refunds/{refund_id}") $auth.query)
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

# ListSites
#
# GET /v2/sites
# operationId: ListSites
export def "sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, sites: table<created_at: string, domain: string, id: string, is_published: bool, site_title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/sites" $auth.query)
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

# DeleteSnippet
#
# DELETE /v2/sites/{site_id}/snippet
# operationId: DeleteSnippet
export def "sites-snippet delete" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/v2/sites/{site_id}/snippet") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# RetrieveSnippet
#
# GET /v2/sites/{site_id}/snippet
# operationId: RetrieveSnippet
export def "sites-snippet get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/v2/sites/{site_id}/snippet") $auth.query)
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

# UpsertSnippet
#
# POST /v2/sites/{site_id}/snippet
# operationId: UpsertSnippet
# --snippet shape: {content: string, created_at?: string, id?: string, site_id?: string, updated_at?: string}
export def "sites-snippet update" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  snippet: record # Represents the snippet that is added to a Square Online site. The snippet code is injected into the `head` element of all pages on the site, except for checkout pages. — shape: {content: string, created_at?: string, id?: string, site_id?: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/v2/sites/{site_id}/snippet") $auth.query)
  let req_body = {"snippet": $snippet} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# CreateSubscription
#
# POST /v2/subscriptions
# operationId: CreateSubscription
# --price_override_money shape: {amount?: int, currency?: string}
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canceled-date: string # The date when the subscription should be canceled, in YYYY-MM-DD format (for example, 2025-02-29). This overrides the plan configuration if it comes before the date the subscription would otherwise end.
  --card-id: string # The ID of the [customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) [card](https://developer.squareup.com/reference/square_2021-08-18/objects/Card) to charge. If not specified, Square sends an invoice via email. For an example to create a customer and add a card on file, see [Subscriptions Walkthrough](https://developer.squareup.com/docs/subscriptions-api/walkthrough).
  customer_id: string # The ID of the [customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) profile.
  --idempotency-key: string # A unique string that identifies this `CreateSubscription` request. If you do not provide a unique string (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency).
  location_id: string # The ID of the location the subscription is associated with.
  plan_id: string # The ID of the subscription plan created using the Catalog API. For more information, see [Set Up and Manage a Subscription Plan](https://developer.squareup.com/docs/subscriptions-api/setup-plan) and [Subscriptions Walkthrough](https://developer.squareup.com/docs/subscriptions-api/walkthrough).
  --price-override-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --start-date: string # The start date of the subscription, in YYYY-MM-DD format. For example, 2013-01-15. If the start date is left empty, the subscription begins immediately.
  --tax-percentage: string # The tax to add when billing the subscription. The percentage is expressed in decimal form, using a `'.'` as the decimal separator and without a `'%'` sign. For example, a value of 7.5 corresponds to 7.5%.
  --timezone: string # The timezone that is used in date calculations for the subscription. If unset, defaults to the location timezone. If a timezone is not configured for the location, defaults to "America/New_York". Format: the IANA Timezone Database identifier for the location timezone. For a list of time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/subscriptions" $auth.query)
  let req_body = {"canceled_date": $canceled_date, "card_id": $card_id, "customer_id": $customer_id, "idempotency_key": $idempotency_key, "location_id": $location_id, "plan_id": $plan_id, "price_override_money": $price_override_money, "start_date": $start_date, "tax_percentage": $tax_percentage, "timezone": $timezone} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchSubscriptions
#
# POST /v2/subscriptions/search
# operationId: SearchSubscriptions
# --query shape: {filter?: record}
export def "subscriptions-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The upper limit on the number of subscriptions to return in the response. Default: `200`
  --query: record # Represents a query (including filtering criteria) used to search for subscriptions. — shape: {filter?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscriptions: table<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list, location_id: string, plan_id: string, price_override_money: record, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/subscriptions/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveSubscription
#
# GET /v2/subscriptions/{subscription_id}
# operationId: RetrieveSubscription
export def "subscriptions get" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscription_id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/v2/subscriptions/{subscription_id}") $auth.query)
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

# UpdateSubscription
#
# PUT /v2/subscriptions/{subscription_id}
# operationId: UpdateSubscription
# --subscription shape: {canceled_date?: string, card_id?: string, charged_through_date?: string, created_at?: string, customer_id?: string, id?: string, invoice_ids?: list<string>, location_id?: string, plan_id?: string, price_override_money?: record, start_date?: string, status?: string, tax_percentage?: string, timezone?: string, version?: int}
export def "subscriptions update" [
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
  --subscription: record # Represents a customer subscription to a subscription plan. For an overview of the `Subscription` type, see [Subscription object](https://developer.squareup.com/docs/subscriptions-api/overview#subscription-object-overview). — shape: {canceled_date?: string, card_id?: string, charged_through_date?: string, created_at?: string, customer_id?: string, id?: string, invoice_ids?: list<string>, location_id?: string, plan_id?: string, price_override_money?: record, start_date?: string, status?: string, tax_percentage?: string, timezone?: string, version?: int}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscription_id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/v2/subscriptions/{subscription_id}") $auth.query)
  let req_body = {"subscription": $subscription} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CancelSubscription
#
# POST /v2/subscriptions/{subscription_id}/cancel
# operationId: CancelSubscription
export def "subscriptions-cancel cancel" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscription_id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/v2/subscriptions/{subscription_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# ListSubscriptionEvents
#
# GET /v2/subscriptions/{subscription_id}/events
# operationId: ListSubscriptionEvents
export def "subscriptions-events list" [
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
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The upper limit on the number of subscription events to return in the response. Default: `200`
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscription_events: table<effective_date: string, id: string, info: any, plan_id: string, subscription_event_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscription_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/v2/subscriptions/{subscription_id}/events") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# ResumeSubscription
#
# POST /v2/subscriptions/{subscription_id}/resume
# operationId: ResumeSubscription
export def "subscriptions-resume create" [
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
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscription_id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/v2/subscriptions/{subscription_id}/resume") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# CreateTeamMember
#
# POST /v2/team-members
# operationId: CreateTeamMember
# --team_member shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
export def "team-members create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies this `CreateTeamMember` request. Keys can be any valid string, but must be unique for every request. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency). The minimum length is 1 and the maximum length is 45.
  --team-member: record # A record representing an individual team member for a business. — shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "team_member": $team_member} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BulkCreateTeamMembers
#
# POST /v2/team-members/bulk-create
# operationId: BulkCreateTeamMembers
export def "team-members-bulk-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  team_members: record # The data used to create the `TeamMember` objects. Each key is the `idempotency_key` that maps to the `CreateTeamMemberRequest`.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/bulk-create" $auth.query)
  let req_body = {"team_members": $team_members} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# BulkUpdateTeamMembers
#
# POST /v2/team-members/bulk-update
# operationId: BulkUpdateTeamMembers
export def "team-members-bulk-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  team_members: record # The data used to update the `TeamMember` objects. Each key is the `team_member_id` that maps to the `UpdateTeamMemberRequest`.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/bulk-update" $auth.query)
  let req_body = {"team_members": $team_members} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchTeamMembers
#
# POST /v2/team-members/search
# operationId: SearchTeamMembers
# --query shape: {filter?: record}
export def "team-members-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The opaque cursor for fetching the next page. For more information, see [pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of `TeamMember` objects in a page (100 by default).
  --query: record # Represents the parameters in a search for `TeamMember` objects. — shape: {filter?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_members: table<assigned_locations: record, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveTeamMember
#
# GET /v2/team-members/{team_member_id}
# operationId: RetrieveTeamMember
export def "team-members get" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_member_id | is-empty) { error make --unspanned { msg: "path parameter 'team_member_id' must be non-empty" } }
  let full_url = (build-url $base ({team_member_id: (encode-path-segment $team_member_id)} | format pattern "/v2/team-members/{team_member_id}") $auth.query)
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

# UpdateTeamMember
#
# PUT /v2/team-members/{team_member_id}
# operationId: UpdateTeamMember
# --team_member shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
export def "team-members update" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-member: record # A record representing an individual team member for a business. — shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_member_id | is-empty) { error make --unspanned { msg: "path parameter 'team_member_id' must be non-empty" } }
  let full_url = (build-url $base ({team_member_id: (encode-path-segment $team_member_id)} | format pattern "/v2/team-members/{team_member_id}") $auth.query)
  let req_body = {"team_member": $team_member} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# RetrieveWageSetting
#
# GET /v2/team-members/{team_member_id}/wage-setting
# operationId: RetrieveWageSetting
export def "team-members-wage-setting get" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_member_id | is-empty) { error make --unspanned { msg: "path parameter 'team_member_id' must be non-empty" } }
  let full_url = (build-url $base ({team_member_id: (encode-path-segment $team_member_id)} | format pattern "/v2/team-members/{team_member_id}/wage-setting") $auth.query)
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

# UpdateWageSetting
#
# PUT /v2/team-members/{team_member_id}/wage-setting
# operationId: UpdateWageSetting
# --wage_setting shape: {created_at?: string, is_overtime_exempt?: bool, job_assignments?: list, team_member_id?: string, updated_at?: string, version?: int}
export def "team-members-wage-setting update" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wage_setting: record # An object representing a team member's wage information. — shape: {created_at?: string, is_overtime_exempt?: bool, job_assignments?: list, team_member_id?: string, updated_at?: string, version?: int}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_member_id | is-empty) { error make --unspanned { msg: "path parameter 'team_member_id' must be non-empty" } }
  let full_url = (build-url $base ({team_member_id: (encode-path-segment $team_member_id)} | format pattern "/v2/team-members/{team_member_id}/wage-setting") $auth.query)
  let req_body = {"wage_setting": $wage_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# CreateTerminalCheckout
#
# POST /v2/terminals/checkouts
# operationId: CreateTerminalCheckout
# --checkout shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_options: record, id?: string, location_id?: string, note?: string, payment_ids?: list<string>, payment_type?: string, reference_id?: string, status?: string, updated_at?: string}
export def "terminals-checkouts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checkout: record # shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_options: record, id?: string, location_id?: string, note?: string, payment_ids?: list<string>, payment_type?: string, reference_id?: string, status?: string, updated_at?: string}
  idempotency_key: string # A unique string that identifies this `CreateCheckout` request. Keys can be any valid string but must be unique for every `CreateCheckout` request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/checkouts" $auth.query)
  let req_body = {"checkout": $checkout, "idempotency_key": $idempotency_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchTerminalCheckouts
#
# POST /v2/terminals/checkouts/search
# operationId: SearchTerminalCheckouts
# --query shape: {filter?: record, sort?: record}
export def "terminals-checkouts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --limit: int # Limits the number of results returned for a single request.
  --query: record # shape: {filter?: record, sort?: record}
]: any -> record<checkouts: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record, id: string, location_id: string, note: string, payment_ids: list, payment_type: string, reference_id: string, status: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/checkouts/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GetTerminalCheckout
#
# GET /v2/terminals/checkouts/{checkout_id}
# operationId: GetTerminalCheckout
export def "terminals-checkouts get" [
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($checkout_id | is-empty) { error make --unspanned { msg: "path parameter 'checkout_id' must be non-empty" } }
  let full_url = (build-url $base ({checkout_id: (encode-path-segment $checkout_id)} | format pattern "/v2/terminals/checkouts/{checkout_id}") $auth.query)
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

# CancelTerminalCheckout
#
# POST /v2/terminals/checkouts/{checkout_id}/cancel
# operationId: CancelTerminalCheckout
export def "terminals-checkouts-cancel cancel" [
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($checkout_id | is-empty) { error make --unspanned { msg: "path parameter 'checkout_id' must be non-empty" } }
  let full_url = (build-url $base ({checkout_id: (encode-path-segment $checkout_id)} | format pattern "/v2/terminals/checkouts/{checkout_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# CreateTerminalRefund
#
# POST /v2/terminals/refunds
# operationId: CreateTerminalRefund
# --refund shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_id?: string, id?: string, location_id?: string, order_id?: string, payment_id: string, reason?: string, refund_id?: string, status?: string, updated_at?: string}
export def "terminals-refunds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateRefund` request. Keys can be any valid string but must be unique for every `CreateRefund` request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  --refund: record # shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_id?: string, id?: string, location_id?: string, order_id?: string, payment_id: string, reason?: string, refund_id?: string, status?: string, updated_at?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/refunds" $auth.query)
  let req_body = {"idempotency_key": $idempotency_key, "refund": $refund} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# SearchTerminalRefunds
#
# POST /v2/terminals/refunds/search
# operationId: SearchTerminalRefunds
# --query shape: {filter?: record, sort?: record}
export def "terminals-refunds-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query.
  --limit: int # Limits the number of results returned for a single request.
  --query: record # shape: {filter?: record, sort?: record}
]: any -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/refunds/search" $auth.query)
  let req_body = {"cursor": $cursor, "limit": $limit, "query": $query} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GetTerminalRefund
#
# GET /v2/terminals/refunds/{terminal_refund_id}
# operationId: GetTerminalRefund
export def "terminals-refunds get" [
  terminal_refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($terminal_refund_id | is-empty) { error make --unspanned { msg: "path parameter 'terminal_refund_id' must be non-empty" } }
  let full_url = (build-url $base ({terminal_refund_id: (encode-path-segment $terminal_refund_id)} | format pattern "/v2/terminals/refunds/{terminal_refund_id}") $auth.query)
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

# CancelTerminalRefund
#
# POST /v2/terminals/refunds/{terminal_refund_id}/cancel
# operationId: CancelTerminalRefund
export def "terminals-refunds-cancel cancel" [
  terminal_refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($terminal_refund_id | is-empty) { error make --unspanned { msg: "path parameter 'terminal_refund_id' must be non-empty" } }
  let full_url = (build-url $base ({terminal_refund_id: (encode-path-segment $terminal_refund_id)} | format pattern "/v2/terminals/refunds/{terminal_refund_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
