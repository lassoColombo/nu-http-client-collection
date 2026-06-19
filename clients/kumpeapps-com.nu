# Auto-generated client for KumpeApps API v5.0.0
# Source: https://api.apis.guru/v2/specs/kumpeapps.com/5.0.0/openapi.json
# Auth: --token flag or $env.KUMPEAPPS_API_TOKEN

const BASE_URL = "https://restapi.kumpeapps.com/v5"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KUMPEAPPS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-auth" => { {scheme: $scheme, headers: {X-Auth: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://restapi.kumpeapps.com/v5" "https://restapi.preprod.kumpeapps.com/v5"] }
def auth-scheme-completer [] { ["x-auth"] }

# Completers for enum parameters
def transaction-type-completer [] { ["Add" "Subtract"] }
def tool-completer [] { ["register" "send" "subscribe" "unsubscribe"] }
def section-completer [] { ["Allowance" "Allowance-New" "Chores" "Chores-New" "Chores-Reminders" "WishList"] }
def priority-completer [] { ["active" "critical" "passive" "time-sensitive"] }
def day-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday" "Weekly"] }
def day-completer-1 [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Today" "Tuesday" "Wednesday" "Weekly"] }
def where-day-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Today" "Tuesday" "Wednesday" "Weekly"] }
def link-completer [] { ["https://khome.kumpeapps.com/portal/chores-today.php" "https://khome.kumpeapps.com/portal/wish-list.php"] }
def scope-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope2-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope3-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope4-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "appkey update" } } | get name | first)
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

# Compromise app key
#
# PATCH /appkey
# DEPRECATED
# operationId: appkey_patch
@deprecated
export def "appkey update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # compromised app key
  --comments: string # Comments (like how was this compromised)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_key" $app_key "scalar") (serialize-qp "comments" $comments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app_key": $app_key, "comments": $comments} | compact), body: null}
}

# Request app key
#
# POST /appkey
# DEPRECATED
# operationId: appkey_post
@deprecated
export def "appkey create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username assigned to your app
  --password: string # Password assigned to your app (format: password)
  --supports-yubikey: oneof<nothing, bool> # App supports YubiKey OTP
]: nothing -> record<app_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "supportsYubikey" $supports_yubikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "supportsYubikey": $supports_yubikey} | compact), body: null}
}

# Deactivate app key
#
# PUT /appkey
# DEPRECATED
# operationId: appkey_put
@deprecated
export def "appkey update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # app key to deactivate
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_key" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app_key": $app_key} | compact), body: null}
}

# Compromise app key
#
# PATCH /authentication/appkey
# operationId: auth_appkey_patch
export def "authentication-appkey update-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # compromised app key
  --comments: string # Comments (like how was this compromised)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_key" $app_key "scalar") (serialize-qp "comments" $comments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app_key": $app_key, "comments": $comments} | compact), body: null}
}

# Request app key
#
# POST /authentication/appkey
# operationId: auth_appkey_post
export def "authentication-appkey create-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username assigned to your app
  --password: string # Password assigned to your app (format: password)
  --supports-yubikey: oneof<nothing, bool> # App supports YubiKey OTP
]: nothing -> record<app_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "supportsYubikey" $supports_yubikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "supportsYubikey": $supports_yubikey} | compact), body: null}
}

# Deactivate app key
#
# PUT /authentication/appkey
# operationId: auth_appkey_put
export def "authentication-appkey update-auth-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # app key to deactivate
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_key" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/appkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app_key": $app_key} | compact), body: null}
}

# Request auth key for user (login user)
#
# GET /authentication/authkey
# operationId: auth_authkey_get
export def "authentication-authkey get-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username
  --password: string # Authenticated password (format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
  --device-name: string # User's device name
  --identifier-for-vendor: string # identifierForVendor for User's Device (if app is iOS)
]: nothing -> record<auth_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "otp" $otp "scalar") (serialize-qp "deviceName" $device_name "scalar") (serialize-qp "identifierForVendor" $identifier_for_vendor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "otp": $otp, "deviceName": $device_name, "identifierForVendor": $identifier_for_vendor} | compact), body: null}
}

# Compromise auth key
#
# PATCH /authentication/authkey
# operationId: auth_authkey_patch
export def "authentication-authkey update-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to mark as compromised (format: password)
  --comments: string # Comments (like how was this compromised)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_key" $auth_key "scalar") (serialize-qp "comments" $comments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"auth_key": $auth_key, "comments": $comments} | compact), body: null}
}

# Request auth key for user (login user)
#
# POST /authentication/authkey
# operationId: auth_authkey_post
export def "authentication-authkey create-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username
  --password: string # Authenticated password (format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> record<auth_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "otp" $otp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "otp": $otp} | compact), body: null}
}

# Deactivate auth key (logout)
#
# PUT /authentication/authkey
# operationId: auth_authkey_put
export def "authentication-authkey update-auth-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to logout (format: password)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_key" $auth_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"auth_key": $auth_key} | compact), body: null}
}

# Verifies YubiKey OTP for authenticated user
#
# GET /authentication/verifyotp
# operationId: auth_verifyotp_get
export def "authentication-verifyotp get-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --otp: string # YubiKey OTP code
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "otp" $otp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication/verifyotp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"otp": $otp} | compact), body: null}
}

# Request auth key for user (login user)
#
# GET /authkey
# DEPRECATED
# operationId: authkey_get
@deprecated
export def "authkey get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username
  --password: string # Authenticated password (format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> record<auth_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "otp" $otp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "otp": $otp} | compact), body: null}
}

# Compromise auth key
#
# PATCH /authkey
# DEPRECATED
# operationId: authkey_patch
@deprecated
export def "authkey update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to mark as compromised (format: password)
  --comments: string # Comments (like how was this compromised)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_key" $auth_key "scalar") (serialize-qp "comments" $comments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"auth_key": $auth_key, "comments": $comments} | compact), body: null}
}

# Request auth key for user (login user)
#
# POST /authkey
# DEPRECATED
# operationId: authkey_post
@deprecated
export def "authkey create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username
  --password: string # Authenticated password (format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> record<auth_key: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "otp" $otp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "otp": $otp} | compact), body: null}
}

# Deactivate auth key (logout)
#
# PUT /authkey
# DEPRECATED
# operationId: authkey_put
@deprecated
export def "authkey update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to logout (format: password)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_key" $auth_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authkey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"auth_key": $auth_key} | compact), body: null}
}

# returns allowance balance and allowance transactions
#
# GET /kkid/allowance
# operationId: kkid_allowance_get
export def "kkid-allowance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
  --transaction-days: int # number of days you wish to search allowance transactions (default is 90 days)
]: nothing -> record<allowanceTransaction: table<amount: int, date: string, transactionDescription: string, transactionId: int, transactionType: string, userId: int>, balance: int, id: int, lastUpdated: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUserId" $kid_user_id "scalar") (serialize-qp "transactionDays" $transaction_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/allowance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUserId": $kid_user_id, "transactionDays": $transaction_days} | compact), body: null}
}

# adds new allowance transaction to kidUserID
#
# POST /kkid/allowance
# operationId: kkid_allowance_post
export def "kkid-allowance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
  --amount: float # amount you wish to Add/Subtract (subtract value should be a negative value)
  --description: string # Description (reason) of allowance transaction
  --transaction-type: string@transaction-type-completer # Transaction Type (Add/Subtract)
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUserId" $kid_user_id "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "transactionType" $transaction_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/allowance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUserId": $kid_user_id, "amount": $amount, "description": $description, "transactionType": $transaction_type} | compact), body: null}
}

# subscribes/unsubscribes/registers for apns push notifications
#
# POST /kkid/apns
# operationId: kkid_apns_post
export def "kkid-apns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
  --tool: string@tool-completer # tool you wish to talk to
  --qp-token: string # device APNS token (required for register)
  --devicename: string # Name of device to associate to token (required for register)
  --title: string # title of APNS message (required for send)
  --message: string # APNS message body (required for send)
  --badge: int # Number for badge icon (optional for send)
  --sound: string # Name of sound file to play for send notification (optional for send)
  --section: string@section-completer # Notification section name (required for send/subscribe/unsubscribe)
  --priority: string@priority-completer # Notification section name (optional for send, default is active)
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUserId" $kid_user_id "scalar") (serialize-qp "tool" $tool "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devicename" $devicename "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "badge" $badge "scalar") (serialize-qp "sound" $sound "scalar") (serialize-qp "section" $section "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/apns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUserId": $kid_user_id, "tool": $tool, "token": $qp_token, "devicename": $devicename, "title": $title, "message": $message, "badge": $badge, "sound": $sound, "section": $section, "priority": $priority} | compact), body: null}
}

# deletes chore for given chore id
#
# DELETE /kkid/chorelist
# operationId: kkid_chorelist_delete
export def "kkid-chorelist delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-chore-list: int # id of the chore you wish to delete
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idChoreList" $id_chore_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/chorelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"idChoreList": $id_chore_list} | compact), body: null}
}

# returns list of chores for given user
#
# GET /kkid/chorelist
# operationId: kkid_chorelist_get
export def "kkid-chorelist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-username: string # Username of kid you wish to search
  --day: string@day-completer # Day of week for chores (Weekly for weekly chores)
  --status: string # Status of Chore to search
  --block-dash: oneof<nothing, bool> # Filter results by blockDash parameter
  --optional: oneof<nothing, bool> # Filter results by optional parameter
  --can-steal: oneof<nothing, bool> # Filter results by canSteal parameter
  --include-calendar: oneof<nothing, bool> # include calendar notations (default is false)
]: nothing -> record<chore: table<aiIcon: string, altitude: int, blockDash: bool, choreDescription: string, choreName: string, choreNumber: int, day: string, extraAllowance: int, idChoreList: int, isCalendar: bool, kid: string, latitude: int, longitude: int, nfcTag: string, notes: string, oneTime: bool, optional: bool, reassignable: bool, reassigned: bool, requireObjectDetection: string, startDate: string, status: string, stolen: bool, stolenBy: string, updated: string, updatedBy: string>, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUsername" $kid_username "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "blockDash" $block_dash "scalar") (serialize-qp "optional" $optional "scalar") (serialize-qp "canSteal" $can_steal "scalar") (serialize-qp "includeCalendar" $include_calendar "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/chorelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUsername": $kid_username, "day": $day, "status": $status, "blockDash": $block_dash, "optional": $optional, "canSteal": $can_steal, "includeCalendar": $include_calendar} | compact), body: null}
}

# adds chore for given user
#
# POST /kkid/chorelist
# operationId: kkid_chorelist_post
export def "kkid-chorelist create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-username: string # username of kid to assign the chore to.
  --day: string@day-completer-1 # day of week (Monday, Tuesday....) for the chore. For weekly chores put Weekly or leave blank
  --nfc-tag: string # text field of nfc tag required to check off chore
  --status: string # status of chore (default is todo)
  --chore-name: string # name of chore
  --chore-description: string # optional chore description
  --chore-number: int # number priority of chore (default is 5)
  --block-dash: oneof<nothing, bool> # block dash option on this chore
  --one-time: oneof<nothing, bool> # mark as one time chore (does not repeat each week)
  --extra-allowance: int # ammount of allowance added at end of week for completing this chore
  --optional: oneof<nothing, bool> # mark as optional chore
  --reassignable: oneof<nothing, bool> # mark as reassignable (default is true)
  --can-steal: oneof<nothing, bool> # mark as sibling can steal chore
  --start-date: string # date (yyyy-mm-dd) that you wish the chore to start showing up. (default is today)
  --notes: string # notes added to chore (visable only on reports, kids do not see this note, this is mostly just for the developer)
  --require-object-detection: oneof<nothing, bool> # require use of camera to detect object detection tag order to check off chore
  --object-detection-tag: string # tag for object detection to search for (required if requireObjectDetection is true)
  --updated-by-automation: oneof<nothing, bool> # true if chore updated via API from an Automation System
  --ai-icon: string # Notes if AI Icons should be used (n for no, y for yes, e for yes- error)
  --is-calendar: oneof<nothing, bool> # True if this is a calendar note instead of a chore.
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUsername" $kid_username "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "nfcTag" $nfc_tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "choreName" $chore_name "scalar") (serialize-qp "choreDescription" $chore_description "scalar") (serialize-qp "choreNumber" $chore_number "scalar") (serialize-qp "blockDash" $block_dash "scalar") (serialize-qp "oneTime" $one_time "scalar") (serialize-qp "extraAllowance" $extra_allowance "scalar") (serialize-qp "optional" $optional "scalar") (serialize-qp "reassignable" $reassignable "scalar") (serialize-qp "canSteal" $can_steal "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "requireObjectDetection" $require_object_detection "scalar") (serialize-qp "objectDetectionTag" $object_detection_tag "scalar") (serialize-qp "updatedByAutomation" $updated_by_automation "scalar") (serialize-qp "aiIcon" $ai_icon "scalar") (serialize-qp "isCalendar" $is_calendar "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/chorelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUsername": $kid_username, "day": $day, "nfcTag": $nfc_tag, "status": $status, "choreName": $chore_name, "choreDescription": $chore_description, "choreNumber": $chore_number, "blockDash": $block_dash, "oneTime": $one_time, "extraAllowance": $extra_allowance, "optional": $optional, "reassignable": $reassignable, "canSteal": $can_steal, "startDate": $start_date, "notes": $notes, "requireObjectDetection": $require_object_detection, "objectDetectionTag": $object_detection_tag, "updatedByAutomation": $updated_by_automation, "aiIcon": $ai_icon, "isCalendar": $is_calendar} | compact), body: null}
}

# updates chore for given chore id
#
# PUT /kkid/chorelist
# operationId: kkid_chorelist_put
export def "kkid-chorelist update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-chore-list: int # id number of chore you wish to update
  --status: string # new status of chore
  --stolen: oneof<nothing, bool> # mark chore as stolen by sibling
  --stolen-by: string # username of sibling that stole the chore (required if stolen is true)
  --nfc-tag: string # text field of NFC tag that is required to be scanned to check off this chore (normally null)
  --notes: string # notes field for chore
  --latitude: int # GPS latitude of where the chore was marked
  --longitude: int # GPS longitude of where the chore was marked
  --altitude: int # GPS altitude of where the chore was marked
  --updated-by-automation: oneof<nothing, bool> # true if updated via API by automation system
  --where-day: string@where-day-completer # Where day equals...
  --where-status: string # Where status equals...
  --where-name: string # Where chore name equals...
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idChoreList" $id_chore_list "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "stolen" $stolen "scalar") (serialize-qp "stolenBy" $stolen_by "scalar") (serialize-qp "nfcTag" $nfc_tag "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "updatedByAutomation" $updated_by_automation "scalar") (serialize-qp "whereDay" $where_day "scalar") (serialize-qp "whereStatus" $where_status "scalar") (serialize-qp "whereName" $where_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/chorelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"idChoreList": $id_chore_list, "status": $status, "stolen": $stolen, "stolenBy": $stolen_by, "nfcTag": $nfc_tag, "notes": $notes, "latitude": $latitude, "longitude": $longitude, "altitude": $altitude, "updatedByAutomation": $updated_by_automation, "whereDay": $where_day, "whereStatus": $where_status, "whereName": $where_name} | compact), body: null}
}

# adds new master user account
#
# POST /kkid/masteruser
# operationId: kkid_masteruser_post
export def "kkid-masteruser create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username of user to create
  --password: string # password of user to create (format: password)
  --email: string # email address of user to create
  --first-name: string # First Name of user to create
  --last-name: string # Last Name of user to create
]: nothing -> record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/masteruser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "email": $email, "firstName": $first_name, "lastName": $last_name} | compact), body: null}
}

# Create Share Link
#
# GET /kkid/share
# operationId: kkid_share_get
export def "kkid-share get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --link-user-id: string # User ID that the link should be authenticated to
  --link: string@link-completer # Link to share
  --scope: string@scope-completer # Authentication scope for link
  --scope2: string@scope2-completer # Authentication scope for link
  --scope3: string@scope3-completer # Authentication scope for link
  --scope4: string@scope4-completer # Authentication scope for link
]: nothing -> record<auth_link: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "linkUserId" $link_user_id "scalar") (serialize-qp "link" $link "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "scope2" $scope2 "scalar") (serialize-qp "scope3" $scope3 "scalar") (serialize-qp "scope4" $scope4 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/share" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"linkUserId": $link_user_id, "link": $link, "scope": $scope, "scope2": $scope2, "scope3": $scope3, "scope4": $scope4} | compact), body: null}
}

# Gets user info
#
# GET /kkid/user
# operationId: kkid_user_get
export def "kkid-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable-bool: oneof<nothing, bool> # Use bool values instead of Int 0/1
]: nothing -> record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enableBool" $enable_bool "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"enableBool": $enable_bool} | compact), body: null}
}

# deletes user
#
# DELETE /kkid/userlist
# operationId: kkid_userlist_delete
export def "kkid-userlist delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # userID of the user you wish to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/userlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"userID": $user_id} | compact), body: null}
}

# returns list of users
#
# GET /kkid/userlist
# operationId: kkid_userlist_get
export def "kkid-userlist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-child: oneof<nothing, bool> # Filter Search by isChild flag
  --is-active: oneof<nothing, bool> # Filter Search by isActive flag
  --is-admin: oneof<nothing, bool> # Filter Search by isAdmin flag
  --enable-allowance: oneof<nothing, bool> # Filter Search by enableAllowance flag
  --enable-chores: oneof<nothing, bool> # Filter Search by enableChores flag
  --user-id: int # userID of user to search
  --username: string # Username of user to search
  --email: string # Email address of user to search
]: nothing -> record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isChild" $is_child "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "isAdmin" $is_admin "scalar") (serialize-qp "enableAllowance" $enable_allowance "scalar") (serialize-qp "enableChores" $enable_chores "scalar") (serialize-qp "userID" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/userlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isChild": $is_child, "isActive": $is_active, "isAdmin": $is_admin, "enableAllowance": $enable_allowance, "enableChores": $enable_chores, "userID": $user_id, "username": $username, "email": $email} | compact), body: null}
}

# adds new child user
#
# POST /kkid/userlist
# operationId: kkid_userlist_post
export def "kkid-userlist create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username of user to create
  --password: string # password of user to create (format: password)
  --email: string # email address of user to create
  --first-name: string # First Name of user to create
  --last-name: string # Last Name of user to create
]: nothing -> record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/userlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password, "email": $email, "firstName": $first_name, "lastName": $last_name} | compact), body: null}
}

# updates user
#
# PUT /kkid/userlist
# operationId: kkid_userlist_put
export def "kkid-userlist update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # userID of the user you wish to update
  --username: string # username of user to create
  --email: string # email address of user to create
  --first-name: string # First Name of user to create
  --last-name: string # Last Name of user to create
  --emoji: string # emoji character for user
  --tmdb-key: string # User's TMdB Session Key
  --enable-wish-list: oneof<nothing, bool> # set status of Wish List module enabled
  --enable-chores: oneof<nothing, bool> # set status of chores module enabled
  --enable-allowance: oneof<nothing, bool> # set status of allowance module enabled
  --enable-admin: oneof<nothing, bool> # set status of isAdmin
  --enable-tmdb: oneof<nothing, bool> # set status of enableTmdb (movie and tv search)
  --enable-object-detection: oneof<nothing, bool> # set status of enableObjectDetection
]: nothing -> record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userID" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "emoji" $emoji "scalar") (serialize-qp "tmdbKey" $tmdb_key "scalar") (serialize-qp "enableWishList" $enable_wish_list "scalar") (serialize-qp "enableChores" $enable_chores "scalar") (serialize-qp "enableAllowance" $enable_allowance "scalar") (serialize-qp "enableAdmin" $enable_admin "scalar") (serialize-qp "enableTmdb" $enable_tmdb "scalar") (serialize-qp "enableObjectDetection" $enable_object_detection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/userlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"userID": $user_id, "username": $username, "email": $email, "firstName": $first_name, "lastName": $last_name, "emoji": $emoji, "tmdbKey": $tmdb_key, "enableWishList": $enable_wish_list, "enableChores": $enable_chores, "enableAllowance": $enable_allowance, "enableAdmin": $enable_admin, "enableTmdb": $enable_tmdb, "enableObjectDetection": $enable_object_detection} | compact), body: null}
}

# Delete item from wishlist
#
# DELETE /kkid/wishlist
# operationId: kkid_wishlist_delete
export def "kkid-wishlist delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wish-id: int # ID of wishlist item to delete
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wishId" $wish_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/wishlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"wishId": $wish_id} | compact), body: null}
}

# Get list of wishlist items
#
# GET /kkid/wishlist
# operationId: kkid_wishlist_get
export def "kkid-wishlist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
]: nothing -> record<success: bool, wish: table<description: string, id: int, link: string, master_id: int, priority: int, title: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUserId" $kid_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/wishlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUserId": $kid_user_id} | compact), body: null}
}

# Add item to kid's wishlist
#
# POST /kkid/wishlist
# operationId: kkid_wishlist_post
export def "kkid-wishlist create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
  --title: string # Item title
  --description: string # Item Description
  --priority: int # Item Priority
  --link: string # URL Link to item
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kidUserId" $kid_user_id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "link" $link "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/wishlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kidUserId": $kid_user_id, "title": $title, "description": $description, "priority": $priority, "link": $link} | compact), body: null}
}

# Update item on kid's wishlist
#
# PUT /kkid/wishlist
# operationId: kkid_wishlist_put
export def "kkid-wishlist update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wish-id: int # Wish list item ID to update
  --title: string # Item title
  --description: string # Item Description
  --priority: int # Item Priority
  --link: string # URL Link to item
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wishId" $wish_id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "link" $link "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kkid/wishlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"wishId": $wish_id, "title": $title, "description": $description, "priority": $priority, "link": $link} | compact), body: null}
}
