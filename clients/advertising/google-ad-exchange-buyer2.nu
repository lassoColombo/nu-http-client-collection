# Auto-generated client for Ad Exchange Buyer API II vv2beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer2/v2beta1/openapi.json
# Auth: --token flag or $env.AD_EXCHANGE_BUYER_API_II_TOKEN

const BASE_URL = "https://adexchangebuyer.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AD_EXCHANGE_BUYER_API_II_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://adexchangebuyer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def entityType-completer [] { ["ADVERTISER" "AGENCY" "BRAND" "ENTITY_TYPE_UNCLASSIFIED" "ENTITY_TYPE_UNSPECIFIED"] }
def role-completer [] { ["CLIENT_DEAL_APPROVER" "CLIENT_DEAL_NEGOTIATOR" "CLIENT_DEAL_VIEWER" "CLIENT_ROLE_UNSPECIFIED"] }
def status-completer [] { ["ACTIVE" "CLIENT_STATUS_UNSPECIFIED" "DISABLED"] }
def status-completer-1 [] { ["ACTIVE" "DISABLED" "PENDING" "USER_STATUS_UNSPECIFIED"] }
def duplicateIdMode-completer [] { ["FORCE_ENABLE_DUPLICATE_IDS" "NO_DUPLICATES"] }
def dealsStatus-completer [] { ["APPROVED" "CONDITIONALLY_APPROVED" "DISAPPROVED" "NOT_CHECKED" "PENDING_REVIEW" "STATUS_TYPE_UNSPECIFIED" "STATUS_UNSPECIFIED"] }
def openAuctionStatus-completer [] { ["APPROVED" "CONDITIONALLY_APPROVED" "DISAPPROVED" "NOT_CHECKED" "PENDING_REVIEW" "STATUS_TYPE_UNSPECIFIED" "STATUS_UNSPECIFIED"] }
def filterSyntax-completer [] { ["FILTER_SYNTAX_UNSPECIFIED" "LIST_FILTER" "PQL"] }
def environment-completer [] { ["APP" "ENVIRONMENT_UNSPECIFIED" "WEB"] }
def format-completer [] { ["FORMAT_UNSPECIFIED" "NATIVE_DISPLAY" "NATIVE_VIDEO" "NON_NATIVE_DISPLAY" "NON_NATIVE_VIDEO"] }
def timeSeriesGranularity-completer [] { ["DAILY" "HOURLY" "TIME_SERIES_GRANULARITY_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v2beta1-accounts-clients adexchangebuyer2accountsclientslist" } } | get name | first)
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
export def "v2beta1-accounts-clients adexchangebuyer2accountsclientslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer clients than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientsResponse.nextPageToken returned from the previous call to the accounts.clients.list method.
  --partnerClientId: string # Optional unique identifier (from the standpoint of an Ad Exchange sponsor buyer partner) of the client to return. If specified, at most one client will be returned in the response.
]: nothing -> record<clients: table<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "partnerClientId" $partnerClientId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new client buyer.
#
# POST /v2beta1/accounts/{accountId}/clients
# operationId: adexchangebuyer2.accounts.clients.create
export def "v2beta1-accounts-clients adexchangebuyer2accountsclientscreate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clientAccountId: string # The globally-unique numerical ID of the client. The value of this field is ignored in create and update operations. (format: int64)
  --clientName: string # Name used to represent this client to publishers. You may have multiple clients that map to the same entity, but for each client the combination of `clientName` and entity must be unique. You can specify this field as empty. Maximum length of 255 characters is allowed.
  --entityId: string # Numerical identifier of the client entity. The entity can be an advertiser, a brand, or an agency. This identifier is unique among all the entities with the same type. The value of this field is ignored if the entity type is not provided. A list of all known advertisers with their identifiers is available in the [advertisers.txt](https://storage.googleapis.com/adx-rtb-dictionaries/advertisers.txt) file. A list of all known brands with their identifiers is available in the [brands.txt](https://storage.googleapis.com/adx-rtb-dictionaries/brands.txt) file. A list of all known agencies with their identifiers is available in the [agencies.txt](https://storage.googleapis.com/adx-rtb-dictionaries/agencies.txt) file. (format: int64)
  --entityName: string # The name of the entity. This field is automatically fetched based on the type and ID. The value of this field is ignored in create and update operations.
  --entityType: string@entityType-completer # An optional field for specifying the type of the client entity: `ADVERTISER`, `BRAND`, or `AGENCY`.
  --partnerClientId: string # Optional arbitrary unique identifier of this client buyer from the standpoint of its Ad Exchange sponsor buyer. This field can be used to associate a client buyer with the identifier in the namespace of its sponsor buyer, lookup client buyers by that identifier and verify whether an Ad Exchange counterpart of a given client buyer already exists. If present, must be unique among all the client buyers for its Ad Exchange sponsor buyer.
  --role: string@role-completer # The role which is assigned to the client buyer. Each role implies a set of permissions granted to the client. Must be one of `CLIENT_DEAL_VIEWER`, `CLIENT_DEAL_NEGOTIATOR` or `CLIENT_DEAL_APPROVER`.
  --status: string@status-completer # The status of the client buyer.
  --visibleToSeller: oneof<nothing, bool> # Whether the client buyer will be visible to sellers.
]: any -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients" $qp)
  let body = {clientAccountId: $clientAccountId, clientName: $clientName, entityId: $entityId, entityName: $entityName, entityType: $entityType, partnerClientId: $partnerClientId, role: $role, status: $status, visibleToSeller: $visibleToSeller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a client buyer with a given client account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}
# operationId: adexchangebuyer2.accounts.clients.get
export def "v2beta1-accounts-clients adexchangebuyer2accountsclientsget" [
  accountId: string
  clientAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing client buyer.
#
# PUT /v2beta1/accounts/{accountId}/clients/{clientAccountId}
# operationId: adexchangebuyer2.accounts.clients.update
export def "v2beta1-accounts-clients adexchangebuyer2accountsclientsupdate" [
  accountId: string
  clientAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-clientAccountId: string # The globally-unique numerical ID of the client. The value of this field is ignored in create and update operations. (format: int64)
  --clientName: string # Name used to represent this client to publishers. You may have multiple clients that map to the same entity, but for each client the combination of `clientName` and entity must be unique. You can specify this field as empty. Maximum length of 255 characters is allowed.
  --entityId: string # Numerical identifier of the client entity. The entity can be an advertiser, a brand, or an agency. This identifier is unique among all the entities with the same type. The value of this field is ignored if the entity type is not provided. A list of all known advertisers with their identifiers is available in the [advertisers.txt](https://storage.googleapis.com/adx-rtb-dictionaries/advertisers.txt) file. A list of all known brands with their identifiers is available in the [brands.txt](https://storage.googleapis.com/adx-rtb-dictionaries/brands.txt) file. A list of all known agencies with their identifiers is available in the [agencies.txt](https://storage.googleapis.com/adx-rtb-dictionaries/agencies.txt) file. (format: int64)
  --entityName: string # The name of the entity. This field is automatically fetched based on the type and ID. The value of this field is ignored in create and update operations.
  --entityType: string@entityType-completer # An optional field for specifying the type of the client entity: `ADVERTISER`, `BRAND`, or `AGENCY`.
  --partnerClientId: string # Optional arbitrary unique identifier of this client buyer from the standpoint of its Ad Exchange sponsor buyer. This field can be used to associate a client buyer with the identifier in the namespace of its sponsor buyer, lookup client buyers by that identifier and verify whether an Ad Exchange counterpart of a given client buyer already exists. If present, must be unique among all the client buyers for its Ad Exchange sponsor buyer.
  --role: string@role-completer # The role which is assigned to the client buyer. Each role implies a set of permissions granted to the client. Must be one of `CLIENT_DEAL_VIEWER`, `CLIENT_DEAL_NEGOTIATOR` or `CLIENT_DEAL_APPROVER`.
  --status: string@status-completer # The status of the client buyer.
  --visibleToSeller: oneof<nothing, bool> # Whether the client buyer will be visible to sellers.
]: any -> record<clientAccountId: string, clientName: string, entityId: string, entityName: string, entityType: string, partnerClientId: string, role: string, status: string, visibleToSeller: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)" $qp)
  let body = {clientAccountId: $body_clientAccountId, clientName: $clientName, entityId: $entityId, entityName: $entityName, entityType: $entityType, partnerClientId: $partnerClientId, role: $role, status: $status, visibleToSeller: $visibleToSeller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all the client users invitations for a client with a given account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations
# operationId: adexchangebuyer2.accounts.clients.invitations.list
export def "v2beta1-accounts-clients-invitations adexchangebuyer2accountsclientsinvitationslist" [
  accountId: string
  clientAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. Server may return fewer clients than requested. If unspecified, server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientUserInvitationsResponse.nextPageToken returned from the previous call to the clients.invitations.list method.
]: nothing -> record<invitations: table<clientAccountId: string, email: string, invitationId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates and sends out an email invitation to access an Ad Exchange client buyer account.
#
# POST /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations
# operationId: adexchangebuyer2.accounts.clients.invitations.create
export def "v2beta1-accounts-clients-invitations adexchangebuyer2accountsclientsinvitationscreate" [
  accountId: string
  clientAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-clientAccountId: string # Numerical account ID of the client buyer that the invited user is associated with. The value of this field is ignored in create operations. (format: int64)
  --email: string # The email address to which the invitation is sent. Email addresses should be unique among all client users under each sponsor buyer.
  --invitationId: string # The unique numerical ID of the invitation that is sent to the user. The value of this field is ignored in create operations. (format: int64)
]: any -> record<clientAccountId: string, email: string, invitationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/invitations" $qp)
  let body = {clientAccountId: $body_clientAccountId, email: $email, invitationId: $invitationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an existing client user invitation.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/invitations/{invitationId}
# operationId: adexchangebuyer2.accounts.clients.invitations.get
export def "v2beta1-accounts-clients-invitations adexchangebuyer2accountsclientsinvitationsget" [
  accountId: string
  clientAccountId: string
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<clientAccountId: string, email: string, invitationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/invitations/($invitationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the known client users for a specified sponsor buyer account ID.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users
# operationId: adexchangebuyer2.accounts.clients.users.list
export def "v2beta1-accounts-clients-users adexchangebuyer2accountsclientsuserslist" [
  accountId: string
  clientAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer clients than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientUsersResponse.nextPageToken returned from the previous call to the accounts.clients.users.list method.
]: nothing -> record<nextPageToken: string, users: table<clientAccountId: string, email: string, status: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves an existing client user.
#
# GET /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users/{userId}
# operationId: adexchangebuyer2.accounts.clients.users.get
export def "v2beta1-accounts-clients-users adexchangebuyer2accountsclientsusersget" [
  accountId: string
  clientAccountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<clientAccountId: string, email: string, status: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing client user. Only the user status can be changed on update.
#
# PUT /v2beta1/accounts/{accountId}/clients/{clientAccountId}/users/{userId}
# operationId: adexchangebuyer2.accounts.clients.users.update
export def "v2beta1-accounts-clients-users adexchangebuyer2accountsclientsusersupdate" [
  accountId: string
  clientAccountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-clientAccountId: string # Numerical account ID of the client buyer with which the user is associated; the buyer must be a client of the current sponsor buyer. The value of this field is ignored in an update operation. (format: int64)
  --email: string # User's email address. The value of this field is ignored in an update operation.
  --status: string@status-completer-1 # The status of the client user.
  --body-userId: string # The unique numerical ID of the client user that has accepted an invitation. The value of this field is ignored in an update operation. (format: int64)
]: any -> record<clientAccountId: string, email: string, status: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/clients/($clientAccountId)/users/($userId)" $qp)
  let body = {clientAccountId: $body_clientAccountId, email: $email, status: $status, userId: $body_userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists creatives.
#
# GET /v2beta1/accounts/{accountId}/creatives
# operationId: adexchangebuyer2.accounts.creatives.list
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativeslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer creatives than requested (due to timeout constraint) even if more are available through another call. If unspecified, server will pick an appropriate default. Acceptable values are 1 to 1000, inclusive.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativesResponse.next_page_token returned from the previous call to 'ListCreatives' method.
  --qp-query: string # An optional query string to filter creatives. If no filter is specified, all active creatives will be returned. Supported queries are: - accountId=*account_id_string* - creativeId=*creative_id_string* - dealsStatus: {approved, conditionally_approved, disapproved, not_checked} - openAuctionStatus: {approved, conditionally_approved, disapproved, not_checked} - attribute: {a numeric attribute from the list of attributes} - disapprovalReason: {a reason from DisapprovalReason} Example: 'accountId=12345 AND (dealsStatus:disapproved AND disapprovalReason:unacceptable_content) OR attribute:47'
]: nothing -> record<creatives: table<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list, clickThroughUrls: list, corrections: list, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list, detectedAdvertiserIds: list, detectedDomains: list, detectedLanguages: list, detectedProductCategories: list, detectedSensitiveCategories: list, html: record, impressionTrackingUrls: list, native: record, openAuctionStatus: string, restrictedCategories: list, servingRestrictions: list, vendorIds: list, version: int, video: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives
# operationId: adexchangebuyer2.accounts.creatives.create
# --adTechnologyProviders shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
# --html shape: {height?: int, snippet?: string, width?: int}
# --native shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
# --servingRestrictions item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
# --video shape: {videoUrl?: string, videoVastXml?: string}
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativescreate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --duplicateIdMode: string@duplicateIdMode-completer # Indicates if multiple creatives can share an ID or not. Default is NO_DUPLICATES (one ID per creative).
  --body-accountId: string # The account that this creative belongs to. Can be used to filter the response of the creatives.list method.
  --adChoicesDestinationUrl: string # The link to AdChoices destination page.
  --adTechnologyProviders: record # Detected ad technology provider information. — shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
  --advertiserName: string # The name of the company being advertised in the creative.
  --agencyId: string # The agency ID for this creative. (format: int64)
  --apiUpdateTime: string # Output only. The last update timestamp of the creative through the API. (format: google-datetime)
  --attributes: list # All attributes for the ads that may be shown from this creative. Can be used to filter the response of the creatives.list method.
  --clickThroughUrls: list # The set of destination URLs for the creative.
  --corrections: list # Output only. Shows any corrections that were applied to this creative. — item shape: {contexts?: list, details?: list, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
  --creativeId: string # The buyer-defined creative ID of this creative. Can be used to filter the response of the creatives.list method.
  --dealsStatus: string@dealsStatus-completer # Output only. The top-level deals status of this creative. If disapproved, an entry for 'auctionType=DIRECT_DEALS' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --declaredClickThroughUrls: list # The set of declared destination URLs for the creative.
  --detectedAdvertiserIds: list # Output only. Detected advertiser IDs, if any.
  --detectedDomains: list # Output only. The detected domains for this creative.
  --detectedLanguages: list # Output only. The detected languages for this creative. The order is arbitrary. The codes are 2 or 5 characters and are documented at https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  --detectedProductCategories: list # Output only. Detected product categories, if any. See the ad-product-categories.txt file in the technical documentation for a list of IDs.
  --detectedSensitiveCategories: list # Output only. Detected sensitive categories, if any. See the ad-sensitive-categories.txt file in the technical documentation for a list of IDs. You should use these IDs along with the excluded-sensitive-category field in the bid request to filter your bids.
  --html: record # HTML content for a creative. — shape: {height?: int, snippet?: string, width?: int}
  --impressionTrackingUrls: list # The set of URLs to be called to record an impression.
  --native: record # Native content for a creative. — shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
  --openAuctionStatus: string@openAuctionStatus-completer # Output only. The top-level open auction status of this creative. If disapproved, an entry for 'auctionType = OPEN_AUCTION' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --restrictedCategories: list # All restricted categories for the ads that may be shown from this creative.
  --servingRestrictions: list # Output only. The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS versus HTTP request, or the type of auction). — item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
  --vendorIds: list # All vendor IDs for the ads that may be shown from this creative. See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for possible values.
  --version: int # Output only. The version of this creative. (format: int32)
  --video: record # Video content for a creative. — shape: {videoUrl?: string, videoVastXml?: string}
]: any -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "duplicateIdMode" $duplicateIdMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives" $qp)
  let body = {accountId: $body_accountId, adChoicesDestinationUrl: $adChoicesDestinationUrl, adTechnologyProviders: $adTechnologyProviders, advertiserName: $advertiserName, agencyId: $agencyId, apiUpdateTime: $apiUpdateTime, attributes: $attributes, clickThroughUrls: $clickThroughUrls, corrections: $corrections, creativeId: $creativeId, dealsStatus: $dealsStatus, declaredClickThroughUrls: $declaredClickThroughUrls, detectedAdvertiserIds: $detectedAdvertiserIds, detectedDomains: $detectedDomains, detectedLanguages: $detectedLanguages, detectedProductCategories: $detectedProductCategories, detectedSensitiveCategories: $detectedSensitiveCategories, html: $html, impressionTrackingUrls: $impressionTrackingUrls, native: $native, openAuctionStatus: $openAuctionStatus, restrictedCategories: $restrictedCategories, servingRestrictions: $servingRestrictions, vendorIds: $vendorIds, version: $version, video: $video} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a creative.
#
# GET /v2beta1/accounts/{accountId}/creatives/{creativeId}
# operationId: adexchangebuyer2.accounts.creatives.get
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativesget" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a creative.
#
# PUT /v2beta1/accounts/{accountId}/creatives/{creativeId}
# operationId: adexchangebuyer2.accounts.creatives.update
# --adTechnologyProviders shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
# --html shape: {height?: int, snippet?: string, width?: int}
# --native shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
# --servingRestrictions item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
# --video shape: {videoUrl?: string, videoVastXml?: string}
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativesupdate" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-accountId: string # The account that this creative belongs to. Can be used to filter the response of the creatives.list method.
  --adChoicesDestinationUrl: string # The link to AdChoices destination page.
  --adTechnologyProviders: record # Detected ad technology provider information. — shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
  --advertiserName: string # The name of the company being advertised in the creative.
  --agencyId: string # The agency ID for this creative. (format: int64)
  --apiUpdateTime: string # Output only. The last update timestamp of the creative through the API. (format: google-datetime)
  --attributes: list # All attributes for the ads that may be shown from this creative. Can be used to filter the response of the creatives.list method.
  --clickThroughUrls: list # The set of destination URLs for the creative.
  --corrections: list # Output only. Shows any corrections that were applied to this creative. — item shape: {contexts?: list, details?: list, type?: "CORRECTION_TYPE_UNSPECIFIED"|"VENDOR_IDS_ADDED"|"SSL_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_REMOVED"|"FLASH_FREE_ATTRIBUTE_ADDED"|"REQUIRED_ATTRIBUTE_ADDED"|"REQUIRED_VENDOR_ADDED"|"SSL_ATTRIBUTE_ADDED"|"IN_BANNER_VIDEO_ATTRIBUTE_ADDED"|"MRAID_ATTRIBUTE_ADDED"|"FLASH_ATTRIBUTE_REMOVED"|"VIDEO_IN_SNIPPET_ATTRIBUTE_ADDED"}
  --body-creativeId: string # The buyer-defined creative ID of this creative. Can be used to filter the response of the creatives.list method.
  --dealsStatus: string@dealsStatus-completer # Output only. The top-level deals status of this creative. If disapproved, an entry for 'auctionType=DIRECT_DEALS' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --declaredClickThroughUrls: list # The set of declared destination URLs for the creative.
  --detectedAdvertiserIds: list # Output only. Detected advertiser IDs, if any.
  --detectedDomains: list # Output only. The detected domains for this creative.
  --detectedLanguages: list # Output only. The detected languages for this creative. The order is arbitrary. The codes are 2 or 5 characters and are documented at https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  --detectedProductCategories: list # Output only. Detected product categories, if any. See the ad-product-categories.txt file in the technical documentation for a list of IDs.
  --detectedSensitiveCategories: list # Output only. Detected sensitive categories, if any. See the ad-sensitive-categories.txt file in the technical documentation for a list of IDs. You should use these IDs along with the excluded-sensitive-category field in the bid request to filter your bids.
  --html: record # HTML content for a creative. — shape: {height?: int, snippet?: string, width?: int}
  --impressionTrackingUrls: list # The set of URLs to be called to record an impression.
  --native: record # Native content for a creative. — shape: {advertiserName?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, logo?: record, priceDisplayText?: string, starRating?: float, storeUrl?: string, videoUrl?: string}
  --openAuctionStatus: string@openAuctionStatus-completer # Output only. The top-level open auction status of this creative. If disapproved, an entry for 'auctionType = OPEN_AUCTION' (or 'ALL') in serving_restrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case, it may be preferable to read from serving_restrictions directly. Can be used to filter the response of the creatives.list method.
  --restrictedCategories: list # All restricted categories for the ads that may be shown from this creative.
  --servingRestrictions: list # Output only. The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS versus HTTP request, or the type of auction). — item shape: {contexts?: list, disapproval?: record, disapprovalReasons?: list, status?: "STATUS_UNSPECIFIED"|"DISAPPROVAL"|"PENDING_REVIEW"}
  --vendorIds: list # All vendor IDs for the ads that may be shown from this creative. See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for possible values.
  --version: int # Output only. The version of this creative. (format: int32)
  --video: record # Video content for a creative. — shape: {videoUrl?: string, videoVastXml?: string}
]: any -> record<accountId: string, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserName: string, agencyId: string, apiUpdateTime: string, attributes: list<string>, clickThroughUrls: list<string>, corrections: table<contexts: list, details: list, type: string>, creativeId: string, dealsStatus: string, declaredClickThroughUrls: list<string>, detectedAdvertiserIds: list<string>, detectedDomains: list<string>, detectedLanguages: list<string>, detectedProductCategories: list<int>, detectedSensitiveCategories: list<int>, html: record<height: int, snippet: string, width: int>, impressionTrackingUrls: list<string>, native: record<advertiserName: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, logo: record<height: int, url: string, width: int>, priceDisplayText: string, starRating: float, storeUrl: string, videoUrl: string>, openAuctionStatus: string, restrictedCategories: list<string>, servingRestrictions: table<contexts: list, disapproval: record, disapprovalReasons: list, status: string>, vendorIds: list<int>, version: int, video: record<videoUrl: string, videoVastXml: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId)" $qp)
  let body = {accountId: $body_accountId, adChoicesDestinationUrl: $adChoicesDestinationUrl, adTechnologyProviders: $adTechnologyProviders, advertiserName: $advertiserName, agencyId: $agencyId, apiUpdateTime: $apiUpdateTime, attributes: $attributes, clickThroughUrls: $clickThroughUrls, corrections: $corrections, creativeId: $body_creativeId, dealsStatus: $dealsStatus, declaredClickThroughUrls: $declaredClickThroughUrls, detectedAdvertiserIds: $detectedAdvertiserIds, detectedDomains: $detectedDomains, detectedLanguages: $detectedLanguages, detectedProductCategories: $detectedProductCategories, detectedSensitiveCategories: $detectedSensitiveCategories, html: $html, impressionTrackingUrls: $impressionTrackingUrls, native: $native, openAuctionStatus: $openAuctionStatus, restrictedCategories: $restrictedCategories, servingRestrictions: $servingRestrictions, vendorIds: $vendorIds, version: $version, video: $video} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all creative-deal associations.
#
# GET /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.list
export def "v2beta1-accounts-creatives-deal-associations adexchangebuyer2accountscreativesdealAssociationslist" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. Server may return fewer associations than requested. If unspecified, server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListDealAssociationsResponse.next_page_token returned from the previous call to 'ListDealAssociations' method.
  --qp-query: string # An optional query string to filter deal associations. If no filter is specified, all associations will be returned. Supported queries are: - accountId=*account_id_string* - creativeId=*creative_id_string* - dealsId=*deals_id_string* - dealsStatus:{approved, conditionally_approved, disapproved, not_checked} - openAuctionStatus:{approved, conditionally_approved, disapproved, not_checked} Example: 'dealsId=12345 AND dealsStatus:disapproved'
]: nothing -> record<associations: table<accountId: string, creativeId: string, dealsId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId)/dealAssociations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate an existing deal with a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations:add
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.add
# --association shape: {accountId?: string, creativeId?: string, dealsId?: string}
export def "v2beta1-accounts-creatives-deal-associations-add adexchangebuyer2accountscreativesdealAssociationsadd" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --association: record # The association between a creative and a deal. — shape: {accountId?: string, creativeId?: string, dealsId?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId)/dealAssociations:add" $qp)
  let body = {association: $association} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove the association between a deal and a creative.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}/dealAssociations:remove
# operationId: adexchangebuyer2.accounts.creatives.dealAssociations.remove
# --association shape: {accountId?: string, creativeId?: string, dealsId?: string}
export def "v2beta1-accounts-creatives-deal-associations-remove adexchangebuyer2accountscreativesdealAssociationsremove" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --association: record # The association between a creative and a deal. — shape: {accountId?: string, creativeId?: string, dealsId?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId)/dealAssociations:remove" $qp)
  let body = {association: $association} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stops watching a creative. Will stop push notifications being sent to the topics when the creative changes status.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}:stopWatching
# operationId: adexchangebuyer2.accounts.creatives.stopWatching
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativesstopWatching" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId):stopWatching" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Watches a creative. Will result in push notifications being sent to the topic when the creative changes status.
#
# POST /v2beta1/accounts/{accountId}/creatives/{creativeId}:watch
# operationId: adexchangebuyer2.accounts.creatives.watch
export def "v2beta1-accounts-creatives adexchangebuyer2accountscreativeswatch" [
  accountId: string
  creativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --topic: string # The Pub/Sub topic to publish notifications to. This topic must already exist and must give permission to ad-exchange-buyside-reports@google.com to write to the topic. This should be the full resource name in "projects/{project_id}/topics/{topic_id}" format.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/creatives/($creativeId):watch" $qp)
  let body = {topic: $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List finalized proposals, regardless if a proposal is being renegotiated. A filter expression (PQL query) may be specified to filter the results. The notes will not be returned.
#
# GET /v2beta1/accounts/{accountId}/finalizedProposals
# operationId: adexchangebuyer2.accounts.finalizedProposals.list
export def "v2beta1-accounts-finalized-proposals adexchangebuyer2accountsfinalizedProposalslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # An optional PQL filter query used to query for proposals. Nested repeated fields, such as proposal.deals.targetingCriterion, cannot be filtered.
  --filterSyntax: string@filterSyntax-completer # Syntax the filter is written in. Current implementation defaults to PQL but in the future it will be LIST_FILTER.
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # The page token as returned from ListProposalsResponse.
]: nothing -> record<nextPageToken: string, proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, deals: list, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: list, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record, sellerContacts: list, termsAndConditions: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filterSyntax" $filterSyntax "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/finalizedProposals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update given deals to pause serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to true for all listed deals in the request. Currently, this method only applies to PG and PD deals. For PA deals, call accounts.proposals.pause endpoint. It is a no-op to pause already-paused deals. It is an error to call PauseProposalDeals for deals which are not part of the proposal of proposal_id or which are not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/finalizedProposals/{proposalId}:pause
# operationId: adexchangebuyer2.accounts.finalizedProposals.pause
export def "v2beta1-accounts-finalized-proposals adexchangebuyer2accountsfinalizedProposalspause" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --externalDealIds: list # The external_deal_id's of the deals to be paused. If empty, all the deals in the proposal will be paused.
  --reason: string # The reason why the deals are being paused. This human readable message will be displayed in the seller's UI. (Max length: 1000 unicode code units.)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/finalizedProposals/($proposalId):pause" $qp)
  let body = {externalDealIds: $externalDealIds, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update given deals to resume serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to false for all listed deals in the request. Currently, this method only applies to PG and PD deals. For PA deals, call accounts.proposals.resume endpoint. It is a no-op to resume running deals or deals paused by the other party. It is an error to call ResumeProposalDeals for deals which are not part of the proposal of proposal_id or which are not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/finalizedProposals/{proposalId}:resume
# operationId: adexchangebuyer2.accounts.finalizedProposals.resume
export def "v2beta1-accounts-finalized-proposals adexchangebuyer2accountsfinalizedProposalsresume" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --externalDealIds: list # The external_deal_id's of the deals to resume. If empty, all the deals in the proposal will be resumed.
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/finalizedProposals/($proposalId):resume" $qp)
  let body = {externalDealIds: $externalDealIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all products visible to the buyer (optionally filtered by the specified PQL query).
#
# GET /v2beta1/accounts/{accountId}/products
# operationId: adexchangebuyer2.accounts.products.list
export def "v2beta1-accounts-products adexchangebuyer2accountsproductslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # An optional PQL query used to query for products. See https://developers.google.com/ad-manager/docs/pqlreference for documentation about PQL and examples. Nested repeated fields, such as product.targetingCriterion.inclusions, cannot be filtered.
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # The page token as returned from ListProductsResponse.
]: nothing -> record<nextPageToken: string, products: table<availableEndTime: string, availableStartTime: string, createTime: string, creatorContacts: list, displayName: string, hasCreatorSignedOff: bool, productId: string, productRevision: string, publisherProfileId: string, seller: record, syndicationProduct: string, targetingCriterion: list, terms: record, updateTime: string, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the requested product by ID.
#
# GET /v2beta1/accounts/{accountId}/products/{productId}
# operationId: adexchangebuyer2.accounts.products.get
export def "v2beta1-accounts-products adexchangebuyer2accountsproductsget" [
  accountId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<availableEndTime: string, availableStartTime: string, createTime: string, creatorContacts: table<email: string, name: string>, displayName: string, hasCreatorSignedOff: bool, productId: string, productRevision: string, publisherProfileId: string, seller: record<accountId: string, subAccountId: string>, syndicationProduct: string, targetingCriterion: table<exclusions: list, inclusions: list, key: string>, terms: record<brandingType: string, description: string, estimatedGrossSpend: record<amount: record, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricesPerBuyer: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, sellerTimeZone: string>, updateTime: string, webPropertyCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/products/($productId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List proposals. A filter expression (PQL query) may be specified to filter the results. To retrieve all finalized proposals, regardless if a proposal is being renegotiated, see the FinalizedProposals resource. Note that Bidder/ChildSeat relationships differ from the usual behavior. A Bidder account can only see its child seats' proposals by specifying the ChildSeat's accountId in the request path.
#
# GET /v2beta1/accounts/{accountId}/proposals
# operationId: adexchangebuyer2.accounts.proposals.list
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # An optional PQL filter query used to query for proposals. Nested repeated fields, such as proposal.deals.targetingCriterion, cannot be filtered.
  --filterSyntax: string@filterSyntax-completer # Syntax the filter is written in. Current implementation defaults to PQL but in the future it will be LIST_FILTER.
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # The page token as returned from ListProposalsResponse.
]: nothing -> record<nextPageToken: string, proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, deals: list, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: list, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record, sellerContacts: list, termsAndConditions: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filterSyntax" $filterSyntax "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalscreate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --billedBuyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyerContacts: list # Contact information for the buyer. — item shape: {email?: string, name?: string}
  --buyerPrivateData: record # Buyers are allowed to store certain types of private data in a proposal/deal. — shape: {referenceId?: string}
  --deals: list # The deals associated with this proposal. For Private Auction proposals (whose deals have NonGuaranteedAuctionTerms), there will only be one deal. — item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
  --displayName: string # The name for the proposal.
  --seller: record # Represents a seller of inventory. Each seller is identified by a unique Ad Manager account ID. — shape: {accountId?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals" $qp)
  let body = {billedBuyer: $billedBuyer, buyer: $buyer, buyerContacts: $buyerContacts, buyerPrivateData: $buyerPrivateData, deals: $deals, displayName: $displayName, seller: $seller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a proposal given its ID. The proposal is returned at its head revision.
#
# GET /v2beta1/accounts/{accountId}/proposals/{proposalId}
# operationId: adexchangebuyer2.accounts.proposals.get
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalsget" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalsupdate" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --billedBuyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyer: record # Represents a buyer of inventory. Each buyer is identified by a unique Authorized Buyers account ID. — shape: {accountId?: string}
  --buyerContacts: list # Contact information for the buyer. — item shape: {email?: string, name?: string}
  --buyerPrivateData: record # Buyers are allowed to store certain types of private data in a proposal/deal. — shape: {referenceId?: string}
  --deals: list # The deals associated with this proposal. For Private Auction proposals (whose deals have NonGuaranteedAuctionTerms), there will only be one deal. — item shape: {availableEndTime?: string, availableStartTime?: string, buyerPrivateData?: record, createProductId?: string, createProductRevision?: string, creativeRestrictions?: record, dealServingMetadata?: record, dealTerms?: record, deliveryControl?: record, description?: string, displayName?: string, syndicationProduct?: "SYNDICATION_PRODUCT_UNSPECIFIED"|"CONTENT"|"MOBILE"|"VIDEO"|"GAMES", targeting?: record, targetingCriterion?: list, webPropertyCode?: string}
  --displayName: string # The name for the proposal.
  --seller: record # Represents a seller of inventory. Each seller is identified by a unique Ad Manager account ID. — shape: {accountId?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId)" $qp)
  let body = {billedBuyer: $billedBuyer, buyer: $buyer, buyerContacts: $buyerContacts, buyerPrivateData: $buyerPrivateData, deals: $deals, displayName: $displayName, seller: $seller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark the proposal as accepted at the given revision number. If the number does not match the server's revision number an `ABORTED` error message will be returned. This call updates the proposal_state from `PROPOSED` to `BUYER_ACCEPTED`, or from `SELLER_ACCEPTED` to `FINALIZED`. Upon calling this endpoint, the buyer implicitly agrees to the terms and conditions optionally set within the proposal by the publisher.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:accept
# operationId: adexchangebuyer2.accounts.proposals.accept
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalsaccept" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --proposalRevision: string # The last known client revision number of the proposal. (format: int64)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):accept" $qp)
  let body = {proposalRevision: $proposalRevision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new note and attach it to the proposal. The note is assigned a unique ID by the server. The proposal revision number will not increase when associated with a new note.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:addNote
# operationId: adexchangebuyer2.accounts.proposals.addNote
# --note shape: {note?: string}
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalsaddNote" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --note: record # A proposal may be associated to several notes. — shape: {note?: string}
]: any -> record<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):addNote" $qp)
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an ongoing negotiation on a proposal. This does not cancel or end serving for the deals if the proposal has been finalized, but only cancels a negotiation unilaterally.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:cancelNegotiation
# operationId: adexchangebuyer2.accounts.proposals.cancelNegotiation
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalscancelNegotiation" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):cancelNegotiation" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# You can opt-in to manually update proposals to indicate that setup is complete. By default, proposal setup is automatically completed after their deals are finalized. Contact your Technical Account Manager to opt in. Buyers can call this method when the proposal has been finalized, and all the required creatives have been uploaded using the Creatives API. This call updates the `is_setup_completed` field on the deals in the proposal, and notifies the seller. The server then advances the revision number of the most recent proposal. To mark an individual deal as ready to serve, call `buyers.finalizedDeals.setReadyToServe` in the Marketplace API.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:completeSetup
# operationId: adexchangebuyer2.accounts.proposals.completeSetup
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalscompleteSetup" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):completeSetup" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the given proposal to pause serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to true for all deals in the proposal. It is a no-op to pause an already-paused proposal. It is an error to call PauseProposal for a proposal that is not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:pause
# operationId: adexchangebuyer2.accounts.proposals.pause
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalspause" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --reason: string # The reason why the proposal is being paused. This human readable message will be displayed in the seller's UI. (Max length: 1000 unicode code units.)
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):pause" $qp)
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the given proposal to resume serving. This method will set the `DealServingMetadata.DealPauseStatus.has_buyer_paused` bit to false for all deals in the proposal. Note that if the `has_seller_paused` bit is also set, serving will not resume until the seller also resumes. It is a no-op to resume an already-running proposal. It is an error to call ResumeProposal for a proposal that is not finalized or renegotiating.
#
# POST /v2beta1/accounts/{accountId}/proposals/{proposalId}:resume
# operationId: adexchangebuyer2.accounts.proposals.resume
export def "v2beta1-accounts-proposals adexchangebuyer2accountsproposalsresume" [
  accountId: string
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string>, deals: table<availableEndTime: string, availableStartTime: string, buyerPrivateData: record, createProductId: string, createProductRevision: string, createTime: string, creativePreApprovalPolicy: string, creativeRestrictions: record, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, dealTerms: record, deliveryControl: record, description: string, displayName: string, externalDealId: string, isSetupComplete: bool, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, syndicationProduct: string, targeting: record, targetingCriterion: list, updateTime: string, webPropertyCode: string>, displayName: string, isRenegotiating: bool, isSetupComplete: bool, lastUpdaterOrCommentorRole: string, notes: table<createTime: string, creatorRole: string, note: string, noteId: string, proposalRevision: string>, originatorRole: string, privateAuctionId: string, proposalId: string, proposalRevision: string, proposalState: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>, termsAndConditions: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/proposals/($proposalId):resume" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all publisher profiles visible to the buyer
#
# GET /v2beta1/accounts/{accountId}/publisherProfiles
# operationId: adexchangebuyer2.accounts.publisherProfiles.list
export def "v2beta1-accounts-publisher-profiles adexchangebuyer2accountspublisherProfileslist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Specify the number of results to include per page.
  --pageToken: string # The page token as return from ListPublisherProfilesResponse.
]: nothing -> record<nextPageToken: string, publisherProfiles: table<audienceDescription: string, buyerPitchStatement: string, directDealsContact: string, displayName: string, domains: list, googlePlusUrl: string, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: list, overview: string, programmaticDealsContact: string, publisherProfileId: string, rateCardInfoUrl: string, samplePageUrl: string, seller: record, topHeadlines: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/publisherProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the requested publisher profile by id.
#
# GET /v2beta1/accounts/{accountId}/publisherProfiles/{publisherProfileId}
# operationId: adexchangebuyer2.accounts.publisherProfiles.get
export def "v2beta1-accounts-publisher-profiles adexchangebuyer2accountspublisherProfilesget" [
  accountId: string
  publisherProfileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<audienceDescription: string, buyerPitchStatement: string, directDealsContact: string, displayName: string, domains: list<string>, googlePlusUrl: string, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: table<appStore: string, externalAppId: string, name: string>, overview: string, programmaticDealsContact: string, publisherProfileId: string, rateCardInfoUrl: string, samplePageUrl: string, seller: record<accountId: string, subAccountId: string>, topHeadlines: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/accounts/($accountId)/publisherProfiles/($publisherProfileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all metrics that are measured in terms of number of bids.
#
# GET /v2beta1/{filterSetName}/bidMetrics
# operationId: adexchangebuyer2.bidders.filterSets.bidMetrics.list
export def "v2beta1-bid-metrics adexchangebuyer2biddersfilterSetsbidMetricslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidMetricsResponse.nextPageToken returned from the previous call to the bidMetrics.list method.
]: nothing -> record<bidMetricsRows: table<bids: record, bidsInAuction: record, billedImpressions: record, impressionsWon: record, measurableImpressions: record, reachedQueries: record, rowDimensions: record, viewableImpressions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/bidMetrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all errors that occurred in bid responses, with the number of bid responses affected for each reason.
#
# GET /v2beta1/{filterSetName}/bidResponseErrors
# operationId: adexchangebuyer2.bidders.filterSets.bidResponseErrors.list
export def "v2beta1-bid-response-errors adexchangebuyer2biddersfilterSetsbidResponseErrorslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidResponseErrorsResponse.nextPageToken returned from the previous call to the bidResponseErrors.list method.
]: nothing -> record<calloutStatusRows: table<calloutStatusId: int, impressionCount: record, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/bidResponseErrors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all reasons for which bid responses were considered to have no applicable bids, with the number of bid responses affected for each reason.
#
# GET /v2beta1/{filterSetName}/bidResponsesWithoutBids
# operationId: adexchangebuyer2.bidders.filterSets.bidResponsesWithoutBids.list
export def "v2beta1-bid-responses-without-bids adexchangebuyer2biddersfilterSetsbidResponsesWithoutBidslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListBidResponsesWithoutBidsResponse.nextPageToken returned from the previous call to the bidResponsesWithoutBids.list method.
]: nothing -> record<bidResponseWithoutBidsStatusRows: table<impressionCount: record, rowDimensions: record, status: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/bidResponsesWithoutBids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all reasons that caused a bid request not to be sent for an impression, with the number of bid requests not sent for each reason.
#
# GET /v2beta1/{filterSetName}/filteredBidRequests
# operationId: adexchangebuyer2.bidders.filterSets.filteredBidRequests.list
export def "v2beta1-filtered-bid-requests adexchangebuyer2biddersfilterSetsfilteredBidRequestslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilteredBidRequestsResponse.nextPageToken returned from the previous call to the filteredBidRequests.list method.
]: nothing -> record<calloutStatusRows: table<calloutStatusId: int, impressionCount: record, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/filteredBidRequests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all reasons for which bids were filtered, with the number of bids filtered for each reason.
#
# GET /v2beta1/{filterSetName}/filteredBids
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.list
export def "v2beta1-filtered-bids adexchangebuyer2biddersfilterSetsfilteredBidslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilteredBidsResponse.nextPageToken returned from the previous call to the filteredBids.list method.
]: nothing -> record<creativeStatusRows: table<bidCount: record, creativeStatusId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/filteredBids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all creatives associated with a specific reason for which bids were filtered, with the number of bids filtered for each creative.
#
# GET /v2beta1/{filterSetName}/filteredBids/{creativeStatusId}/creatives
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.creatives.list
export def "v2beta1-filtered-bids-creatives adexchangebuyer2biddersfilterSetsfilteredBidscreativeslist" [
  filterSetName: string
  creativeStatusId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativeStatusBreakdownByCreativeResponse.nextPageToken returned from the previous call to the filteredBids.creatives.list method.
]: nothing -> record<filteredBidCreativeRows: table<bidCount: record, creativeId: string, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/filteredBids/($creativeStatusId)/creatives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all details associated with a specific reason for which bids were filtered, with the number of bids filtered for each detail.
#
# GET /v2beta1/{filterSetName}/filteredBids/{creativeStatusId}/details
# operationId: adexchangebuyer2.bidders.filterSets.filteredBids.details.list
export def "v2beta1-filtered-bids-details adexchangebuyer2biddersfilterSetsfilteredBidsdetailslist" [
  filterSetName: string
  creativeStatusId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListCreativeStatusBreakdownByDetailResponse.nextPageToken returned from the previous call to the filteredBids.details.list method.
]: nothing -> record<detailType: string, filteredBidDetailRows: table<bidCount: record, detail: string, detailId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/filteredBids/($creativeStatusId)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all metrics that are measured in terms of number of impressions.
#
# GET /v2beta1/{filterSetName}/impressionMetrics
# operationId: adexchangebuyer2.bidders.filterSets.impressionMetrics.list
export def "v2beta1-impression-metrics adexchangebuyer2biddersfilterSetsimpressionMetricslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListImpressionMetricsResponse.nextPageToken returned from the previous call to the impressionMetrics.list method.
]: nothing -> record<impressionMetricsRows: table<availableImpressions: record, bidRequests: record, inventoryMatches: record, responsesWithBids: record, rowDimensions: record, successfulResponses: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/impressionMetrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all reasons for which bids lost in the auction, with the number of bids that lost for each reason.
#
# GET /v2beta1/{filterSetName}/losingBids
# operationId: adexchangebuyer2.bidders.filterSets.losingBids.list
export def "v2beta1-losing-bids adexchangebuyer2biddersfilterSetslosingBidslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListLosingBidsResponse.nextPageToken returned from the previous call to the losingBids.list method.
]: nothing -> record<creativeStatusRows: table<bidCount: record, creativeStatusId: int, rowDimensions: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/losingBids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all reasons for which winning bids were not billable, with the number of bids not billed for each reason.
#
# GET /v2beta1/{filterSetName}/nonBillableWinningBids
# operationId: adexchangebuyer2.bidders.filterSets.nonBillableWinningBids.list
export def "v2beta1-non-billable-winning-bids adexchangebuyer2biddersfilterSetsnonBillableWinningBidslist" [
  filterSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListNonBillableWinningBidsResponse.nextPageToken returned from the previous call to the nonBillableWinningBids.list method.
]: nothing -> record<nextPageToken: string, nonBillableWinningBidStatusRows: table<bidCount: record, rowDimensions: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($filterSetName)/nonBillableWinningBids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the requested filter set from the account with the given account ID.
#
# DELETE /v2beta1/{name}
# operationId: adexchangebuyer2.bidders.filterSets.delete
export def "v2beta1 adexchangebuyer2biddersfilterSetsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the requested filter set for the account with the given account ID.
#
# GET /v2beta1/{name}
# operationId: adexchangebuyer2.bidders.filterSets.get
export def "v2beta1 adexchangebuyer2biddersfilterSetsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<absoluteDateRange: record<endDate: record<day: int, month: int, year: int>, startDate: record<day: int, month: int, year: int>>, breakdownDimensions: list<string>, creativeId: string, dealId: string, environment: string, format: string, formats: list<string>, name: string, platforms: list<string>, publisherIdentifiers: list<string>, realtimeTimeRange: record<startTimestamp: string>, relativeDateRange: record<durationDays: int, offsetDays: int>, sellerNetworkIds: list<int>, timeSeriesGranularity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all filter sets for the account with the given account ID.
#
# GET /v2beta1/{ownerName}/filterSets
# operationId: adexchangebuyer2.bidders.filterSets.list
export def "v2beta1-filter-sets adexchangebuyer2biddersfilterSetslist" [
  ownerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will pick an appropriate default.
  --pageToken: string # A token identifying a page of results the server should return. Typically, this is the value of ListFilterSetsResponse.nextPageToken returned from the previous call to the accounts.filterSets.list method.
]: nothing -> record<filterSets: table<absoluteDateRange: record, breakdownDimensions: list, creativeId: string, dealId: string, environment: string, format: string, formats: list, name: string, platforms: list, publisherIdentifiers: list, realtimeTimeRange: record, relativeDateRange: record, sellerNetworkIds: list, timeSeriesGranularity: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($ownerName)/filterSets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates the specified filter set for the account with the given account ID.
#
# POST /v2beta1/{ownerName}/filterSets
# operationId: adexchangebuyer2.bidders.filterSets.create
# --absoluteDateRange shape: {endDate?: record, startDate?: record}
# --realtimeTimeRange shape: {startTimestamp?: string}
# --relativeDateRange shape: {durationDays?: int, offsetDays?: int}
export def "v2beta1-filter-sets adexchangebuyer2biddersfilterSetscreate" [
  ownerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --isTransient: oneof<nothing, bool> # Whether the filter set is transient, or should be persisted indefinitely. By default, filter sets are not transient. If transient, it will be available for at least 1 hour after creation.
  --absoluteDateRange: record # An absolute date range, specified by its start date and end date. The supported range of dates begins 30 days before today and ends today. Validity checked upon filter set creation. If a filter set with an absolute date range is run at a later date more than 30 days after start_date, it will fail. — shape: {endDate?: record, startDate?: record}
  --breakdownDimensions: list # The set of dimensions along which to break down the response; may be empty. If multiple dimensions are requested, the breakdown is along the Cartesian product of the requested dimensions.
  --creativeId: string # The ID of the creative on which to filter; optional. This field may be set only for a filter set that accesses account-level troubleshooting data, for example, one whose name matches the `bidders/*/accounts/*/filterSets/*` pattern.
  --dealId: string # The ID of the deal on which to filter; optional. This field may be set only for a filter set that accesses account-level troubleshooting data, for example, one whose name matches the `bidders/*/accounts/*/filterSets/*` pattern. (format: int64)
  --environment: string@environment-completer # The environment on which to filter; optional.
  --format: string@format-completer # Creative format bidded on or allowed to bid on, can be empty.
  --formats: list # Creative formats bidded on or allowed to bid on, can be empty. Although this field is a list, it can only be populated with a single item. A HTTP 400 bad request error will be returned in the response if you specify multiple items.
  --name: string # A user-defined name of the filter set. Filter set names must be unique globally and match one of the patterns: - `bidders/*/filterSets/*` (for accessing bidder-level troubleshooting data) - `bidders/*/accounts/*/filterSets/*` (for accessing account-level troubleshooting data) This field is required in create operations.
  --platforms: list # The list of platforms on which to filter; may be empty. The filters represented by multiple platforms are ORed together (for example, if non-empty, results must match any one of the platforms).
  --publisherIdentifiers: list # For Open Bidding partners only. The list of publisher identifiers on which to filter; may be empty. The filters represented by multiple publisher identifiers are ORed together.
  --realtimeTimeRange: record # An open-ended realtime time range specified by the start timestamp. For filter sets that specify a realtime time range RTB metrics continue to be aggregated throughout the lifetime of the filter set. — shape: {startTimestamp?: string}
  --relativeDateRange: record # A relative date range, specified by an offset and a duration. The supported range of dates begins 30 days before today and ends today, for example, the limits for these values are: offset_days >= 0 duration_days >= 1 offset_days + duration_days <= 30 — shape: {durationDays?: int, offsetDays?: int}
  --sellerNetworkIds: list # For Authorized Buyers only. The list of IDs of the seller (publisher) networks on which to filter; may be empty. The filters represented by multiple seller network IDs are ORed together (for example, if non-empty, results must match any one of the publisher networks). See [seller-network-ids](https://developers.google.com/authorized-buyers/rtb/downloads/seller-network-ids) file for the set of existing seller network IDs.
  --timeSeriesGranularity: string@timeSeriesGranularity-completer # The granularity of time intervals if a time series breakdown is preferred; optional.
]: any -> record<absoluteDateRange: record<endDate: record<day: int, month: int, year: int>, startDate: record<day: int, month: int, year: int>>, breakdownDimensions: list<string>, creativeId: string, dealId: string, environment: string, format: string, formats: list<string>, name: string, platforms: list<string>, publisherIdentifiers: list<string>, realtimeTimeRange: record<startTimestamp: string>, relativeDateRange: record<durationDays: int, offsetDays: int>, sellerNetworkIds: list<int>, timeSeriesGranularity: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "isTransient" $isTransient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2beta1/($ownerName)/filterSets" $qp)
  let body = {absoluteDateRange: $absoluteDateRange, breakdownDimensions: $breakdownDimensions, creativeId: $creativeId, dealId: $dealId, environment: $environment, format: $format, formats: $formats, name: $name, platforms: $platforms, publisherIdentifiers: $publisherIdentifiers, realtimeTimeRange: $realtimeTimeRange, relativeDateRange: $relativeDateRange, sellerNetworkIds: $sellerNetworkIds, timeSeriesGranularity: $timeSeriesGranularity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
