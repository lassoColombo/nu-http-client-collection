# Auto-generated client for Ad Exchange Buyer API II vv2beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer2/v2beta1/openapi.json
# Auth: --token flag or $env.AD_EXCHANGE_BUYER_API_II_TOKEN

const BASE_URL = "https://adexchangebuyer.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AD_EXCHANGE_BUYER_API_II_TOKEN | default "" }
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

def base-url-completer [] { ["https://adexchangebuyer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def entity-type-completer [] { ["ADVERTISER" "AGENCY" "BRAND" "ENTITY_TYPE_UNCLASSIFIED" "ENTITY_TYPE_UNSPECIFIED"] }
def role-completer [] { ["CLIENT_DEAL_APPROVER" "CLIENT_DEAL_NEGOTIATOR" "CLIENT_DEAL_VIEWER" "CLIENT_ROLE_UNSPECIFIED"] }
def status-completer [] { ["ACTIVE" "CLIENT_STATUS_UNSPECIFIED" "DISABLED"] }
def status-completer-1 [] { ["ACTIVE" "DISABLED" "PENDING" "USER_STATUS_UNSPECIFIED"] }
def duplicate-id-mode-completer [] { ["FORCE_ENABLE_DUPLICATE_IDS" "NO_DUPLICATES"] }
def deals-status-completer [] { ["APPROVED" "CONDITIONALLY_APPROVED" "DISAPPROVED" "NOT_CHECKED" "PENDING_REVIEW" "STATUS_TYPE_UNSPECIFIED" "STATUS_UNSPECIFIED"] }
def open-auction-status-completer [] { ["APPROVED" "CONDITIONALLY_APPROVED" "DISAPPROVED" "NOT_CHECKED" "PENDING_REVIEW" "STATUS_TYPE_UNSPECIFIED" "STATUS_UNSPECIFIED"] }
def filter-syntax-completer [] { ["FILTER_SYNTAX_UNSPECIFIED" "LIST_FILTER" "PQL"] }
def environment-completer [] { ["APP" "ENVIRONMENT_UNSPECIFIED" "WEB"] }
def format-completer [] { ["FORMAT_UNSPECIFIED" "NATIVE_DISPLAY" "NATIVE_VIDEO" "NON_NATIVE_DISPLAY" "NON_NATIVE_VIDEO"] }
def time-series-granularity-completer [] { ["DAILY" "HOURLY" "TIME_SERIES_GRANULARITY_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v2beta1-accounts-clients list" } } | get name | first)
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

# Lists all the clients for the current sponsor buyer.
#
# GET /v2beta1/accounts/{accountId}/clients
# operationId: adexchangebuyer2.accounts.clients.list
export def "v2beta1-accounts-clients list" [
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
  --page-size: int # Requested page size. The server may return fewer clients than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientsResponse.nextPageToken returned from the previous call to the accounts.clients.list method.
  --partner-client-id: string # Optional unique identifier (from the standpoint of an Ad Exchange sponsor buyer partner) of the client to return. If specified, at most one client will be returned in the response.
]: nothing -> record<clients: table<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerClientId" $partner_client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "partnerClientId": $partner_client_id} | compact), body: null}
}

# Creates a new client buyer.
#
# POST /v2beta1/accounts/{accountId}/clients
# operationId: adexchangebuyer2.accounts.clients.create
export def "v2beta1-accounts-clients create" [
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
  --client-account-id: string # The globally-unique numerical ID of the client. The value of this field is ignored in create and update operations. (format: int64)
  --client-name: string # Name used to represent this client to publishers. You may have multiple clients that map to the same entity, but for each client the combination of `clientName` and entity must be unique. You can specify this field as empty. Maximum length of 255 characters is allowed.
  --entity-id: string # Numerical identifier of the client entity. The entity can be an advertiser, a brand, or an agency. This identifier is unique among all the entities with the same type. The value of this field is ignored if the entity type is not provided. A list of all known advertisers with their identifiers is available in the [advertisers.txt](https://storage.googleapis.com/adx-rtb-dictionaries/advertisers.txt) file. A list of all known brands with their identifiers is available in the [brands.txt](https://storage.googleapis.com/adx-rtb-dictionaries/brands.txt) file. A list of all known agencies with their identifiers is available in the [agencies.txt](https://storage.googleapis.com/adx-rtb-dictionaries/agencies.txt) file. (format: int64)
  --entity-name: string # The name of the entity. This field is automatically fetched based on the type and ID. The value of this field is ignored in create and update operations.
  --entity-type: string@entity-type-completer # An optional field for specifying the type of the client entity: `ADVERTISER`, `BRAND`, or `AGENCY`.
  --partner-client-id: string # Optional arbitrary unique identifier of this client buyer from the standpoint of its Ad Exchange sponsor buyer. This field can be used to associate a client buyer with the identifier in the namespace of its sponsor buyer, lookup client buyers by that identifier and verify whether an Ad Exchange counterpart of a given client buyer already exists. If present, must be unique among all the client buyers for its Ad Exchange sponsor buyer.
  --role: string@role-completer # The role which is assigned to the client buyer. Each role implies a set of permissions granted to the client. Must be one of `CLIENT_DEAL_VIEWER`, `CLIENT_DEAL_NEGOTIATOR` or `CLIENT_DEAL_APPROVER`.
  --status: string@status-completer # The status of the client buyer.
  --visible-to-seller: oneof<nothing, bool> # Whether the client buyer will be visible to sellers.
]: any -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients") $qp)
  let req_body = {"clientAccountId": $client_account_id, "clientName": $client_name, "entityId": $entity_id, "entityName": $entity_name, "entityType": $entity_type, "partnerClientId": $partner_client_id, "role": $role, "status": $status, "visibleToSeller": $visible_to_seller} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Gets a client buyer with a given client account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}
# operationId: adexchangebuyer2.accounts.clients.get
export def "v2beta1-accounts-clients get" [
  account_id: string
  client_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates an existing client buyer.
#
# PUT /v2beta1/accounts/{accountId}/clients/{clientAccountId}
# operationId: adexchangebuyer2.accounts.clients.update
export def "v2beta1-accounts-clients update" [
  account_id: string
  client_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --body-client-account-id: string # The globally-unique numerical ID of the client. The value of this field is ignored in create and update operations. (format: int64)
  --client-name: string # Name used to represent this client to publishers. You may have multiple clients that map to the same entity, but for each client the combination of `clientName` and entity must be unique. You can specify this field as empty. Maximum length of 255 characters is allowed.
  --entity-id: string # Numerical identifier of the client entity. The entity can be an advertiser, a brand, or an agency. This identifier is unique among all the entities with the same type. The value of this field is ignored if the entity type is not provided. A list of all known advertisers with their identifiers is available in the [advertisers.txt](https://storage.googleapis.com/adx-rtb-dictionaries/advertisers.txt) file. A list of all known brands with their identifiers is available in the [brands.txt](https://storage.googleapis.com/adx-rtb-dictionaries/brands.txt) file. A list of all known agencies with their identifiers is available in the [agencies.txt](https://storage.googleapis.com/adx-rtb-dictionaries/agencies.txt) file. (format: int64)
  --entity-name: string # The name of the entity. This field is automatically fetched based on the type and ID. The value of this field is ignored in create and update operations.
  --entity-type: string@entity-type-completer # An optional field for specifying the type of the client entity: `ADVERTISER`, `BRAND`, or `AGENCY`.
  --partner-client-id: string # Optional arbitrary unique identifier of this client buyer from the standpoint of its Ad Exchange sponsor buyer. This field can be used to associate a client buyer with the identifier in the namespace of its sponsor buyer, lookup client buyers by that identifier and verify whether an Ad Exchange counterpart of a given client buyer already exists. If present, must be unique among all the client buyers for its Ad Exchange sponsor buyer.
  --role: string@role-completer # The role which is assigned to the client buyer. Each role implies a set of permissions granted to the client. Must be one of `CLIENT_DEAL_VIEWER`, `CLIENT_DEAL_NEGOTIATOR` or `CLIENT_DEAL_APPROVER`.
  --status: string@status-completer # The status of the client buyer.
  --visible-to-seller: oneof<nothing, bool> # Whether the client buyer will be visible to sellers.
]: any -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}") $qp)
  let req_body = {"clientAccountId": $body_client_account_id, "clientName": $client_name, "entityId": $entity_id, "entityName": $entity_name, "entityType": $entity_type, "partnerClientId": $partner_client_id, "role": $role, "status": $status, "visibleToSeller": $visible_to_seller} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all the client users invitations for a client with a given account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations
# operationId: adexchangebuyer2.accounts.clients.invitations.list
export def "v2beta1-accounts-clients-invitations list" [
  account_id: string
  client_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. Server may return fewer clients than requested. If unspecified, server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientUserInvitationsResponse.nextPageToken returned from the previous call to the clients.invitations.list method.
]: nothing -> record<invitations: table<clientAccountId: string, email: string, invitationId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/invitations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates and sends out an email invitation to access an Ad Exchange client buyer account.
#
# POST /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations
# operationId: adexchangebuyer2.accounts.clients.invitations.create
export def "v2beta1-accounts-clients-invitations create" [
  account_id: string
  client_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --body-client-account-id: string # Numerical account ID of the client buyer that the invited user is associated with. The value of this field is ignored in create operations. (format: int64)
  --email: string # The email address to which the invitation is sent. Email addresses should be unique among all client users under each sponsor buyer.
  --invitation-id: string # The unique numerical ID of the invitation that is sent to the user. The value of this field is ignored in create operations. (format: int64)
]: any -> record<clientAccountId: string, email: string, invitationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/invitations") $qp)
  let req_body = {"clientAccountId": $body_client_account_id, "email": $email, "invitationId": $invitation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves an existing client user invitation.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations/{invitationId}
# operationId: adexchangebuyer2.accounts.clients.invitations.get
export def "v2beta1-accounts-clients-invitations get" [
  account_id: string
  client_account_id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<clientAccountId: string, email: string, invitationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  if ($invitation_id | is-empty) { error make --unspanned { msg: "path parameter 'invitationId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id), invitation_id: (encode-path-segment $invitation_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/invitations/{invitation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all the known client users for a specified sponsor buyer account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users
# operationId: adexchangebuyer2.accounts.clients.users.list
export def "v2beta1-accounts-clients-users list" [
  account_id: string
  client_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer clients than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientUsersResponse.nextPageToken returned from the previous call to the accounts.clients.users.list method.
]: nothing -> record<nextPageToken: string, users: table<clientAccountId: string, email: string, status: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Retrieves an existing client user.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users/{userId}
# operationId: adexchangebuyer2.accounts.clients.users.get
export def "v2beta1-accounts-clients-users get" [
  account_id: string
  client_account_id: string
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
]: nothing -> record<clientAccountId: string, email: string, status: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id), user_id: (encode-path-segment $user_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates an existing client user. Only the user status can be changed on update.
#
# PUT /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users/{userId}
# operationId: adexchangebuyer2.accounts.clients.users.update
export def "v2beta1-accounts-clients-users update" [
  account_id: string
  client_account_id: string
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
  --body-client-account-id: string # Numerical account ID of the client buyer with which the user is associated; the buyer must be a client of the current sponsor buyer. The value of this field is ignored in an update operation. (format: int64)
  --email: string # User's email address. The value of this field is ignored in an update operation.
  --status: string@status-completer-1 # The status of the client user.
  --body-user-id: string # The unique numerical ID of the client user that has accepted an invitation. The value of this field is ignored in an update operation. (format: int64)
]: any -> record<clientAccountId: string, email: string, status: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($client_account_id | is-empty) { error make --unspanned { msg: "path parameter 'clientAccountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), client_account_id: (encode-path-segment $client_account_id), user_id: (encode-path-segment $user_id)} | format pattern "/v2beta1/accounts/{account_id}/clients/{client_account_id}/users/{user_id}") $qp)
  let req_body = {"clientAccountId": $body_client_account_id, "email": $email, "status": $status, "userId": $body_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists creatives.
#
# GET /v2beta1/accounts/{accountId}/creatives
# operationId: adexchangebuyer2.accounts.creatives.list
export def "v2beta1-accounts-creatives list" [
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
  --page-size: int # Requested page size. The server may return fewer creatives than requested (due to timeout constraint) even if more are available through another call. If unspecified, server will pick an appropriate default. Acceptable values are 1 to 1000, inclusive.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativesResponse.next_page_token returned from the previous call to 'ListCreatives' method.
  --query: string # An optional query string to filter creatives. If no filter is specified, all active creatives will be returned. Supported queries are: - accountId=*account_id_string* - creativeId=*creative_id_string* - dealsStatus: {approved, conditionally_approved, disapproved, not_checked} - openAuctionStatus: {approved, conditionally_approved, disapproved, not_checked} - attribute: {a numeric attribute from the list of attributes} - disapprovalReason: {a reason from DisapprovalReason} Example: 'accountId=12345 AND (dealsStatus:disapproved AND disapprovalReason:unacceptable_content) OR attribute:47'
]: nothing -> record<creatives: table<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list, clickThroughUrls: list, corrections: list, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list, detectedAdvertiserIds: list, detectedDomains: list, detectedLanguages: list, detectedProductCategories: list, detectedSensitiveCategories: list, html: record, impressionTrackingUrls: list, native: record, openAuctionStatus: string, restrictedCategories: list, servingRestrictions: list, vendorIds: list, version: int, video: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact), body: null}
}

# Creates a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives
# operationId: adexchangebuyer2.accounts.creatives.create
# --adTechnologyProviders shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list<string>, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
# --html shape: {height?: int, snippet?: string, width?: int}
# --native shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
# --servingRestrictions item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
# --video shape: {videoUrl?: string, videoVastXml?: string}
export def "v2beta1-accounts-creatives create" [
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
  --duplicate-id-mode: string@duplicate-id-mode-completer # Indicates if multiple creatives can share an ID or not. Default is NO_DUPLICATES (one ID per creative).
  --body-account-id: string # The account that this creative belongs to. Can be used to filter the response of the creatives.list method.
  --ad-choices-destination-url: string # The link to AdChoices destination page.
  --ad-technology-providers: record # Detected ad technology provider information. — shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
  --advertiser-name: string # The name of the company being advertised in the creative.
  --agency-id: string # The agency ID for this creative. (format: int64)
  --api-update-time: string # Output only. The last update timestamp of the creative through the API. (format: google-datetime)
  --attributes: list<string> # All attributes for the ads that may be shown from this creative. Can be used to filter the response of the creatives.list method.
  --click-through-urls: list<string> # The set of destination URLs for the creative.
  --corrections: list # Output only. Shows any corrections that were applied to this creative. — item shape: {contexts?: list, details?: list<string>, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
  --creative-id: string # The buyer-defined creative ID of this creative. Can be used to filter the response of the creatives.list method.
  --deals-status: string@deals-status-completer # Output only. The top-level deals status of this creative. If disapproved, an entry for 'auctionType=DIRECT_DEALS' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --declared-click-through-urls: list<string> # The set of declared destination URLs for the creative.
  --detected-advertiser-ids: list<string> # Output only. Detected advertiser IDs, if any.
  --detected-domains: list<string> # Output only. The detected domains for this creative.
  --detected-languages: list<string> # Output only. The detected languages for this creative. The order is arbitrary. The codes are 2 or 5 characters and are documented at https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  --detected-product-categories: list<int> # Output only. Detected product categories, if any. See the ad-product-categories.txt file in the technical documentation for a list of IDs.
  --detected-sensitive-categories: list<int> # Output only. Detected sensitive categories, if any. See the ad-sensitive-categories.txt file in the technical documentation for a list of IDs. You should use these IDs along with the excluded-sensitive-category field in the bid request to filter your bids.
  --html: record # HTML content for a creative. — shape: {height?: int, snippet?: string, width?: int}
  --impression-tracking-urls: list<string> # The set of URLs to be called to record an impression.
  --native: record # Native content for a creative. — shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
  --open-auction-status: string@open-auction-status-completer # Output only. The top-level open auction status of this creative. If disapproved, an entry for 'auctionType = OPEN_AUCTION' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --restricted-categories: list<string> # All restricted categories for the ads that may be shown from this creative.
  --serving-restrictions: list # Output only. The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS versus HTTP request, or the type of auction). — item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
  --vendor-ids: list<int> # All vendor IDs for the ads that may be shown from this creative. See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for possible values.
  --version: int # Output only. The version of this creative. (format: int32)
  --video: record # Video content for a creative. — shape: {videoUrl?: string, videoVastXml?: string}
]: any -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "duplicateIdMode" $duplicate_id_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives") $qp)
  let req_body = {"accountId": $body_account_id, "adChoicesDestinationUrl": $ad_choices_destination_url, "adTechnologyProviders": $ad_technology_providers, "advertiserName": $advertiser_name, "agencyId": $agency_id, "apiUpdateTime": $api_update_time, "attributes": $attributes, "clickThroughUrls": $click_through_urls, "corrections": $corrections, "creativeId": $creative_id, "dealsStatus": $deals_status, "declaredClickThroughUrls": $declared_click_through_urls, "detectedAdvertiserIds": $detected_advertiser_ids, "detectedDomains": $detected_domains, "detectedLanguages": $detected_languages, "detectedProductCategories": $detected_product_categories, "detectedSensitiveCategories": $detected_sensitive_categories, "html": $html, "impressionTrackingUrls": $impression_tracking_urls, "native": $native, "openAuctionStatus": $open_auction_status, "restrictedCategories": $restricted_categories, "servingRestrictions": $serving_restrictions, "vendorIds": $vendor_ids, "version": $version, "video": $video} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "duplicateIdMode": $duplicate_id_mode} | compact), body: $req_body}
}

# Gets a creative.
#
# GET /v2beta1/accounts/{accountId}/creatives/{creativeId}
# operationId: adexchangebuyer2.accounts.creatives.get
export def "v2beta1-accounts-creatives get" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates a creative.
#
# PUT /v2beta1/accounts/{accountId}/creatives/{creativeId}
# operationId: adexchangebuyer2.accounts.creatives.update
# --adTechnologyProviders shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list<string>, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
# --html shape: {height?: int, snippet?: string, width?: int}
# --native shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
# --servingRestrictions item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
# --video shape: {videoUrl?: string, videoVastXml?: string}
export def "v2beta1-accounts-creatives update" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --body-account-id: string # The account that this creative belongs to. Can be used to filter the response of the creatives.list method.
  --ad-choices-destination-url: string # The link to AdChoices destination page.
  --ad-technology-providers: record # Detected ad technology provider information. — shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
  --advertiser-name: string # The name of the company being advertised in the creative.
  --agency-id: string # The agency ID for this creative. (format: int64)
  --api-update-time: string # Output only. The last update timestamp of the creative through the API. (format: google-datetime)
  --attributes: list<string> # All attributes for the ads that may be shown from this creative. Can be used to filter the response of the creatives.list method.
  --click-through-urls: list<string> # The set of destination URLs for the creative.
  --corrections: list # Output only. Shows any corrections that were applied to this creative. — item shape: {contexts?: list, details?: list<string>, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
  --body-creative-id: string # The buyer-defined creative ID of this creative. Can be used to filter the response of the creatives.list method.
  --deals-status: string@deals-status-completer # Output only. The top-level deals status of this creative. If disapproved, an entry for 'auctionType=DIRECT_DEALS' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --declared-click-through-urls: list<string> # The set of declared destination URLs for the creative.
  --detected-advertiser-ids: list<string> # Output only. Detected advertiser IDs, if any.
  --detected-domains: list<string> # Output only. The detected domains for this creative.
  --detected-languages: list<string> # Output only. The detected languages for this creative. The order is arbitrary. The codes are 2 or 5 characters and are documented at https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  --detected-product-categories: list<int> # Output only. Detected product categories, if any. See the ad-product-categories.txt file in the technical documentation for a list of IDs.
  --detected-sensitive-categories: list<int> # Output only. Detected sensitive categories, if any. See the ad-sensitive-categories.txt file in the technical documentation for a list of IDs. You should use these IDs along with the excluded-sensitive-category field in the bid request to filter your bids.
  --html: record # HTML content for a creative. — shape: {height?: int, snippet?: string, width?: int}
  --impression-tracking-urls: list<string> # The set of URLs to be called to record an impression.
  --native: record # Native content for a creative. — shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
  --open-auction-status: string@open-auction-status-completer # Output only. The top-level open auction status of this creative. If disapproved, an entry for 'auctionType = OPEN_AUCTION' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --restricted-categories: list<string> # All restricted categories for the ads that may be shown from this creative.
  --serving-restrictions: list # Output only. The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS versus HTTP request, or the type of auction). — item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
  --vendor-ids: list<int> # All vendor IDs for the ads that may be shown from this creative. See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for possible values.
  --version: int # Output only. The version of this creative. (format: int32)
  --video: record # Video content for a creative. — shape: {videoUrl?: string, videoVastXml?: string}
]: any -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}") $qp)
  let req_body = {"accountId": $body_account_id, "adChoicesDestinationUrl": $ad_choices_destination_url, "adTechnologyProviders": $ad_technology_providers, "advertiserName": $advertiser_name, "agencyId": $agency_id, "apiUpdateTime": $api_update_time, "attributes": $attributes, "clickThroughUrls": $click_through_urls, "corrections": $corrections, "creativeId": $body_creative_id, "dealsStatus": $deals_status, "declaredClickThroughUrls": $declared_click_through_urls, "detectedAdvertiserIds": $detected_advertiser_ids, "detectedDomains": $detected_domains, "detectedLanguages": $detected_languages, "detectedProductCategories": $detected_product_categories, "detectedSensitiveCategories": $detected_sensitive_categories, "html": $html, "impressionTrackingUrls": $impression_tracking_urls, "native": $native, "openAuctionStatus": $open_auction_status, "restrictedCategories": $restricted_categories, "servingRestrictions": $serving_restrictions, "vendorIds": $vendor_ids, "version": $version, "video": $video} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List all creative-deal associations.
#
# GET /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.list
export def "v2beta1-accounts-creatives-deal-associations list" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. Server may return fewer associations than requested. If unspecified, server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListDealAssociationsResponse.next_page_token returned from the previous call to 'ListDealAssociations' method.
  --query: string # An optional query string to filter deal associations. If no filter is specified, all associations will be returned. Supported queries are: - accountId=*account_id_string* - creativeId=*creative_id_string* - dealsId=*deals_id_string* - dealsStatus:{approved, conditionally_approved, disapproved, not_checked} - openAuctionStatus:{approved, conditionally_approved, disapproved, not_checked} Example: 'dealsId=12345 AND dealsStatus:disapproved'
]: nothing -> record<associations: table<accountId: string, creativeId: string, dealsId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}/dealAssociations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact), body: null}
}

# Associate an existing deal with a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations:add
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.add
# --association shape: {accountId?: string, creativeId?: string, dealsId?: string}
export def "v2beta1-accounts-creatives-deal-associations-add create" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --association: record # The association between a creative and a deal. — shape: {accountId?: string, creativeId?: string, dealsId?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}/dealAssociations:add") $qp)
  let req_body = {"association": $association} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Remove the association between a deal and a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations:remove
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.remove
# --association shape: {accountId?: string, creativeId?: string, dealsId?: string}
export def "v2beta1-accounts-creatives-deal-associations-remove delete" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --association: record # The association between a creative and a deal. — shape: {accountId?: string, creativeId?: string, dealsId?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}/dealAssociations:remove") $qp)
  let req_body = {"association": $association} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Stops watching a creative. Will stop push notifications being sent to the topics when the creative changes status.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}:stopWatching
# operationId: adexchangebuyer2.accounts.creatives.stopWatching
export def "v2beta1-accounts-creatives stop-watching" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}:stopWatching") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Watches a creative. Will result in push notifications being sent to the topic when the creative changes status.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}:watch
# operationId: adexchangebuyer2.accounts.creatives.watch
export def "v2beta1-accounts-creatives watch" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --topic: string # The Pub/Sub topic to publish notifications to. This topic must already exist and must give permission to ad-exchange-buyside-reports@google.com to write to the topic. This should be the full resource name in "projects/{project_id}/topics/{topic_id}" format.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($creative_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2beta1/accounts/{account_id}/creatives/{creative_id}:watch") $qp)
  let req_body = {"topic": $topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List finalized proposals, regardless if a proposal is being renegotiated. A filter expression (PQL query) may be specified to filter the results. The notes will not be returned.
#
# GET /v2beta1/accounts/{accountId}/finalizedProposals
# operationId: adexchangebuyer2.accounts.finalizedProposals.list
export def "v2beta1-accounts-finalized-proposals list" [
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
  --filter: string # An optional PQL filter query used to query for proposals. Nested repeated fields, such as proposal.deals.targetingCriterion, cannot be filtered.
  --filter-syntax: string@filter-syntax-completer # Syntax the filter is written in. Current implementation defaults to PQL but in the future it will be LIST_FILTER.
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # The page token as returned from ListProposalsResponse.
]: nothing -> record<nextPageToken: string, proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, deals: list, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: list, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record, sellerContacts: list, termsAndConditions: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filterSyntax" $filter_syntax "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/finalizedProposals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "filterSyntax": $filter_syntax, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Update given deals to pause serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to true for all listed deals in the request. Currently, this method only applies to PG and PD deals. For PA deals, call accounts.proposals.pause endpoint. It is a no-op to pause already-paused deals. It is an error to call PauseProposalDeals for deals which are not part of the proposal of proposal_id or which are not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/finalizedProposals/{proposalId}:pause
# operationId: adexchangebuyer2.accounts.finalizedProposals.pause
export def "v2beta1-accounts-finalized-proposals pause" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --external-deal-ids: list<string> # The external_deal_id's of the deals to be paused. If empty, all the deals in the proposal will be paused.
  --reason: string # The reason why the deals are being paused. This human readable message will be displayed in the seller's UI. (Max length: 1000 unicode code units.)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/finalizedProposals/{proposal_id}:pause") $qp)
  let req_body = {"externalDealIds": $external_deal_ids, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Update given deals to resume serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to false for all listed deals in the request. Currently, this method only applies to PG and PD deals. For PA deals, call accounts.proposals.resume endpoint. It is a no-op to resume running deals or deals paused by the other party. It is an error to call ResumeProposalDeals for deals which are not part of the proposal of proposal_id or which are not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/finalizedProposals/{proposalId}:resume
# operationId: adexchangebuyer2.accounts.finalizedProposals.resume
export def "v2beta1-accounts-finalized-proposals create-resume" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --external-deal-ids: list<string> # The external_deal_id's of the deals to resume. If empty, all the deals in the proposal will be resumed.
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/finalizedProposals/{proposal_id}:resume") $qp)
  let req_body = {"externalDealIds": $external_deal_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List all products visible to the buyer (optionally filtered by the specified PQL query).
#
# GET /v2beta1/accounts/{accountId}/products
# operationId: adexchangebuyer2.accounts.products.list
export def "v2beta1-accounts-products list" [
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
  --filter: string # An optional PQL query used to query for products. See https://developers.google.com/ad-manager/docs/pqlreference for documentation about PQL and examples. Nested repeated fields, such as product.targetingCriterion.inclusions, cannot be filtered.
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # The page token as returned from ListProductsResponse.
]: nothing -> record<nextPageToken: string, products: table<availableEndTime: string, availableStartTime: string, createTime: string, creatorContacts: list, displayName: string, hasCreatorSignedOff: bool, productId: string, productRevision: string, publisherProfileId: string, seller: record, syndicationProduct: string, targetingCriterion: list, terms: record, updateTime: string, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets the requested product by ID.
#
# GET /v2beta1/accounts/{accountId}/products/{productId}
# operationId: adexchangebuyer2.accounts.products.get
export def "v2beta1-accounts-products get" [
  account_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<availableEndTime: string, availableStartTime: string, createTime: string, creatorContacts: table<email: string, name: string>, displayName: string, hasCreatorSignedOff: bool, productId: string, productRevision: string, publisherProfileId: string, seller: record<accountId: string, subAccountId: string>, syndicationProduct: string, targetingCriterion: table<exclusions: list, inclusions: list, key: string>, terms: record<brandingType: string, description: string, estimatedGrossSpend: record<amount: record, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricesPerBuyer: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, sellerTimeZone: string>, updateTime: string, webPropertyCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2beta1/accounts/{account_id}/products/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# List proposals. A filter expression (PQL query) may be specified to filter the results. To retrieve all finalized proposals, regardless if a proposal is being renegotiated, see the FinalizedProposals resource. Note that Bidder/ChildSeat relationships differ from the usual behavior. A Bidder account can only see its child seats' proposals by specifying the ChildSeat's accountId in the request path.
#
# GET /v2beta1/accounts/{accountId}/proposals
# operationId: adexchangebuyer2.accounts.proposals.list
export def "v2beta1-accounts-proposals list" [
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
  --filter: string # An optional PQL filter query used to query for proposals. Nested repeated fields, such as proposal.deals.targetingCriterion, cannot be filtered.
  --filter-syntax: string@filter-syntax-completer # Syntax the filter is written in. Current implementation defaults to PQL but in the future it will be LIST_FILTER.
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # The page token as returned from ListProposalsResponse.
]: nothing -> record<nextPageToken: string, proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, deals: list, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: list, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record, sellerContacts: list, termsAndConditions: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filterSyntax" $filter_syntax "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "filterSyntax": $filter_syntax, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Create the given proposal. Each created proposal and any deals it contains are assigned a unique ID by the server.
#
# POST /v2beta1/accounts/{accountId}/proposals
# operationId: adexchangebuyer2.accounts.proposals.create
# --billedBuyer shape: {accountId?: string}
# --buyer shape: {accountId?: string}
# --buyerContacts item shape: {email?: string, name?: string}
# --buyerPrivateData shape: {referenceId?: string}
# --deals item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
# --notes item shape: {note?: string}
# --seller shape: {accountId?: string}
# --sellerContacts item shape: {email?: string, name?: string}
export def "v2beta1-accounts-proposals create" [
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
  --billed-buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer-contacts: list # Contact information for the buyer. — item shape: {email?: string, name?: string}
  --buyer-private-data: record # Buyers are allowed to store certain types of private data in a proposal/deal. — shape: {referenceId?: string}
  --deals: list # The deals associated with this proposal. For Private Auction proposals (whose deals have NonGuaranteedAuctionTerms), there will only be one deal. — item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
  --display-name: string # The name for the proposal.
  --seller: record # Represents a seller of inventory. Each seller is identified by a unique Ad Manager account ID. — shape: {accountId?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals") $qp)
  let req_body = {"billedBuyer": $billed_buyer, "buyer": $buyer, "buyerContacts": $buyer_contacts, "buyerPrivateData": $buyer_private_data, "deals": $deals, "displayName": $display_name, "seller": $seller} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Gets a proposal given its ID. The proposal is returned at its head revision.
#
# GET /v2beta1/accounts/{accountId}/proposals/{proposalId}
# operationId: adexchangebuyer2.accounts.proposals.get
export def "v2beta1-accounts-proposals get" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Update the given proposal at the client known revision number. If the server revision has advanced since the passed-in `proposal.proposal_revision`, an `ABORTED` error message will be returned. Only the buyer-modifiable fields of the proposal will be updated. Note that the deals in the proposal will be updated to match the passed-in copy. If a passed-in deal does not have a `deal_id`, the server will assign a new unique ID and create the deal. If passed-in deal has a `deal_id`, it will be updated to match the passed-in copy. Any existing deals not present in the passed-in proposal will be deleted. It is an error to pass in a deal with a `deal_id` not present at head.
#
# PUT /v2beta1/accounts/{accountId}/proposals/{proposalId}
# operationId: adexchangebuyer2.accounts.proposals.update
# --billedBuyer shape: {accountId?: string}
# --buyer shape: {accountId?: string}
# --buyerContacts item shape: {email?: string, name?: string}
# --buyerPrivateData shape: {referenceId?: string}
# --deals item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
# --notes item shape: {note?: string}
# --seller shape: {accountId?: string}
# --sellerContacts item shape: {email?: string, name?: string}
export def "v2beta1-accounts-proposals update" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --billed-buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer-contacts: list # Contact information for the buyer. — item shape: {email?: string, name?: string}
  --buyer-private-data: record # Buyers are allowed to store certain types of private data in a proposal/deal. — shape: {referenceId?: string}
  --deals: list # The deals associated with this proposal. For Private Auction proposals (whose deals have NonGuaranteedAuctionTerms), there will only be one deal. — item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
  --display-name: string # The name for the proposal.
  --seller: record # Represents a seller of inventory. Each seller is identified by a unique Ad Manager account ID. — shape: {accountId?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}") $qp)
  let req_body = {"billedBuyer": $billed_buyer, "buyer": $buyer, "buyerContacts": $buyer_contacts, "buyerPrivateData": $buyer_private_data, "deals": $deals, "displayName": $display_name, "seller": $seller} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Mark the proposal as accepted at the given revision number. If the number does not match the server's revision number an `ABORTED` error message will be returned. This call updates the proposal_state from `PROPOSED` to `BUYER_ACCEPTED`, or from `SELLER_ACCEPTED` to `FINALIZED`. Upon calling this endpoint, the buyer implicitly agrees to the terms and conditions optionally set within the proposal by the publisher.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:accept
# operationId: adexchangebuyer2.accounts.proposals.accept
export def "v2beta1-accounts-proposals create-accept" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --proposal-revision: string # The last known client revision number of the proposal. (format: int64)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:accept") $qp)
  let req_body = {"proposalRevision": $proposal_revision} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Create a new note and attach it to the proposal. The note is assigned a unique ID by the server. The proposal revision number will not increase when associated with a new note.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:addNote
# operationId: adexchangebuyer2.accounts.proposals.addNote
# --note shape: {note?: string}
export def "v2beta1-accounts-proposals create-note" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --note: record # A proposal may be associated to several notes. — shape: {note?: string}
]: any -> record<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:addNote") $qp)
  let req_body = {"note": $note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Cancel an ongoing negotiation on a proposal. This does not cancel or end serving for the deals if the proposal has been finalized, but only cancels a negotiation unilaterally.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:cancelNegotiation
# operationId: adexchangebuyer2.accounts.proposals.cancelNegotiation
export def "v2beta1-accounts-proposals cancel-negotiation" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:cancelNegotiation") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# You can opt-in to manually update proposals to indicate that setup is complete. By default, proposal setup is automatically completed after their deals are finalized. Contact your Technical Account Manager to opt in. Buyers can call this method when the proposal has been finalized, and all the required creatives have been uploaded using the Creatives API. This call updates the `is_setup_completed` field on the deals in the proposal, and notifies the seller. The server then advances the revision number of the most recent proposal. To mark an individual deal as ready to serve, call `buyers.finalizedDeals.setReadyToServe` in the Marketplace API.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:completeSetup
# operationId: adexchangebuyer2.accounts.proposals.completeSetup
export def "v2beta1-accounts-proposals complete-setup" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:completeSetup") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Update the given proposal to pause serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to true for all deals in the proposal. It is a no-op to pause an already-paused proposal. It is an error to call PauseProposal for a proposal that is not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:pause
# operationId: adexchangebuyer2.accounts.proposals.pause
export def "v2beta1-accounts-proposals pause" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --reason: string # The reason why the proposal is being paused. This human readable message will be displayed in the seller's UI. (Max length: 1000 unicode code units.)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:pause") $qp)
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Update the given proposal to resume serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to false for all deals in the proposal. Note that if the `has_seller_paused` bit is also set, serving will not resume until the seller also resumes. It is a no-op to resume an already-running proposal. It is an error to call ResumeProposal for a proposal that is not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:resume
# operationId: adexchangebuyer2.accounts.proposals.resume
export def "v2beta1-accounts-proposals create-resume" [
  account_id: string
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), proposal_id: (encode-path-segment $proposal_id)} | format pattern "/v2beta1/accounts/{account_id}/proposals/{proposal_id}:resume") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List all publisher profiles visible to the buyer
#
# GET /v2beta1/accounts/{accountId}/publisherProfiles
# operationId: adexchangebuyer2.accounts.publisherProfiles.list
export def "v2beta1-accounts-publisher-profiles list" [
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
  --page-size: int # Specify the number of results to include per page.
  --page-token: string # The page token as return from ListPublisherProfilesResponse.
]: nothing -> record<nextPageToken: string, publisherProfiles: table<audienceDescription: string, buyerPitchStatement: string, directDealsContact: string, displayName: string, domains: list, googlePlusUrl: string, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: list, overview: string, programmaticDealsContact: string, publisherProfileId: string, rateCardInfoUrl: string, samplePageUrl: string, seller: record, topHeadlines: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v2beta1/accounts/{account_id}/publisherProfiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets the requested publisher profile by id.
#
# GET /v2beta1/accounts/{accountId}/publisherProfiles/{publisherProfileId}
# operationId: adexchangebuyer2.accounts.publisherProfiles.get
export def "v2beta1-accounts-publisher-profiles get" [
  account_id: string
  publisher_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<audienceDescription: string, buyerPitchStatement: string, directDealsContact: string, displayName: string, domains: list<string>, googlePlusUrl: string, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: table<appStore: string, externalAppId: string, name: string>, overview: string, programmaticDealsContact: string, publisherProfileId: string, rateCardInfoUrl: string, samplePageUrl: string, seller: record<accountId: string, subAccountId: string>, topHeadlines: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($publisher_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'publisherProfileId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), publisher_profile_id: (encode-path-segment $publisher_profile_id)} | format pattern "/v2beta1/accounts/{account_id}/publisherProfiles/{publisher_profile_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all metrics that are measured in terms of number of bids.
#
# GET /v2beta1/{filterSetName}/bidMetrics
# operationId: adexchangebuyer2.bidders.filterSets.bidMetrics.list
export def "v2beta1-bid-metrics list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidMetricsResponse.nextPageToken returned from the previous call to the bidMetrics.list method.
]: nothing -> record<bidMetricsRows: table<bids: record, bidsInAuction: record, billedImpressions: record, impressionsWon: record, measurableImpressions: record, reachedQueries: record, rowDimensions: record, viewableImpressions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/bidMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all errors that occurred in bid responses, with the number of bid responses affected for each reason.
#
# GET /v2beta1/{filterSetName}/bidResponseErrors
# operationId: adexchangebuyer2.bidders.filterSets.bidResponseErrors.list
export def "v2beta1-bid-response-errors list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidResponseErrorsResponse.nextPageToken returned from the previous call to the bidResponseErrors.list method.
]: nothing -> record<calloutStatusRows: table<calloutStatusId: int, impressionCount: record, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/bidResponseErrors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all reasons for which bid responses were considered to have no applicable bids, with the number of bid responses affected for each reason.
#
# GET /v2beta1/{filterSetName}/bidResponsesWithoutBids
# operationId: adexchangebuyer2.bidders.filterSets.bidResponsesWithoutBids.list
export def "v2beta1-bid-responses-without-bids list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidResponsesWithoutBidsResponse.nextPageToken returned from the previous call to the bidResponsesWithoutBids.list method.
]: nothing -> record<bidResponseWithoutBidsStatusRows: table<impressionCount: record, rowDimensions: record, status: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/bidResponsesWithoutBids") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all reasons that caused a bid request not to be sent for an impression, with the number of bid requests not sent for each reason.
#
# GET /v2beta1/{filterSetName}/filteredBidRequests
# operationId: adexchangebuyer2.bidders.filterSets.filteredBidRequests.list
export def "v2beta1-filtered-bid-requests list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilteredBidRequestsResponse.nextPageToken returned from the previous call to the filteredBidRequests.list method.
]: nothing -> record<calloutStatusRows: table<calloutStatusId: int, impressionCount: record, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/filteredBidRequests") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all reasons for which bids were filtered, with the number of bids filtered for each reason.
#
# GET /v2beta1/{filterSetName}/filteredBids
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.list
export def "v2beta1-filtered-bids list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilteredBidsResponse.nextPageToken returned from the previous call to the filteredBids.list method.
]: nothing -> record<creativeStatusRows: table<bidCount: record, creativeStatusId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/filteredBids") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all creatives associated with a specific reason for which bids were filtered, with the number of bids filtered for each creative.
#
# GET /v2beta1/{filterSetName}/filteredBids/{creativeStatusId}/creatives
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.creatives.list
export def "v2beta1-filtered-bids-creatives list" [
  filter_set_name: string
  creative_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativeStatusBreakdownByCreativeResponse.nextPageToken returned from the previous call to the filteredBids.creatives.list method.
]: nothing -> record<filteredBidCreativeRows: table<bidCount: record, creativeId: string, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  if ($creative_status_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeStatusId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name), creative_status_id: (encode-path-segment $creative_status_id)} | format pattern "/v2beta1/{filter_set_name}/filteredBids/{creative_status_id}/creatives") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all details associated with a specific reason for which bids were filtered, with the number of bids filtered for each detail.
#
# GET /v2beta1/{filterSetName}/filteredBids/{creativeStatusId}/details
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.details.list
export def "v2beta1-filtered-bids-details list" [
  filter_set_name: string
  creative_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativeStatusBreakdownByDetailResponse.nextPageToken returned from the previous call to the filteredBids.details.list method.
]: nothing -> record<detailType: string, filteredBidDetailRows: table<bidCount: record, detail: string, detailId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  if ($creative_status_id | is-empty) { error make --unspanned { msg: "path parameter 'creativeStatusId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name), creative_status_id: (encode-path-segment $creative_status_id)} | format pattern "/v2beta1/{filter_set_name}/filteredBids/{creative_status_id}/details") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Lists all metrics that are measured in terms of number of impressions.
#
# GET /v2beta1/{filterSetName}/impressionMetrics
# operationId: adexchangebuyer2.bidders.filterSets.impressionMetrics.list
export def "v2beta1-impression-metrics list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListImpressionMetricsResponse.nextPageToken returned from the previous call to the impressionMetrics.list method.
]: nothing -> record<impressionMetricsRows: table<availableImpressions: record, bidRequests: record, inventoryMatches: record, responsesWithBids: record, rowDimensions: record, successfulResponses: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/impressionMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all reasons for which bids lost in the auction, with the number of bids that lost for each reason.
#
# GET /v2beta1/{filterSetName}/losingBids
# operationId: adexchangebuyer2.bidders.filterSets.losingBids.list
export def "v2beta1-losing-bids list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListLosingBidsResponse.nextPageToken returned from the previous call to the losingBids.list method.
]: nothing -> record<creativeStatusRows: table<bidCount: record, creativeStatusId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/losingBids") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# List all reasons for which winning bids were not billable, with the number of bids not billed for each reason.
#
# GET /v2beta1/{filterSetName}/nonBillableWinningBids
# operationId: adexchangebuyer2.bidders.filterSets.nonBillableWinningBids.list
export def "v2beta1-non-billable-winning-bids list" [
  filter_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListNonBillableWinningBidsResponse.nextPageToken returned from the previous call to the nonBillableWinningBids.list method.
]: nothing -> record<nextPageToken: string, nonBillableWinningBidStatusRows: table<bidCount: record, rowDimensions: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_set_name | is-empty) { error make --unspanned { msg: "path parameter 'filterSetName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_set_name: (encode-path-segment $filter_set_name)} | format pattern "/v2beta1/{filter_set_name}/nonBillableWinningBids") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Deletes the requested filter set from the account with the given account ID.
#
# DELETE /v2beta1/{name}
# operationId: adexchangebuyer2.bidders.filterSets.delete
export def "v2beta1 delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves the requested filter set for the account with the given account ID.
#
# GET /v2beta1/{name}
# operationId: adexchangebuyer2.bidders.filterSets.get
export def "v2beta1 get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record<absoluteDateRange: record<endDate: record<day: int, month: int, year: int>, startDate: record<day: int, month: int, year: int>>, breakdownDimensions: list<string>, creativeId: string, dealId: string, environment: string, format: string, formats: list<string>, name: string, platforms: list<string>, publisherIdentifiers: list<string>, realtimeTimeRange: record<startTimestamp: string>, relativeDateRange: record<durationDays: int, offsetDays: int>, sellerNetworkIds: list<int>, timeSeriesGranularity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all filter sets for the account with the given account ID.
#
# GET /v2beta1/{ownerName}/filterSets
# operationId: adexchangebuyer2.bidders.filterSets.list
export def "v2beta1-filter-sets list" [
  owner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilterSetsResponse.nextPageToken returned from the previous call to the accounts.filterSets.list method.
]: nothing -> record<filterSets: table<absoluteDateRange: record, breakdownDimensions: list, creativeId: string, dealId: string, environment: string, format: string, formats: list, name: string, platforms: list, publisherIdentifiers: list, realtimeTimeRange: record, relativeDateRange: record, sellerNetworkIds: list, timeSeriesGranularity: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'ownerName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name)} | format pattern "/v2beta1/{owner_name}/filterSets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates the specified filter set for the account with the given account ID.
#
# POST /v2beta1/{ownerName}/filterSets
# operationId: adexchangebuyer2.bidders.filterSets.create
# --absoluteDateRange shape: {endDate?: record, startDate?: record}
# --realtimeTimeRange shape: {startTimestamp?: string}
# --relativeDateRange shape: {durationDays?: int, offsetDays?: int}
export def "v2beta1-filter-sets create" [
  owner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --is-transient: oneof<nothing, bool> # Whether the filter set is transient, or should be persisted indefinitely. By default, filter sets are not transient. If transient, it will be available for at least 1 hour after creation.
  --absolute-date-range: record # An absolute date range, specified by its start date and end date. The supported range of dates begins 30 days before today and ends today. Validity checked upon filter set creation. If a filter set with an absolute date range is run at a later date more than 30 days after start_date, it will fail. — shape: {endDate?: record, startDate?: record}
  --breakdown-dimensions: list<string> # The set of dimensions along which to break down the response; may be empty. If multiple dimensions are requested, the breakdown is along the Cartesian product of the requested dimensions.
  --creative-id: string # The ID of the creative on which to filter; optional. This field may be set only for a filter set that accesses account-level troubleshooting data, for example, one whose name matches the `bidders/*/accounts/*/filterSets/*` pattern.
  --deal-id: string # The ID of the deal on which to filter; optional. This field may be set only for a filter set that accesses account-level troubleshooting data, for example, one whose name matches the `bidders/*/accounts/*/filterSets/*` pattern. (format: int64)
  --environment: string@environment-completer # The environment on which to filter; optional.
  --format: string@format-completer # Creative format bidded on or allowed to bid on, can be empty.
  --formats: list<string> # Creative formats bidded on or allowed to bid on, can be empty. Although this field is a list, it can only be populated with a single item. A HTTP 400 bad request error will be returned in the response if you specify multiple items.
  --name: string # A user-defined name of the filter set. Filter set names must be unique globally and match one of the patterns: - `bidders/*/filterSets/*` (for accessing bidder-level troubleshooting data) - `bidders/*/accounts/*/filterSets/*` (for accessing account-level troubleshooting data) This field is required in create operations.
  --platforms: list<string> # The list of platforms on which to filter; may be empty. The filters represented by multiple platforms are ORed together (for example, if non-empty, results must match any one of the platforms).
  --publisher-identifiers: list<string> # For Open Bidding partners only. The list of publisher identifiers on which to filter; may be empty. The filters represented by multiple publisher identifiers are ORed together.
  --realtime-time-range: record # An open-ended realtime time range specified by the start timestamp. For filter sets that specify a realtime time range RTB metrics continue to be aggregated throughout the lifetime of the filter set. — shape: {startTimestamp?: string}
  --relative-date-range: record # A relative date range, specified by an offset and a duration. The supported range of dates begins 30 days before today and ends today, for example, the limits for these values are: offset_days >= 0 duration_days >= 1 offset_days + duration_days <= 30 — shape: {durationDays?: int, offsetDays?: int}
  --seller-network-ids: list<int> # For Authorized Buyers only. The list of IDs of the seller (publisher) networks on which to filter; may be empty. The filters represented by multiple seller network IDs are ORed together (for example, if non-empty, results must match any one of the publisher networks). See [seller-network-ids](https://developers.google.com/authorized-buyers/rtb/downloads/seller-network-ids) file for the set of existing seller network IDs.
  --time-series-granularity: string@time-series-granularity-completer # The granularity of time intervals if a time series breakdown is preferred; optional.
]: any -> record<absoluteDateRange: record<endDate: record<day: int, month: int, year: int>, startDate: record<day: int, month: int, year: int>>, breakdownDimensions: list<string>, creativeId: string, dealId: string, environment: string, format: string, formats: list<string>, name: string, platforms: list<string>, publisherIdentifiers: list<string>, realtimeTimeRange: record<startTimestamp: string>, relativeDateRange: record<durationDays: int, offsetDays: int>, sellerNetworkIds: list<int>, timeSeriesGranularity: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($owner_name | is-empty) { error make --unspanned { msg: "path parameter 'ownerName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "isTransient" $is_transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner_name: (encode-path-segment $owner_name)} | format pattern "/v2beta1/{owner_name}/filterSets") $qp)
  let req_body = {"absoluteDateRange": $absolute_date_range, "breakdownDimensions": $breakdown_dimensions, "creativeId": $creative_id, "dealId": $deal_id, "environment": $environment, "format": $format, "formats": $formats, "name": $name, "platforms": $platforms, "publisherIdentifiers": $publisher_identifiers, "realtimeTimeRange": $realtime_time_range, "relativeDateRange": $relative_date_range, "sellerNetworkIds": $seller_network_ids, "timeSeriesGranularity": $time_series_granularity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "isTransient": $is_transient} | compact), body: $req_body}
}
