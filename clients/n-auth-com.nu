# Auto-generated client for nextAuth API v2.2
# Source: https://api.apis.guru/v2/specs/n-auth.com/2.2/swagger.json
# Auth: --token flag or $env.NEXTAUTH_API_TOKEN

const BASE_URL = "https://api.nextauth.com"
const DEFAULT_AUTH = "x-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEXTAUTH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-apikey" => { {headers: {X-apikey: $token_val}, query: ""} }
    "x-su" => { {headers: {X-su: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.nextauth.com"] }
def auth-scheme-completer [] { ["x-apikey" "x-su"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apikeys get" } } | get name | first)
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

# Get all API keys.
#
# GET /apikeys/
# operationId: getApiKeys
export def "apikeys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apikeys: table<apikey: string, description: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apikeys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new API key.
#
# POST /apikeys/
# operationId: createApiKey
export def "apikeys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description for the new role
]: nothing -> record<apikey: string, description: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all global attributes
#
# DELETE /attributes/
# operationId: deleteGlobalAttributes
export def "attributes delete-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all global attributes
#
# GET /attributes/
# operationId: getGlobalAttributes
export def "attributes get-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set all global attributes
#
# POST /attributes/
# operationId: setGlobalAttributes
export def "attributes setGlobalAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update specified global attributes
#
# PUT /attributes/
# operationId: updateGlobalAttributes
export def "attributes update-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete specific global attribute
#
# DELETE /attributes/{attributekey}
# operationId: deleteGlobalAttribute
export def "attributes delete-global-by-attributekey" [
  attributekey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attributekey: $attributekey} | format pattern "/attributes/{attributekey}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all your servers
#
# GET /servers/
# operationId: getServers
export def "servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
]: nothing -> record<servers: table<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new server
#
# POST /servers/
# operationId: createServer
export def "servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list # Server flags
  server_name: string # Server name
  serverid: string # Base64 encoded id of the nextAuth server
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servers/")
  let body = {"accountCount": $account_count, "appandroid": $appandroid, "appios": $appios, "appname": $appname, "appurl": $appurl, "lastLogin": $last_login, "logo": $logo, "owner": $owner, "pinTimeout": $pin_timeout, "pinTransTimeout": $pin_trans_timeout, "pingTime": $ping_time, "serverFlags": $server_flags, "serverName": $server_name, "serverid": $serverid, "serverpk": $serverpk, "siteurl": $siteurl, "wsurl": $wsurl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configuration of a specific server
#
# GET /servers/{serverid}/
# operationId: getServer
export def "servers get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update configuration of a specific server
#
# PUT /servers/{serverid}/
# operationId: updateServer
export def "servers update" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list # Server flags
  server_name: string # Server name
  --body-serverid: string # Base64 encoded id of the nextAuth server
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/"))
  let body = {"accountCount": $account_count, "appandroid": $appandroid, "appios": $appios, "appname": $appname, "appurl": $appurl, "lastLogin": $last_login, "logo": $logo, "owner": $owner, "pinTimeout": $pin_timeout, "pinTransTimeout": $pin_trans_timeout, "pingTime": $ping_time, "serverFlags": $server_flags, "serverName": $server_name, "serverid": $body_serverid, "serverpk": $serverpk, "siteurl": $siteurl, "wsurl": $wsurl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all accounts
#
# GET /servers/{serverid}/accounts/
# operationId: getAllAccounts
export def "servers-accounts get-all" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/accounts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete specific account
#
# DELETE /servers/{serverid}/accounts/{accountid}/
# operationId: deleteAccount
export def "servers-accounts delete" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, accountid: $accountid} | format pattern "/servers/{serverid}/accounts/{accountid}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get specific account
#
# GET /servers/{serverid}/accounts/{accountid}/
# operationId: getAccount
export def "servers-accounts get" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, accountid: $accountid} | format pattern "/servers/{serverid}/accounts/{accountid}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update specific account
#
# PUT /servers/{serverid}/accounts/{accountid}/
# operationId: updateAccount
export def "servers-accounts update" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocked: oneof<nothing, bool> # True if the account is blocked
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blocked" $blocked "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid, accountid: $accountid} | format pattern "/servers/{serverid}/accounts/{accountid}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/accounts/{accountid}/provokelogin
# operationId: provokeLoginOnAccount
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-accounts-provokelogin provokeLoginOnAccount" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Base64 encoded nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, accountid: $accountid} | format pattern "/servers/{serverid}/accounts/{accountid}/provokelogin"))
  let body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update user of the given account.
#
# PUT /servers/{serverid}/accounts/{accountid}/user
# operationId: updateAccountUser
export def "servers-accounts-user update" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # User name
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid, accountid: $accountid} | format pattern "/servers/{serverid}/accounts/{accountid}/user") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all attributes of a specific server
#
# DELETE /servers/{serverid}/attributes/
# operationId: deleteServerAttributes
export def "servers-attributes delete-by-serverid" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/attributes/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all attributes of a specific server
#
# GET /servers/{serverid}/attributes/
# operationId: getServerAttributes
export def "servers-attributes get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/attributes/"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set all attributes of a specific server
#
# POST /servers/{serverid}/attributes/
# operationId: setServerAttributes
export def "servers-attributes setServerAttributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/attributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update specified attributes of a specific server
#
# PUT /servers/{serverid}/attributes/
# operationId: updateServerAttributes
export def "servers-attributes update" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/attributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete specific attribute of a specific server
#
# DELETE /servers/{serverid}/attributes/{attributekey}
# operationId: deleteServerAttribute
export def "servers-attributes delete-by-serverid-attributekey" [
  serverid: string
  attributekey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, attributekey: $attributekey} | format pattern "/servers/{serverid}/attributes/{attributekey}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all permissions for the specified server.
#
# GET /servers/{serverid}/permissions/
# operationId: getAllPermissions
export def "servers-permissions get-all" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: table<acl: string, role: string, server: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/permissions/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke all permissions for the specified server and role.
#
# DELETE /servers/{serverid}/permissions/{roleid}
# operationId: revokePermissions
export def "servers-permissions delete" [
  serverid: string
  roleid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, roleid: $roleid} | format pattern "/servers/{serverid}/permissions/{roleid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all permissions for the specified server and role.
#
# GET /servers/{serverid}/permissions/{roleid}
# operationId: getPermissions
export def "servers-permissions get" [
  serverid: string
  roleid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: table<acl: string, role: string, server: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, roleid: $roleid} | format pattern "/servers/{serverid}/permissions/{roleid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set new permissions for the specified role on a server
#
# POST /servers/{serverid}/permissions/{roleid}
# operationId: grantPermissions
export def "servers-permissions grantPermissions" [
  serverid: string
  roleid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, roleid: $roleid} | format pattern "/servers/{serverid}/permissions/{roleid}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all privileged attributes of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/
# operationId: deleteServerPrivilegedAttributes
export def "servers-privilegedattributes delete-by-serverid" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/privilegedattributes/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all privileged attributes of a specific server
#
# GET /servers/{serverid}/privilegedattributes/
# operationId: getServerPrivilegedAttributes
export def "servers-privilegedattributes get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/privilegedattributes/"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set all privileged attributes of a specific server
#
# POST /servers/{serverid}/privilegedattributes/
# operationId: setServerPrivilegedAttributes
export def "servers-privilegedattributes setServerPrivilegedAttributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/privilegedattributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update privileged specified attributes of a specific server
#
# PUT /servers/{serverid}/privilegedattributes/
# operationId: updateServerPrivilegedAttributes
export def "servers-privilegedattributes update" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/privilegedattributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete specific privileged attribute of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/{attributekey}
# operationId: deleteServerPrivilegedAttribute
export def "servers-privilegedattributes delete-by-serverid-attributekey" [
  serverid: string
  attributekey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, attributekey: $attributekey} | format pattern "/servers/{serverid}/privilegedattributes/{attributekey}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if the user is logged in
#
# GET /servers/{serverid}/sessions/
# operationId: getSession
export def "servers-sessions get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> record<accountid: int, canprovoke: bool, hsid: string, loggedin: bool, loginqrdata: string, pk: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/"))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate HTML to enrol a new user
#
# GET /servers/{serverid}/sessions/html/enrol
# operationId: getHtmlEnrol
export def "servers-sessions-html-enrol get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account
  --userid: string # User name to register this user under
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/html/enrol") $qp)
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generic HTML to add to footer. Required for login/logout/enrol functionality.
#
# GET /servers/{serverid}/sessions/html/footer
# operationId: getHtmlFooter
# --sessions item shape: {serverid: string, sessionid: string}
export def "servers-sessions-html-footer get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --sessions: list # item shape: {serverid: string, sessionid: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/html/footer"))
  let body = {"sessions": $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate HTML for the login block
#
# GET /servers/{serverid}/sessions/html/login
# operationId: getHtmlLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-html-login get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/html/login"))
  let body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Force a logout on the given session
#
# POST /servers/{serverid}/sessions/logout
# operationId: logout
export def "servers-sessions-logout logout" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/logout"))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/sessions/provokelogin
# operationId: provokeLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-provokelogin provokeLogin" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/provokelogin"))
  let body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate data for an enrol qr code
#
# GET /servers/{serverid}/sessions/qr/enrol
# operationId: getQrEnrol
export def "servers-sessions-qr-enrol get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account
  --userid: string # User name to register this user under
  --img: string # 'png' for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "userid" $userid "scalar") (serialize-qp "img" $img "scalar") (serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/qr/enrol") $qp)
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate data for a login qr code
#
# GET /servers/{serverid}/sessions/qr/login
# operationId: getQrLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-qr-login get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --img: string # "png" for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "img" $img "scalar") (serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/qr/login") $qp)
  let body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Register a userid for the currently logged in account.
#
# POST /servers/{serverid}/sessions/registeruser
# operationId: registerUser
export def "servers-sessions-registeruser create-user" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # Username to register
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/registeruser") $qp)
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transaction to be approved within the current session.
#
# POST /servers/{serverid}/sessions/transactions
# operationId: createTransaction
export def "servers-sessions-transactions create" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --amount: string
  --benificiary: string
  --description: string
]: any -> record<tid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/sessions/transactions"))
  let body = {"amount": $amount, "benificiary": $benificiary, "description": $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get transaction result for a given transaction.
#
# GET /servers/{serverid}/transactions/{transactionid}
# operationId: getTransactionResult
export def "servers-transactions get-transaction-result" [
  serverid: string
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tstatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, transactionid: $transactionid} | format pattern "/servers/{serverid}/transactions/{transactionid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users
#
# GET /servers/{serverid}/users/
# operationId: getUsers
export def "servers-users get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --search: string # Search for a username LIKE %search%
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<totalnumber: int, users: table<lastlogin: int, numberaccounts: int, userid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/users/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific user
#
# DELETE /servers/{serverid}/users/{userid}/
# operationId: deleteUser
export def "servers-users delete" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all accounts of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/accounts
# operationId: deleteUserAccounts
export def "servers-users-accounts delete" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/accounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all accounts of a specific user
#
# GET /servers/{serverid}/users/{userid}/accounts
# operationId: getUser
export def "servers-users-accounts get" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all attributes of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/
# operationId: deleteUserAttributes
export def "servers-users-attributes delete-by-serverid-userid" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/attributes/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all attributes of a specific user
#
# GET /servers/{serverid}/users/{userid}/attributes/
# operationId: getUserAttributes
export def "servers-users-attributes get" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/attributes/"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set all attributes of a specific user
#
# POST /servers/{serverid}/users/{userid}/attributes/
# operationId: setUserAttributes
export def "servers-users-attributes setUserAttributes" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/attributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update specified attributes of a specific user
#
# PUT /servers/{serverid}/users/{userid}/attributes/
# operationId: updateUserAttributes
export def "servers-users-attributes update" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/attributes/"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete specific attribute of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/{attributekey}
# operationId: deleteUserAttribute
export def "servers-users-attributes delete-by-serverid-userid-attributekey" [
  serverid: string
  userid: string
  attributekey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid, attributekey: $attributekey} | format pattern "/servers/{serverid}/users/{userid}/attributes/{attributekey}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/users/{userid}/provokelogin
# operationId: provokeLoginOnUser
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-users-provokelogin provokeLoginOnUser" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/provokelogin"))
  let body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get role for a specific user.
#
# GET /servers/{serverid}/users/{userid}/role/
# operationId: getUserRole
export def "servers-users-role get" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/role/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get or create a role for a specific user.
#
# POST /servers/{serverid}/users/{userid}/role/
# operationId: getOrCreateUserRole
export def "servers-users-role get-or-create" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid, userid: $userid} | format pattern "/servers/{serverid}/users/{userid}/role/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Visual hash of this server
#
# GET /servers/{serverid}/vash
# operationId: getServerVash
export def "servers-vash get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serverid: $serverid} | format pattern "/servers/{serverid}/vash"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
