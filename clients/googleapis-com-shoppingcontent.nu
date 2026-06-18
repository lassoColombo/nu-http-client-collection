# Auto-generated client for Content API for Shopping vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/shoppingcontent/v2/openapi.json
# Auth: --token flag or $env.CONTENT_API_FOR_SHOPPING_TOKEN

const BASE_URL = "https://shoppingcontent.googleapis.com/content/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTENT_API_FOR_SHOPPING_TOKEN | default "" }
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://shoppingcontent.googleapis.com/content/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def order-by-completer [] { ["RETURN_CREATION_TIME_ASC" "RETURN_CREATION_TIME_DESC"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-authinfo get" } } | get name | first)
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

# Returns information about the authenticated user.
#
# GET /accounts/authinfo
# operationId: content.accounts.authinfo
export def "accounts-authinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<accountIdentifiers: table<aggregatorId: string, merchantId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts/authinfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves, inserts, updates, and deletes multiple Merchant Center (sub-)accounts in a single request.
#
# POST /accounts/batch
# operationId: content.accounts.custombatch
# --entries item shape: {account?: record, accountId?: string, batchId?: int, force?: bool, labelIds?: list<string>, linkRequest?: record, merchantId?: string, method?: string, overwrite?: bool}
export def "accounts-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {account?: record, accountId?: string, batchId?: int, force?: bool, labelIds?: list<string>, linkRequest?: record, merchantId?: string, method?: string, overwrite?: bool}
]: any -> record<entries: table<account: record, batchId: int, errors: record, kind: string, linkStatus: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves multiple Merchant Center account statuses in a single request.
#
# POST /accountstatuses/batch
# operationId: content.accountstatuses.custombatch
# --entries item shape: {accountId?: string, batchId?: int, destinations?: list<string>, merchantId?: string, method?: string}
export def "accountstatuses-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, destinations?: list<string>, merchantId?: string, method?: string}
]: any -> record<entries: table<accountStatus: record, batchId: int, errors: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accountstatuses/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves and updates tax settings of multiple accounts in a single request.
#
# POST /accounttax/batch
# operationId: content.accounttax.custombatch
# --entries item shape: {accountId?: string, accountTax?: record, batchId?: int, merchantId?: string, method?: string}
export def "accounttax-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, accountTax?: record, batchId?: int, merchantId?: string, method?: string}
]: any -> record<entries: table<accountTax: record, batchId: int, errors: record, kind: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounttax/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes, fetches, gets, inserts and updates multiple datafeeds in a single request.
#
# POST /datafeeds/batch
# operationId: content.datafeeds.custombatch
# --entries item shape: {batchId?: int, datafeed?: record, datafeedId?: string, merchantId?: string, method?: string}
export def "datafeeds-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, datafeed?: record, datafeedId?: string, merchantId?: string, method?: string}
]: any -> record<entries: table<batchId: int, datafeed: record, errors: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datafeeds/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets multiple Merchant Center datafeed statuses in a single request.
#
# POST /datafeedstatuses/batch
# operationId: content.datafeedstatuses.custombatch
# --entries item shape: {batchId?: int, country?: string, datafeedId?: string, language?: string, merchantId?: string, method?: string}
export def "datafeedstatuses-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, country?: string, datafeedId?: string, language?: string, merchantId?: string, method?: string}
]: any -> record<entries: table<batchId: int, datafeedStatus: record, errors: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datafeedstatuses/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves and/or updates the LIA settings of multiple accounts in a single request.
#
# POST /liasettings/batch
# operationId: content.liasettings.custombatch
# --entries item shape: {accountId?: string, batchId?: int, contactEmail?: string, contactName?: string, country?: string, gmbEmail?: string, liaSettings?: record, merchantId?: string, method?: string, posDataProviderId?: string, posExternalAccountId?: string}
export def "liasettings-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, contactEmail?: string, contactName?: string, country?: string, gmbEmail?: string, liaSettings?: record, merchantId?: string, method?: string, posDataProviderId?: string, posExternalAccountId?: string}
]: any -> record<entries: table<batchId: int, errors: record, gmbAccounts: record, kind: string, liaSettings: record, posDataProviders: list>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/liasettings/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the list of POS data providers that have active settings for the all eiligible countries.
#
# GET /liasettings/posdataproviders
# operationId: content.liasettings.listposdataproviders
export def "liasettings-posdataproviders get-listposdataproviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string, posDataProviders: table<country: string, posDataProviders: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/liasettings/posdataproviders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves or modifies multiple orders in a single request.
#
# POST /orders/batch
# operationId: content.orders.custombatch
# --entries item shape: {batchId?: int, cancel?: record, cancelLineItem?: record, inStoreRefundLineItem?: record, merchantId?: string, merchantOrderId?: string, method?: string, operationId?: string, orderId?: string, refund?: record, rejectReturnLineItem?: record, returnLineItem?: record, returnRefundLineItem?: record, setLineItemMetadata?: record, shipLineItems?: record, updateLineItemShippingDetails?: record, updateShipment?: record}
export def "orders-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, cancel?: record, cancelLineItem?: record, inStoreRefundLineItem?: record, merchantId?: string, merchantOrderId?: string, method?: string, operationId?: string, orderId?: string, refund?: record, rejectReturnLineItem?: record, returnLineItem?: record, returnRefundLineItem?: record, setLineItemMetadata?: record, shipLineItems?: record, updateLineItemShippingDetails?: record, updateShipment?: record}
]: any -> record<entries: table<batchId: int, errors: record, executionStatus: string, kind: string, order: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Batches multiple POS-related calls in a single request.
#
# POST /pos/batch
# operationId: content.pos.custombatch
# --entries item shape: {batchId?: int, inventory?: record, merchantId?: string, method?: string, sale?: record, store?: record, storeCode?: string, targetMerchantId?: string}
export def "pos-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, inventory?: record, merchantId?: string, method?: string, sale?: record, store?: record, storeCode?: string, targetMerchantId?: string}
]: any -> record<entries: table<batchId: int, errors: record, inventory: record, kind: string, sale: record, store: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pos/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves, inserts, and deletes multiple products in a single request.
#
# POST /products/batch
# operationId: content.products.custombatch
# --entries item shape: {batchId?: int, merchantId?: string, method?: string, product?: record, productId?: string}
export def "products-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, merchantId?: string, method?: string, product?: record, productId?: string}
]: any -> record<entries: table<batchId: int, errors: record, kind: string, product: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the statuses of multiple products in a single request.
#
# POST /productstatuses/batch
# operationId: content.productstatuses.custombatch
# --entries item shape: {batchId?: int, destinations?: list<string>, includeAttributes?: bool, merchantId?: string, method?: string, productId?: string}
export def "productstatuses-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the results of this request. The default value is false.
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, destinations?: list<string>, includeAttributes?: bool, merchantId?: string, method?: string, productId?: string}
]: any -> record<entries: table<batchId: int, errors: record, kind: string, productStatus: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/productstatuses/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves and updates the shipping settings of multiple accounts in a single request.
#
# POST /shippingsettings/batch
# operationId: content.shippingsettings.custombatch
# --entries item shape: {accountId?: string, batchId?: int, merchantId?: string, method?: string, shippingSettings?: record}
export def "shippingsettings-batch create-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, merchantId?: string, method?: string, shippingSettings?: record}
]: any -> record<entries: table<batchId: int, errors: record, kind: string, shippingSettings: record>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shippingsettings/batch" $qp)
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accounts
# operationId: content.accounts.list
export def "accounts list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of accounts to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<adultContent: bool, adwordsLinks: list, businessInformation: record, googleMyBusinessLink: record, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: list, websiteUrl: string, youtubeChannelLinks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Merchant Center sub-account.
#
# POST /{merchantId}/accounts
# operationId: content.accounts.insert
# --adwordsLinks item shape: {adwordsId?: string, status?: string}
# --businessInformation shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
# --googleMyBusinessLink shape: {gmbEmail?: string, status?: string}
# --users item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
# --youtubeChannelLinks item shape: {channelId?: string, status?: string}
export def "accounts create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --adwords-links: list # List of linked AdWords accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the AdWords interface or through the AdWords API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adwordsId?: string, status?: string}
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
  --google-my-business-link: record # shape: {gmbEmail?: string, status?: string}
  --id: string # Required for update. Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`"
  --name: string # Required. Display name for the account.
  --reviews-url: string # [DEPRECATED] This field is never returned and will be ignored if provided.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # List of linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/accounts") $qp)
  let req_body = {"adultContent": $adult_content, "adwordsLinks": $adwords_links, "businessInformation": $business_information, "googleMyBusinessLink": $google_my_business_link, "id": $id, "kind": $kind, "name": $name, "reviewsUrl": $reviews_url, "sellerId": $seller_id, "users": $users, "websiteUrl": $website_url, "youtubeChannelLinks": $youtube_channel_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a Merchant Center sub-account.
#
# DELETE /{merchantId}/accounts/{accountId}
# operationId: content.accounts.delete
export def "accounts delete" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --force: oneof<nothing, bool> # Flag to delete sub-accounts with products. The default value is false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Merchant Center account.
#
# GET /{merchantId}/accounts/{accountId}
# operationId: content.accounts.get
export def "accounts get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Merchant Center account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/accounts/{accountId}
# operationId: content.accounts.update
# --adwordsLinks item shape: {adwordsId?: string, status?: string}
# --businessInformation shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
# --googleMyBusinessLink shape: {gmbEmail?: string, status?: string}
# --users item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
# --youtubeChannelLinks item shape: {channelId?: string, status?: string}
export def "accounts update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --adwords-links: list # List of linked AdWords accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the AdWords interface or through the AdWords API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adwordsId?: string, status?: string}
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
  --google-my-business-link: record # shape: {gmbEmail?: string, status?: string}
  --id: string # Required for update. Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`"
  --name: string # Required. Display name for the account.
  --reviews-url: string # [DEPRECATED] This field is never returned and will be ignored if provided.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # List of linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounts/{account_id}") $qp)
  let req_body = {"adultContent": $adult_content, "adwordsLinks": $adwords_links, "businessInformation": $business_information, "googleMyBusinessLink": $google_my_business_link, "id": $id, "kind": $kind, "name": $name, "reviewsUrl": $reviews_url, "sellerId": $seller_id, "users": $users, "websiteUrl": $website_url, "youtubeChannelLinks": $youtube_channel_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Claims the website of a Merchant Center sub-account.
#
# POST /{merchantId}/accounts/{accountId}/claimwebsite
# operationId: content.accounts.claimwebsite
export def "accounts-claimwebsite create" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --overwrite: oneof<nothing, bool> # Only available to selected merchants. When set to `True`, this flag removes any existing claim on the requested website by another account and replaces it with a claim from this account.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "overwrite" $overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounts/{account_id}/claimwebsite") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs an action on a link between two Merchant Center accounts, namely accountId and linkedAccountId.
#
# POST /{merchantId}/accounts/{accountId}/link
# operationId: content.accounts.link
export def "accounts-link create" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --action: string # Action to perform for this link. The `"request"` action is only available to select merchants. Acceptable values are: - "`approve`" - "`remove`" - "`request`"
  --link-type: string # Type of the link between the two accounts. Acceptable values are: - "`channelPartner`" - "`eCommercePlatform`"
  --linked-account-id: string # The ID of the linked account.
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounts/{account_id}/link") $qp)
  let req_body = {"action": $action, "linkType": $link_type, "linkedAccountId": $linked_account_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the statuses of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accountstatuses
# operationId: content.accountstatuses.list
export def "accountstatuses list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
  --max-results: int # The maximum number of account statuses to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<accountId: string, accountLevelIssues: list, dataQualityIssues: list, kind: string, products: list, websiteClaimed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "destinations" $destinations "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/accountstatuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the status of a Merchant Center account. No itemLevelIssues are returned for multi-client accounts.
#
# GET /{merchantId}/accountstatuses/{accountId}
# operationId: content.accountstatuses.get
export def "accountstatuses get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
]: nothing -> record<accountId: string, accountLevelIssues: table<country: string, destination: string, detail: string, documentation: string, id: string, severity: string, title: string>, dataQualityIssues: table<country: string, destination: string, detail: string, displayedValue: string, exampleItems: list, id: string, lastChecked: string, location: string, numItems: int, severity: string, submittedValue: string>, kind: string, products: table<channel: string, country: string, destination: string, itemLevelIssues: list, statistics: record>, websiteClaimed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "destinations" $destinations "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accountstatuses/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the tax settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accounttax
# operationId: content.accounttax.list
export def "accounttax list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of tax settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<accountId: string, kind: string, rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/accounttax") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the tax settings of the account.
#
# GET /{merchantId}/accounttax/{accountId}
# operationId: content.accounttax.get
export def "accounttax get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounttax/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the tax settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/accounttax/{accountId}
# operationId: content.accounttax.update
# --rules item shape: {country?: string, locationId?: string, ratePercent?: string, shippingTaxed?: bool, useGlobalRate?: bool}
export def "accounttax update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --body-account-id: string # Required. The ID of the account to which these account tax settings belong. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "content#accountTax".
  --rules: list # Tax rules. Updating the tax rules will enable US taxes (not reversible). Defining no rules is equivalent to not charging tax at all. — item shape: {country?: string, locationId?: string, ratePercent?: string, shippingTaxed?: bool, useGlobalRate?: bool}
]: any -> record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/accounttax/{account_id}") $qp)
  let req_body = {"accountId": $body_account_id, "kind": $kind, "rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the configurations for datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeeds
# operationId: content.datafeeds.list
export def "datafeeds list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record, fileName: string, format: record, id: string, intendedDestinations: list, kind: string, name: string, targetCountry: string, targets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/datafeeds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Registers a datafeed configuration with your Merchant Center account.
#
# POST /{merchantId}/datafeeds
# operationId: content.datafeeds.insert
# --fetchSchedule shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
# --format shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
# --targets item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
export def "datafeeds create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-language: string # [DEPRECATED] Please use targets[].language instead. The two-letter ISO 639-1 language of the items in the feed. Must be a valid language for `targetCountry`.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --intended-destinations: list<string> # [DEPRECATED] Please use targets[].includedDestinations instead. The list of intended destinations (corresponds to checked check boxes in Merchant Center).
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --target-country: string # [DEPRECATED] Please use targets[].country instead. The country where the items in the feed will be included in the search index, represented as a CLDR territory code.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
]: any -> record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/datafeeds") $qp)
  let req_body = {"attributeLanguage": $attribute_language, "contentLanguage": $content_language, "contentType": $content_type, "fetchSchedule": $fetch_schedule, "fileName": $file_name, "format": $format, "id": $id, "intendedDestinations": $intended_destinations, "kind": $kind, "name": $name, "targetCountry": $target_country, "targets": $targets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a datafeed configuration from your Merchant Center account.
#
# DELETE /{merchantId}/datafeeds/{datafeedId}
# operationId: content.datafeeds.delete
export def "datafeeds delete" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), datafeed_id: (encode-path-segment $datafeed_id)} | format pattern "/{merchant_id}/datafeeds/{datafeed_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a datafeed configuration from your Merchant Center account.
#
# GET /{merchantId}/datafeeds/{datafeedId}
# operationId: content.datafeeds.get
export def "datafeeds get" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), datafeed_id: (encode-path-segment $datafeed_id)} | format pattern "/{merchant_id}/datafeeds/{datafeed_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a datafeed configuration of your Merchant Center account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/datafeeds/{datafeedId}
# operationId: content.datafeeds.update
# --fetchSchedule shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
# --format shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
# --targets item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
export def "datafeeds update" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-language: string # [DEPRECATED] Please use targets[].language instead. The two-letter ISO 639-1 language of the items in the feed. Must be a valid language for `targetCountry`.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --intended-destinations: list<string> # [DEPRECATED] Please use targets[].includedDestinations instead. The list of intended destinations (corresponds to checked check boxes in Merchant Center).
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --target-country: string # [DEPRECATED] Please use targets[].country instead. The country where the items in the feed will be included in the search index, represented as a CLDR territory code.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
]: any -> record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), datafeed_id: (encode-path-segment $datafeed_id)} | format pattern "/{merchant_id}/datafeeds/{datafeed_id}") $qp)
  let req_body = {"attributeLanguage": $attribute_language, "contentLanguage": $content_language, "contentType": $content_type, "fetchSchedule": $fetch_schedule, "fileName": $file_name, "format": $format, "id": $id, "intendedDestinations": $intended_destinations, "kind": $kind, "name": $name, "targetCountry": $target_country, "targets": $targets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Invokes a fetch for the datafeed in your Merchant Center account. If you need to call this method more than once per day, we recommend you use the Products service to update your product data.
#
# POST /{merchantId}/datafeeds/{datafeedId}/fetchNow
# operationId: content.datafeeds.fetchnow
export def "datafeeds-fetch-now create-fetchnow" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), datafeed_id: (encode-path-segment $datafeed_id)} | format pattern "/{merchant_id}/datafeeds/{datafeed_id}/fetchNow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the statuses of the datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeedstatuses
# operationId: content.datafeedstatuses.list
export def "datafeedstatuses list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<country: string, datafeedId: string, errors: list, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/datafeedstatuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the status of a datafeed from your Merchant Center account.
#
# GET /{merchantId}/datafeedstatuses/{datafeedId}
# operationId: content.datafeedstatuses.get
export def "datafeedstatuses get" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --country: string # The country for which to get the datafeed status. If this parameter is provided then language must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
  --language: string # The language for which to get the datafeed status. If this parameter is provided then country must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
]: nothing -> record<country: string, datafeedId: string, errors: table<code: string, count: string, examples: list, message: string>, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: table<code: string, count: string, examples: list, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), datafeed_id: (encode-path-segment $datafeed_id)} | format pattern "/{merchant_id}/datafeedstatuses/{datafeed_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the LIA settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/liasettings
# operationId: content.liasettings.list
export def "liasettings list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of LIA settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<accountId: string, countrySettings: list, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/liasettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the LIA settings of the account.
#
# GET /{merchantId}/liasettings/{accountId}
# operationId: content.liasettings.get
export def "liasettings get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the LIA settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/liasettings/{accountId}
# operationId: content.liasettings.update
# --countrySettings item shape: {about?: record, country?: string, hostedLocalStorefrontActive?: bool, inventory?: record, onDisplayToOrder?: record, posDataProvider?: record, storePickupActive?: bool}
export def "liasettings update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --body-account-id: string # The ID of the account to which these LIA settings belong. Ignored upon update, always present in get request responses. (format: uint64)
  --country-settings: list # The LIA settings for each country. — item shape: {about?: record, country?: string, hostedLocalStorefrontActive?: bool, inventory?: record, onDisplayToOrder?: record, posDataProvider?: record, storePickupActive?: bool}
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#liaSettings`"
]: any -> record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}") $qp)
  let req_body = {"accountId": $body_account_id, "countrySettings": $country_settings, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the list of accessible Google My Business accounts.
#
# GET /{merchantId}/liasettings/{accountId}/accessiblegmbaccounts
# operationId: content.liasettings.getaccessiblegmbaccounts
export def "liasettings-accessiblegmbaccounts get-getaccessiblegmbaccounts" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<accountId: string, gmbAccounts: table<email: string, listingCount: string, name: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}/accessiblegmbaccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Requests access to a specified Google My Business account.
#
# POST /{merchantId}/liasettings/{accountId}/requestgmbaccess
# operationId: content.liasettings.requestgmbaccess
export def "liasettings-requestgmbaccess create" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --gmb-email: string # The email of the Google My Business account.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "gmbEmail" $gmb_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}/requestgmbaccess") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Requests inventory validation for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/requestinventoryverification/{country}
# operationId: content.liasettings.requestinventoryverification
export def "liasettings-requestinventoryverification create" [
  merchant_id: string
  account_id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id), country: (encode-path-segment $country)} | format pattern "/{merchant_id}/liasettings/{account_id}/requestinventoryverification/{country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the inventory verification contract for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/setinventoryverificationcontact
# operationId: content.liasettings.setinventoryverificationcontact
export def "liasettings-setinventoryverificationcontact create" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --country: string # The country for which inventory verification is requested.
  --language: string # The language for which inventory verification is requested.
  --contact-name: string # The name of the inventory verification contact.
  --contact-email: string # The email of the inventory verification contact.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "contactName" $contact_name "scalar") (serialize-qp "contactEmail" $contact_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}/setinventoryverificationcontact") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the POS data provider for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/setposdataprovider
# operationId: content.liasettings.setposdataprovider
export def "liasettings-setposdataprovider create" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --country: string # The country for which the POS data provider is selected.
  --pos-data-provider-id: string # The ID of POS data provider.
  --pos-external-account-id: string # The account ID by which this merchant is known to the POS data provider.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "posDataProviderId" $pos_data_provider_id "scalar") (serialize-qp "posExternalAccountId" $pos_external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/liasettings/{account_id}/setposdataprovider") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a charge invoice for a shipment group, and triggers a charge capture for orderinvoice enabled orders.
#
# POST /{merchantId}/orderinvoices/{orderId}/createChargeInvoice
# operationId: content.orderinvoices.createchargeinvoice
# --invoiceSummary shape: {additionalChargeSummaries?: list, customerBalance?: record, googleBalance?: record, merchantBalance?: record, productTotal?: record, promotionSummaries?: list}
# --lineItemInvoices item shape: {lineItemId?: string, productId?: string, shipmentUnitIds?: list<string>, unitInvoice?: record}
export def "orderinvoices-create-charge-invoice create-createchargeinvoice" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --invoice-id: string # [required] The ID of the invoice.
  --invoice-summary: record # shape: {additionalChargeSummaries?: list, customerBalance?: record, googleBalance?: record, merchantBalance?: record, productTotal?: record, promotionSummaries?: list}
  --line-item-invoices: list # [required] Invoice details per line item. — item shape: {lineItemId?: string, productId?: string, shipmentUnitIds?: list<string>, unitInvoice?: record}
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order.
  --shipment-group-id: string # [required] ID of the shipment group. It is assigned by the merchant in the `shipLineItems` method and is used to group multiple line items that have the same kind of shipping charges.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orderinvoices/{order_id}/createChargeInvoice") $qp)
  let req_body = {"invoiceId": $invoice_id, "invoiceSummary": $invoice_summary, "lineItemInvoices": $line_item_invoices, "operationId": $operation_id, "shipmentGroupId": $shipment_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a refund invoice for one or more shipment groups, and triggers a refund for orderinvoice enabled orders. This can only be used for line items that have previously been charged using `createChargeInvoice`. All amounts (except for the summary) are incremental with respect to the previous invoice.
#
# POST /{merchantId}/orderinvoices/{orderId}/createRefundInvoice
# operationId: content.orderinvoices.createrefundinvoice
# --refundOnlyOption shape: {description?: string, reason?: string}
# --returnOption shape: {description?: string, reason?: string}
# --shipmentInvoices item shape: {invoiceSummary?: record, lineItemInvoices?: list, shipmentGroupId?: string}
export def "orderinvoices-create-refund-invoice create-createrefundinvoice" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --invoice-id: string # [required] The ID of the invoice.
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order.
  --refund-only-option: record # shape: {description?: string, reason?: string}
  --return-option: record # shape: {description?: string, reason?: string}
  --shipment-invoices: list # Invoice details for different shipment groups. — item shape: {invoiceSummary?: record, lineItemInvoices?: list, shipmentGroupId?: string}
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orderinvoices/{order_id}/createRefundInvoice") $qp)
  let req_body = {"invoiceId": $invoice_id, "operationId": $operation_id, "refundOnlyOption": $refund_only_option, "returnOption": $return_option, "shipmentInvoices": $shipment_invoices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a report for disbursements from your Merchant Center account.
#
# GET /{merchantId}/orderreports/disbursements
# operationId: content.orderreports.listdisbursements
export def "orderreports-disbursements get-listdisbursements" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --disbursement-end-date: string # The last date which disbursements occurred. In ISO 8601 format. Default: current date.
  --disbursement-start-date: string # The first date which disbursements occurred. In ISO 8601 format.
  --max-results: int # The maximum number of disbursements to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<disbursements: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "disbursementEndDate" $disbursement_end_date "scalar") (serialize-qp "disbursementStartDate" $disbursement_start_date "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/orderreports/disbursements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of transactions for a disbursement from your Merchant Center account.
#
# GET /{merchantId}/orderreports/disbursements/{disbursementId}/transactions
# operationId: content.orderreports.listtransactions
export def "orderreports-disbursements-transactions get-listtransactions" [
  merchant_id: string
  disbursement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of disbursements to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
  --transaction-end-date: string # The last date in which transaction occurred. In ISO 8601 format. Default: current date.
  --transaction-start-date: string # The first date in which transaction occurred. In ISO 8601 format.
]: nothing -> record<kind: string, nextPageToken: string, transactions: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string, merchantOrderId: string, orderId: string, productAmount: record, productAmountWithRemittedTax: record, transactionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "transactionEndDate" $transaction_end_date "scalar") (serialize-qp "transactionStartDate" $transaction_start_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), disbursement_id: (encode-path-segment $disbursement_id)} | format pattern "/{merchant_id}/orderreports/disbursements/{disbursement_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists order returns in your Merchant Center account.
#
# GET /{merchantId}/orderreturns
# operationId: content.orderreturns.list
export def "orderreturns list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --created-end-date: string # Obtains order returns created before this date (inclusively), in ISO 8601 format.
  --created-start-date: string # Obtains order returns created after this date (inclusively), in ISO 8601 format.
  --max-results: int # The maximum number of order returns to return in the response, used for paging. The default value is 25 returns per page, and the maximum allowed value is 250 returns per page.
  --order-by: string@order-by-completer # Return the results in the specified order.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list, returnShipments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "createdEndDate" $created_end_date "scalar") (serialize-qp "createdStartDate" $created_start_date "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/orderreturns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an order return from your Merchant Center account.
#
# GET /{merchantId}/orderreturns/{returnId}
# operationId: content.orderreturns.get
export def "orderreturns get" [
  merchant_id: string
  return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: table<customerReturnReason: record, itemId: string, merchantReturnReason: record, product: record, returnShipmentIds: list, state: string>, returnShipments: table<creationDate: string, deliveryDate: string, returnMethodType: string, shipmentId: string, shipmentTrackingInfos: list, shippingDate: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), return_id: (encode-path-segment $return_id)} | format pattern "/{merchant_id}/orderreturns/{return_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the orders in your Merchant Center account.
#
# GET /{merchantId}/orders
# operationId: content.orders.list
export def "orders list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --acknowledged: oneof<nothing, bool> # Obtains orders that match the acknowledgement status. When set to true, obtains orders that have been acknowledged. When false, obtains orders that have not been acknowledged. We recommend using this filter set to `false`, in conjunction with the `acknowledge` call, such that only un-acknowledged orders are returned.
  --max-results: int # The maximum number of orders to return in the response, used for paging. The default value is 25 orders per page, and the maximum allowed value is 250 orders per page.
  --order-by: string # Order results by placement date in descending or ascending order. Acceptable values are: - placedDateAsc - placedDateDesc
  --page-token: string # The token returned by the previous request.
  --placed-date-end: string # Obtains orders placed before this date (exclusively), in ISO 8601 format.
  --placed-date-start: string # Obtains orders placed after this date (inclusively), in ISO 8601 format.
  --statuses: list<string> # Obtains orders that match any of the specified statuses. Please note that `active` is a shortcut for `pendingShipment` and `partiallyShipped`, and `completed` is a shortcut for `shipped`, `partiallyDelivered`, `delivered`, `partiallyReturned`, `returned`, and `canceled`.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<acknowledged: bool, channelType: string, customer: record, deliveryDetails: record, id: string, kind: string, lineItems: list, merchantId: string, merchantOrderId: string, netAmount: record, paymentMethod: record, paymentStatus: string, pickupDetails: record, placedDate: string, promotions: list, refunds: list, shipments: list, shippingCost: record, shippingCostTax: record, shippingOption: string, status: string, taxCollector: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "acknowledged" $acknowledged "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "placedDateEnd" $placed_date_end "scalar") (serialize-qp "placedDateStart" $placed_date_start "scalar") (serialize-qp "statuses" $statuses "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/orders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an order from your Merchant Center account.
#
# GET /{merchantId}/orders/{orderId}
# operationId: content.orders.get
export def "orders get" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record<explicitMarketingPreference: string, lastUpdatedTimestamp: string, marketingEmailAddress: string>>, deliveryDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, phoneNumber: string>, id: string, kind: string, lineItems: table<annotations: list, cancellations: list, id: string, price: record, product: record, quantityCanceled: int, quantityDelivered: int, quantityOrdered: int, quantityPending: int, quantityReadyForPickup: int, quantityReturned: int, quantityShipped: int, returnInfo: record, returns: list, shippingDetails: record, tax: record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, collectors: list<record>, locationId: string>, placedDate: string, promotions: table<benefits: list, effectiveDates: string, genericRedemptionCode: string, id: string, longTitle: string, productApplicability: string, redemptionChannel: string>, refunds: table<actor: string, amount: record, creationDate: string, reason: string, reasonText: string>, shipments: table<carrier: string, creationDate: string, deliveryDate: string, id: string, lineItems: list, scheduledDeliveryDetails: record, status: string, trackingId: string>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Marks an order as acknowledged.
#
# POST /{merchantId}/orders/{orderId}/acknowledge
# operationId: content.orders.acknowledge
export def "orders-acknowledge create" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/acknowledge") $qp)
  let req_body = {"operationId": $operation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancels all line items in an order, making a full refund.
#
# POST /{merchantId}/orders/{orderId}/cancel
# operationId: content.orders.cancel
export def "orders-cancel cancel" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/cancel") $qp)
  let req_body = {"operationId": $operation_id, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancels a line item, making a full refund.
#
# POST /{merchantId}/orders/{orderId}/cancelLineItem
# operationId: content.orders.cancellineitem
# --amount shape: {currency?: string, value?: string}
# --amountPretax shape: {currency?: string, value?: string}
# --amountTax shape: {currency?: string, value?: string}
export def "orders-cancel-line-item create-cancellineitem" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --amount: record # shape: {currency?: string, value?: string}
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to cancel. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to cancel. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to cancel. (format: uint32)
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/cancelLineItem") $qp)
  let req_body = {"amount": $amount, "amountPretax": $amount_pretax, "amountTax": $amount_tax, "lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "quantity": $quantity, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated. Notifies that item return and refund was handled directly by merchant outside of Google payments processing (e.g. cash refund done in store). Note: We recommend calling the returnrefundlineitem method to refund in-store returns. We will issue the refund directly to the customer. This helps to prevent possible differences arising between merchant and Google transaction records. We also recommend having the point of sale system communicate with Google to ensure that customers do not receive a double refund by first refunding via Google then via an in-store return.
#
# POST /{merchantId}/orders/{orderId}/inStoreRefundLineItem
# operationId: content.orders.instorerefundlineitem
# --amountPretax shape: {currency?: string, value?: string}
# --amountTax shape: {currency?: string, value?: string}
export def "orders-in-store-refund-line-item create-instorerefundlineitem" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/inStoreRefundLineItem") $qp)
  let req_body = {"amountPretax": $amount_pretax, "amountTax": $amount_tax, "lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "quantity": $quantity, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated, please use returnRefundLineItem instead.
#
# POST /{merchantId}/orders/{orderId}/refund
# operationId: content.orders.refund
# --amount shape: {currency?: string, value?: string}
# --amountPretax shape: {currency?: string, value?: string}
# --amountTax shape: {currency?: string, value?: string}
export def "orders-refund create" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --amount: record # shape: {currency?: string, value?: string}
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the refund. Acceptable values are: - "`adjustment`" - "`courtesyAdjustment`" - "`customerCanceled`" - "`customerDiscretionaryReturn`" - "`deliveredLateByCarrier`" - "`feeAdjustment`" - "`lateShipmentCredit`" - "`noInventory`" - "`other`" - "`priceError`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`shippingCostAdjustment`" - "`taxAdjustment`" - "`undeliverableShippingAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/refund") $qp)
  let req_body = {"amount": $amount, "amountPretax": $amount_pretax, "amountTax": $amount_tax, "operationId": $operation_id, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rejects return on an line item.
#
# POST /{merchantId}/orders/{orderId}/rejectReturnLineItem
# operationId: content.orders.rejectreturnlineitem
export def "orders-reject-return-line-item create-rejectreturnlineitem" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`damagedOrUsed`" - "`missingComponent`" - "`notEligible`" - "`other`" - "`outOfReturnWindow`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/rejectReturnLineItem") $qp)
  let req_body = {"lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "quantity": $quantity, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a line item.
#
# POST /{merchantId}/orders/{orderId}/returnLineItem
# operationId: content.orders.returnlineitem
export def "orders-return-line-item create-returnlineitem" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/returnLineItem") $qp)
  let req_body = {"lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "quantity": $quantity, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns and refunds a line item. Note that this method can only be called on fully shipped orders. Please also note that the Orderreturns API is the preferred way to handle returns after you receive a return from a customer. You can use Orderreturns.list or Orderreturns.get to search for the return, and then use Orderreturns.processreturn to issue the refund. If the return cannot be found, then we recommend using this API to issue a refund.
#
# POST /{merchantId}/orders/{orderId}/returnRefundLineItem
# operationId: content.orders.returnrefundlineitem
# --amountPretax shape: {currency?: string, value?: string}
# --amountTax shape: {currency?: string, value?: string}
export def "orders-return-refund-line-item create-returnrefundlineitem" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. Quantity is required. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/returnRefundLineItem") $qp)
  let req_body = {"amountPretax": $amount_pretax, "amountTax": $amount_tax, "lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "quantity": $quantity, "reason": $reason, "reasonText": $reason_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sets (or overrides if it already exists) merchant provided annotations in the form of key-value pairs. A common use case would be to supply us with additional structured information about a line item that cannot be provided via other methods. Submitted key-value pairs can be retrieved as part of the orders resource.
#
# POST /{merchantId}/orders/{orderId}/setLineItemMetadata
# operationId: content.orders.setlineitemmetadata
# --annotations item shape: {key?: string, value?: string}
export def "orders-set-line-item-metadata create-setlineitemmetadata" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --annotations: list # item shape: {key?: string, value?: string}
  --line-item-id: string # The ID of the line item to set metadata. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to set metadata. This is the REST ID used in the products service. Either lineItemId or productId is required.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/setLineItemMetadata") $qp)
  let req_body = {"annotations": $annotations, "lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Marks line item(s) as shipped.
#
# POST /{merchantId}/orders/{orderId}/shipLineItems
# operationId: content.orders.shiplineitems
# --lineItems item shape: {lineItemId?: string, productId?: string, quantity?: int}
# --shipmentInfos item shape: {carrier?: string, shipmentId?: string, trackingId?: string}
export def "orders-ship-line-items create-shiplineitems" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --carrier: string # Deprecated. Please use shipmentInfo instead. The carrier handling the shipment. See `shipments[].carrier` in the Orders resource representation for a list of acceptable values.
  --line-items: list # Line items to ship. — item shape: {lineItemId?: string, productId?: string, quantity?: int}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --shipment-group-id: string # ID of the shipment group. Required for orders that use the orderinvoices service.
  --shipment-id: string # Deprecated. Please use shipmentInfo instead. The ID of the shipment.
  --shipment-infos: list # Shipment information. This field is repeated because a single line item can be shipped in several packages (and have several tracking IDs). — item shape: {carrier?: string, shipmentId?: string, trackingId?: string}
  --tracking-id: string # Deprecated. Please use shipmentInfo instead. The tracking ID for the shipment.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/shipLineItems") $qp)
  let req_body = {"carrier": $carrier, "lineItems": $line_items, "operationId": $operation_id, "shipmentGroupId": $shipment_group_id, "shipmentId": $shipment_id, "shipmentInfos": $shipment_infos, "trackingId": $tracking_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sandbox only. Creates a test return.
#
# POST /{merchantId}/orders/{orderId}/testreturn
# operationId: content.orders.createtestreturn
# --items item shape: {lineItemId?: string, quantity?: int}
export def "orders-testreturn create-createtestreturn" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --items: list # Returned items. — item shape: {lineItemId?: string, quantity?: int}
]: any -> record<kind: string, returnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/testreturn") $qp)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates ship by and delivery by dates for a line item.
#
# POST /{merchantId}/orders/{orderId}/updateLineItemShippingDetails
# operationId: content.orders.updatelineitemshippingdetails
export def "orders-update-line-item-shipping-details create-updatelineitemshippingdetails" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deliver-by-date: string # Updated delivery by date, in ISO 8601 format. If not specified only ship by date is updated. Provided date should be within 1 year timeframe and can not be a date in the past.
  --line-item-id: string # The ID of the line item to set metadata. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to set metadata. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --ship-by-date: string # Updated ship by date, in ISO 8601 format. If not specified only deliver by date is updated. Provided date should be within 1 year timeframe and can not be a date in the past.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/updateLineItemShippingDetails") $qp)
  let req_body = {"deliverByDate": $deliver_by_date, "lineItemId": $line_item_id, "operationId": $operation_id, "productId": $product_id, "shipByDate": $ship_by_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the merchant order ID for a given order.
#
# POST /{merchantId}/orders/{orderId}/updateMerchantOrderId
# operationId: content.orders.updatemerchantorderid
export def "orders-update-merchant-order-id create-updatemerchantorderid" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --merchant-order-id: string # The merchant order id to be assigned to the order. Must be unique per merchant.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/updateMerchantOrderId") $qp)
  let req_body = {"merchantOrderId": $merchant_order_id, "operationId": $operation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a shipment's status, carrier, and/or tracking ID.
#
# POST /{merchantId}/orders/{orderId}/updateShipment
# operationId: content.orders.updateshipment
export def "orders-update-shipment create-updateshipment" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --carrier: string # The carrier handling the shipment. Not updated if missing. See `shipments[].carrier` in the Orders resource representation for a list of acceptable values.
  --delivery-date: string # Date on which the shipment has been delivered, in ISO 8601 format. Optional and can be provided only if `status` is `delivered`.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --shipment-id: string # The ID of the shipment.
  --status: string # New status for the shipment. Not updated if missing. Acceptable values are: - "`delivered`" - "`undeliverable`" - "`readyForPickup`"
  --tracking-id: string # The tracking ID for the shipment. Not updated if missing.
]: any -> record<executionStatus: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/orders/{order_id}/updateShipment") $qp)
  let req_body = {"carrier": $carrier, "deliveryDate": $delivery_date, "operationId": $operation_id, "shipmentId": $shipment_id, "status": $status, "trackingId": $tracking_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves an order using merchant order ID.
#
# GET /{merchantId}/ordersbymerchantid/{merchantOrderId}
# operationId: content.orders.getbymerchantorderid
export def "ordersbymerchantid get-getbymerchantorderid" [
  merchant_id: string
  merchant_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string, order: record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record>, deliveryDetails: record<address: record, phoneNumber: string>, id: string, kind: string, lineItems: list<record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record, collectors: list, locationId: string>, placedDate: string, promotions: list<record>, refunds: list<record>, shipments: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), merchant_order_id: (encode-path-segment $merchant_order_id)} | format pattern "/{merchant_id}/ordersbymerchantid/{merchant_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit inventory for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/inventory
# operationId: content.pos.inventory
# --price shape: {currency?: string, value?: string}
export def "pos-inventory create" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The available quantity of the item. (format: int64)
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted via the API or the code of the store in Google My Business.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, storeCode: string, targetCountry: string, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/inventory") $qp)
  let req_body = {"contentLanguage": $content_language, "gtin": $gtin, "itemId": $item_id, "price": $price, "quantity": $quantity, "storeCode": $store_code, "targetCountry": $target_country, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Submit a sale event for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/sale
# operationId: content.pos.sale
# --price shape: {currency?: string, value?: string}
export def "pos-sale create" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The relative change of the available quantity. Negative for items returned. (format: int64)
  --sale-id: string # A unique ID to group items from the same sale event.
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted via the API or the code of the store in Google My Business.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, saleId: string, storeCode: string, targetCountry: string, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/sale") $qp)
  let req_body = {"contentLanguage": $content_language, "gtin": $gtin, "itemId": $item_id, "price": $price, "quantity": $quantity, "saleId": $sale_id, "storeCode": $store_code, "targetCountry": $target_country, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the stores of the target merchant.
#
# GET /{merchantId}/pos/{targetMerchantId}/store
# operationId: content.pos.list
export def "pos-store list" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string, resources: table<gcidCategory: list, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/store") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a store for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/store
# operationId: content.pos.insert
export def "pos-store create" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --gcid-category: list<string> # The business type of the store.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#posStore`"
  --phone-number: string # The store phone number.
  --place-id: string # The Google Place Id of the store location.
  --store-address: string # Required. The street address of the store.
  --store-code: string # Required. A store identifier that is unique for the given merchant.
  --store-name: string # The merchant or store name.
  --website-url: string # The website url for the store or merchant.
]: any -> record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/store") $qp)
  let req_body = {"gcidCategory": $gcid_category, "kind": $kind, "phoneNumber": $phone_number, "placeId": $place_id, "storeAddress": $store_address, "storeCode": $store_code, "storeName": $store_name, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a store for the given merchant.
#
# DELETE /{merchantId}/pos/{targetMerchantId}/store/{storeCode}
# operationId: content.pos.delete
export def "pos-store delete" [
  merchant_id: string
  target_merchant_id: string
  store_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id), store_code: (encode-path-segment $store_code)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/store/{store_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about the given store.
#
# GET /{merchantId}/pos/{targetMerchantId}/store/{storeCode}
# operationId: content.pos.get
export def "pos-store get" [
  merchant_id: string
  target_merchant_id: string
  store_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), target_merchant_id: (encode-path-segment $target_merchant_id), store_code: (encode-path-segment $store_code)} | format pattern "/{merchant_id}/pos/{target_merchant_id}/store/{store_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the products in your Merchant Center account. The response might contain fewer items than specified by maxResults. Rely on nextPageToken to determine if there are more items to be requested.
#
# GET /{merchantId}/products
# operationId: content.products.list
export def "products list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --include-invalid-inserted-items: oneof<nothing, bool> # Flag to include the invalid inserted items in the result of the list request. By default the invalid items are not shown (the default value is false).
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<additionalImageLinks: list, additionalProductTypes: list, adult: bool, adwordsGrouping: string, adwordsLabels: list, adwordsRedirect: string, ageGroup: string, aspects: list, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record, customAttributes: list, customGroups: list, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record, productType: string, promotionIds: list, salePrice: record, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list, shippingHeight: record, shippingLabel: string, shippingLength: record, shippingWeight: record, shippingWidth: record, sizeSystem: string, sizeType: string, sizes: list, source: string, targetCountry: string, taxes: list, title: string, unitPricingBaseMeasure: record, unitPricingMeasure: record, validatedDestinations: list, warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeInvalidInsertedItems" $include_invalid_inserted_items "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a product to your Merchant Center account. If an item with the same channel, contentLanguage, offerId, and targetCountry already exists, this method updates that entry.
#
# POST /{merchantId}/products
# operationId: content.products.insert
# --aspects item shape: {aspectName?: string, destinationName?: string, intention?: string}
# --costOfGoodsSold shape: {currency?: string, value?: string}
# --customAttributes item shape: {name?: string, type?: string, unit?: string, value?: string}
# --customGroups item shape: {attributes?: list, name?: string}
# --destinations item shape: {destinationName?: string, intention?: string}
# --installment shape: {amount?: record, months?: string}
# --loyaltyPoints shape: {name?: string, pointsValue?: string, ratio?: float}
# --price shape: {currency?: string, value?: string}
# --salePrice shape: {currency?: string, value?: string}
# --shipping item shape: {country?: string, locationGroupName?: string, locationId?: string, postalCode?: string, price?: record, region?: string, service?: string}
# --shippingHeight shape: {unit?: string, value?: float}
# --shippingLength shape: {unit?: string, value?: float}
# --shippingWeight shape: {unit?: string, value?: float}
# --shippingWidth shape: {unit?: string, value?: float}
# --taxes item shape: {country?: string, locationId?: string, postalCode?: string, rate?: float, region?: string, taxShip?: bool}
# --unitPricingBaseMeasure shape: {unit?: string, value?: string}
# --unitPricingMeasure shape: {unit?: string, value?: float}
# --warnings item shape: {domain?: string, message?: string, reason?: string}
export def "products create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --additional-image-links: list<string> # Additional URLs of images of the item.
  --additional-product-types: list<string> # Additional categories of the item (formatted as in products data specification).
  --adult: oneof<nothing, bool> # Should be set to true if the item is targeted towards adults.
  --adwords-grouping: string # Used to group items in an arbitrary way. Only for CPA%, discouraged otherwise.
  --adwords-labels: list<string> # Similar to adwords_grouping, but only works on CPC.
  --adwords-redirect: string # Allows advertisers to override the item URL when the product is shown within the context of Product Ads.
  --age-group: string # Target age group of the item. Acceptable values are: - "`adult`" - "`infant`" - "`kids`" - "`newborn`" - "`toddler`" - "`youngAdult`"
  --aspects: list # Deprecated. Do not use. — item shape: {aspectName?: string, destinationName?: string, intention?: string}
  --availability: string # Availability status of the item. Acceptable values are: - "`in stock`" - "`out of stock`" - "`preorder`"
  --availability-date: string # The day a pre-ordered product becomes available for delivery, in ISO 8601 format.
  --brand: string # Brand of the item.
  --canonical-link: string # URL for the canonical version of your item's landing page.
  --channel: string # Required. The item's channel (online or local). Acceptable values are: - "`local`" - "`online`"
  --color: string # Color of the item.
  --condition: string # Condition or state of the item. Acceptable values are: - "`new`" - "`refurbished`" - "`used`"
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --cost-of-goods-sold: record # shape: {currency?: string, value?: string}
  --custom-attributes: list # A list of custom (merchant-provided) attributes. It can also be used for submitting any attribute of the feed specification in its generic form (e.g., `{ "name": "size type", "value": "regular" }`). This is useful for submitting attributes not explicitly exposed by the API, such as additional attributes used for Buy on Google (formerly known as Shopping Actions). — item shape: {name?: string, type?: string, unit?: string, value?: string}
  --custom-groups: list # A list of custom (merchant-provided) custom attribute groups. — item shape: {attributes?: list, name?: string}
  --custom-label0: string # Custom label 0 for custom grouping of items in a Shopping campaign.
  --custom-label1: string # Custom label 1 for custom grouping of items in a Shopping campaign.
  --custom-label2: string # Custom label 2 for custom grouping of items in a Shopping campaign.
  --custom-label3: string # Custom label 3 for custom grouping of items in a Shopping campaign.
  --custom-label4: string # Custom label 4 for custom grouping of items in a Shopping campaign.
  --description: string # Description of the item.
  --destinations: list # Specifies the intended destinations for the product. — item shape: {destinationName?: string, intention?: string}
  --display-ads-id: string # An identifier for an item for dynamic remarketing campaigns.
  --display-ads-link: string # URL directly to your item's landing page for dynamic remarketing campaigns.
  --display-ads-similar-ids: list<string> # Advertiser-specified recommendations.
  --display-ads-title: string # Title of an item for dynamic remarketing campaigns.
  --display-ads-value: float # Offer margin for dynamic remarketing campaigns. (format: double)
  --energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --expiration-date: string # Date on which the item should expire, as specified upon insertion, in ISO 8601 format. The actual expiration date in Google Shopping is exposed in `productstatuses` as `googleExpirationDate` and might be earlier if `expirationDate` is too far in the future.
  --gender: string # Target gender of the item. Acceptable values are: - "`female`" - "`male`" - "`unisex`"
  --google-product-category: string # Google's category of the item (see [Google product taxonomy](https://support.google.com/merchants/answer/1705911)). When querying products, this field will contain the user provided value. There is currently no way to get back the auto assigned google product categories through the API.
  --gtin: string # Global Trade Item Number (GTIN) of the item.
  --id: string # The REST ID of the product. Content API methods that operate on products take this as their `productId` parameter. The REST ID for a product is of the form channel:contentLanguage: targetCountry: offerId.
  --identifier-exists: oneof<nothing, bool> # False when the item does not have unique product identifiers appropriate to its category, such as GTIN, MPN, and brand. Required according to the Unique Product Identifier Rules for all target countries except for Canada.
  --image-link: string # URL of an image of the item.
  --installment: record # shape: {amount?: record, months?: string}
  --is-bundle: oneof<nothing, bool> # Whether the item is a merchant-defined bundle. A bundle is a custom grouping of different products sold by a merchant for a single price.
  --item-group-id: string # Shared identifier for all variants of the same product.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#product`"
  --link: string # URL directly linking to your item's page on your website.
  --loyalty-points: record # shape: {name?: string, pointsValue?: string, ratio?: float}
  --material: string # The material of which the item is made.
  --max-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --max-handling-time: string # Maximal product handling time (in business days). (format: int64)
  --min-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --min-handling-time: string # Minimal product handling time (in business days). (format: int64)
  --mobile-link: string # URL for the mobile-optimized version of your item's landing page.
  --mpn: string # Manufacturer Part Number (MPN) of the item.
  --multipack: string # The number of identical products in a merchant-defined multipack. (format: int64)
  --offer-id: string # Required. A unique identifier for the item. Leading and trailing whitespaces are stripped and multiple whitespaces are replaced by a single whitespace upon submission. Only valid unicode characters are accepted. See the products feed specification for details. *Note:* Content API methods that operate on products take the REST ID of the product, *not* this identifier.
  --online-only: oneof<nothing, bool> # Deprecated.
  --pattern: string # The item's pattern (e.g. polka dots).
  --price: record # shape: {currency?: string, value?: string}
  --product-type: string # Your category of the item (formatted as in products data specification).
  --promotion-ids: list<string> # The unique ID of a promotion.
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # Date range during which the item is on sale (see products data specification ).
  --sell-on-google-quantity: string # The quantity of the product that is available for selling on Google. Supported only for online products. (format: int64)
  --shipping: list # Shipping rules. — item shape: {country?: string, locationGroupName?: string, locationId?: string, postalCode?: string, price?: record, region?: string, service?: string}
  --shipping-height: record # shape: {unit?: string, value?: float}
  --shipping-label: string # The shipping label of the product, used to group product in account-level shipping rules.
  --shipping-length: record # shape: {unit?: string, value?: float}
  --shipping-weight: record # shape: {unit?: string, value?: float}
  --shipping-width: record # shape: {unit?: string, value?: float}
  --size-system: string # System in which the size is specified. Recommended for apparel items. Acceptable values are: - "`AU`" - "`BR`" - "`CN`" - "`DE`" - "`EU`" - "`FR`" - "`IT`" - "`JP`" - "`MEX`" - "`UK`" - "`US`"
  --size-type: string # The cut of the item. Recommended for apparel items. Acceptable values are: - "`big and tall`" - "`maternity`" - "`oversize`" - "`petite`" - "`plus`" - "`regular`"
  --sizes: list<string> # Size of the item. Only one value is allowed. For variants with different sizes, insert a separate product for each size with the same `itemGroupId` value (see size definition).
  --body-source: string # The source of the offer, i.e., how the offer was created. Acceptable values are: - "`api`" - "`crawl`" - "`feed`"
  --target-country: string # Required. The CLDR territory code for the item.
  --taxes: list # Tax information. — item shape: {country?: string, locationId?: string, postalCode?: string, rate?: float, region?: string, taxShip?: bool}
  --title: string # Title of the item.
  --unit-pricing-base-measure: record # shape: {unit?: string, value?: string}
  --unit-pricing-measure: record # shape: {unit?: string, value?: float}
  --validated-destinations: list<string> # Deprecated. The read-only list of intended destinations which passed validation.
  --warnings: list # Read-only warnings. — item shape: {domain?: string, message?: string, reason?: string}
]: any -> record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/products") $qp)
  let req_body = {"additionalImageLinks": $additional_image_links, "additionalProductTypes": $additional_product_types, "adult": $adult, "adwordsGrouping": $adwords_grouping, "adwordsLabels": $adwords_labels, "adwordsRedirect": $adwords_redirect, "ageGroup": $age_group, "aspects": $aspects, "availability": $availability, "availabilityDate": $availability_date, "brand": $brand, "canonicalLink": $canonical_link, "channel": $channel, "color": $color, "condition": $condition, "contentLanguage": $content_language, "costOfGoodsSold": $cost_of_goods_sold, "customAttributes": $custom_attributes, "customGroups": $custom_groups, "customLabel0": $custom_label0, "customLabel1": $custom_label1, "customLabel2": $custom_label2, "customLabel3": $custom_label3, "customLabel4": $custom_label4, "description": $description, "destinations": $destinations, "displayAdsId": $display_ads_id, "displayAdsLink": $display_ads_link, "displayAdsSimilarIds": $display_ads_similar_ids, "displayAdsTitle": $display_ads_title, "displayAdsValue": $display_ads_value, "energyEfficiencyClass": $energy_efficiency_class, "expirationDate": $expiration_date, "gender": $gender, "googleProductCategory": $google_product_category, "gtin": $gtin, "id": $id, "identifierExists": $identifier_exists, "imageLink": $image_link, "installment": $installment, "isBundle": $is_bundle, "itemGroupId": $item_group_id, "kind": $kind, "link": $link, "loyaltyPoints": $loyalty_points, "material": $material, "maxEnergyEfficiencyClass": $max_energy_efficiency_class, "maxHandlingTime": $max_handling_time, "minEnergyEfficiencyClass": $min_energy_efficiency_class, "minHandlingTime": $min_handling_time, "mobileLink": $mobile_link, "mpn": $mpn, "multipack": $multipack, "offerId": $offer_id, "onlineOnly": $online_only, "pattern": $pattern, "price": $price, "productType": $product_type, "promotionIds": $promotion_ids, "salePrice": $sale_price, "salePriceEffectiveDate": $sale_price_effective_date, "sellOnGoogleQuantity": $sell_on_google_quantity, "shipping": $shipping, "shippingHeight": $shipping_height, "shippingLabel": $shipping_label, "shippingLength": $shipping_length, "shippingWeight": $shipping_weight, "shippingWidth": $shipping_width, "sizeSystem": $size_system, "sizeType": $size_type, "sizes": $sizes, "source": $body_source, "targetCountry": $target_country, "taxes": $taxes, "title": $title, "unitPricingBaseMeasure": $unit_pricing_base_measure, "unitPricingMeasure": $unit_pricing_measure, "validatedDestinations": $validated_destinations, "warnings": $warnings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a product from your Merchant Center account.
#
# DELETE /{merchantId}/products/{productId}
# operationId: content.products.delete
export def "products delete" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), product_id: (encode-path-segment $product_id)} | format pattern "/{merchant_id}/products/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a product from your Merchant Center account.
#
# GET /{merchantId}/products/{productId}
# operationId: content.products.get
export def "products get" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), product_id: (encode-path-segment $product_id)} | format pattern "/{merchant_id}/products/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the statuses of the products in your Merchant Center account.
#
# GET /{merchantId}/productstatuses
# operationId: content.productstatuses.list
export def "productstatuses list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the results of the list request. The default value is false.
  --include-invalid-inserted-items: oneof<nothing, bool> # Flag to include the invalid inserted items in the result of the list request. By default the invalid items are not shown (the default value is false).
  --max-results: int # The maximum number of product statuses to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<creationDate: string, dataQualityIssues: list, destinationStatuses: list, googleExpirationDate: string, itemLevelIssues: list, kind: string, lastUpdateDate: string, link: string, product: record, productId: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "destinations" $destinations "multi") (serialize-qp "includeAttributes" $include_attributes "scalar") (serialize-qp "includeInvalidInsertedItems" $include_invalid_inserted_items "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/productstatuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the status of a product from your Merchant Center account.
#
# GET /{merchantId}/productstatuses/{productId}
# operationId: content.productstatuses.get
export def "productstatuses get" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the result of this get request. The default value is false.
]: nothing -> record<creationDate: string, dataQualityIssues: table<destination: string, detail: string, fetchStatus: string, id: string, location: string, severity: string, timestamp: string, valueOnLandingPage: string, valueProvided: string>, destinationStatuses: table<approvalPending: bool, approvalStatus: string, destination: string, intention: string>, googleExpirationDate: string, itemLevelIssues: table<attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, kind: string, lastUpdateDate: string, link: string, product: record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: list<record>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: list<record>, customGroups: list<record>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list<record>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list<record>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: list<record>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: list<record>>, productId: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "destinations" $destinations "multi") (serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), product_id: (encode-path-segment $product_id)} | format pattern "/{merchant_id}/productstatuses/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the shipping settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/shippingsettings
# operationId: content.shippingsettings.list
export def "shippingsettings list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of shipping settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<kind: string, nextPageToken: string, resources: table<accountId: string, postalCodeGroups: list, services: list, warehouses: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/shippingsettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the shipping settings of the account.
#
# GET /{merchantId}/shippingsettings/{accountId}
# operationId: content.shippingsettings.get
export def "shippingsettings get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/shippingsettings/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the shipping settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/shippingsettings/{accountId}
# operationId: content.shippingsettings.update
# --postalCodeGroups item shape: {country?: string, name?: string, postalCodeRanges?: list}
# --services item shape: {active?: bool, currency?: string, deliveryCountry?: string, deliveryTime?: record, eligibility?: string, minimumOrderValue?: record, minimumOrderValueTable?: record, name?: string, pickupService?: record, rateGroups?: list, shipmentType?: string}
# --warehouses item shape: {businessDayConfig?: record, cutoffTime?: record, handlingDays?: string, name?: string, shippingAddress?: record}
export def "shippingsettings update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any).
  --body-account-id: string # The ID of the account to which these account shipping settings belong. Ignored upon update, always present in get request responses. (format: uint64)
  --postal-code-groups: list # A list of postal code groups that can be referred to in `services`. Optional. — item shape: {country?: string, name?: string, postalCodeRanges?: list}
  --services: list # The target account's list of services. Optional. — item shape: {active?: bool, currency?: string, deliveryCountry?: string, deliveryTime?: record, eligibility?: string, minimumOrderValue?: record, minimumOrderValueTable?: record, name?: string, pickupService?: record, rateGroups?: list, shipmentType?: string}
  --warehouses: list # Optional. A list of warehouses which can be referred to in `services`. — item shape: {businessDayConfig?: record, cutoffTime?: record, handlingDays?: string, name?: string, shippingAddress?: record}
]: any -> record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), account_id: (encode-path-segment $account_id)} | format pattern "/{merchant_id}/shippingsettings/{account_id}") $qp)
  let req_body = {"accountId": $body_account_id, "postalCodeGroups": $postal_code_groups, "services": $services, "warehouses": $warehouses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves supported carriers and carrier services for an account.
#
# GET /{merchantId}/supportedCarriers
# operationId: content.shippingsettings.getsupportedcarriers
export def "supported-carriers get-getsupportedcarriers" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<carriers: table<country: string, eddServices: list, name: string, services: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/supportedCarriers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves supported holidays for an account.
#
# GET /{merchantId}/supportedHolidays
# operationId: content.shippingsettings.getsupportedholidays
export def "supported-holidays get-getsupportedholidays" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<holidays: table<countryCode: string, date: string, deliveryGuaranteeDate: string, deliveryGuaranteeHour: string, id: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/supportedHolidays") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves supported pickup services for an account.
#
# GET /{merchantId}/supportedPickupServices
# operationId: content.shippingsettings.getsupportedpickupservices
export def "supported-pickup-services get-getsupportedpickupservices" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string, pickupServices: table<carrierName: string, country: string, serviceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/supportedPickupServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sandbox only. Creates a test order.
#
# POST /{merchantId}/testorders
# operationId: content.orders.createtestorder
# --testOrder shape: {customer?: record, enableOrderinvoices?: bool, kind?: string, lineItems?: list, notificationMode?: string, paymentMethod?: record, predefinedDeliveryAddress?: string, predefinedPickupDetails?: string, promotions?: list, shippingCost?: record, shippingCostTax?: record, shippingOption?: string}
export def "testorders create-createtestorder" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --country: string # The CLDR territory code of the country of the test order to create. Affects the currency and addresses of orders created via `template_name`, or the addresses of orders created via `test_order`. Acceptable values are: - "`US`" - "`FR`" Defaults to `US`.
  --template-name: string # The test order template to use. Specify as an alternative to `testOrder` as a shortcut for retrieving a template and then creating an order using that template. Acceptable values are: - "`template1`" - "`template1a`" - "`template1b`" - "`template2`" - "`template3`"
  --test-order: record # shape: {customer?: record, enableOrderinvoices?: bool, kind?: string, lineItems?: list, notificationMode?: string, paymentMethod?: record, predefinedDeliveryAddress?: string, predefinedPickupDetails?: string, promotions?: list, shippingCost?: record, shippingCostTax?: record, shippingOption?: string}
]: any -> record<kind: string, orderId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id)} | format pattern "/{merchant_id}/testorders") $qp)
  let req_body = {"country": $country, "templateName": $template_name, "testOrder": $test_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sandbox only. Moves a test order from state "`inProgress`" to state "`pendingShipment`".
#
# POST /{merchantId}/testorders/{orderId}/advance
# operationId: content.orders.advancetestorder
export def "testorders-advance create-advancetestorder" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/testorders/{order_id}/advance") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sandbox only. Cancels a test order for customer-initiated cancellation.
#
# POST /{merchantId}/testorders/{orderId}/cancelByCustomer
# operationId: content.orders.canceltestorderbycustomer
export def "testorders-cancel-by-customer create-canceltestorderbycustomer" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --reason: string # The reason for the cancellation. Acceptable values are: - "`changedMind`" - "`orderedWrongItem`" - "`other`"
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), order_id: (encode-path-segment $order_id)} | format pattern "/{merchant_id}/testorders/{order_id}/cancelByCustomer") $qp)
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sandbox only. Retrieves an order template that can be used to quickly create a new order in sandbox.
#
# GET /{merchantId}/testordertemplates/{templateName}
# operationId: content.orders.gettestordertemplate
export def "testordertemplates get-gettestordertemplate" [
  merchant_id: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --country: string # The country of the template to retrieve. Defaults to `US`.
]: nothing -> record<kind: string, template: record<customer: record<email: string, explicitMarketingPreference: bool, fullName: string, marketingRightsInfo: record>, enableOrderinvoices: bool, kind: string, lineItems: list<record>, notificationMode: string, paymentMethod: record<expirationMonth: int, expirationYear: int, lastFourDigits: string, predefinedBillingAddress: string, type: string>, predefinedDeliveryAddress: string, predefinedPickupDetails: string, promotions: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({merchant_id: (encode-path-segment $merchant_id), template_name: (encode-path-segment $template_name)} | format pattern "/{merchant_id}/testordertemplates/{template_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
