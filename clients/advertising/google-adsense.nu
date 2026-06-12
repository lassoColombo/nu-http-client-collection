# Auto-generated client for AdSense Management API vv1.4
# Source: https://api.apis.guru/v2/specs/googleapis.com/adsense/v1.4/openapi.json
# Auth: --token flag or $env.ADSENSE_MANAGEMENT_API_TOKEN

const BASE_URL = "https://www.googleapis.com/adsense/v1.4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADSENSE_MANAGEMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/adsense/v1.4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["csv" "json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts adsenseaccountslist" } } | get name | first)
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

# List all accounts available to this AdSense account.
#
# GET /accounts
# operationId: adsense.accounts.list
export def "accounts adsenseaccountslist" [
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
  --maxResults: int # The maximum number of accounts to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through accounts. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<creation_time: string, id: string, kind: string, name: string, premium: bool, subAccounts: list, timezone: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about the selected AdSense account.
#
# GET /accounts/{accountId}
# operationId: adsense.accounts.get
export def "accounts adsenseaccountsget" [
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
  --tree: oneof<nothing, bool> # Whether the tree of sub accounts should be returned.
]: nothing -> record<creation_time: string, id: string, kind: string, name: string, premium: bool, subAccounts: list<any>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "tree" $tree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad clients in the specified account.
#
# GET /accounts/{accountId}/adclients
# operationId: adsense.accounts.adclients.list
export def "accounts-adclients adsenseaccountsadclientslist" [
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
  --maxResults: int # The maximum number of ad clients to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Auto ad code for a given ad client.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adcode
# operationId: adsense.accounts.adclients.getAdCode
export def "accounts-adclients-adcode adsenseaccountsadclientsgetAdCode" [
  accountId: string
  adClientId: string
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
  --tagPartner: string # Tag partner to include in the ad code snippet.
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "tagPartner" $tagPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/adcode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad units in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsense.accounts.adunits.list
export def "accounts-adclients-adunits adsenseaccountsadunitslist" [
  accountId: string
  adClientId: string
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
  --includeInactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --maxResults: int # The maximum number of ad units to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeInactive" $includeInactive "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/adunits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified ad unit in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsense.accounts.adunits.get
export def "accounts-adclients-adunits adsenseaccountsadunitsget" [
  accountId: string
  adClientId: string
  adUnitId: string
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, feedAdsSettings: record<adPosition: string, frequency: int, minimumWordCount: int, type: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, savedStyleId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/adunits/($adUnitId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ad code for the specified ad unit.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}/adcode
# operationId: adsense.accounts.adunits.getAdCode
export def "accounts-adclients-adunits-adcode adsenseaccountsadunitsgetAdCode" [
  accountId: string
  adClientId: string
  adUnitId: string
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
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/adunits/($adUnitId)/adcode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all custom channels which the specified ad unit belongs to.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}/customchannels
# operationId: adsense.accounts.adunits.customchannels.list
export def "accounts-adclients-adunits-customchannels adsenseaccountsadunitscustomchannelslist" [
  accountId: string
  adClientId: string
  adUnitId: string
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
  --maxResults: int # The maximum number of custom channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/adunits/($adUnitId)/customchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all custom channels in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels
# operationId: adsense.accounts.customchannels.list
export def "accounts-adclients-customchannels adsenseaccountscustomchannelslist" [
  accountId: string
  adClientId: string
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
  --maxResults: int # The maximum number of custom channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/customchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the specified custom channel from the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsense.accounts.customchannels.get
export def "accounts-adclients-customchannels adsenseaccountscustomchannelsget" [
  accountId: string
  adClientId: string
  customChannelId: string
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
]: nothing -> record<code: string, id: string, kind: string, name: string, targetingInfo: record<adsAppearOn: string, description: string, location: string, siteLanguage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/customchannels/($customChannelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad units in the specified custom channel.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels/{customChannelId}/adunits
# operationId: adsense.accounts.customchannels.adunits.list
export def "accounts-adclients-customchannels-adunits adsenseaccountscustomchannelsadunitslist" [
  accountId: string
  adClientId: string
  customChannelId: string
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
  --includeInactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --maxResults: int # The maximum number of ad units to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeInactive" $includeInactive "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/customchannels/($customChannelId)/adunits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all URL channels in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/urlchannels
# operationId: adsense.accounts.urlchannels.list
export def "accounts-adclients-urlchannels adsenseaccountsurlchannelslist" [
  accountId: string
  adClientId: string
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
  --maxResults: int # The maximum number of URL channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through URL channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, urlPattern: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/adclients/($adClientId)/urlchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the alerts for the specified AdSense account.
#
# GET /accounts/{accountId}/alerts
# operationId: adsense.accounts.alerts.list
export def "accounts-alerts adsenseaccountsalertslist" [
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
  --locale: string # The locale to use for translating alert messages. The account locale will be used if this is not supplied. The AdSense default (English) will be used if the supplied locale is invalid or unsupported.
]: nothing -> record<items: table<id: string, isDismissible: bool, kind: string, message: string, severity: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss (delete) the specified alert from the specified publisher AdSense account.
#
# DELETE /accounts/{accountId}/alerts/{alertId}
# operationId: adsense.accounts.alerts.delete
export def "accounts-alerts adsenseaccountsalertsdelete" [
  accountId: string
  alertId: string
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
  let full_url = (build-url $base $"/accounts/($accountId)/alerts/($alertId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the payments for the specified AdSense account.
#
# GET /accounts/{accountId}/payments
# operationId: adsense.accounts.payments.list
export def "accounts-payments adsenseaccountspaymentslist" [
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
]: nothing -> record<items: table<id: string, kind: string, paymentAmount: string, paymentAmountCurrencyCode: string, paymentDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /accounts/{accountId}/reports
# operationId: adsense.accounts.reports.generate
export def "accounts-reports adsenseaccountsreportsgenerate" [
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
  --startDate: string # Start of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --endDate: string # End of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --currency: string # Optional currency to use when reporting on monetary metrics. Defaults to the account's currency if not set.
  --dimension: list # Dimensions to base the report on.
  --filter: list # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --maxResults: int # The maximum number of rows of report data to return.
  --metric: list # Numeric columns to include in the report.
  --qp-sort: list # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --startIndex: int # Index of the first row of report data to return.
  --useTimezoneReporting: oneof<nothing, bool> # Whether the report should be generated in the AdSense account's local timezone. If false default PST/PDT timezone will be used.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "useTimezoneReporting" $useTimezoneReporting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all saved reports in the specified AdSense account.
#
# GET /accounts/{accountId}/reports/saved
# operationId: adsense.accounts.reports.saved.list
export def "accounts-reports-saved adsenseaccountsreportssavedlist" [
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
  --maxResults: int # The maximum number of saved reports to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through saved reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/reports/saved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an AdSense report based on the saved report ID sent in the query parameters.
#
# GET /accounts/{accountId}/reports/{savedReportId}
# operationId: adsense.accounts.reports.saved.generate
export def "accounts-reports adsenseaccountsreportssavedgenerate" [
  accountId: string
  savedReportId: string
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
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --maxResults: int # The maximum number of rows of report data to return.
  --startIndex: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/reports/($savedReportId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all saved ad styles in the specified account.
#
# GET /accounts/{accountId}/savedadstyles
# operationId: adsense.accounts.savedadstyles.list
export def "accounts-savedadstyles adsenseaccountssavedadstyleslist" [
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
  --maxResults: int # The maximum number of saved ad styles to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through saved ad styles. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<adStyle: record, id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/savedadstyles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a specific saved ad style for the specified account.
#
# GET /accounts/{accountId}/savedadstyles/{savedAdStyleId}
# operationId: adsense.accounts.savedadstyles.get
export def "accounts-savedadstyles adsenseaccountssavedadstylesget" [
  accountId: string
  savedAdStyleId: string
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
]: nothing -> record<adStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/savedadstyles/($savedAdStyleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad clients in this AdSense account.
#
# GET /adclients
# operationId: adsense.adclients.list
export def "adclients adsenseadclientslist" [
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
  --maxResults: int # The maximum number of ad clients to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/adclients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad units in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/adunits
# operationId: adsense.adunits.list
export def "adclients-adunits adsenseadunitslist" [
  adClientId: string
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
  --includeInactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --maxResults: int # The maximum number of ad units to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeInactive" $includeInactive "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/adunits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified ad unit in the specified ad client.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsense.adunits.get
export def "adclients-adunits adsenseadunitsget" [
  adClientId: string
  adUnitId: string
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, feedAdsSettings: record<adPosition: string, frequency: int, minimumWordCount: int, type: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, savedStyleId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/adunits/($adUnitId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ad code for the specified ad unit.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}/adcode
# operationId: adsense.adunits.getAdCode
export def "adclients-adunits-adcode adsenseadunitsgetAdCode" [
  adClientId: string
  adUnitId: string
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
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/adunits/($adUnitId)/adcode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all custom channels which the specified ad unit belongs to.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}/customchannels
# operationId: adsense.adunits.customchannels.list
export def "adclients-adunits-customchannels adsenseadunitscustomchannelslist" [
  adClientId: string
  adUnitId: string
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
  --maxResults: int # The maximum number of custom channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/adunits/($adUnitId)/customchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all custom channels in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/customchannels
# operationId: adsense.customchannels.list
export def "adclients-customchannels adsensecustomchannelslist" [
  adClientId: string
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
  --maxResults: int # The maximum number of custom channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/customchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the specified custom channel from the specified ad client.
#
# GET /adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsense.customchannels.get
export def "adclients-customchannels adsensecustomchannelsget" [
  adClientId: string
  customChannelId: string
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
]: nothing -> record<code: string, id: string, kind: string, name: string, targetingInfo: record<adsAppearOn: string, description: string, location: string, siteLanguage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/customchannels/($customChannelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ad units in the specified custom channel.
#
# GET /adclients/{adClientId}/customchannels/{customChannelId}/adunits
# operationId: adsense.customchannels.adunits.list
export def "adclients-customchannels-adunits adsensecustomchannelsadunitslist" [
  adClientId: string
  customChannelId: string
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
  --includeInactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --maxResults: int # The maximum number of ad units to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeInactive" $includeInactive "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/customchannels/($customChannelId)/adunits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all URL channels in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/urlchannels
# operationId: adsense.urlchannels.list
export def "adclients-urlchannels adsenseurlchannelslist" [
  adClientId: string
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
  --maxResults: int # The maximum number of URL channels to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through URL channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, urlPattern: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adclients/($adClientId)/urlchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the alerts for this AdSense account.
#
# GET /alerts
# operationId: adsense.alerts.list
export def "alerts adsensealertslist" [
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
  --locale: string # The locale to use for translating alert messages. The account locale will be used if this is not supplied. The AdSense default (English) will be used if the supplied locale is invalid or unsupported.
]: nothing -> record<items: table<id: string, isDismissible: bool, kind: string, message: string, severity: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss (delete) the specified alert from the publisher's AdSense account.
#
# DELETE /alerts/{alertId}
# operationId: adsense.alerts.delete
export def "alerts adsensealertsdelete" [
  alertId: string
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
  let full_url = (build-url $base $"/alerts/($alertId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the metadata for the dimensions available to this AdSense account.
#
# GET /metadata/dimensions
# operationId: adsense.metadata.dimensions.list
export def "metadata-dimensions adsensemetadatadimensionslist" [
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
]: nothing -> record<items: table<compatibleDimensions: list, compatibleMetrics: list, id: string, kind: string, requiredDimensions: list, requiredMetrics: list, supportedProducts: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/dimensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the metadata for the metrics available to this AdSense account.
#
# GET /metadata/metrics
# operationId: adsense.metadata.metrics.list
export def "metadata-metrics adsensemetadatametricslist" [
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
]: nothing -> record<items: table<compatibleDimensions: list, compatibleMetrics: list, id: string, kind: string, requiredDimensions: list, requiredMetrics: list, supportedProducts: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the payments for this AdSense account.
#
# GET /payments
# operationId: adsense.payments.list
export def "payments adsensepaymentslist" [
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
]: nothing -> record<items: table<id: string, kind: string, paymentAmount: string, paymentAmountCurrencyCode: string, paymentDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /reports
# operationId: adsense.reports.generate
export def "reports adsensereportsgenerate" [
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
  --startDate: string # Start of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --endDate: string # End of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --accountId: list # Accounts upon which to report.
  --currency: string # Optional currency to use when reporting on monetary metrics. Defaults to the account's currency if not set.
  --dimension: list # Dimensions to base the report on.
  --filter: list # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --maxResults: int # The maximum number of rows of report data to return.
  --metric: list # Numeric columns to include in the report.
  --qp-sort: list # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --startIndex: int # Index of the first row of report data to return.
  --useTimezoneReporting: oneof<nothing, bool> # Whether the report should be generated in the AdSense account's local timezone. If false default PST/PDT timezone will be used.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "accountId" $accountId "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "useTimezoneReporting" $useTimezoneReporting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all saved reports in this AdSense account.
#
# GET /reports/saved
# operationId: adsense.reports.saved.list
export def "reports-saved adsensereportssavedlist" [
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
  --maxResults: int # The maximum number of saved reports to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through saved reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/saved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an AdSense report based on the saved report ID sent in the query parameters.
#
# GET /reports/{savedReportId}
# operationId: adsense.reports.saved.generate
export def "reports adsensereportssavedgenerate" [
  savedReportId: string
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
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --maxResults: int # The maximum number of rows of report data to return.
  --startIndex: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($savedReportId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all saved ad styles in the user's account.
#
# GET /savedadstyles
# operationId: adsense.savedadstyles.list
export def "savedadstyles adsensesavedadstyleslist" [
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
  --maxResults: int # The maximum number of saved ad styles to include in the response, used for paging.
  --pageToken: string # A continuation token, used to page through saved ad styles. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<adStyle: record, id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/savedadstyles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific saved ad style from the user's account.
#
# GET /savedadstyles/{savedAdStyleId}
# operationId: adsense.savedadstyles.get
export def "savedadstyles adsensesavedadstylesget" [
  savedAdStyleId: string
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
]: nothing -> record<adStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/savedadstyles/($savedAdStyleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
