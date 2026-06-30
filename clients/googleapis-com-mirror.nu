# Auto-generated client for Google Mirror vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/mirror/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_MIRROR_TOKEN

const BASE_URL = "https://www.googleapis.com/mirror/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_MIRROR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://www.googleapis.com/mirror/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def order-by-completer [] { ["displayTime" "writeTime"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts create" } } | get name | first)
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

# Inserts a new account for a user
#
# POST /accounts/{userToken}/{accountType}/{accountName}
# operationId: mirror.accounts.insert
# --authTokens item shape: {authToken?: string, type?: string}
# --userData item shape: {key?: string, value?: string}
export def "accounts create" [
  user_token: string
  account_type: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --auth-tokens: list # item shape: {authToken?: string, type?: string}
  --features: list<string>
  --password: string
  --user-data: list # item shape: {key?: string, value?: string}
]: any -> record<authTokens: table<authToken: string, type: string>, features: list<string>, password: string, userData: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_token | is-empty) { error make --unspanned { msg: "path parameter 'userToken' must be non-empty" } }
  if ($account_type | is-empty) { error make --unspanned { msg: "path parameter 'accountType' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_token: (encode-path-segment $user_token), account_type: (encode-path-segment $account_type), account_name: (encode-path-segment $account_name)} | format pattern "/accounts/{user_token}/{account_type}/{account_name}") $qp $auth.query)
  let req_body = {"authTokens": $auth_tokens, "features": $features, "password": $password, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of contacts for the authenticated user.
#
# GET /contacts
# operationId: mirror.contacts.list
export def "contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Inserts a new contact.
#
# POST /contacts
# operationId: mirror.contacts.insert
# --acceptCommands item shape: {type?: string}
export def "contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --id: string # An ID for this contact. This is generated by the application and is treated as an opaque token.
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --body-source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp $auth.query)
  let req_body = {"acceptCommands": $accept_commands, "acceptTypes": $accept_types, "displayName": $display_name, "id": $id, "imageUrls": $image_urls, "kind": $kind, "phoneNumber": $phone_number, "priority": $priority, "sharingFeatures": $sharing_features, "source": $body_source, "speakableName": $speakable_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a contact.
#
# DELETE /contacts/{id}
# operationId: mirror.contacts.delete
export def "contacts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets a single contact by ID.
#
# GET /contacts/{id}
# operationId: mirror.contacts.get
export def "contacts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a contact in place. This method supports patch semantics.
#
# PATCH /contacts/{id}
# operationId: mirror.contacts.patch
# --acceptCommands item shape: {type?: string}
export def "contacts update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --body-id: string # An ID for this contact. This is generated by the application and is treated as an opaque token.
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --body-source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}") $qp $auth.query)
  let req_body = {"acceptCommands": $accept_commands, "acceptTypes": $accept_types, "displayName": $display_name, "id": $body_id, "imageUrls": $image_urls, "kind": $kind, "phoneNumber": $phone_number, "priority": $priority, "sharingFeatures": $sharing_features, "source": $body_source, "speakableName": $speakable_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a contact in place.
#
# PUT /contacts/{id}
# operationId: mirror.contacts.update
# --acceptCommands item shape: {type?: string}
export def "contacts update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --body-id: string # An ID for this contact. This is generated by the application and is treated as an opaque token.
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --body-source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}") $qp $auth.query)
  let req_body = {"acceptCommands": $accept_commands, "acceptTypes": $accept_types, "displayName": $display_name, "id": $body_id, "imageUrls": $image_urls, "kind": $kind, "phoneNumber": $phone_number, "priority": $priority, "sharingFeatures": $sharing_features, "source": $body_source, "speakableName": $speakable_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of locations for the user.
#
# GET /locations
# operationId: mirror.locations.list
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a single location by ID.
#
# GET /locations/{id}
# operationId: mirror.locations.get
export def "locations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locations/{id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a single setting by ID.
#
# GET /settings/{id}
# operationId: mirror.settings.get
export def "settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<id: string, kind: string, value: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/settings/{id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of subscriptions for the authenticated user and service.
#
# GET /subscriptions
# operationId: mirror.subscriptions.list
export def "subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<callbackUrl: string, collection: string, id: string, kind: string, notification: record, operation: list, updated: string, userToken: string, verifyToken: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new subscription.
#
# POST /subscriptions
# operationId: mirror.subscriptions.insert
# --notification shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --callback-url: string # The URL where notifications should be delivered (must start with https://).
  --collection: string # The collection to subscribe to. Allowed values are: - timeline - Changes in the timeline including insertion, deletion, and updates. - locations - Location updates. - settings - Settings updates.
  --id: string # The ID of the subscription.
  --kind: string # The type of resource. This is always mirror#subscription. (default: mirror#subscription)
  --notification: record # A notification delivered by the API. — shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
  --operation: list<string> # A list of operations that should be subscribed to. An empty list indicates that all operations on the collection should be subscribed to. Allowed values are: - UPDATE - The item has been updated. - INSERT - A new item has been inserted. - DELETE - The item has been deleted. - MENU_ACTION - A custom menu item has been triggered by the user.
  --updated: string # The time at which this subscription was last modified, formatted according to RFC 3339. (format: date-time)
  --user-token: string # An opaque token sent to the subscriber in notifications so that it can determine the ID of the user.
  --verify-token: string # A secret token sent to the subscriber in notifications so that it can verify that the notification was generated by Google.
]: any -> record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp $auth.query)
  let req_body = {"callbackUrl": $callback_url, "collection": $collection, "id": $id, "kind": $kind, "notification": $notification, "operation": $operation, "updated": $updated, "userToken": $user_token, "verifyToken": $verify_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a subscription.
#
# DELETE /subscriptions/{id}
# operationId: mirror.subscriptions.delete
export def "subscriptions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Updates an existing subscription in place.
#
# PUT /subscriptions/{id}
# operationId: mirror.subscriptions.update
# --notification shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
export def "subscriptions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --callback-url: string # The URL where notifications should be delivered (must start with https://).
  --collection: string # The collection to subscribe to. Allowed values are: - timeline - Changes in the timeline including insertion, deletion, and updates. - locations - Location updates. - settings - Settings updates.
  --body-id: string # The ID of the subscription.
  --kind: string # The type of resource. This is always mirror#subscription. (default: mirror#subscription)
  --notification: record # A notification delivered by the API. — shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
  --operation: list<string> # A list of operations that should be subscribed to. An empty list indicates that all operations on the collection should be subscribed to. Allowed values are: - UPDATE - The item has been updated. - INSERT - A new item has been inserted. - DELETE - The item has been deleted. - MENU_ACTION - A custom menu item has been triggered by the user.
  --updated: string # The time at which this subscription was last modified, formatted according to RFC 3339. (format: date-time)
  --user-token: string # An opaque token sent to the subscriber in notifications so that it can determine the ID of the user.
  --verify-token: string # A secret token sent to the subscriber in notifications so that it can verify that the notification was generated by Google.
]: any -> record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $qp $auth.query)
  let req_body = {"callbackUrl": $callback_url, "collection": $collection, "id": $body_id, "kind": $kind, "notification": $notification, "operation": $operation, "updated": $updated, "userToken": $user_token, "verifyToken": $verify_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of timeline items for the authenticated user.
#
# GET /timeline
# operationId: mirror.timeline.list
export def "timeline list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --bundle-id: string # If provided, only items with the given bundleId will be returned.
  --include-deleted: oneof<nothing, bool> # If true, tombstone records for deleted items will be returned.
  --max-results: int # The maximum number of items to include in the response, used for paging.
  --order-by: string@order-by-completer # Controls the order in which timeline items are returned.
  --page-token: string # Token for the page of results to return.
  --pinned-only: oneof<nothing, bool> # If true, only pinned items will be returned.
  --source-item-id: string # If provided, only items with the given sourceItemId will be returned.
]: nothing -> record<items: table<attachments: list, bundleId: string, canonicalUrl: string, created: string, creator: record, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record, menuItems: list, notification: record, pinScore: int, recipients: list, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "bundleId" $bundle_id "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "pinnedOnly" $pinned_only "scalar") (serialize-qp "sourceItemId" $source_item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeline" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "bundleId": $bundle_id, "includeDeleted": $include_deleted, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "pinnedOnly": $pinned_only, "sourceItemId": $source_item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Inserts a new item into the timeline.
#
# POST /timeline
# operationId: mirror.timeline.insert
export def "timeline create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeline" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "audio/1d-interleaved-parityfec"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a timeline item.
#
# DELETE /timeline/{id}
# operationId: mirror.timeline.delete
export def "timeline delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/timeline/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets a single timeline item by ID.
#
# GET /timeline/{id}
# operationId: mirror.timeline.get
export def "timeline get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/timeline/{id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a timeline item in place. This method supports patch semantics.
#
# PATCH /timeline/{id}
# operationId: mirror.timeline.patch
# --attachments item shape: {contentType?: string, contentUrl?: string, id?: string, isProcessingContent?: bool}
# --creator shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
# --location shape: {accuracy?: float, address?: string, displayName?: string, id?: string, kind?: string, latitude?: float, longitude?: float, timestamp?: string}
# --menuItems item shape: {action?: string, contextual_command?: string, id?: string, payload?: string, removeWhenSelected?: bool, values?: list}
# --notification shape: {deliveryTime?: string, level?: string}
# --recipients item shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
export def "timeline update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --attachments: list # A list of media attachments associated with this item. As a convenience, you can refer to attachments in your HTML payloads with the attachment or cid scheme. For example: - attachment: where attachment_index is the 0-based index of this array. - cid: where attachment_id is the ID of the attachment. — item shape: {contentType?: string, contentUrl?: string, id?: string, isProcessingContent?: bool}
  --bundle-id: string # The bundle ID for this item. Services can specify a bundleId to group many items together. They appear under a single top-level item on the device.
  --canonical-url: string # A canonical URL pointing to the canonical/high quality version of the data represented by the timeline item.
  --created: string # The time at which this item was created, formatted according to RFC 3339. (format: date-time)
  --creator: record # A person or group that can be used as a creator or a contact. — shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
  --display-time: string # The time that should be displayed when this item is viewed in the timeline, formatted according to RFC 3339. This user's timeline is sorted chronologically on display time, so this will also determine where the item is displayed in the timeline. If not set by the service, the display time defaults to the updated time. (format: date-time)
  --etag: string # ETag for this item.
  --html: string # HTML content for this item. If both text and html are provided for an item, the html will be rendered in the timeline. Allowed HTML elements - You can use these elements in your timeline cards. - Headers: h1, h2, h3, h4, h5, h6 - Images: img - Lists: li, ol, ul - HTML5 semantics: article, aside, details, figure, figcaption, footer, header, nav, section, summary, time - Structural: blockquote, br, div, hr, p, span - Style: b, big, center, em, i, u, s, small, strike, strong, style, sub, sup - Tables: table, tbody, td, tfoot, th, thead, tr Blocked HTML elements: These elements and their contents are removed from HTML payloads. - Document headers: head, title - Embeds: audio, embed, object, source, video - Frames: frame, frameset - Scripting: applet, script Other elements: Any elements that aren't listed are removed, but their contents are preserved.
  --body-id: string # The ID of the timeline item. This is unique within a user's timeline.
  --in-reply-to: string # If this item was generated as a reply to another item, this field will be set to the ID of the item being replied to. This can be used to attach a reply to the appropriate conversation or post.
  --is-bundle-cover: oneof<nothing, bool> # Whether this item is a bundle cover. If an item is marked as a bundle cover, it will be the entry point to the bundle of items that have the same bundleId as that item. It will be shown only on the main timeline — not within the opened bundle. On the main timeline, items that are shown are: - Items that have isBundleCover set to true - Items that do not have a bundleId In a bundle sub-timeline, items that are shown are: - Items that have the bundleId in question AND isBundleCover set to false
  --is-deleted: oneof<nothing, bool> # When true, indicates this item is deleted, and only the ID property is set.
  --is-pinned: oneof<nothing, bool> # When true, indicates this item is pinned, which means it's grouped alongside "active" items like navigation and hangouts, on the opposite side of the home screen from historical (non-pinned) timeline items. You can allow the user to toggle the value of this property with the TOGGLE_PINNED built-in menu item.
  --kind: string # The type of resource. This is always mirror#timelineItem. (default: mirror#timelineItem)
  --location: record # A geographic location that can be associated with a timeline item. — shape: {accuracy?: float, address?: string, displayName?: string, id?: string, kind?: string, latitude?: float, longitude?: float, timestamp?: string}
  --menu-items: list # A list of menu items that will be presented to the user when this item is selected in the timeline. — item shape: {action?: string, contextual_command?: string, id?: string, payload?: string, removeWhenSelected?: bool, values?: list}
  --notification: record # Controls how notifications for a timeline item are presented to the user. — shape: {deliveryTime?: string, level?: string}
  --pin-score: int # For pinned items, this determines the order in which the item is displayed in the timeline, with a higher score appearing closer to the clock. Note: setting this field is currently not supported. (format: int32)
  --recipients: list # A list of users or groups that this item has been shared with. — item shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
  --self-link: string # A URL that can be used to retrieve this item.
  --source-item-id: string # Opaque string you can use to map a timeline item to data in your own service.
  --speakable-text: string # The speakable version of the content of this item. Along with the READ_ALOUD menu item, use this field to provide text that would be clearer when read aloud, or to provide extended information to what is displayed visually on Glass. Glassware should also specify the speakableType field, which will be spoken before this text in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification.
  --speakable-type: string # A speakable description of the type of this item. This will be announced to the user prior to reading the content of the item in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification. This should be a short, simple noun phrase such as "Email", "Text message", or "Daily Planet News Update". Glassware are encouraged to populate this field for every timeline item, even if the item does not contain speakableText or text so that the user can learn the type of the item without looking at the screen.
  --text: string # Text content of this item.
  --title: string # The title of this item.
  --updated: string # The time at which this item was last modified, formatted according to RFC 3339. (format: date-time)
]: any -> record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/timeline/{id}") $qp $auth.query)
  let req_body = {"attachments": $attachments, "bundleId": $bundle_id, "canonicalUrl": $canonical_url, "created": $created, "creator": $creator, "displayTime": $display_time, "etag": $etag, "html": $html, "id": $body_id, "inReplyTo": $in_reply_to, "isBundleCover": $is_bundle_cover, "isDeleted": $is_deleted, "isPinned": $is_pinned, "kind": $kind, "location": $location, "menuItems": $menu_items, "notification": $notification, "pinScore": $pin_score, "recipients": $recipients, "selfLink": $self_link, "sourceItemId": $source_item_id, "speakableText": $speakable_text, "speakableType": $speakable_type, "text": $text, "title": $title, "updated": $updated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a timeline item in place.
#
# PUT /timeline/{id}
# operationId: mirror.timeline.update
export def "timeline update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/timeline/{id}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "audio/1d-interleaved-parityfec"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of attachments for a timeline item.
#
# GET /timeline/{itemId}/attachments
# operationId: mirror.timeline.attachments.list
export def "timeline-attachments list" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<items: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/timeline/{item_id}/attachments") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a new attachment to a timeline item.
#
# POST /timeline/{itemId}/attachments
# operationId: mirror.timeline.attachments.insert
export def "timeline-attachments create" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/timeline/{item_id}/attachments") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Deletes an attachment from a timeline item.
#
# DELETE /timeline/{itemId}/attachments/{attachmentId}
# operationId: mirror.timeline.attachments.delete
export def "timeline-attachments delete" [
  item_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/timeline/{item_id}/attachments/{attachment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieves an attachment on a timeline item by item ID and attachment ID.
#
# GET /timeline/{itemId}/attachments/{attachmentId}
# operationId: mirror.timeline.attachments.get
export def "timeline-attachments get" [
  item_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_MIRROR_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_MIRROR_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/timeline/{item_id}/attachments/{attachment_id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
