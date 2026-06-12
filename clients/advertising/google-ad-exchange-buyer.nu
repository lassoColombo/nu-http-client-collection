# Auto-generated client for Ad Exchange Buyer API vv1.4
# Source: https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer/v1.4/openapi.json
# Auth: --token flag or $env.AD_EXCHANGE_BUYER_API_TOKEN

const BASE_URL = "https://www.googleapis.com/adexchangebuyer/v1.4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AD_EXCHANGE_BUYER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/adexchangebuyer/v1.4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def dealsStatusFilter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }
def openAuctionStatusFilter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts adexchangebuyeraccountslist" } } | get name | first)
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
export def "accounts adexchangebuyeraccountslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: list, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets one account by ID.
#
# GET /accounts/{id}
# operationId: adexchangebuyer.accounts.get
export def "accounts adexchangebuyeraccountsget" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing account. This method supports patch semantics.
#
# PATCH /accounts/{id}
# operationId: adexchangebuyer.accounts.patch
# --bidderLocation item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
export def "accounts adexchangebuyeraccountspatch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --confirmUnsafeAccountChange: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --applyPretargetingToNonGuaranteedDeals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidderLocation: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookieMatchingNid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookieMatchingUrl: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximumActiveCreatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximumTotalQps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --numberActiveCreatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "confirmUnsafeAccountChange" $confirmUnsafeAccountChange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($id)" $qp)
  let body = {applyPretargetingToNonGuaranteedDeals: $applyPretargetingToNonGuaranteedDeals, bidderLocation: $bidderLocation, cookieMatchingNid: $cookieMatchingNid, cookieMatchingUrl: $cookieMatchingUrl, id: $body_id, kind: $kind, maximumActiveCreatives: $maximumActiveCreatives, maximumTotalQps: $maximumTotalQps, numberActiveCreatives: $numberActiveCreatives} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing account.
#
# PUT /accounts/{id}
# operationId: adexchangebuyer.accounts.update
# --bidderLocation item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
export def "accounts adexchangebuyeraccountsupdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --confirmUnsafeAccountChange: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --applyPretargetingToNonGuaranteedDeals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidderLocation: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookieMatchingNid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookieMatchingUrl: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximumActiveCreatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximumTotalQps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --numberActiveCreatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "confirmUnsafeAccountChange" $confirmUnsafeAccountChange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($id)" $qp)
  let body = {applyPretargetingToNonGuaranteedDeals: $applyPretargetingToNonGuaranteedDeals, bidderLocation: $bidderLocation, cookieMatchingNid: $cookieMatchingNid, cookieMatchingUrl: $cookieMatchingUrl, id: $body_id, kind: $kind, maximumActiveCreatives: $maximumActiveCreatives, maximumTotalQps: $maximumTotalQps, numberActiveCreatives: $numberActiveCreatives} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of billing information for all accounts of the authenticated user.
#
# GET /billinginfo
# operationId: adexchangebuyer.billingInfo.list
export def "billinginfo adexchangebuyerbillingInfolist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<accountId: int, accountName: string, billingId: list, kind: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billinginfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the billing information for one account specified by account ID.
#
# GET /billinginfo/{accountId}
# operationId: adexchangebuyer.billingInfo.get
export def "billinginfo adexchangebuyerbillingInfoget" [
  accountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: int, accountName: string, billingId: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billinginfo/($accountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the budget information for the adgroup specified by the accountId and billingId.
#
# GET /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.get
export def "billinginfo adexchangebuyerbudgetget" [
  accountId: string
  billingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billinginfo/($accountId)/($billingId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request. This method supports patch semantics.
#
# PATCH /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.patch
export def "billinginfo adexchangebuyerbudgetpatch" [
  accountId: string
  billingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --body-accountId: string # The id of the account. This is required for get and update requests. (format: int64)
  --body-billingId: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64)
  --budgetAmount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currencyCode: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billinginfo/($accountId)/($billingId)" $qp)
  let body = {accountId: $body_accountId, billingId: $body_billingId, budgetAmount: $budgetAmount, currencyCode: $currencyCode, id: $id, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request.
#
# PUT /billinginfo/{accountId}/{billingId}
# operationId: adexchangebuyer.budget.update
export def "billinginfo adexchangebuyerbudgetupdate" [
  accountId: string
  billingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --body-accountId: string # The id of the account. This is required for get and update requests. (format: int64)
  --body-billingId: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64)
  --budgetAmount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currencyCode: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billinginfo/($accountId)/($billingId)" $qp)
  let body = {accountId: $body_accountId, billingId: $body_billingId, budgetAmount: $budgetAmount, currencyCode: $currencyCode, id: $id, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of the authenticated user's active creatives. A creative will be available 30-40 minutes after submission.
#
# GET /creatives
# operationId: adexchangebuyer.creatives.list
export def "creatives adexchangebuyercreativeslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --accountId: list # When specified, only creatives for the given account ids are returned.
  --buyerCreativeId: list # When specified, only creatives for the given buyer creative ids are returned.
  --dealsStatusFilter: string@dealsStatusFilter-completer # When specified, only creatives having the given deals status are returned.
  --maxResults: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --openAuctionStatusFilter: string@openAuctionStatusFilter-completer # When specified, only creatives having the given open auction status are returned.
  --pageToken: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> record<items: table<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserId: list, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list, buyerCreativeId: string, clickThroughUrl: list, corrections: list, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list, filteringReasons: record, height: int, impressionTrackingUrl: list, kind: string, languages: list, nativeAd: record, openAuctionStatus: string, productCategories: list, restrictedCategories: list, sensitiveCategories: list, servingRestrictions: list, vendorType: list, version: int, videoURL: string, videoVastXML: string, width: int>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "accountId" $accountId "multi") (serialize-qp "buyerCreativeId" $buyerCreativeId "multi") (serialize-qp "dealsStatusFilter" $dealsStatusFilter "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "openAuctionStatusFilter" $openAuctionStatusFilter "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/creatives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit a new creative.
#
# POST /creatives
# operationId: adexchangebuyer.creatives.insert
# --adTechnologyProviders shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
# --corrections item shape: {contexts?: list, details?: list, reason?: string}
# --filteringReasons shape: {date?: string, reasons?: list}
# --nativeAd shape: {advertiser?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, impressionTrackingUrl?: list, logo?: record, price?: string, starRating?: float, videoURL?: string}
# --servingRestrictions item shape: {contexts?: list, disapprovalReasons?: list, reason?: string}
export def "creatives adexchangebuyercreativesinsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --HTMLSnippet: string # The HTML snippet that displays the ad when inserted in the web page. If set, videoURL, videoVastXML, and nativeAd should not be set.
  --accountId: int # Account id. (format: int32)
  --adChoicesDestinationUrl: string # The link to the Ad Preferences page. This is only supported for native ads.
  --adTechnologyProviders: record # shape: {detectedProviderIds?: list, hasUnidentifiedProvider?: bool}
  --advertiserId: list # Detected advertiser id, if any. Read-only. This field should not be set in requests.
  --advertiserName: string # The name of the company being advertised in the creative. A list of advertisers is provided in the advertisers.txt file.
  --agencyId: string # The agency id for this creative. (format: int64)
  --apiUploadTimestamp: string # The last upload timestamp of this creative if it was uploaded via API. Read-only. The value of this field is generated, and will be ignored for uploads. (formatted RFC 3339 timestamp). (format: date-time)
  --attribute: list # List of buyer selectable attributes for the ads that may be shown from this snippet. Each attribute is represented by an integer as defined in  buyer-declarable-creative-attributes.txt.
  --buyerCreativeId: string # A buyer-specific id identifying the creative in this ad.
  --clickThroughUrl: list # The set of destination urls for the snippet.
  --corrections: list # Shows any corrections that were applied to this creative. Read-only. This field should not be set in requests. — item shape: {contexts?: list, details?: list, reason?: string}
  --creativeStatusIdentityType: string # Creative status identity type that the creative item applies to. Ad Exchange real-time bidding is migrating to the sizeless creative verification. Originally, Ad Exchange assigned creative verification status to a unique combination of a buyer creative ID and creative dimensions. Post-migration, a single verification status will be assigned at the buyer creative ID level. This field allows to distinguish whether a given creative status applies to a unique combination of a buyer creative ID and creative dimensions, or to a buyer creative ID as a whole.
  --dealsStatus: string # Top-level deals status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=DIRECT_DEALS (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from servingRestrictions directly.
  --detectedDomains: list # Detected domains for this creative. Read-only. This field should not be set in requests.
  --filteringReasons: record # The filtering reasons for the creative. Read-only. This field should not be set in requests. — shape: {date?: string, reasons?: list}
  --height: int # Ad height. (format: int32)
  --impressionTrackingUrl: list # The set of urls to be called to record an impression.
  --kind: string # Resource type. (default: adexchangebuyer#creative)
  --languages: list # Detected languages for this creative. Read-only. This field should not be set in requests.
  --nativeAd: record # If nativeAd is set, HTMLSnippet, videoVastXML, and the videoURL outside of nativeAd should not be set. (The videoURL inside nativeAd can be set.) — shape: {advertiser?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, impressionTrackingUrl?: list, logo?: record, price?: string, starRating?: float, videoURL?: string}
  --openAuctionStatus: string # Top-level open auction status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=OPEN_AUCTION (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from ServingRestrictions directly.
  --productCategories: list # Detected product categories, if any. Each category is represented by an integer as defined in  ad-product-categories.txt. Read-only. This field should not be set in requests.
  --restrictedCategories: list # All restricted categories for the ads that may be shown from this snippet. Each category is represented by an integer as defined in the  ad-restricted-categories.txt.
  --sensitiveCategories: list # Detected sensitive categories, if any. Each category is represented by an integer as defined in  ad-sensitive-categories.txt. Read-only. This field should not be set in requests.
  --servingRestrictions: list # The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS vs HTTP request, or the type of auction). Read-only. This field should not be set in requests. See the examples in the Creatives guide for more details. — item shape: {contexts?: list, disapprovalReasons?: list, reason?: string}
  --vendorType: list # List of vendor types for the ads that may be shown from this snippet. Each vendor type is represented by an integer as defined in vendors.txt.
  --version: int # The version for this creative. Read-only. This field should not be set in requests. (format: int32)
  --videoURL: string # The URL to fetch a video ad. If set, HTMLSnippet, videoVastXML, and nativeAd should not be set. Note, this is different from resource.native_ad.video_url above.
  --videoVastXML: string # The contents of a VAST document for a video ad. This document should conform to the VAST 2.0 or 3.0 standard. If set, HTMLSnippet, videoURL, and nativeAd and should not be set.
  --width: int # Ad width. (format: int32)
]: any -> record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/creatives" $qp)
  let body = {HTMLSnippet: $HTMLSnippet, accountId: $accountId, adChoicesDestinationUrl: $adChoicesDestinationUrl, adTechnologyProviders: $adTechnologyProviders, advertiserId: $advertiserId, advertiserName: $advertiserName, agencyId: $agencyId, apiUploadTimestamp: $apiUploadTimestamp, attribute: $attribute, buyerCreativeId: $buyerCreativeId, clickThroughUrl: $clickThroughUrl, corrections: $corrections, creativeStatusIdentityType: $creativeStatusIdentityType, dealsStatus: $dealsStatus, detectedDomains: $detectedDomains, filteringReasons: $filteringReasons, height: $height, impressionTrackingUrl: $impressionTrackingUrl, kind: $kind, languages: $languages, nativeAd: $nativeAd, openAuctionStatus: $openAuctionStatus, productCategories: $productCategories, restrictedCategories: $restrictedCategories, sensitiveCategories: $sensitiveCategories, servingRestrictions: $servingRestrictions, vendorType: $vendorType, version: $version, videoURL: $videoURL, videoVastXML: $videoVastXML, width: $width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the status for a single creative. A creative will be available 30-40 minutes after submission.
#
# GET /creatives/{accountId}/{buyerCreativeId}
# operationId: adexchangebuyer.creatives.get
export def "creatives adexchangebuyercreativesget" [
  accountId: int
  buyerCreativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/creatives/($accountId)/($buyerCreativeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a deal id association for the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/addDeal/{dealId}
# operationId: adexchangebuyer.creatives.addDeal
export def "creatives-add-deal adexchangebuyercreativesaddDeal" [
  accountId: int
  buyerCreativeId: string
  dealId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/creatives/($accountId)/($buyerCreativeId)/addDeal/($dealId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the external deal ids associated with the creative.
#
# GET /creatives/{accountId}/{buyerCreativeId}/listDeals
# operationId: adexchangebuyer.creatives.listDeals
export def "creatives-list-deals adexchangebuyercreativeslistDeals" [
  accountId: int
  buyerCreativeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<dealStatuses: table<arcStatus: string, dealId: string, webPropertyId: int>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/creatives/($accountId)/($buyerCreativeId)/listDeals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a deal id associated with the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/removeDeal/{dealId}
# operationId: adexchangebuyer.creatives.removeDeal
export def "creatives-remove-deal adexchangebuyercreativesremoveDeal" [
  accountId: int
  buyerCreativeId: string
  dealId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/creatives/($accountId)/($buyerCreativeId)/removeDeal/($dealId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the authenticated user's list of performance metrics.
#
# GET /performancereport
# operationId: adexchangebuyer.performanceReport.list
export def "performancereport adexchangebuyerperformanceReportlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --accountId: string # The account id to get the reports.
  --endDateTime: string # The end time of the report in ISO 8601 timestamp format using UTC.
  --startDateTime: string # The start time of the report in ISO 8601 timestamp format using UTC.
  --maxResults: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --pageToken: string # A continuation token, used to page through performance reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> record<kind: string, performanceReport: table<bidRate: float, bidRequestRate: float, calloutStatusRate: list, cookieMatcherStatusRate: list, creativeStatusRate: list, filteredBidRate: float, hostedMatchStatusRate: list, inventoryMatchRate: float, kind: string, latency50thPercentile: float, latency85thPercentile: float, latency95thPercentile: float, noQuotaInRegion: float, outOfQuota: float, pixelMatchRequests: float, pixelMatchResponses: float, quotaConfiguredLimit: float, quotaThrottledLimit: float, region: string, successfulRequestRate: float, timestamp: string, unsuccessfulRequestRate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "accountId" $accountId "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/performancereport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of the authenticated user's pretargeting configurations.
#
# GET /pretargetingconfigs/{accountId}
# operationId: adexchangebuyer.pretargetingConfig.list
export def "pretargetingconfigs adexchangebuyerpretargetingConfiglist" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<billingId: string, configId: string, configName: string, creativeType: list, dimensions: list, excludedContentLabels: list, excludedGeoCriteriaIds: list, excludedPlacements: list, excludedUserLists: list, excludedVerticals: list, geoCriteriaIds: list, isActive: bool, kind: string, languages: list, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list, mobileDevices: list, mobileOperatingSystemVersions: list, placements: list, platforms: list, supportedCreativeAttributes: list, userIdentifierDataRequired: list, userLists: list, vendorTypes: list, verticals: list, videoPlayerSizes: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inserts a new pretargeting configuration.
#
# POST /pretargetingconfigs/{accountId}
# operationId: adexchangebuyer.pretargetingConfig.insert
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs adexchangebuyerpretargetingConfiginsert" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --billingId: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --configId: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --configName: string # The name of the config. Must be unique. Required for all requests.
  --creativeType: list # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excludedContentLabels: list # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excludedGeoCriteriaIds: list # Requests containing any of these geo criteria ids will not match.
  --excludedPlacements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excludedUserLists: list # Requests containing any of these users list ids will not match.
  --excludedVerticals: list # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geoCriteriaIds: list # Requests containing any of these geo criteria ids will match.
  --isActive: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list # Request containing any of these language codes will match.
  --maximumQps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimumViewabilityDecile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobileCarriers: list # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobileDevices: list # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobileOperatingSystemVersions: list # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supportedCreativeAttributes: list # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --userIdentifierDataRequired: list # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --userLists: list # Requests containing any of these user list ids will match.
  --vendorTypes: list # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list # Requests containing any of these vertical ids will match.
  --videoPlayerSizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)" $qp)
  let body = {billingId: $billingId, configId: $configId, configName: $configName, creativeType: $creativeType, dimensions: $dimensions, excludedContentLabels: $excludedContentLabels, excludedGeoCriteriaIds: $excludedGeoCriteriaIds, excludedPlacements: $excludedPlacements, excludedUserLists: $excludedUserLists, excludedVerticals: $excludedVerticals, geoCriteriaIds: $geoCriteriaIds, isActive: $isActive, kind: $kind, languages: $languages, maximumQps: $maximumQps, minimumViewabilityDecile: $minimumViewabilityDecile, mobileCarriers: $mobileCarriers, mobileDevices: $mobileDevices, mobileOperatingSystemVersions: $mobileOperatingSystemVersions, placements: $placements, platforms: $platforms, supportedCreativeAttributes: $supportedCreativeAttributes, userIdentifierDataRequired: $userIdentifierDataRequired, userLists: $userLists, vendorTypes: $vendorTypes, verticals: $verticals, videoPlayerSizes: $videoPlayerSizes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an existing pretargeting config.
#
# DELETE /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.delete
export def "pretargetingconfigs adexchangebuyerpretargetingConfigdelete" [
  accountId: string
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)/($configId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific pretargeting configuration
#
# GET /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.get
export def "pretargetingconfigs adexchangebuyerpretargetingConfigget" [
  accountId: string
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)/($configId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing pretargeting config. This method supports patch semantics.
#
# PATCH /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.patch
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs adexchangebuyerpretargetingConfigpatch" [
  accountId: string
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --billingId: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-configId: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --configName: string # The name of the config. Must be unique. Required for all requests.
  --creativeType: list # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excludedContentLabels: list # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excludedGeoCriteriaIds: list # Requests containing any of these geo criteria ids will not match.
  --excludedPlacements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excludedUserLists: list # Requests containing any of these users list ids will not match.
  --excludedVerticals: list # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geoCriteriaIds: list # Requests containing any of these geo criteria ids will match.
  --isActive: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list # Request containing any of these language codes will match.
  --maximumQps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimumViewabilityDecile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobileCarriers: list # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobileDevices: list # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobileOperatingSystemVersions: list # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supportedCreativeAttributes: list # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --userIdentifierDataRequired: list # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --userLists: list # Requests containing any of these user list ids will match.
  --vendorTypes: list # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list # Requests containing any of these vertical ids will match.
  --videoPlayerSizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)/($configId)" $qp)
  let body = {billingId: $billingId, configId: $body_configId, configName: $configName, creativeType: $creativeType, dimensions: $dimensions, excludedContentLabels: $excludedContentLabels, excludedGeoCriteriaIds: $excludedGeoCriteriaIds, excludedPlacements: $excludedPlacements, excludedUserLists: $excludedUserLists, excludedVerticals: $excludedVerticals, geoCriteriaIds: $geoCriteriaIds, isActive: $isActive, kind: $kind, languages: $languages, maximumQps: $maximumQps, minimumViewabilityDecile: $minimumViewabilityDecile, mobileCarriers: $mobileCarriers, mobileDevices: $mobileDevices, mobileOperatingSystemVersions: $mobileOperatingSystemVersions, placements: $placements, platforms: $platforms, supportedCreativeAttributes: $supportedCreativeAttributes, userIdentifierDataRequired: $userIdentifierDataRequired, userLists: $userLists, vendorTypes: $vendorTypes, verticals: $verticals, videoPlayerSizes: $videoPlayerSizes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing pretargeting config.
#
# PUT /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.update
# --dimensions item shape: {height?: string, width?: string}
# --excludedPlacements item shape: {token?: string, type?: string}
# --placements item shape: {token?: string, type?: string}
# --videoPlayerSizes item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
export def "pretargetingconfigs adexchangebuyerpretargetingConfigupdate" [
  accountId: string
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --billingId: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-configId: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --configName: string # The name of the config. Must be unique. Required for all requests.
  --creativeType: list # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excludedContentLabels: list # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excludedGeoCriteriaIds: list # Requests containing any of these geo criteria ids will not match.
  --excludedPlacements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excludedUserLists: list # Requests containing any of these users list ids will not match.
  --excludedVerticals: list # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geoCriteriaIds: list # Requests containing any of these geo criteria ids will match.
  --isActive: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list # Request containing any of these language codes will match.
  --maximumQps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimumViewabilityDecile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobileCarriers: list # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobileDevices: list # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobileOperatingSystemVersions: list # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supportedCreativeAttributes: list # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --userIdentifierDataRequired: list # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --userLists: list # Requests containing any of these user list ids will match.
  --vendorTypes: list # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list # Requests containing any of these vertical ids will match.
  --videoPlayerSizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pretargetingconfigs/($accountId)/($configId)" $qp)
  let body = {billingId: $billingId, configId: $body_configId, configName: $configName, creativeType: $creativeType, dimensions: $dimensions, excludedContentLabels: $excludedContentLabels, excludedGeoCriteriaIds: $excludedGeoCriteriaIds, excludedPlacements: $excludedPlacements, excludedUserLists: $excludedUserLists, excludedVerticals: $excludedVerticals, geoCriteriaIds: $geoCriteriaIds, isActive: $isActive, kind: $kind, languages: $languages, maximumQps: $maximumQps, minimumViewabilityDecile: $minimumViewabilityDecile, mobileCarriers: $mobileCarriers, mobileDevices: $mobileDevices, mobileOperatingSystemVersions: $mobileOperatingSystemVersions, placements: $placements, platforms: $platforms, supportedCreativeAttributes: $supportedCreativeAttributes, userIdentifierDataRequired: $userIdentifierDataRequired, userLists: $userLists, vendorTypes: $vendorTypes, verticals: $verticals, videoPlayerSizes: $videoPlayerSizes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a given private auction proposal
#
# POST /privateauction/{privateAuctionId}/updateproposal
# operationId: adexchangebuyer.marketplaceprivateauction.updateproposal
# --note shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
export def "privateauction-updateproposal adexchangebuyermarketplaceprivateauctionupdateproposal" [
  privateAuctionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --externalDealId: string # The externalDealId of the deal to be updated.
  --note: record # A proposal is associated with a bunch of notes which may optionally be associated with a deal and/or revision number. — shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
  --proposalRevisionNumber: string # The current revision number of the proposal to be updated. (format: int64)
  --updateAction: string # The proposed action on the private auction proposal.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/privateauction/($privateAuctionId)/updateproposal" $qp)
  let body = {externalDealId: $externalDealId, note: $note, proposalRevisionNumber: $proposalRevisionNumber, updateAction: $updateAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the requested product.
#
# GET /products/search
# operationId: adexchangebuyer.products.search
export def "products-search adexchangebuyerproductssearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pqlQuery: string # The pql query used to query for products.
]: nothing -> record<products: table<billedBuyer: record, buyer: record, creationTimeMs: string, creatorContacts: list, creatorRole: string, deliveryControl: record, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: list, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record, revisionNumber: string, seller: record, sharedTargetings: list, state: string, syndicationProduct: string, terms: record, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pqlQuery" $pqlQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the requested product by id.
#
# GET /products/{productId}
# operationId: adexchangebuyer.products.get
export def "products adexchangebuyerproductsget" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, creationTimeMs: string, creatorContacts: table<email: string, name: string>, creatorRole: string, deliveryControl: record<creativeBlockingLevel: string, deliveryRateType: string, frequencyCaps: list<record>>, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record<dimensions: list<record>, weeklyImpressions: string, weeklyUniques: string>, revisionNumber: string, seller: record<accountId: string, subAccountId: string>, sharedTargetings: table<exclusions: list, inclusions: list, key: string>, state: string, syndicationProduct: string, terms: record<brandingType: string, crossListedExternalDealIdType: string, description: string, estimatedGrossSpend: record<amountMicros: float, currencyCode: string, expectedCpmMicros: float, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<billingInfo: record, fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, minimumDailyLooks: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricePerBuyers: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, rubiconNonGuaranteedTerms: record<priorityPrice: record, standardPrice: record>, sellerTimeZone: string>, webPropertyCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($productId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the given list of proposals
#
# POST /proposals/insert
# operationId: adexchangebuyer.proposals.insert
# --proposals item shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, seller?: record, sellerContacts?: list}
export def "proposals-insert adexchangebuyerproposalsinsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --proposals: list # The list of proposals to create. — item shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, seller?: record, sellerContacts?: list}
  --webPropertyCode: string # Web property id of the seller creating these orders
]: any -> record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proposals/insert" $qp)
  let body = {proposals: $proposals, webPropertyCode: $webPropertyCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for proposals using pql query
#
# GET /proposals/search
# operationId: adexchangebuyer.proposals.search
export def "proposals-search adexchangebuyerproposalssearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pqlQuery: string # Query string to retrieve specific proposals.
]: nothing -> record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pqlQuery" $pqlQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proposals/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a proposal given its id
#
# GET /proposals/{proposalId}
# operationId: adexchangebuyer.proposals.get
export def "proposals adexchangebuyerproposalsget" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all the deals for a given proposal
#
# GET /proposals/{proposalId}/deals
# operationId: adexchangebuyer.marketplacedeals.list
export def "proposals-deals adexchangebuyermarketplacedealslist" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pqlQuery: string # Query string to retrieve specific deals.
]: nothing -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pqlQuery" $pqlQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/deals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specified deals from the proposal
#
# POST /proposals/{proposalId}/deals/delete
# operationId: adexchangebuyer.marketplacedeals.delete
export def "proposals-deals-delete adexchangebuyermarketplacedealsdelete" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --dealIds: list # List of deals to delete for a given proposal
  --proposalRevisionNumber: string # The last known proposal revision number. (format: int64)
  --updateAction: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/deals/delete" $qp)
  let body = {dealIds: $dealIds, proposalRevisionNumber: $proposalRevisionNumber, updateAction: $updateAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add new deals for the specified proposal
#
# POST /proposals/{proposalId}/deals/insert
# operationId: adexchangebuyer.marketplacedeals.insert
# --deals item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, programmaticCreativeSource?: string, proposalId?: string, sellerContacts?: list, sharedTargetings?: list, syndicationProduct?: string, terms?: record, webPropertyCode?: string}
export def "proposals-deals-insert adexchangebuyermarketplacedealsinsert" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --deals: list # The list of deals to add — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, programmaticCreativeSource?: string, proposalId?: string, sellerContacts?: list, sharedTargetings?: list, syndicationProduct?: string, terms?: record, webPropertyCode?: string}
  --proposalRevisionNumber: string # The last known proposal revision number. (format: int64)
  --updateAction: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/deals/insert" $qp)
  let body = {deals: $deals, proposalRevisionNumber: $proposalRevisionNumber, updateAction: $updateAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replaces all the deals in the proposal with the passed in deals
#
# POST /proposals/{proposalId}/deals/update
# operationId: adexchangebuyer.marketplacedeals.update
# --deals item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, programmaticCreativeSource?: string, proposalId?: string, sellerContacts?: list, sharedTargetings?: list, syndicationProduct?: string, terms?: record, webPropertyCode?: string}
# --proposal shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, seller?: record, sellerContacts?: list}
export def "proposals-deals-update adexchangebuyermarketplacedealsupdate" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --deals: list # List of deals to edit. Service may perform 3 different operations based on comparison of deals in this list vs deals already persisted in database: 1. Add new deal to proposal If a deal in this list does not exist in the proposal, the service will create a new deal and add it to the proposal. Validation will follow AddOrderDealsRequest. 2. Update existing deal in the proposal If a deal in this list already exist in the proposal, the service will update that existing deal to this new deal in the request. Validation will follow UpdateOrderDealsRequest. 3. Delete deals from the proposal (just need the id) If a existing deal in the proposal is not present in this list, the service will delete that deal from the proposal. Validation will follow DeleteOrderDealsRequest. — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, programmaticCreativeSource?: string, proposalId?: string, sellerContacts?: list, sharedTargetings?: list, syndicationProduct?: string, terms?: record, webPropertyCode?: string}
  --proposal: record # Represents a proposal in the marketplace. A proposal is the unit of negotiation between a seller and a buyer and contains deals which are served. Each field in a proposal can have one of the following setting:  (readonly) - It is an error to try and set this field. (buyer-readonly) - Only the seller can set this field. (seller-readonly) - Only the buyer can set this field. (updatable) - The field is updatable at all times by either buyer or the seller. — shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, seller?: record, sellerContacts?: list}
  --proposalRevisionNumber: string # The last known revision number for the proposal. (format: int64)
  --updateAction: string # Indicates an optional action to take on the proposal
]: any -> record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, orderRevisionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/deals/update" $qp)
  let body = {deals: $deals, proposal: $proposal, proposalRevisionNumber: $proposalRevisionNumber, updateAction: $updateAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all the notes associated with a proposal
#
# GET /proposals/{proposalId}/notes
# operationId: adexchangebuyer.marketplacenotes.list
export def "proposals-notes adexchangebuyermarketplacenoteslist" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pqlQuery: string # Query string to retrieve specific notes. To search the text contents of notes, please use syntax like "WHERE note.note = "foo" or "WHERE note.note LIKE "%bar%"
]: nothing -> record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pqlQuery" $pqlQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add notes to the proposal
#
# POST /proposals/{proposalId}/notes/insert
# operationId: adexchangebuyer.marketplacenotes.insert
# --notes item shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
export def "proposals-notes-insert adexchangebuyermarketplacenotesinsert" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --notes: list # The list of notes to add. — item shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
]: any -> record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/notes/insert" $qp)
  let body = {notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the given proposal to indicate that setup has been completed.
#
# POST /proposals/{proposalId}/setupcomplete
# operationId: adexchangebuyer.proposals.setupcomplete
export def "proposals-setupcomplete adexchangebuyerproposalssetupcomplete" [
  proposalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/setupcomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "proposals adexchangebuyerproposalspatch" [
  proposalId: string
  revisionNumber: string
  updateAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --billedBuyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyerContacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyerPrivateData: record # shape: {referenceId?: string, referencePayload?: string}
  --dbmAdvertiserIds: list # IDs of DBM advertisers permission to this proposal.
  --hasBuyerSignedOff: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --hasSellerSignedOff: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventorySource: string # What exchange will provide this inventory (readonly, except on create).
  --isRenegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --isSetupComplete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --lastUpdaterOrCommentorRole: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiationId: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originatorRole: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --privateAuctionId: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposalId: string # The unique id of the proposal. (readonly).
  --proposalState: string # The current state of the proposal. (readonly)
  --body-revisionNumber: string # The revision number for the proposal (readonly). (format: int64)
  --revisionTimeMs: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --sellerContacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/($revisionNumber)/($updateAction)" $qp)
  let body = {billedBuyer: $billedBuyer, buyer: $buyer, buyerContacts: $buyerContacts, buyerPrivateData: $buyerPrivateData, dbmAdvertiserIds: $dbmAdvertiserIds, hasBuyerSignedOff: $hasBuyerSignedOff, hasSellerSignedOff: $hasSellerSignedOff, inventorySource: $inventorySource, isRenegotiating: $isRenegotiating, isSetupComplete: $isSetupComplete, kind: $kind, labels: $labels, lastUpdaterOrCommentorRole: $lastUpdaterOrCommentorRole, name: $name, negotiationId: $negotiationId, originatorRole: $originatorRole, privateAuctionId: $privateAuctionId, proposalId: $body_proposalId, proposalState: $proposalState, revisionNumber: $body_revisionNumber, revisionTimeMs: $revisionTimeMs, seller: $seller, sellerContacts: $sellerContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
export def "proposals adexchangebuyerproposalsupdate" [
  proposalId: string
  revisionNumber: string
  updateAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --billedBuyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyerContacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyerPrivateData: record # shape: {referenceId?: string, referencePayload?: string}
  --dbmAdvertiserIds: list # IDs of DBM advertisers permission to this proposal.
  --hasBuyerSignedOff: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --hasSellerSignedOff: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventorySource: string # What exchange will provide this inventory (readonly, except on create).
  --isRenegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --isSetupComplete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --lastUpdaterOrCommentorRole: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiationId: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originatorRole: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --privateAuctionId: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposalId: string # The unique id of the proposal. (readonly).
  --proposalState: string # The current state of the proposal. (readonly)
  --body-revisionNumber: string # The revision number for the proposal (readonly). (format: int64)
  --revisionTimeMs: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --sellerContacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proposals/($proposalId)/($revisionNumber)/($updateAction)" $qp)
  let body = {billedBuyer: $billedBuyer, buyer: $buyer, buyerContacts: $buyerContacts, buyerPrivateData: $buyerPrivateData, dbmAdvertiserIds: $dbmAdvertiserIds, hasBuyerSignedOff: $hasBuyerSignedOff, hasSellerSignedOff: $hasSellerSignedOff, inventorySource: $inventorySource, isRenegotiating: $isRenegotiating, isSetupComplete: $isSetupComplete, kind: $kind, labels: $labels, lastUpdaterOrCommentorRole: $lastUpdaterOrCommentorRole, name: $name, negotiationId: $negotiationId, originatorRole: $originatorRole, privateAuctionId: $privateAuctionId, proposalId: $body_proposalId, proposalState: $proposalState, revisionNumber: $body_revisionNumber, revisionTimeMs: $revisionTimeMs, seller: $seller, sellerContacts: $sellerContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the requested publisher profile(s) by publisher accountId.
#
# GET /publisher/{accountId}/profiles
# operationId: adexchangebuyer.pubprofiles.list
export def "publisher-profiles adexchangebuyerpubprofileslist" [
  accountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<profiles: table<audience: string, buyerPitchStatement: string, directContact: string, exchange: string, forecastInventory: string, googlePlusLink: string, isParent: bool, isPublished: bool, kind: string, logoUrl: string, mediaKitLink: string, name: string, overview: string, profileId: int, programmaticContact: string, publisherAppIds: list, publisherApps: list, publisherDomains: list, publisherProfileId: string, publisherProvidedForecast: record, rateCardInfoLink: string, samplePageLink: string, seller: record, state: string, topHeadlines: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/publisher/($accountId)/profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
