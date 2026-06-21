# Auto-generated client for Ad Exchange Buyer API vv1.4
# Source: https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer/v1.4/openapi.json
# Auth: --token flag or $env.AD_EXCHANGE_BUYER_API_TOKEN

const BASE_URL = "https://www.googleapis.com/adexchangebuyer/v1.4"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AD_EXCHANGE_BUYER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/adexchangebuyer/v1.4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def deals-status-filter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }
def open-auction-status-filter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# Retrieves the authenticated user's list of accounts.
#
# GET /accounts
# operationId: adexchangebuyer.accounts.list
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: list, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets one account by ID.
#
# GET /accounts/{id}
# operationId: adexchangebuyer.accounts.get
export def "accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates an existing account. This method supports patch semantics.
#
# PATCH /accounts/{id}
# operationId: adexchangebuyer.accounts.patch
# --bidderLocation item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
export def "accounts update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --confirm-unsafe-account-change: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --apply-pretargeting-to-non-guaranteed-deals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidder-location: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookie-matching-nid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookie-matching-url: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximum-active-creatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximum-total-qps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --number-active-creatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "confirmUnsafeAccountChange" $confirm_unsafe_account_change "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}") $qp)
  let req_body = {"applyPretargetingToNonGuaranteedDeals": $apply_pretargeting_to_non_guaranteed_deals, "bidderLocation": $bidder_location, "cookieMatchingNid": $cookie_matching_nid, "cookieMatchingUrl": $cookie_matching_url, "id": $body_id, "kind": $kind, "maximumActiveCreatives": $maximum_active_creatives, "maximumTotalQps": $maximum_total_qps, "numberActiveCreatives": $number_active_creatives} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "confirmUnsafeAccountChange": $confirm_unsafe_account_change} | compact), body: $req_body}
}

# Updates an existing account.
#
# PUT /accounts/{id}
# operationId: adexchangebuyer.accounts.update
# --bidderLocation item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
export def "accounts update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --confirm-unsafe-account-change: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --apply-pretargeting-to-non-guaranteed-deals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidder-location: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookie-matching-nid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookie-matching-url: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximum-active-creatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximum-total-qps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --number-active-creatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "confirmUnsafeAccountChange" $confirm_unsafe_account_change "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}") $qp)
  let req_body = {"applyPretargetingToNonGuaranteedDeals": $apply_pretargeting_to_non_guaranteed_deals, "bidderLocation": $bidder_location, "cookieMatchingNid": $cookie_matching_nid, "cookieMatchingUrl": $cookie_matching_url, "id": $body_id, "kind": $kind, "maximumActiveCreatives": $maximum_active_creatives, "maximumTotalQps": $maximum_total_qps, "numberActiveCreatives": $number_active_creatives} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "confirmUnsafeAccountChange": $confirm_unsafe_account_change} | compact), body: $req_body}
}

# Retrieves a list of billing information for all accounts of the authenticated user.
#
# GET /billinginfo
# operationId: adexchangebuyer.billingInfo.list
export def "billinginfo list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<accountId: int, accountName: string, billingId: list, kind: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billinginfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns the billing information for one account specified by account ID.
#
# GET /billinginfo/{accountId}
# operationId: adexchangebuyer.billingInfo.get
export def "billinginfo list-1" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: int, accountName: string, billingId: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/billinginfo/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns the budget information for the adgroup specified by the accountId and billingId.
#
# GET /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.get
export def "billinginfo get" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($billing_id | is-empty) { error make --unspanned { msg: "path parameter 'billingId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), billing_id: (encode-path-segment $billing_id)} | format pattern "/billinginfo/{account_id}/{billing_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request. This method supports patch semantics.
#
# PATCH /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.patch
export def "billinginfo update-by-account-id-billing-id" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # The id of the account. This is required for get and update requests. (format: int64)
  --body-billing-id: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64)
  --budget-amount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currency-code: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($billing_id | is-empty) { error make --unspanned { msg: "path parameter 'billingId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), billing_id: (encode-path-segment $billing_id)} | format pattern "/billinginfo/{account_id}/{billing_id}") $qp)
  let req_body = {"accountId": $body_account_id, "billingId": $body_billing_id, "budgetAmount": $budget_amount, "currencyCode": $currency_code, "id": $id, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request.
#
# PUT /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.update
export def "billinginfo update-by-account-id-billing-id-1" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # The id of the account. This is required for get and update requests. (format: int64)
  --body-billing-id: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64)
  --budget-amount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currency-code: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($billing_id | is-empty) { error make --unspanned { msg: "path parameter 'billingId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), billing_id: (encode-path-segment $billing_id)} | format pattern "/billinginfo/{account_id}/{billing_id}") $qp)
  let req_body = {"accountId": $body_account_id, "billingId": $body_billing_id, "budgetAmount": $budget_amount, "currencyCode": $currency_code, "id": $id, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Retrieves a list of the authenticated user's active creatives. A creative will be available 30-40 minutes after submission.
#
# GET /creatives
# operationId: adexchangebuyer.creatives.list
export def "creatives list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-id: list<int> # When specified, only creatives for the given account ids are returned.
  --buyer-creative-id: list<string> # When specified, only creatives for the given buyer creative ids are returned.
  --deals-status-filter: string@deals-status-filter-completer # When specified, only creatives having the given deals status are returned.
  --max-results: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --open-auction-status-filter: string@open-auction-status-filter-completer # When specified, only creatives having the given open auction status are returned.
  --page-token: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> record<items: table<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserId: list, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list, buyerCreativeId: string, clickThroughUrl: list, corrections: list, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list, filteringReasons: record, height: int, impressionTrackingUrl: list, kind: string, languages: list, nativeAd: record, openAuctionStatus: string, productCategories: list, restrictedCategories: list, sensitiveCategories: list, servingRestrictions: list, vendorType: list, version: int, videoURL: string, videoVastXML: string, width: int>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "accountId" $account_id "multi") (serialize-qp "buyerCreativeId" $buyer_creative_id "multi") (serialize-qp "dealsStatusFilter" $deals_status_filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "openAuctionStatusFilter" $open_auction_status_filter "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/creatives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "accountId": $account_id, "buyerCreativeId": $buyer_creative_id, "dealsStatusFilter": $deals_status_filter, "maxResults": $max_results, "openAuctionStatusFilter": $open_auction_status_filter, "pageToken": $page_token} | compact), body: null}
}

# Submit a new creative.
#
# POST /creatives
# operationId: adexchangebuyer.creatives.insert
# --adTechnologyProviders shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list<string>, reason?: string}
# --filteringReasons shape: {date?: string, reasons?: list}
# --nativeAd shape: {advertiser?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, impressionTrackingUrl?: list<string>, logo?: record, price?: string, starRating?: float, videoURL?: string}
# --servingRestrictions item shape: {contexts?: list, disapprovalReasons?: list, reason?: string}
export def "creatives create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --html-snippet: string # The HTML snippet that displays the ad when inserted in the web page. If set, videoURL, videoVastXML, and nativeAd should not be set.
  --account-id: int # Account id. (format: int32)
  --ad-choices-destination-url: string # The link to the Ad Preferences page. This is only supported for native ads.
  --ad-technology-providers: record # shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
  --advertiser-id: list<string> # Detected advertiser id, if any. Read-only. This field should not be set in requests.
  --advertiser-name: string # The name of the company being advertised in the creative. A list of advertisers is provided in the advertisers.txt file.
  --agency-id: string # The agency id for this creative. (format: int64)
  --api-upload-timestamp: string # The last upload timestamp of this creative if it was uploaded via API. Read-only. The value of this field is generated, and will be ignored for uploads. (formatted RFC 3339 timestamp). (format: date-time)
  --attribute: list<int> # List of buyer selectable attributes for the ads that may be shown from this snippet. Each attribute is represented by an integer as defined in buyer-declarable-creative-attributes.txt.
  --buyer-creative-id: string # A buyer-specific id identifying the creative in this ad.
  --click-through-url: list<string> # The set of destination urls for the snippet.
  --corrections: list # Shows any corrections that were applied to this creative. Read-only. This field should not be set in requests. — item shape: {contexts?: list, details?: list<string>, reason?: string}
  --creative-status-identity-type: string # Creative status identity type that the creative item applies to. Ad Exchange real-time bidding is migrating to the sizeless creative verification. Originally, Ad Exchange assigned creative verification status to a unique combination of a buyer creative ID and creative dimensions. Post-migration, a single verification status will be assigned at the buyer creative ID level. This field allows to distinguish whether a given creative status applies to a unique combination of a buyer creative ID and creative dimensions, or to a buyer creative ID as a whole.
  --deals-status: string # Top-level deals status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=DIRECT_DEALS (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from servingRestrictions directly.
  --detected-domains: list<string> # Detected domains for this creative. Read-only. This field should not be set in requests.
  --filtering-reasons: record # The filtering reasons for the creative. Read-only. This field should not be set in requests. — shape: {date?: string, reasons?: list}
  --height: int # Ad height. (format: int32)
  --impression-tracking-url: list<string> # The set of urls to be called to record an impression.
  --kind: string # Resource type. (default: adexchangebuyer#creative)
  --languages: list<string> # Detected languages for this creative. Read-only. This field should not be set in requests.
  --native-ad: record # If nativeAd is set, HTMLSnippet, videoVastXML, and the videoURL outside of nativeAd should not be set. (The videoURL inside nativeAd can be set.) — shape: {advertiser?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, impressionTrackingUrl?: list<string>, logo?: record, price?: string, starRating?: float, videoURL?: string}
  --open-auction-status: string # Top-level open auction status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=OPEN_AUCTION (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from ServingRestrictions directly.
  --product-categories: list<int> # Detected product categories, if any. Each category is represented by an integer as defined in ad-product-categories.txt. Read-only. This field should not be set in requests.
  --restricted-categories: list<int> # All restricted categories for the ads that may be shown from this snippet. Each category is represented by an integer as defined in the ad-restricted-categories.txt.
  --sensitive-categories: list<int> # Detected sensitive categories, if any. Each category is represented by an integer as defined in ad-sensitive-categories.txt. Read-only. This field should not be set in requests.
  --serving-restrictions: list # The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS vs HTTP request, or the type of auction). Read-only. This field should not be set in requests. See the examples in the Creatives guide for more details. — item shape: {contexts?: list, disapprovalReasons?: list, reason?: string}
  --vendor-type: list<int> # List of vendor types for the ads that may be shown from this snippet. Each vendor type is represented by an integer as defined in vendors.txt.
  --version: int # The version for this creative. Read-only. This field should not be set in requests. (format: int32)
  --video-url: string # The URL to fetch a video ad. If set, HTMLSnippet, videoVastXML, and nativeAd should not be set. Note, this is different from resource.native_ad.video_url above.
  --video-vast-xml: string # The contents of a VAST document for a video ad. This document should conform to the VAST 2.0 or 3.0 standard. If set, HTMLSnippet, videoURL, and nativeAd and should not be set.
  --width: int # Ad width. (format: int32)
]: any -> record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/creatives" $qp)
  let req_body = {"HTMLSnippet": $html_snippet, "accountId": $account_id, "adChoicesDestinationUrl": $ad_choices_destination_url, "adTechnologyProviders": $ad_technology_providers, "advertiserId": $advertiser_id, "advertiserName": $advertiser_name, "agencyId": $agency_id, "apiUploadTimestamp": $api_upload_timestamp, "attribute": $attribute, "buyerCreativeId": $buyer_creative_id, "clickThroughUrl": $click_through_url, "corrections": $corrections, "creativeStatusIdentityType": $creative_status_identity_type, "dealsStatus": $deals_status, "detectedDomains": $detected_domains, "filteringReasons": $filtering_reasons, "height": $height, "impressionTrackingUrl": $impression_tracking_url, "kind": $kind, "languages": $languages, "nativeAd": $native_ad, "openAuctionStatus": $open_auction_status, "productCategories": $product_categories, "restrictedCategories": $restricted_categories, "sensitiveCategories": $sensitive_categories, "servingRestrictions": $serving_restrictions, "vendorType": $vendor_type, "version": $version, "videoURL": $video_url, "videoVastXML": $video_vast_xml, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Gets the status for a single creative. A creative will be available 30-40 minutes after submission.
#
# GET /creatives/{accountId}/{buyerCreativeId}
# operationId: adexchangebuyer.creatives.get
export def "creatives get" [
  account_id: int
  buyer_creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($buyer_creative_id | is-empty) { error make --unspanned { msg: "path parameter 'buyerCreativeId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), buyer_creative_id: (encode-path-segment $buyer_creative_id)} | format pattern "/creatives/{account_id}/{buyer_creative_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Add a deal id association for the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/addDeal/{dealId}
# operationId: adexchangebuyer.creatives.addDeal
export def "creatives-add-deal create" [
  account_id: int
  buyer_creative_id: string
  deal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($buyer_creative_id | is-empty) { error make --unspanned { msg: "path parameter 'buyerCreativeId' must be non-empty" } }
  if ($deal_id | is-empty) { error make --unspanned { msg: "path parameter 'dealId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), buyer_creative_id: (encode-path-segment $buyer_creative_id), deal_id: (encode-path-segment $deal_id)} | format pattern "/creatives/{account_id}/{buyer_creative_id}/addDeal/{deal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Lists the external deal ids associated with the creative.
#
# GET /creatives/{accountId}/{buyerCreativeId}/listDeals
# operationId: adexchangebuyer.creatives.listDeals
export def "creatives-list-deals list" [
  account_id: int
  buyer_creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<dealStatuses: table<arcStatus: string, dealId: string, webPropertyId: int>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($buyer_creative_id | is-empty) { error make --unspanned { msg: "path parameter 'buyerCreativeId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), buyer_creative_id: (encode-path-segment $buyer_creative_id)} | format pattern "/creatives/{account_id}/{buyer_creative_id}/listDeals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Remove a deal id associated with the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/removeDeal/{dealId}
# operationId: adexchangebuyer.creatives.removeDeal
export def "creatives-remove-deal delete" [
  account_id: int
  buyer_creative_id: string
  deal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($buyer_creative_id | is-empty) { error make --unspanned { msg: "path parameter 'buyerCreativeId' must be non-empty" } }
  if ($deal_id | is-empty) { error make --unspanned { msg: "path parameter 'dealId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), buyer_creative_id: (encode-path-segment $buyer_creative_id), deal_id: (encode-path-segment $deal_id)} | format pattern "/creatives/{account_id}/{buyer_creative_id}/removeDeal/{deal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Retrieves the authenticated user's list of performance metrics.
#
# GET /performancereport
# operationId: adexchangebuyer.performanceReport.list
export def "performancereport list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-id: string # The account id to get the reports.
  --end-date-time: string # The end time of the report in ISO 8601 timestamp format using UTC.
  --start-date-time: string # The start time of the report in ISO 8601 timestamp format using UTC.
  --max-results: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --page-token: string # A continuation token, used to page through performance reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> record<kind: string, performanceReport: table<bidRate: float, bidRequestRate: float, calloutStatusRate: list, cookieMatcherStatusRate: list, creativeStatusRate: list, filteredBidRate: float, hostedMatchStatusRate: list, inventoryMatchRate: float, kind: string, latency50thPercentile: float, latency85thPercentile: float, latency95thPercentile: float, noQuotaInRegion: float, outOfQuota: float, pixelMatchRequests: float, pixelMatchResponses: float, quotaConfiguredLimit: float, quotaThrottledLimit: float, region: string, successfulRequestRate: float, timestamp: string, unsuccessfulRequestRate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/performancereport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "accountId": $account_id, "endDateTime": $end_date_time, "startDateTime": $start_date_time, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Retrieves a list of the authenticated user's pretargeting configurations.
#
# GET /pretargetingconfigs/{accountId}
# operationId: adexchangebuyer.pretargetingConfig.list
export def "pretargetingconfigs list" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<billingId: string, configId: string, configName: string, creativeType: list, dimensions: list, excludedContentLabels: list, excludedGeoCriteriaIds: list, excludedPlacements: list, excludedUserLists: list, excludedVerticals: list, geoCriteriaIds: list, isActive: bool, kind: string, languages: list, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list, mobileDevices: list, mobileOperatingSystemVersions: list, placements: list, platforms: list, supportedCreativeAttributes: list, userIdentifierDataRequired: list, userLists: list, vendorTypes: list, verticals: list, videoPlayerSizes: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/pretargetingconfigs/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Inserts a new pretargeting configuration.
#
# POST /pretargetingconfigs/{accountId}
# operationId: adexchangebuyer.pretargetingConfig.insert
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs create" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/pretargetingconfigs/{account_id}") $qp)
  let req_body = {"billingId": $billing_id, "configId": $config_id, "configName": $config_name, "creativeType": $creative_type, "dimensions": $dimensions, "excludedContentLabels": $excluded_content_labels, "excludedGeoCriteriaIds": $excluded_geo_criteria_ids, "excludedPlacements": $excluded_placements, "excludedUserLists": $excluded_user_lists, "excludedVerticals": $excluded_verticals, "geoCriteriaIds": $geo_criteria_ids, "isActive": $is_active, "kind": $kind, "languages": $languages, "maximumQps": $maximum_qps, "minimumViewabilityDecile": $minimum_viewability_decile, "mobileCarriers": $mobile_carriers, "mobileDevices": $mobile_devices, "mobileOperatingSystemVersions": $mobile_operating_system_versions, "placements": $placements, "platforms": $platforms, "supportedCreativeAttributes": $supported_creative_attributes, "userIdentifierDataRequired": $user_identifier_data_required, "userLists": $user_lists, "vendorTypes": $vendor_types, "verticals": $verticals, "videoPlayerSizes": $video_player_sizes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Deletes an existing pretargeting config.
#
# DELETE /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.delete
export def "pretargetingconfigs delete" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($config_id | is-empty) { error make --unspanned { msg: "path parameter 'configId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), config_id: (encode-path-segment $config_id)} | format pattern "/pretargetingconfigs/{account_id}/{config_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets a specific pretargeting configuration
#
# GET /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.get
export def "pretargetingconfigs get" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($config_id | is-empty) { error make --unspanned { msg: "path parameter 'configId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), config_id: (encode-path-segment $config_id)} | format pattern "/pretargetingconfigs/{account_id}/{config_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates an existing pretargeting config. This method supports patch semantics.
#
# PATCH /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.patch
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs update-by-account-id-config-id" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($config_id | is-empty) { error make --unspanned { msg: "path parameter 'configId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), config_id: (encode-path-segment $config_id)} | format pattern "/pretargetingconfigs/{account_id}/{config_id}") $qp)
  let req_body = {"billingId": $billing_id, "configId": $body_config_id, "configName": $config_name, "creativeType": $creative_type, "dimensions": $dimensions, "excludedContentLabels": $excluded_content_labels, "excludedGeoCriteriaIds": $excluded_geo_criteria_ids, "excludedPlacements": $excluded_placements, "excludedUserLists": $excluded_user_lists, "excludedVerticals": $excluded_verticals, "geoCriteriaIds": $geo_criteria_ids, "isActive": $is_active, "kind": $kind, "languages": $languages, "maximumQps": $maximum_qps, "minimumViewabilityDecile": $minimum_viewability_decile, "mobileCarriers": $mobile_carriers, "mobileDevices": $mobile_devices, "mobileOperatingSystemVersions": $mobile_operating_system_versions, "placements": $placements, "platforms": $platforms, "supportedCreativeAttributes": $supported_creative_attributes, "userIdentifierDataRequired": $user_identifier_data_required, "userLists": $user_lists, "vendorTypes": $vendor_types, "verticals": $verticals, "videoPlayerSizes": $video_player_sizes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Updates an existing pretargeting config.
#
# PUT /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.update
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs update-by-account-id-config-id-1" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($config_id | is-empty) { error make --unspanned { msg: "path parameter 'configId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), config_id: (encode-path-segment $config_id)} | format pattern "/pretargetingconfigs/{account_id}/{config_id}") $qp)
  let req_body = {"billingId": $billing_id, "configId": $body_config_id, "configName": $config_name, "creativeType": $creative_type, "dimensions": $dimensions, "excludedContentLabels": $excluded_content_labels, "excludedGeoCriteriaIds": $excluded_geo_criteria_ids, "excludedPlacements": $excluded_placements, "excludedUserLists": $excluded_user_lists, "excludedVerticals": $excluded_verticals, "geoCriteriaIds": $geo_criteria_ids, "isActive": $is_active, "kind": $kind, "languages": $languages, "maximumQps": $maximum_qps, "minimumViewabilityDecile": $minimum_viewability_decile, "mobileCarriers": $mobile_carriers, "mobileDevices": $mobile_devices, "mobileOperatingSystemVersions": $mobile_operating_system_versions, "placements": $placements, "platforms": $platforms, "supportedCreativeAttributes": $supported_creative_attributes, "userIdentifierDataRequired": $user_identifier_data_required, "userLists": $user_lists, "vendorTypes": $vendor_types, "verticals": $verticals, "videoPlayerSizes": $video_player_sizes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Update a given private auction proposal
#
# POST /privateauction/{privateAuctionId}/updateproposal
# operationId: adexchangebuyer.marketplaceprivateauction.updateproposal
# --note shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
export def "privateauction-update-proposal update" [
  private_auction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --external-deal-id: string # The externalDealId of the deal to be updated.
  --note: record # A proposal is associated with a bunch of notes which may optionally be associated with a deal and/or revision number. — shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
  --proposal-revision-number: string # The current revision number of the proposal to be updated. (format: int64)
  --update-action: string # The proposed action on the private auction proposal.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($private_auction_id | is-empty) { error make --unspanned { msg: "path parameter 'privateAuctionId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({private_auction_id: (encode-path-segment $private_auction_id)} | format pattern "/privateauction/{private_auction_id}/updateproposal") $qp)
  let req_body = {"externalDealId": $external_deal_id, "note": $note, "proposalRevisionNumber": $proposal_revision_number, "updateAction": $update_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Gets the requested product.
#
# GET /products/search
# operationId: adexchangebuyer.products.search
export def "products-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # The pql query used to query for products.
]: nothing -> record<products: table<billedBuyer: record, buyer: record, creationTimeMs: string, creatorContacts: list, creatorRole: string, deliveryControl: record, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: list, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record, revisionNumber: string, seller: record, sharedTargetings: list, state: string, syndicationProduct: string, terms: record, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "pqlQuery" $pql_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "pqlQuery": $pql_query} | compact), body: null}
}

# Gets the requested product by id.
#
# GET /products/{productId}
# operationId: adexchangebuyer.products.get
export def "products get" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, creationTimeMs: string, creatorContacts: table<email: string, name: string>, creatorRole: string, deliveryControl: record<creativeBlockingLevel: string, deliveryRateType: string, frequencyCaps: list<record>>, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record<dimensions: list<record>, weeklyImpressions: string, weeklyUniques: string>, revisionNumber: string, seller: record<accountId: string, subAccountId: string>, sharedTargetings: table<exclusions: list, inclusions: list, key: string>, state: string, syndicationProduct: string, terms: record<brandingType: string, crossListedExternalDealIdType: string, description: string, estimatedGrossSpend: record<amountMicros: float, currencyCode: string, expectedCpmMicros: float, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<billingInfo: record, fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, minimumDailyLooks: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricePerBuyers: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, rubiconNonGuaranteedTerms: record<priorityPrice: record, standardPrice: record>, sellerTimeZone: string>, webPropertyCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Create the given list of proposals
#
# POST /proposals/insert
# operationId: adexchangebuyer.proposals.insert
# --proposals item shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
export def "proposals-insert create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --proposals: list # The list of proposals to create. — item shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
  --web-property-code: string # Web property id of the seller creating these orders
]: any -> record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proposals/insert" $qp)
  let req_body = {"proposals": $proposals, "webPropertyCode": $web_property_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Search for proposals using pql query
#
# GET /proposals/search
# operationId: adexchangebuyer.proposals.search
export def "proposals-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific proposals.
]: nothing -> record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "pqlQuery" $pql_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proposals/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "pqlQuery": $pql_query} | compact), body: null}
}

# Get a proposal given its id
#
# GET /proposals/{proposalId}
# operationId: adexchangebuyer.proposals.get
export def "proposals get" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all the deals for a given proposal
#
# GET /proposals/{proposalId}/deals
# operationId: adexchangebuyer.marketplacedeals.list
export def "proposals-deals list" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific deals.
]: nothing -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "pqlQuery" $pql_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/deals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "pqlQuery": $pql_query} | compact), body: null}
}

# Delete the specified deals from the proposal
#
# POST /proposals/{proposalId}/deals/delete
# operationId: adexchangebuyer.marketplacedeals.delete
export def "proposals-deals-delete delete" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deal-ids: list<string> # List of deals to delete for a given proposal
  --proposal-revision-number: string # The last known proposal revision number. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/deals/delete") $qp)
  let req_body = {"dealIds": $deal_ids, "proposalRevisionNumber": $proposal_revision_number, "updateAction": $update_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Add new deals for the specified proposal
#
# POST /proposals/{proposalId}/deals/insert
# operationId: adexchangebuyer.marketplacedeals.insert
# --deals item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
export def "proposals-deals-insert create" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deals: list # The list of deals to add — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
  --proposal-revision-number: string # The last known proposal revision number. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/deals/insert") $qp)
  let req_body = {"deals": $deals, "proposalRevisionNumber": $proposal_revision_number, "updateAction": $update_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Replaces all the deals in the proposal with the passed in deals
#
# POST /proposals/{proposalId}/deals/update
# operationId: adexchangebuyer.marketplacedeals.update
# --deals item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
# --proposal shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
export def "proposals-deals-update update" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deals: list # List of deals to edit. Service may perform 3 different operations based on comparison of deals in this list vs deals already persisted in database: 1. Add new deal to proposal If a deal in this list does not exist in the proposal, the service will create a new deal and add it to the proposal. Validation will follow AddOrderDealsRequest. 2. Update existing deal in the proposal If a deal in this list already exist in the proposal, the service will update that existing deal to this new deal in the request. Validation will follow UpdateOrderDealsRequest. 3. Delete deals from the proposal (just need the id) If a existing deal in the proposal is not present in this list, the service will delete that deal from the proposal. Validation will follow DeleteOrderDealsRequest. — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
  --proposal: record # Represents a proposal in the marketplace. A proposal is the unit of negotiation between a seller and a buyer and contains deals which are served. Each field in a proposal can have one of the following setting: (readonly) - It is an error to try and set this field. (buyer-readonly) - Only the seller can set this field. (seller-readonly) - Only the buyer can set this field. (updatable) - The field is updatable at all times by either buyer or the seller. — shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
  --proposal-revision-number: string # The last known revision number for the proposal. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, orderRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/deals/update") $qp)
  let req_body = {"deals": $deals, "proposal": $proposal, "proposalRevisionNumber": $proposal_revision_number, "updateAction": $update_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Get all the notes associated with a proposal
#
# GET /proposals/{proposalId}/notes
# operationId: adexchangebuyer.marketplacenotes.list
export def "proposals-notes list" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific notes. To search the text contents of notes, please use syntax like "WHERE note.note = "foo" or "WHERE note.note LIKE "%bar%"
]: nothing -> record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "pqlQuery" $pql_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/notes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "pqlQuery": $pql_query} | compact), body: null}
}

# Add notes to the proposal
#
# POST /proposals/{proposalId}/notes/insert
# operationId: adexchangebuyer.marketplacenotes.insert
# --notes item shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
export def "proposals-notes-insert create" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --notes: list # The list of notes to add. — item shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
]: any -> record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/notes/insert") $qp)
  let req_body = {"notes": $notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Update the given proposal to indicate that setup has been completed.
#
# POST /proposals/{proposalId}/setupcomplete
# operationId: adexchangebuyer.proposals.setupcomplete
export def "proposals-setupcomplete create" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id)} | format pattern "/proposals/{proposal_id}/setupcomplete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Update the given proposal. This method supports patch semantics.
#
# PATCH /proposals/{proposalId}/{revisionNumber}/{updateAction}
# operationId: adexchangebuyer.proposals.patch
# --billedBuyer shape: {accountId?: string}
# --buyer shape: {accountId?: string}
# --buyerContacts item shape: {email?: string, name?: string}
# --buyerPrivateData shape: {referenceId?: string, referencePayload?: string}
# --labels item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
# --seller shape: {accountId?: string, subAccountId?: string}
# --sellerContacts item shape: {email?: string, name?: string}
export def "proposals update-by-proposal-id-revision-number-update-action" [
  proposal_id: string
  revision_number: string
  update_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billed-buyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyer-contacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyer-private-data: record # shape: {referenceId?: string, referencePayload?: string}
  --dbm-advertiser-ids: list<string> # IDs of DBM advertisers permission to this proposal.
  --has-buyer-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --has-seller-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventory-source: string # What exchange will provide this inventory (readonly, except on create).
  --is-renegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --is-setup-complete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --last-updater-or-commentor-role: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiation-id: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originator-role: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --private-auction-id: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposal-id: string # The unique id of the proposal. (readonly).
  --proposal-state: string # The current state of the proposal. (readonly)
  --body-revision-number: string # The revision number for the proposal (readonly). (format: int64)
  --revision-time-ms: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --seller-contacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'revisionNumber' must be non-empty" } }
  if ($update_action | is-empty) { error make --unspanned { msg: "path parameter 'updateAction' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id), revision_number: (encode-path-segment $revision_number), update_action: (encode-path-segment $update_action)} | format pattern "/proposals/{proposal_id}/{revision_number}/{update_action}") $qp)
  let req_body = {"billedBuyer": $billed_buyer, "buyer": $buyer, "buyerContacts": $buyer_contacts, "buyerPrivateData": $buyer_private_data, "dbmAdvertiserIds": $dbm_advertiser_ids, "hasBuyerSignedOff": $has_buyer_signed_off, "hasSellerSignedOff": $has_seller_signed_off, "inventorySource": $inventory_source, "isRenegotiating": $is_renegotiating, "isSetupComplete": $is_setup_complete, "kind": $kind, "labels": $labels, "lastUpdaterOrCommentorRole": $last_updater_or_commentor_role, "name": $name, "negotiationId": $negotiation_id, "originatorRole": $originator_role, "privateAuctionId": $private_auction_id, "proposalId": $body_proposal_id, "proposalState": $proposal_state, "revisionNumber": $body_revision_number, "revisionTimeMs": $revision_time_ms, "seller": $seller, "sellerContacts": $seller_contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Update the given proposal
#
# PUT /proposals/{proposalId}/{revisionNumber}/{updateAction}
# operationId: adexchangebuyer.proposals.update
# --billedBuyer shape: {accountId?: string}
# --buyer shape: {accountId?: string}
# --buyerContacts item shape: {email?: string, name?: string}
# --buyerPrivateData shape: {referenceId?: string, referencePayload?: string}
# --labels item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
# --seller shape: {accountId?: string, subAccountId?: string}
# --sellerContacts item shape: {email?: string, name?: string}
export def "proposals update-by-proposal-id-revision-number-update-action-1" [
  proposal_id: string
  revision_number: string
  update_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billed-buyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyer-contacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyer-private-data: record # shape: {referenceId?: string, referencePayload?: string}
  --dbm-advertiser-ids: list<string> # IDs of DBM advertisers permission to this proposal.
  --has-buyer-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --has-seller-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventory-source: string # What exchange will provide this inventory (readonly, except on create).
  --is-renegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --is-setup-complete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --last-updater-or-commentor-role: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiation-id: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originator-role: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --private-auction-id: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposal-id: string # The unique id of the proposal. (readonly).
  --proposal-state: string # The current state of the proposal. (readonly)
  --body-revision-number: string # The revision number for the proposal (readonly). (format: int64)
  --revision-time-ms: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --seller-contacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proposal_id | is-empty) { error make --unspanned { msg: "path parameter 'proposalId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'revisionNumber' must be non-empty" } }
  if ($update_action | is-empty) { error make --unspanned { msg: "path parameter 'updateAction' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proposal_id: (encode-path-segment $proposal_id), revision_number: (encode-path-segment $revision_number), update_action: (encode-path-segment $update_action)} | format pattern "/proposals/{proposal_id}/{revision_number}/{update_action}") $qp)
  let req_body = {"billedBuyer": $billed_buyer, "buyer": $buyer, "buyerContacts": $buyer_contacts, "buyerPrivateData": $buyer_private_data, "dbmAdvertiserIds": $dbm_advertiser_ids, "hasBuyerSignedOff": $has_buyer_signed_off, "hasSellerSignedOff": $has_seller_signed_off, "inventorySource": $inventory_source, "isRenegotiating": $is_renegotiating, "isSetupComplete": $is_setup_complete, "kind": $kind, "labels": $labels, "lastUpdaterOrCommentorRole": $last_updater_or_commentor_role, "name": $name, "negotiationId": $negotiation_id, "originatorRole": $originator_role, "privateAuctionId": $private_auction_id, "proposalId": $body_proposal_id, "proposalState": $proposal_state, "revisionNumber": $body_revision_number, "revisionTimeMs": $revision_time_ms, "seller": $seller, "sellerContacts": $seller_contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Gets the requested publisher profile(s) by publisher accountId.
#
# GET /publisher/{accountId}/profiles
# operationId: adexchangebuyer.pubprofiles.list
export def "publisher-profiles list" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<profiles: table<audience: string, buyerPitchStatement: string, directContact: string, exchange: string, forecastInventory: string, googlePlusLink: string, isParent: bool, isPublished: bool, kind: string, logoUrl: string, mediaKitLink: string, name: string, overview: string, profileId: int, programmaticContact: string, publisherAppIds: list, publisherApps: list, publisherDomains: list, publisherProfileId: string, publisherProvidedForecast: record, rateCardInfoLink: string, samplePageLink: string, seller: record, state: string, topHeadlines: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/publisher/{account_id}/profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}
