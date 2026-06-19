# Auto-generated client for AdSense Management API vv1.4
# Source: https://api.apis.guru/v2/specs/googleapis.com/adsense/v1.4/openapi.json
# Auth: --token flag or $env.ADSENSE_MANAGEMENT_API_TOKEN

const BASE_URL = "https://www.googleapis.com/adsense/v1.4"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADSENSE_MANAGEMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/adsense/v1.4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["csv" "json"] }

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

# List all accounts available to this AdSense account.
#
# GET /accounts
# operationId: adsense.accounts.list
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
  --max-results: int # The maximum number of accounts to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through accounts. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<creation_time: string, id: string, kind: string, name: string, premium: bool, subAccounts: list, timezone: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Get information about the selected AdSense account.
#
# GET /accounts/{accountId}
# operationId: adsense.accounts.get
export def "accounts get" [
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
  --tree: oneof<nothing, bool> # Whether the tree of sub accounts should be returned.
]: nothing -> record<creation_time: string, id: string, kind: string, name: string, premium: bool, subAccounts: list<any>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "tree" $tree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "tree": $tree} | compact), body: null}
}

# List all ad clients in the specified account.
#
# GET /accounts/{accountId}/adclients
# operationId: adsense.accounts.adclients.list
export def "accounts-adclients list" [
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
  --max-results: int # The maximum number of ad clients to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/adclients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Get Auto ad code for a given ad client.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adcode
# operationId: adsense.accounts.adclients.getAdCode
export def "accounts-adclients-adcode get-ad-code" [
  account_id: string
  ad_client_id: string
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
  --tag-partner: string # Tag partner to include in the ad code snippet.
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "tagPartner" $tag_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adcode") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "tagPartner": $tag_partner} | compact), body: null}
}

# List all ad units in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsense.accounts.adunits.list
export def "accounts-adclients-adunits list" [
  account_id: string
  ad_client_id: string
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
  --include-inactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --max-results: int # The maximum number of ad units to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "includeInactive": $include_inactive, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Gets the specified ad unit in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsense.accounts.adunits.get
export def "accounts-adclients-adunits get" [
  account_id: string
  ad_client_id: string
  ad_unit_id: string
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, feedAdsSettings: record<adPosition: string, frequency: int, minimumWordCount: int, type: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, savedStyleId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits/{ad_unit_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Get ad code for the specified ad unit.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}/adcode
# operationId: adsense.accounts.adunits.getAdCode
export def "accounts-adclients-adunits-adcode get-ad-code" [
  account_id: string
  ad_client_id: string
  ad_unit_id: string
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
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits/{ad_unit_id}/adcode") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all custom channels which the specified ad unit belongs to.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}/customchannels
# operationId: adsense.accounts.adunits.customchannels.list
export def "accounts-adclients-adunits-customchannels list" [
  account_id: string
  ad_client_id: string
  ad_unit_id: string
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
  --max-results: int # The maximum number of custom channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits/{ad_unit_id}/customchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List all custom channels in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels
# operationId: adsense.accounts.customchannels.list
export def "accounts-adclients-customchannels list" [
  account_id: string
  ad_client_id: string
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
  --max-results: int # The maximum number of custom channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/customchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Get the specified custom channel from the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsense.accounts.customchannels.get
export def "accounts-adclients-customchannels get" [
  account_id: string
  ad_client_id: string
  custom_channel_id: string
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
]: nothing -> record<code: string, id: string, kind: string, name: string, targetingInfo: record<adsAppearOn: string, description: string, location: string, siteLanguage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($custom_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'customChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), custom_channel_id: (encode-path-segment $custom_channel_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/customchannels/{custom_channel_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all ad units in the specified custom channel.
#
# GET /accounts/{accountId}/adclients/{adClientId}/customchannels/{customChannelId}/adunits
# operationId: adsense.accounts.customchannels.adunits.list
export def "accounts-adclients-customchannels-adunits list" [
  account_id: string
  ad_client_id: string
  custom_channel_id: string
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
  --include-inactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --max-results: int # The maximum number of ad units to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($custom_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'customChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), custom_channel_id: (encode-path-segment $custom_channel_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/customchannels/{custom_channel_id}/adunits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "includeInactive": $include_inactive, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List all URL channels in the specified ad client for the specified account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/urlchannels
# operationId: adsense.accounts.urlchannels.list
export def "accounts-adclients-urlchannels list" [
  account_id: string
  ad_client_id: string
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
  --max-results: int # The maximum number of URL channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through URL channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, urlPattern: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/urlchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List the alerts for the specified AdSense account.
#
# GET /accounts/{accountId}/alerts
# operationId: adsense.accounts.alerts.list
export def "accounts-alerts list" [
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
  --locale: string # The locale to use for translating alert messages. The account locale will be used if this is not supplied. The AdSense default (English) will be used if the supplied locale is invalid or unsupported.
]: nothing -> record<items: table<id: string, isDismissible: bool, kind: string, message: string, severity: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "locale": $locale} | compact), body: null}
}

# Dismiss (delete) the specified alert from the specified publisher AdSense account.
#
# DELETE /accounts/{accountId}/alerts/{alertId}
# operationId: adsense.accounts.alerts.delete
export def "accounts-alerts delete" [
  account_id: string
  alert_id: string
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
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alertId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/accounts/{account_id}/alerts/{alert_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List the payments for the specified AdSense account.
#
# GET /accounts/{accountId}/payments
# operationId: adsense.accounts.payments.list
export def "accounts-payments list" [
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
]: nothing -> record<items: table<id: string, kind: string, paymentAmount: string, paymentAmountCurrencyCode: string, paymentDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/payments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /accounts/{accountId}/reports
# operationId: adsense.accounts.reports.generate
export def "accounts-reports list" [
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
  --start-date: string # Start of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --end-date: string # End of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --currency: string # Optional currency to use when reporting on monetary metrics. Defaults to the account's currency if not set.
  --dimension: list<string> # Dimensions to base the report on.
  --filter: list<string> # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --metric: list<string> # Numeric columns to include in the report.
  --qp-sort: list<string> # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --start-index: int # Index of the first row of report data to return.
  --use-timezone-reporting: oneof<nothing, bool> # Whether the report should be generated in the AdSense account's local timezone. If false default PST/PDT timezone will be used.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $start_index "scalar") (serialize-qp "useTimezoneReporting" $use_timezone_reporting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "startDate": $start_date, "endDate": $end_date, "currency": $currency, "dimension": $dimension, "filter": $filter, "locale": $locale, "maxResults": $max_results, "metric": $metric, "sort": $qp_sort, "startIndex": $start_index, "useTimezoneReporting": $use_timezone_reporting} | compact), body: null}
}

# List all saved reports in the specified AdSense account.
#
# GET /accounts/{accountId}/reports/saved
# operationId: adsense.accounts.reports.saved.list
export def "accounts-reports-saved list" [
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
  --max-results: int # The maximum number of saved reports to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through saved reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/reports/saved") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Generate an AdSense report based on the saved report ID sent in the query parameters.
#
# GET /accounts/{accountId}/reports/{savedReportId}
# operationId: adsense.accounts.reports.saved.generate
export def "accounts-reports generate" [
  account_id: string
  saved_report_id: string
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
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --start-index: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($saved_report_id | is-empty) { error make --unspanned { msg: "path parameter 'savedReportId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), saved_report_id: (encode-path-segment $saved_report_id)} | format pattern "/accounts/{account_id}/reports/{saved_report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "locale": $locale, "maxResults": $max_results, "startIndex": $start_index} | compact), body: null}
}

# List all saved ad styles in the specified account.
#
# GET /accounts/{accountId}/savedadstyles
# operationId: adsense.accounts.savedadstyles.list
export def "accounts-savedadstyles list" [
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
  --max-results: int # The maximum number of saved ad styles to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through saved ad styles. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<adStyle: record, id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/savedadstyles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List a specific saved ad style for the specified account.
#
# GET /accounts/{accountId}/savedadstyles/{savedAdStyleId}
# operationId: adsense.accounts.savedadstyles.get
export def "accounts-savedadstyles get" [
  account_id: string
  saved_ad_style_id: string
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
]: nothing -> record<adStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($saved_ad_style_id | is-empty) { error make --unspanned { msg: "path parameter 'savedAdStyleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), saved_ad_style_id: (encode-path-segment $saved_ad_style_id)} | format pattern "/accounts/{account_id}/savedadstyles/{saved_ad_style_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all ad clients in this AdSense account.
#
# GET /adclients
# operationId: adsense.adclients.list
export def "adclients list" [
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
  --max-results: int # The maximum number of ad clients to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/adclients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List all ad units in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/adunits
# operationId: adsense.adunits.list
export def "adclients-adunits list" [
  ad_client_id: string
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
  --include-inactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --max-results: int # The maximum number of ad units to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/adunits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "includeInactive": $include_inactive, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Gets the specified ad unit in the specified ad client.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsense.adunits.get
export def "adclients-adunits get" [
  ad_client_id: string
  ad_unit_id: string
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, feedAdsSettings: record<adPosition: string, frequency: int, minimumWordCount: int, type: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, savedStyleId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/adclients/{ad_client_id}/adunits/{ad_unit_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Get ad code for the specified ad unit.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}/adcode
# operationId: adsense.adunits.getAdCode
export def "adclients-adunits-adcode get-ad-code" [
  ad_client_id: string
  ad_unit_id: string
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
]: nothing -> record<adCode: string, ampBody: string, ampHead: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/adclients/{ad_client_id}/adunits/{ad_unit_id}/adcode") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all custom channels which the specified ad unit belongs to.
#
# GET /adclients/{adClientId}/adunits/{adUnitId}/customchannels
# operationId: adsense.adunits.customchannels.list
export def "adclients-adunits-customchannels list" [
  ad_client_id: string
  ad_unit_id: string
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
  --max-results: int # The maximum number of custom channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/adclients/{ad_client_id}/adunits/{ad_unit_id}/customchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List all custom channels in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/customchannels
# operationId: adsense.customchannels.list
export def "adclients-customchannels list" [
  ad_client_id: string
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
  --max-results: int # The maximum number of custom channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through custom channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string, targetingInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/customchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Get the specified custom channel from the specified ad client.
#
# GET /adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsense.customchannels.get
export def "adclients-customchannels get" [
  ad_client_id: string
  custom_channel_id: string
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
]: nothing -> record<code: string, id: string, kind: string, name: string, targetingInfo: record<adsAppearOn: string, description: string, location: string, siteLanguage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($custom_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'customChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), custom_channel_id: (encode-path-segment $custom_channel_id)} | format pattern "/adclients/{ad_client_id}/customchannels/{custom_channel_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all ad units in the specified custom channel.
#
# GET /adclients/{adClientId}/customchannels/{customChannelId}/adunits
# operationId: adsense.customchannels.adunits.list
export def "adclients-customchannels-adunits list" [
  ad_client_id: string
  custom_channel_id: string
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
  --include-inactive: oneof<nothing, bool> # Whether to include inactive ad units. Default: true.
  --max-results: int # The maximum number of ad units to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through ad units. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, feedAdsSettings: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, savedStyleId: string, status: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($custom_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'customChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), custom_channel_id: (encode-path-segment $custom_channel_id)} | format pattern "/adclients/{ad_client_id}/customchannels/{custom_channel_id}/adunits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "includeInactive": $include_inactive, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List all URL channels in the specified ad client for this AdSense account.
#
# GET /adclients/{adClientId}/urlchannels
# operationId: adsense.urlchannels.list
export def "adclients-urlchannels list" [
  ad_client_id: string
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
  --max-results: int # The maximum number of URL channels to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through URL channels. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, urlPattern: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/urlchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# List the alerts for this AdSense account.
#
# GET /alerts
# operationId: adsense.alerts.list
export def "alerts list" [
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
  --locale: string # The locale to use for translating alert messages. The account locale will be used if this is not supplied. The AdSense default (English) will be used if the supplied locale is invalid or unsupported.
]: nothing -> record<items: table<id: string, isDismissible: bool, kind: string, message: string, severity: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "locale": $locale} | compact), body: null}
}

# Dismiss (delete) the specified alert from the publisher's AdSense account.
#
# DELETE /alerts/{alertId}
# operationId: adsense.alerts.delete
export def "alerts delete" [
  alert_id: string
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
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alertId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alert_id: (encode-path-segment $alert_id)} | format pattern "/alerts/{alert_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List the metadata for the dimensions available to this AdSense account.
#
# GET /metadata/dimensions
# operationId: adsense.metadata.dimensions.list
export def "metadata-dimensions list" [
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
]: nothing -> record<items: table<compatibleDimensions: list, compatibleMetrics: list, id: string, kind: string, requiredDimensions: list, requiredMetrics: list, supportedProducts: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/dimensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List the metadata for the metrics available to this AdSense account.
#
# GET /metadata/metrics
# operationId: adsense.metadata.metrics.list
export def "metadata-metrics list" [
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
]: nothing -> record<items: table<compatibleDimensions: list, compatibleMetrics: list, id: string, kind: string, requiredDimensions: list, requiredMetrics: list, supportedProducts: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List the payments for this AdSense account.
#
# GET /payments
# operationId: adsense.payments.list
export def "payments list" [
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
]: nothing -> record<items: table<id: string, kind: string, paymentAmount: string, paymentAmountCurrencyCode: string, paymentDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /reports
# operationId: adsense.reports.generate
export def "reports list" [
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
  --start-date: string # Start of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --end-date: string # End of the date range to report on in "YYYY-MM-DD" format, inclusive.
  --account-id: list<string> # Accounts upon which to report.
  --currency: string # Optional currency to use when reporting on monetary metrics. Defaults to the account's currency if not set.
  --dimension: list<string> # Dimensions to base the report on.
  --filter: list<string> # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --metric: list<string> # Numeric columns to include in the report.
  --qp-sort: list<string> # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --start-index: int # Index of the first row of report data to return.
  --use-timezone-reporting: oneof<nothing, bool> # Whether the report should be generated in the AdSense account's local timezone. If false default PST/PDT timezone will be used.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "accountId" $account_id "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $start_index "scalar") (serialize-qp "useTimezoneReporting" $use_timezone_reporting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "startDate": $start_date, "endDate": $end_date, "accountId": $account_id, "currency": $currency, "dimension": $dimension, "filter": $filter, "locale": $locale, "maxResults": $max_results, "metric": $metric, "sort": $qp_sort, "startIndex": $start_index, "useTimezoneReporting": $use_timezone_reporting} | compact), body: null}
}

# List all saved reports in this AdSense account.
#
# GET /reports/saved
# operationId: adsense.reports.saved.list
export def "reports-saved list" [
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
  --max-results: int # The maximum number of saved reports to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through saved reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/saved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Generate an AdSense report based on the saved report ID sent in the query parameters.
#
# GET /reports/{savedReportId}
# operationId: adsense.reports.saved.generate
export def "reports generate" [
  saved_report_id: string
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
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --start-index: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, endDate: string, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, startDate: string, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($saved_report_id | is-empty) { error make --unspanned { msg: "path parameter 'savedReportId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({saved_report_id: (encode-path-segment $saved_report_id)} | format pattern "/reports/{saved_report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "locale": $locale, "maxResults": $max_results, "startIndex": $start_index} | compact), body: null}
}

# List all saved ad styles in the user's account.
#
# GET /savedadstyles
# operationId: adsense.savedadstyles.list
export def "savedadstyles list" [
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
  --max-results: int # The maximum number of saved ad styles to include in the response, used for paging.
  --page-token: string # A continuation token, used to page through saved ad styles. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response.
]: nothing -> record<etag: string, items: table<adStyle: record, id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/savedadstyles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Get a specific saved ad style from the user's account.
#
# GET /savedadstyles/{savedAdStyleId}
# operationId: adsense.savedadstyles.get
export def "savedadstyles get" [
  saved_ad_style_id: string
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
]: nothing -> record<adStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($saved_ad_style_id | is-empty) { error make --unspanned { msg: "path parameter 'savedAdStyleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({saved_ad_style_id: (encode-path-segment $saved_ad_style_id)} | format pattern "/savedadstyles/{saved_ad_style_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}
