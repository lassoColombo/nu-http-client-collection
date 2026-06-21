# Auto-generated client for IoE² IoT API - to create end-user applications v3.0.0
# Source: https://api.apis.guru/v2/specs/ijenko.net/3.0.0/swagger.json
# Auth: --token flag or $env.IOE_IOT_API_TO_CREATE_END_USER_APPLICATIONS_TOKEN

const BASE_URL = "https://ioe2api.ijenko.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IOE_IOT_API_TO_CREATE_END_USER_APPLICATIONS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "access-token" => { {scheme: $scheme, headers: {Access-Token: $token_val}, query: "", location: "header"} }
    "query-token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "token")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://ioe2api.ijenko.net"] }
def auth-scheme-completer [] { ["access-token" "query-token" "none"] }

# Completers for enum parameters
def span-completer [] { ["D" "H" "M" "Wmo" "Wsu" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-change-password create" } } | get name | first)
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

# Change the password
#
# POST /account/change-password
# operationId: Account.changePassword
export def "account-change-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # format: password
  old_password: string # format: password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/change-password")
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Places of the Account
#
# GET /account/places
# operationId: Account.places
export def "account-places get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/places")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a Place
#
# POST /account/places
# operationId: Account.newPlace
export def "account-places create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string # e.g. ⌂ Home
  time_zone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  zip_code: string # Postal code
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/places")
  let req_body = {"country": $country, "metadata": $metadata, "name": $name, "timeZone": $time_zone, "zipCode": $zip_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List active Tokens of the Account
#
# GET /account/tokens
# operationId: Account.tokens
export def "account-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appName: string, id: string, lastUse: string, places: list<record>, refreshTokenExpires: string, self: bool, user: record<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Revoke a Token
#
# DELETE /account/tokens/{tokenId}
# operationId: Account.revokeToken
export def "account-tokens delete" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/account/tokens/{token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Users of the Account
#
# GET /account/users
# operationId: Account.users
export def "account-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/account/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed-metadata": $embed_metadata} | compact), body: null}
}

# New User
#
# POST /account/users
# operationId: Account.newUser
export def "account-users create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --phone-number: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users")
  let req_body = {"email": $email, "locale": $locale, "metadata": $metadata, "name": $name, "phoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a User
#
# DELETE /account/users/{userId}
# operationId: Account.deleteUser
export def "account-users delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/account/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Information about a User
#
# GET /account/users/{userId}
# operationId: Account.getUser
export def "account-users get" [
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
]: nothing -> record<account: string, canLogin: bool, email: string, locale: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/account/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify a User
#
# PATCH /account/users/{userId}
# operationId: Account.patchUser
export def "account-users update" [
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
  --email: string # format: email
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
  --name: string
  --phone-number: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/account/users/{user_id}"))
  let req_body = {"email": $email, "locale": $locale, "name": $name, "phoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List metadata
#
# GET /account/users/{userId}/metadata
# operationId: User.getMetadata
export def "account-users-metadata get" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/account/users/{user_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata
#
# PATCH /account/users/{userId}/metadata
# operationId: User.patchMetadata
export def "account-users-metadata update" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/account/users/{user_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a token using login+password
#
# POST /auth/login
# operationId: AuthAccountLogin
export def "auth-login create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  login: string
  password: string # format: password
  --ttl: int # Desired maximum life-time in seconds for the refresh token (e.g. 1800)
]: any -> record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let req_body = {"appId": $app_id, "login": $login, "password": $password, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Refresh a token
#
# POST /auth/refresh
# operationId: AuthRefreshToken
export def "auth-refresh refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  refresh_token: string
]: any -> record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let req_body = {"appId": $app_id, "refreshToken": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ask for a new password
#
# POST /auth/reset-password
# operationId: AuthResetPassword
export def "auth-reset-password reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  --email: string # format: email
  --login: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/reset-password")
  let req_body = {"appId": $app_id, "email": $email, "login": $login} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Revoke a token
#
# POST /auth/revoke
# operationId: AuthRevokeToken
export def "auth-revoke delete-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Information about a Device
#
# GET /devices/{deviceId}
# operationId: Devices.get
export def "devices get" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, attributes: record, class: string, functionalities: table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list>, isOnline: bool, manufacturer: string, metadata: record, model: string, name: string, place: string, protocol: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Device
#
# PATCH /devices/{deviceId}
# operationId: Devices.patch
export def "devices update" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the *Device* as defined by the user. Can be used for user interfaces.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add dynamically a functionality
#
# POST /devices/{deviceId}/functionalities
# operationId: Device.addFunctionality
export def "devices-functionalities create-functionality" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  --name: string # Free functionality name
  --tags: list<string>
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}/functionalities"))
  let req_body = {"metadata": $metadata, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List metadata
#
# GET /devices/{deviceId}/metadata
# operationId: Device.getMetadata
export def "devices-metadata get" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata
#
# PATCH /devices/{deviceId}/metadata
# operationId: Device.patchMetadata
export def "devices-metadata update" [
  device_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run actions
#
# POST /devices/{deviceId}/run/{action}
# operationId: Device.run
export def "devices-run create" [
  device_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ».
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let qp = [(serialize-qp "functionalities" $functionalities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id), action: (encode-path-segment $action)} | format pattern "/devices/{device_id}/run/{action}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"functionalities": $functionalities} | compact), body: $req_body}
}

# List tags
#
# GET /devices/{deviceId}/tags
# operationId: Device.getTags
export def "devices-tags get" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify tags
#
# PATCH /devices/{deviceId}/tags
# operationId: Device.patchTags
export def "devices-tags update" [
  device_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: list<string> # list of tags to add
  --remove: list<string> # list of tags to remove
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/devices/{device_id}/tags"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Information about a Functionality
#
# GET /functionalities/{functionalityId}
# operationId: Functionalities.get
export def "functionalities get" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: list<string>, attributes: list<string>, class: string, device: string, endpoint: int, metadata: record, name: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify a Functionality
#
# PATCH /functionalities/{functionalityId}
# operationId: Functionality.patch
export def "functionalities update" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Free functionality name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get history of multiple attributes
#
# GET /functionalities/{functionalityId}/attributes
# operationId: Functionality.values
export def "functionalities-attributes get-values" [
  functionality_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --names: list<string> # One or multiple *Attribute* names separated by commas
  --qp-from: string # Beginning of the time interval. (format: date-time)
  --qp-to: string # End of the interval. Default: now. (format: date-time)
  --surround: oneof<nothing, bool> # If true, return also one value before from and one value after to
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "surround" $surround "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}/attributes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"names": $names, "from": $qp_from, "to": $qp_to, "surround": $surround} | compact), body: null}
}

# Get an Attribute value
#
# GET /functionalities/{functionalityId}/attributes/{attributeName}
# operationId: Functionality.value
export def "functionalities-attributes get-value" [
  functionality_id: string
  attribute_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: any, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attributeName' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/functionalities/{functionality_id}/attributes/{attribute_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify an Attribute value
#
# PUT /functionalities/{functionalityId}/attributes/{attributeName}
# operationId: Functionality.set
export def "functionalities-attributes update" [
  functionality_id: string
  attribute_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attributeName' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/functionalities/{functionality_id}/attributes/{attribute_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List metadata
#
# GET /functionalities/{functionalityId}/metadata
# operationId: Functionality.getMetadata
export def "functionalities-metadata get" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata
#
# PATCH /functionalities/{functionalityId}/metadata
# operationId: Functionality.patchMetadata
export def "functionalities-metadata update" [
  functionality_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run an action
#
# POST /functionalities/{functionalityId}/run/{action}
# operationId: Functionality.run
export def "functionalities-run create" [
  functionality_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<functionality: string, result: list<any>, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id), action: (encode-path-segment $action)} | format pattern "/functionalities/{functionality_id}/run/{action}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List tags
#
# GET /functionalities/{functionalityId}/tags
# operationId: Functionality.getTags
export def "functionalities-tags get" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify tags
#
# PATCH /functionalities/{functionalityId}/tags
# operationId: Functionality.patchTags
export def "functionalities-tags update" [
  functionality_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: list<string> # list of tags to add
  --remove: list<string> # list of tags to remove
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($functionality_id | is-empty) { error make --unspanned { msg: "path parameter 'functionalityId' must be non-empty" } }
  let full_url = (build-url $base ({functionality_id: (encode-path-segment $functionality_id)} | format pattern "/functionalities/{functionality_id}/tags"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Information about the User
#
# GET /me
# operationId: Me.get
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string, locale: string, login: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update User information
#
# PATCH /me
# operationId: Me.patch
export def "me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let req_body = {"locale": $locale} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Notification
#
# DELETE /notifications/{notificationId}
# operationId: Notification.delete
export def "notifications delete" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({notification_id: (encode-path-segment $notification_id)} | format pattern "/notifications/{notification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Information about a Notification
#
# GET /notifications/{notificationId}
# operationId: Notifications.get
export def "notifications get" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, metadata: record, name: string, place: string, routing: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({notification_id: (encode-path-segment $notification_id)} | format pattern "/notifications/{notification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify a Notification
#
# PATCH /notifications/{notificationId}
# operationId: Notification.patch
export def "notifications update" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --name: string
  --routing: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({notification_id: (encode-path-segment $notification_id)} | format pattern "/notifications/{notification_id}"))
  let req_body = {"data": $data, "name": $name, "routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List metadata
#
# GET /notifications/{notificationId}/metadata
# operationId: Notification.getMetadata
export def "notifications-metadata get" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({notification_id: (encode-path-segment $notification_id)} | format pattern "/notifications/{notification_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata of a Notification
#
# PATCH /notifications/{notificationId}/metadata
# operationId: Notification.patchMetadata
export def "notifications-metadata update" [
  notification_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({notification_id: (encode-path-segment $notification_id)} | format pattern "/notifications/{notification_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List accessible Places
#
# GET /places
# operationId: Me.places
export def "places list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed-metadata": $embed_metadata} | compact), body: null}
}

# Information about a Place
#
# GET /places/{placeId}
# operationId: Places.get
export def "places get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, country: string, metadata: record, name: string, timeZone: string, zipCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Place
#
# PATCH /places/{placeId}
# operationId: Place.patch
export def "places update" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --name: string # e.g. ⌂ Home
  --time-zone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  --zip-code: string # Postal code
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}"))
  let req_body = {"country": $country, "name": $name, "timeZone": $time_zone, "zipCode": $zip_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Buses
#
# GET /places/{placeId}/buses
# operationId: Place.buses
export def "places-buses get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-pairing: oneof<nothing, bool> # Filter out buses that have no pairing window (default: false)
]: nothing -> table<functionality: string, id: string, protocol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "withPairing" $with_pairing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/buses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"withPairing": $with_pairing} | compact), body: null}
}

# State of the pairing window
#
# GET /places/{placeId}/buses/{busId}/pairing
# operationId: Place.pairing
export def "places-buses-pairing get" [
  place_id: string
  bus_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: int, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  if ($bus_id | is-empty) { error make --unspanned { msg: "path parameter 'busId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id), bus_id: (encode-path-segment $bus_id)} | format pattern "/places/{place_id}/buses/{bus_id}/pairing"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Open/Close the pairing window
#
# PUT /places/{placeId}/buses/{busId}/pairing
# operationId: Place.openPairing
export def "places-buses-pairing open" [
  place_id: string
  bus_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --duration: int # Duration of the pairing window.
  --enabled: oneof<nothing, bool>
]: any -> record<duration: int, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  if ($bus_id | is-empty) { error make --unspanned { msg: "path parameter 'busId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id), bus_id: (encode-path-segment $bus_id)} | format pattern "/places/{place_id}/buses/{bus_id}/pairing"))
  let req_body = {"duration": $duration, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List of Devices
#
# GET /places/{placeId}/devices
# operationId: Place.devices
export def "places-devices get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<address: string, class: string, id: string, isOnline: bool, metadata: record, name: string, place: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "devices" $devices "scalar") (serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"devices": $devices, "embed-metadata": $embed_metadata} | compact), body: null}
}

# Get autonomy rate of the place
#
# GET /places/{placeId}/electricity/autonomy
# operationId: Place.Electricity.autonomy
export def "places-electricity-autonomy get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year)
]: nothing -> record<autonomy: float, code: int, from: string, message: string, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "when" $when "scalar") (serialize-qp "span" $span "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/electricity/autonomy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"when": $when, "span": $span} | compact), body: null}
}

# Get electricity virtual flows
#
# GET /places/{placeId}/electricity/flows
# operationId: Place.Electricity.getFlows
export def "places-electricity-flows get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flows: list<string> # Names of the flows requested
]: nothing -> record<code: int, flows: record<battery_charge: list<record>, battery_discharge: list<record>, battery_grid: list<record>, elec_drawn: list<record>, elec_feed_in: list<record>, elec_from_household: list<record>, elec_local: list<record>, elec_to_pv: list<record>, elec_total_gen: list<record>, elec_total_usage: list<record>, elec_usage: list<record>>, message: string, missing: record<battery_charge: bool, battery_discharge: bool, battery_grid: bool, elec_drawn: bool, elec_feed_in: bool, elec_from_household: bool, elec_local: bool, elec_to_pv: bool, elec_total_gen: bool, elec_total_usage: bool, elec_usage: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "flows" $flows "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/electricity/flows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"flows": $flows} | compact), body: null}
}

# Get electricity flows setup
#
# GET /places/{placeId}/electricity/flows/setup
# operationId: Place.Electricity.getFlowsSetup
export def "places-electricity-flows-setup get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<battery_charge: table<class: string, id: string>, battery_discharge: table<class: string, id: string>, battery_grid: table<class: string, id: string>, elec_drawn: table<class: string, id: string>, elec_feed_in: table<class: string, id: string>, elec_from_household: table<class: string, id: string>, elec_local: table<class: string, id: string>, elec_to_pv: table<class: string, id: string>, elec_total_gen: table<class: string, id: string>, elec_total_usage: table<class: string, id: string>, elec_usage: table<class: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/electricity/flows/setup"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get self-consumption rate of the place
#
# GET /places/{placeId}/electricity/self-consumption
# operationId: Place.Electricity.selfConsumption
export def "places-electricity-self-consumption get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year)
]: nothing -> record<code: int, from: string, message: string, selfConsumption: float, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "when" $when "scalar") (serialize-qp "span" $span "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/electricity/self-consumption") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"when": $when, "span": $span} | compact), body: null}
}

# List Functionalities
#
# GET /places/{placeId}/functionalities
# operationId: Place.functionalities
export def "places-functionalities get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/functionalities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed-metadata": $embed_metadata} | compact), body: null}
}

# List metadata
#
# GET /places/{placeId}/metadata
# operationId: Place.getMetadata
export def "places-metadata get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata
#
# PATCH /places/{placeId}/metadata
# operationId: Place.patchMetadata
export def "places-metadata update" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Notifications
#
# GET /places/{placeId}/notifications
# operationId: Place.notifications
export def "places-notifications get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<id: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/notifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed-metadata": $embed_metadata} | compact), body: null}
}

# Create a Notification
#
# POST /places/{placeId}/notifications
# operationId: Place.newNotification
export def "places-notifications create-new" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --routing: string # format: uri
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/notifications"))
  let req_body = {"data": $data, "metadata": $metadata, "name": $name, "routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Programs
#
# GET /places/{placeId}/programs
# operationId: Place.programs
export def "places-programs get" [
  place_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<enabled: bool, id: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/programs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed-metadata": $embed_metadata} | compact), body: null}
}

# Create a Program
#
# POST /places/{placeId}/programs
# operationId: Place.newProgram
export def "places-programs create-new" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/places/{place_id}/programs"))
  let req_body = {"code": $code, "enabled": $enabled, "metadata": $metadata, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run actions
#
# POST /places/{placeId}/run/{action}
# operationId: Place.run
export def "places-run create" [
  place_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ».
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'placeId' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let qp = [(serialize-qp "devices" $devices "scalar") (serialize-qp "functionalities" $functionalities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id), action: (encode-path-segment $action)} | format pattern "/places/{place_id}/run/{action}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"devices": $devices, "functionalities": $functionalities} | compact), body: $req_body}
}

# Delete a Program
#
# DELETE /programs/{programId}
# operationId: Program.delete
export def "programs delete" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Information about a Program
#
# GET /programs/{programId}
# operationId: Programs.get
export def "programs get" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: any, enabled: bool, metadata: record, name: string, place: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify a Program
#
# PATCH /programs/{programId}
# operationId: Program.patch
export def "programs update" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool>
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}"))
  let req_body = {"code": $code, "enabled": $enabled, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# History of executions of a Program
#
# GET /programs/{programId}/log
# operationId: Program.log
export def "programs-log get" [
  program_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Beginning of the time interval. (format: date-time)
  --qp-to: string # End of the interval. Default: now. (format: date-time)
]: nothing -> table<actions: list<record>, errors: list<string>, notifications: list<string>, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}/log") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "to": $qp_to} | compact), body: null}
}

# List metadata
#
# GET /programs/{programId}/metadata
# operationId: Program.getMetadata
export def "programs-metadata get" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify metadata of a Program
#
# PATCH /programs/{programId}/metadata
# operationId: Program.patchMetadata
export def "programs-metadata update" [
  program_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}/metadata"))
  let req_body = {"add": $add, "remove": $remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run the Program
#
# POST /programs/{programId}/run
# operationId: Program.run
export def "programs-run create" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  if ($program_id | is-empty) { error make --unspanned { msg: "path parameter 'programId' must be non-empty" } }
  let full_url = (build-url $base ({program_id: (encode-path-segment $program_id)} | format pattern "/programs/{program_id}/run"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
