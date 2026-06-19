# Auto-generated client for AdSense Host API vv4.1
# Source: https://api.apis.guru/v2/specs/googleapis.com/adsensehost/v4.1/openapi.json
# Auth: --token flag or $env.ADSENSE_HOST_API_TOKEN

const BASE_URL = "https://www.googleapis.com/adsensehost/v4.1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADSENSE_HOST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/adsensehost/v4.1"] }
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

# List hosted accounts associated with this AdSense account by ad client id.
#
# GET /accounts
# operationId: adsensehost.accounts.list
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
  --filter-ad-client-id: list<string> # Ad clients to list accounts for.
]: nothing -> record<etag: string, items: table<id: string, kind: string, name: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "filterAdClientId" $filter_ad_client_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "filterAdClientId": $filter_ad_client_id} | compact), body: null}
}

# Get information about the selected associated AdSense account.
#
# GET /accounts/{accountId}
# operationId: adsensehost.accounts.get
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
]: nothing -> record<id: string, kind: string, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all hosted ad clients in the specified hosted account.
#
# GET /accounts/{accountId}/adclients
# operationId: adsensehost.accounts.adclients.list
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

# Get information about one of the ad clients in the specified publisher's AdSense account.
#
# GET /accounts/{accountId}/adclients/{adClientId}
# operationId: adsensehost.accounts.adclients.get
export def "accounts-adclients get" [
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
]: nothing -> record<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all ad units in the specified publisher's AdSense account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsensehost.accounts.adunits.list
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
]: nothing -> record<etag: string, items: table<code: string, contentAdsSettings: record, customStyle: record, id: string, kind: string, mobileContentAdsSettings: record, name: string, status: string>, kind: string, nextPageToken: string> {
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

# Update the supplied ad unit in the specified publisher AdSense account. This method supports patch semantics.
#
# PATCH /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsensehost.accounts.adunits.patch
# --contentAdsSettings shape: {backupOption?: record, size?: string, type?: string}
# --customStyle shape: {colors?: record, corners?: string, font?: record, kind?: string}
# --mobileContentAdsSettings shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
export def "accounts-adclients-adunits update-by-account-id-ad-client-id" [
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
  --ad-unit-id: string # Ad unit to get.
  --code: string # Identity code of this ad unit, not necessarily unique across ad clients.
  --content-ads-settings: record # Settings specific to content ads (AFC) and highend mobile content ads (AFMC - deprecated). — shape: {backupOption?: record, size?: string, type?: string}
  --custom-style: record # shape: {colors?: record, corners?: string, font?: record, kind?: string}
  --id: string # Unique identifier of this ad unit. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#adUnit. (default: adsensehost#adUnit)
  --mobile-content-ads-settings: record # Settings specific to WAP mobile content ads (AFMC - deprecated). — shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
  --name: string # Name of this ad unit.
  --status: string # Status of this ad unit. Possible values are: NEW: Indicates that the ad unit was created within the last seven days and does not yet have any activity associated with it. ACTIVE: Indicates that there has been activity on this ad unit in the last seven days. INACTIVE: Indicates that there has been no activity on this ad unit in the last seven days.
]: any -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "adUnitId" $ad_unit_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits") $qp)
  let req_body = {"code": $code, "contentAdsSettings": $content_ads_settings, "customStyle": $custom_style, "id": $id, "kind": $kind, "mobileContentAdsSettings": $mobile_content_ads_settings, "name": $name, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "adUnitId": $ad_unit_id} | compact), body: $req_body}
}

# Insert the supplied ad unit into the specified publisher AdSense account.
#
# POST /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsensehost.accounts.adunits.insert
# --contentAdsSettings shape: {backupOption?: record, size?: string, type?: string}
# --customStyle shape: {colors?: record, corners?: string, font?: record, kind?: string}
# --mobileContentAdsSettings shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
export def "accounts-adclients-adunits create" [
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
  --code: string # Identity code of this ad unit, not necessarily unique across ad clients.
  --content-ads-settings: record # Settings specific to content ads (AFC) and highend mobile content ads (AFMC - deprecated). — shape: {backupOption?: record, size?: string, type?: string}
  --custom-style: record # shape: {colors?: record, corners?: string, font?: record, kind?: string}
  --id: string # Unique identifier of this ad unit. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#adUnit. (default: adsensehost#adUnit)
  --mobile-content-ads-settings: record # Settings specific to WAP mobile content ads (AFMC - deprecated). — shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
  --name: string # Name of this ad unit.
  --status: string # Status of this ad unit. Possible values are: NEW: Indicates that the ad unit was created within the last seven days and does not yet have any activity associated with it. ACTIVE: Indicates that there has been activity on this ad unit in the last seven days. INACTIVE: Indicates that there has been no activity on this ad unit in the last seven days.
]: any -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits") $qp)
  let req_body = {"code": $code, "contentAdsSettings": $content_ads_settings, "customStyle": $custom_style, "id": $id, "kind": $kind, "mobileContentAdsSettings": $mobile_content_ads_settings, "name": $name, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Update the supplied ad unit in the specified publisher AdSense account.
#
# PUT /accounts/{accountId}/adclients/{adClientId}/adunits
# operationId: adsensehost.accounts.adunits.update
# --contentAdsSettings shape: {backupOption?: record, size?: string, type?: string}
# --customStyle shape: {colors?: record, corners?: string, font?: record, kind?: string}
# --mobileContentAdsSettings shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
export def "accounts-adclients-adunits update-by-account-id-ad-client-id-1" [
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
  --code: string # Identity code of this ad unit, not necessarily unique across ad clients.
  --content-ads-settings: record # Settings specific to content ads (AFC) and highend mobile content ads (AFMC - deprecated). — shape: {backupOption?: record, size?: string, type?: string}
  --custom-style: record # shape: {colors?: record, corners?: string, font?: record, kind?: string}
  --id: string # Unique identifier of this ad unit. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#adUnit. (default: adsensehost#adUnit)
  --mobile-content-ads-settings: record # Settings specific to WAP mobile content ads (AFMC - deprecated). — shape: {markupLanguage?: string, scriptingLanguage?: string, size?: string, type?: string}
  --name: string # Name of this ad unit.
  --status: string # Status of this ad unit. Possible values are: NEW: Indicates that the ad unit was created within the last seven days and does not yet have any activity associated with it. ACTIVE: Indicates that there has been activity on this ad unit in the last seven days. INACTIVE: Indicates that there has been no activity on this ad unit in the last seven days.
]: any -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits") $qp)
  let req_body = {"code": $code, "contentAdsSettings": $content_ads_settings, "customStyle": $custom_style, "id": $id, "kind": $kind, "mobileContentAdsSettings": $mobile_content_ads_settings, "name": $name, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Delete the specified ad unit from the specified publisher AdSense account.
#
# DELETE /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsensehost.accounts.adunits.delete
export def "accounts-adclients-adunits delete" [
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits/{ad_unit_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Get the specified host ad unit in this AdSense account.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}
# operationId: adsensehost.accounts.adunits.get
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
]: nothing -> record<code: string, contentAdsSettings: record<backupOption: record<color: string, type: string, url: string>, size: string, type: string>, customStyle: record<colors: record<background: string, border: string, text: string, title: string, url: string>, corners: string, font: record<family: string, size: string>, kind: string>, id: string, kind: string, mobileContentAdsSettings: record<markupLanguage: string, scriptingLanguage: string, size: string, type: string>, name: string, status: string> {
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

# Get ad code for the specified ad unit, attaching the specified host custom channels.
#
# GET /accounts/{accountId}/adclients/{adClientId}/adunits/{adUnitId}/adcode
# operationId: adsensehost.accounts.adunits.getAdCode
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
  --host-custom-channel-id: list<string> # Host custom channel to attach to the ad code.
]: nothing -> record<adCode: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($ad_unit_id | is-empty) { error make --unspanned { msg: "path parameter 'adUnitId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "hostCustomChannelId" $host_custom_channel_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), ad_client_id: (encode-path-segment $ad_client_id), ad_unit_id: (encode-path-segment $ad_unit_id)} | format pattern "/accounts/{account_id}/adclients/{ad_client_id}/adunits/{ad_unit_id}/adcode") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "hostCustomChannelId": $host_custom_channel_id} | compact), body: null}
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /accounts/{accountId}/reports
# operationId: adsensehost.accounts.reports.generate
export def "accounts-reports generate" [
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
  --dimension: list<string> # Dimensions to base the report on.
  --filter: list<string> # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --metric: list<string> # Numeric columns to include in the report.
  --qp-sort: list<string> # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --start-index: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "startDate": $start_date, "endDate": $end_date, "dimension": $dimension, "filter": $filter, "locale": $locale, "maxResults": $max_results, "metric": $metric, "sort": $qp_sort, "startIndex": $start_index} | compact), body: null}
}

# List all host ad clients in this AdSense account.
#
# GET /adclients
# operationId: adsensehost.adclients.list
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

# Get information about one of the ad clients in the Host AdSense account.
#
# GET /adclients/{adClientId}
# operationId: adsensehost.adclients.get
export def "adclients get" [
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
]: nothing -> record<arcOptIn: bool, id: string, kind: string, productCode: string, supportsReporting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# List all host custom channels in this AdSense account.
#
# GET /adclients/{adClientId}/customchannels
# operationId: adsensehost.customchannels.list
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
]: nothing -> record<etag: string, items: table<code: string, id: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/customchannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Update a custom channel in the host AdSense account. This method supports patch semantics.
#
# PATCH /adclients/{adClientId}/customchannels
# operationId: adsensehost.customchannels.patch
export def "adclients-customchannels update-by-ad-client-id" [
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
  --custom-channel-id: string # Custom channel to get.
  --code: string # Code of this custom channel, not necessarily unique across ad clients.
  --id: string # Unique identifier of this custom channel. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#customChannel. (default: adsensehost#customChannel)
  --name: string # Name of this custom channel.
]: any -> record<code: string, id: string, kind: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "customChannelId" $custom_channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/customchannels") $qp)
  let req_body = {"code": $code, "id": $id, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "customChannelId": $custom_channel_id} | compact), body: $req_body}
}

# Add a new custom channel to the host AdSense account.
#
# POST /adclients/{adClientId}/customchannels
# operationId: adsensehost.customchannels.insert
export def "adclients-customchannels create" [
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
  --code: string # Code of this custom channel, not necessarily unique across ad clients.
  --id: string # Unique identifier of this custom channel. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#customChannel. (default: adsensehost#customChannel)
  --name: string # Name of this custom channel.
]: any -> record<code: string, id: string, kind: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/customchannels") $qp)
  let req_body = {"code": $code, "id": $id, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Update a custom channel in the host AdSense account.
#
# PUT /adclients/{adClientId}/customchannels
# operationId: adsensehost.customchannels.update
export def "adclients-customchannels update-by-ad-client-id-1" [
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
  --code: string # Code of this custom channel, not necessarily unique across ad clients.
  --id: string # Unique identifier of this custom channel. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#customChannel. (default: adsensehost#customChannel)
  --name: string # Name of this custom channel.
]: any -> record<code: string, id: string, kind: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/customchannels") $qp)
  let req_body = {"code": $code, "id": $id, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Delete a specific custom channel from the host AdSense account.
#
# DELETE /adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsensehost.customchannels.delete
export def "adclients-customchannels delete" [
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
]: nothing -> record<code: string, id: string, kind: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($custom_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'customChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), custom_channel_id: (encode-path-segment $custom_channel_id)} | format pattern "/adclients/{ad_client_id}/customchannels/{custom_channel_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Get a specific custom channel from the host AdSense account.
#
# GET /adclients/{adClientId}/customchannels/{customChannelId}
# operationId: adsensehost.customchannels.get
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
]: nothing -> record<code: string, id: string, kind: string, name: string> {
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

# List all host URL channels in the host AdSense account.
#
# GET /adclients/{adClientId}/urlchannels
# operationId: adsensehost.urlchannels.list
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

# Add a new URL channel to the host AdSense account.
#
# POST /adclients/{adClientId}/urlchannels
# operationId: adsensehost.urlchannels.insert
export def "adclients-urlchannels create" [
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
  --id: string # Unique identifier of this URL channel. This should be considered an opaque identifier; it is not safe to rely on it being in any particular format.
  --kind: string # Kind of resource this is, in this case adsensehost#urlChannel. (default: adsensehost#urlChannel)
  --url-pattern: string # URL Pattern of this URL channel. Does not include "http://" or "https://". Example: www.example.com/home
]: any -> record<id: string, kind: string, urlPattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id)} | format pattern "/adclients/{ad_client_id}/urlchannels") $qp)
  let req_body = {"id": $id, "kind": $kind, "urlPattern": $url_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Delete a URL channel from the host AdSense account.
#
# DELETE /adclients/{adClientId}/urlchannels/{urlChannelId}
# operationId: adsensehost.urlchannels.delete
export def "adclients-urlchannels delete" [
  ad_client_id: string
  url_channel_id: string
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
]: nothing -> record<id: string, kind: string, urlPattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ad_client_id | is-empty) { error make --unspanned { msg: "path parameter 'adClientId' must be non-empty" } }
  if ($url_channel_id | is-empty) { error make --unspanned { msg: "path parameter 'urlChannelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ad_client_id: (encode-path-segment $ad_client_id), url_channel_id: (encode-path-segment $url_channel_id)} | format pattern "/adclients/{ad_client_id}/urlchannels/{url_channel_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Create an association session for initiating an association with an AdSense user.
#
# GET /associationsessions/start
# operationId: adsensehost.associationsessions.start
export def "associationsessions-start start" [
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
  --product-code: list<string> # Products to associate with the user.
  --website-url: string # The URL of the user's hosted website.
  --callback-url: string # The URL to redirect the user to once association is completed. It receives a token parameter that can then be used to retrieve the associated account.
  --user-locale: string # The preferred locale of the user.
  --website-locale: string # The locale of the user's hosted website.
]: nothing -> record<accountId: string, id: string, kind: string, productCodes: list<string>, redirectUrl: string, status: string, userLocale: string, websiteLocale: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "productCode" $product_code "multi") (serialize-qp "websiteUrl" $website_url "scalar") (serialize-qp "callbackUrl" $callback_url "scalar") (serialize-qp "userLocale" $user_locale "scalar") (serialize-qp "websiteLocale" $website_locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/associationsessions/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "productCode": $product_code, "websiteUrl": $website_url, "callbackUrl": $callback_url, "userLocale": $user_locale, "websiteLocale": $website_locale} | compact), body: null}
}

# Verify an association session after the association callback returns from AdSense signup.
#
# GET /associationsessions/verify
# operationId: adsensehost.associationsessions.verify
export def "associationsessions-verify verify" [
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
  --qp-token: string # The token returned to the association callback URL.
]: nothing -> record<accountId: string, id: string, kind: string, productCodes: list<string>, redirectUrl: string, status: string, userLocale: string, websiteLocale: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/associationsessions/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "token": $qp_token} | compact), body: null}
}

# Generate an AdSense report based on the report request sent in the query parameters. Returns the result as JSON; to retrieve output in CSV format specify "alt=csv" as a query parameter.
#
# GET /reports
# operationId: adsensehost.reports.generate
export def "reports generate" [
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
  --dimension: list<string> # Dimensions to base the report on.
  --filter: list<string> # Filters to be run on the report.
  --locale: string # Optional locale to use for translating report output to a local language. Defaults to "en_US" if not specified.
  --max-results: int # The maximum number of rows of report data to return.
  --metric: list<string> # Numeric columns to include in the report.
  --qp-sort: list<string> # The name of a dimension or metric to sort the resulting report on, optionally prefixed with "+" to sort ascending or "-" to sort descending. If no prefix is specified, the column is sorted ascending.
  --start-index: int # Index of the first row of report data to return.
]: nothing -> record<averages: list<string>, headers: table<currency: string, name: string, type: string>, kind: string, rows: list<list<string>>, totalMatchedRows: string, totals: list<string>, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "dimension" $dimension "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "metric" $metric "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "startDate": $start_date, "endDate": $end_date, "dimension": $dimension, "filter": $filter, "locale": $locale, "maxResults": $max_results, "metric": $metric, "sort": $qp_sort, "startIndex": $start_index} | compact), body: null}
}
