# Auto-generated client for Zoom API v2.0.0
# Source: https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.json
# Auth: --token flag or $env.ZOOM_API_TOKEN

const BASE_URL = "https://api.zoom.us/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ZOOM_API_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.zoom.us/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def pay-mode-completer [] { ["master" "sub"] }
def action-completer [] { ["cancel"] }
def reason-completer [] { ["1" "2" "3" "4" "5" "6"] }
def option-completer [] { ["meeting_authentication" "recording_authentication"] }
def option-completer-1 [] { ["meeting_authentication" "meeting_security" "recording_authentication" "security"] }
def show-zoom-provided-numbers-completer [] { ["0" "1" "2"] }
def query-data-type-completer [] { ["archive_complete_time" "meeting_start_time"] }
def type-completer [] { ["1" "2" "3"] }
def action-completer-1 [] { ["move" "set_primary"] }
def option-completer-2 [] { ["meeting_authentication" "meeting_security" "recording_authentication"] }
def encryption-completer [] { ["auto" "no" "yes"] }
def protocol-completer [] { ["H.323" "SIP"] }
def type-completer-1 [] { ["normal" "restricted" "shared"] }
def accept-completer-1 [] { ["application/json" "application/xml" "new"] }
def action-completer-2 [] { ["start" "stop"] }
def action-completer-3 [] { ["delete" "trash"] }
def status-completer [] { ["approved" "denied" "pending"] }
def action-completer-4 [] { ["approve" "deny"] }
def approval-type-completer [] { ["0" "1" "2"] }
def share-recording-completer [] { ["internally" "none" "publicly"] }
def action-completer-5 [] { ["recover"] }
def action-completer-6 [] { ["approve" "cancel" "deny"] }
def action-completer-7 [] { ["end" "recover"] }
def type-completer-2 [] { ["live" "past" "pastOne"] }
def include-fields-completer [] { ["tracking_fields"] }
def include-fields-completer-1 [] { ["registrant_id"] }
def type-completer-3 [] { ["live" "past"] }
def block-type-completer [] { ["inbound" "outbound"] }
def match-type-completer [] { ["phoneNumber" "prefix"] }
def status-completer-1 [] { ["active" "inactive"] }
def time-type-completer [] { ["endTime" "startTime"] }
def type-completer-4 [] { ["assigned" "unassigned"] }
def type-completer-5 [] { ["all" "assigned" "unassigned"] }
def extension-type-completer [] { ["autoReceptionist" "callQueue" "commonAreaPhone" "user"] }
def number-type-completer [] { ["toll" "tollfree"] }
def type-completer-6 [] { ["autoReceptionist" "commonarea" "group" "interop" "user"] }
def type-completer-7 [] { ["all" "missed"] }
def status-completer-2 [] { ["all" "read" "unread"] }
def category-type-completer [] { ["account" "all" "billing" "im" "phone_contacts" "recording" "role" "sub_account" "user" "user_settings" "webinar" "zoom_rooms"] }
def type-completer-8 [] { ["1" "3"] }
def type-completer-9 [] { ["active" "inactive"] }
def type-completer-10 [] { ["past" "pastOne"] }
def status-completer-3 [] { ["Available" "InMeeting" "Offline" "UnderConstruction"] }
def type-completer-11 [] { ["DigitalSignageOnly" "SchedulingDisplayOnly" "ZoomRoom"] }
def setting-type-completer [] { ["alert" "meeting"] }
def method-completer [] { ["zoomroom.emergency_alert_displayed"] }
def action-completer-8 [] { ["cancel" "downgrade" "upgrade"] }
def transport-protocol-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def transport-protocol2-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def transport-protocol3-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def tsp-bridge-completer [] { ["EU_TSP_TB" "US_TSP_TB"] }
def status-completer-4 [] { ["active" "inactive" "pending"] }
def action-completer-9 [] { ["autoCreate" "create" "custCreate" "ssoCreate"] }
def action-completer-10 [] { ["delete" "disassociate"] }
def login-type-completer [] { ["0" "1" "100" "101" "99"] }
def type-completer-12 [] { ["1" "2" "3" "99"] }
def type-completer-13 [] { ["live" "scheduled" "upcoming"] }
def type-completer-14 [] { ["1" "2" "3" "8"] }
def status-completer-5 [] { ["Available" "Away" "Do_No_Disturb"] }
def option-completer-3 [] { ["meeting_authentication" "meeting_secuirty" "recording_authentication"] }
def action-completer-11 [] { ["activate" "deactivate"] }
def type-completer-15 [] { ["token" "zak"] }
def type-completer-16 [] { ["5" "6" "9"] }
def action-completer-12 [] { ["end"] }

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

# List sub accounts
#
# GET /accounts
# operationId: accounts
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a sub account
#
# POST /accounts
# operationId: accountCreate
# --options shape: {billing_auto_renew?: bool, meeting_connector_list?: list<string>, pay_mode?: "master"|"sub", room_connector_list?: list<string>, share_mc?: bool, share_rc?: bool}
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --account-name: string # Name of the account. If you do not provide a value for this field, by default, the value will be set as a concatenation of "first_name" and "last_name".
  email: string # User's email address.
  first_name: string # User's first name.
  last_name: string # User's last name.
  --options: record # Account options object. — shape: {billing_auto_renew?: bool, meeting_connector_list?: list<string>, pay_mode?: "master"|"sub", room_connector_list?: list<string>, share_mc?: bool, share_rc?: bool}
  password: string # User's password. **Note:** If the account owner or admin has enabled [enhanced password requirements](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_fa9186e4-6818-4f7a-915c-2e25c19f0acd), the value provided in this field must meet those requirements. These requirements can be retrieved by calling the [Get Account Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) and referring to the `password_requirement` field present in the `security` object.
]: any -> record<created_at: string, id: string, owner_email: string, owner_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let req_body = {"account_name": $account_name, "email": $email, "first_name": $first_name, "last_name": $last_name, "options": $options, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Disassociate a sub account
#
# DELETE /accounts/{accountId}
# operationId: accountDisassociate
export def "accounts delete-disassociate" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get sub account details
#
# GET /accounts/{accountId}
# operationId: account
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: string, options: record<billing_auto_renew: bool, meeting_connector_list: list<string>, pay_mode: string, room_connector_list: list<string>, share_mc: bool, share_rc: bool>, owner_email: string, owner_id: string, vanity_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get billing information
#
# GET /accounts/{accountId}/billing
# operationId: accountBilling
export def "accounts-billing get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<address: string, apt: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/billing") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update billing information
#
# PATCH /accounts/{accountId}/billing
# operationId: accountBillingUpdate
export def "accounts-billing update" [
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
  --address: string # Billing Contact's address.
  --apt: string # Billing Contact's apartment/suite.
  --city: string # Billing Contact's city.
  --country: string # Billing Contact's country.
  --email: string # Billing Contact's email address.
  --first-name: string # Billing Contact's first name.
  --last-name: string # Billing Contact's last name.
  --phone-number: string # Billing Contact's phone number.
  --state: string # Billing Contact's state.
  --zip: string # Billing Contact's zip/postal code.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/billing") $auth.query)
  let req_body = {"address": $address, "apt": $apt, "city": $city, "country": $country, "email": $email, "first_name": $first_name, "last_name": $last_name, "phone_number": $phone_number, "state": $state, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# List billing invoices
#
# GET /accounts/{accountId}/billing/invoices
# operationId: accountBillingInvoices
export def "accounts-billing-invoices list" [
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
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date for the invoice query in `yyyy-mm-dd` format. The date range defined by the “from” and “to” parameters should not exceed one year. The range defined should fall within the past three years. (format: date)
  --qp-to: string # End date for the invoice query in `yyyy-mm-dd` format (format: date)
]: nothing -> record<currency: string, invoices: table<balance: float, due_date: string, id: string, invoice_date: string, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/billing/invoices") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get invoice details
#
# GET /accounts/{accountId}/billing/invoices/{invoiceId}
# operationId: getAccountBillingInvoice
export def "accounts-billing-invoices get" [
  account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<balance: float, currency: string, due_date: string, id: string, invoice_date: string, invoice_items: table<charge_name: string, charge_number: string, charge_type: string, end_date: string, quantity: int, start_date: string, tax_amount: float, total_amount: float>, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounts/{account_id}/billing/invoices/{invoice_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get locked settings
#
# GET /accounts/{accountId}/lock_settings
# operationId: getAccountLockSettings
export def "accounts-lock-settings get" [
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
  --accept: string@accept-completer # Response content type
  --option: string # `meeting_security`: Use this query parameter to view meeting security settings applied on the account.
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "option" $option "scalar") (serialize-qp "custom_query_fields" $custom_query_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/lock_settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"option": $option, "custom_query_fields": $custom_query_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update locked settings
#
# PATCH /accounts/{accountId}/lock_settings
# operationId: updateAccountLockSettings
# --email_notification shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
# --in_meeting shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, dscp_marking?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, original_audio?: bool, polling?: bool, ... (12 more fields)}
# --recording shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, recording_authentication?: string}
# --schedule_meeting shape: {audio_type?: bool, embed_password_in_join_link?: bool, enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool}
# --telephony shape: {telephony_regions?: bool, third_party_audio?: bool}
# --tsp shape: {call_out?: bool, show_international_numbers_link?: bool}
# --meeting_security shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
export def "accounts-lock-settings update" [
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
  --accept: string@accept-completer # Response content type
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, dscp_marking?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, original_audio?: bool, polling?: bool, ... (12 more fields)}
  --recording: record # shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, recording_authentication?: string}
  --schedule-meeting: record # shape: {audio_type?: bool, embed_password_in_join_link?: bool, enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool}
  --telephony: record # shape: {telephony_regions?: bool, third_party_audio?: bool}
  --tsp: record # shape: {call_out?: bool, show_international_numbers_link?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/lock_settings") $auth.query)
  let req_body = {"email_notification": $email_notification, "in_meeting": $in_meeting, "recording": $recording, "schedule_meeting": $schedule_meeting, "telephony": $telephony, "tsp": $tsp, "meeting_security": $meeting_security} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Get managed domains
#
# GET /accounts/{accountId}/managed_domains
# operationId: accountManagedDomain
export def "accounts-managed-domains get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<domains: list<record>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/managed_domains") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update options
#
# PATCH /accounts/{accountId}/options
# operationId: accountOptionsUpdate
export def "accounts-options update" [
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
  --billing-auto-renew: oneof<nothing, bool> # Toggle whether automatic billing renewal is on or off.
  --meeting-connector-list: list<string> # Specify the IP addresses of the Meeting Connectors that you would like to share with the sub account. Multiple values can be separated by comma. If no value is provided in this field, all the Meeting Connectors of a master account will be shared with the sub account. **Note:** This option can only be used if the value of `share_mc` is set to `true`.
  --pay-mode: string@pay-mode-completer # Payee:`master` - master account holder pays.`sub` - Sub account holder pays. (default: master)
  --room-connector-list: list<string> # Specify the IP addresses of the Room Connectors that you would like to share with the sub account. Multiple values can be separated by comma. If no value is provided in this field, all the Room Connectors of a master account will be shared with the sub account. **Note:** This option can only be used if the value of `share_rc` is set to `true`.
  --share-mc: oneof<nothing, bool> # Enable/disable the option for a sub account to use shared [Meeting Connector(s)](https://support.zoom.us/hc/en-us/articles/201363093-Getting-Started-with-the-Meeting-Connector) that are set up by the master account. Meeting Connectors can only be used by On-prem users. (default: false)
  --share-rc: oneof<nothing, bool> # Enable/disable the option for a sub account to use shared [Virtual Room Connector(s)](https://support.zoom.us/hc/en-us/articles/202134758-Getting-Started-With-Virtual-Room-Connector) that are set up by the master account. Virtual Room Connectors can only be used by On-prem users. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/options") $auth.query)
  let req_body = {"billing_auto_renew": $billing_auto_renew, "meeting_connector_list": $meeting_connector_list, "pay_mode": $pay_mode, "room_connector_list": $room_connector_list, "share_mc": $share_mc, "share_rc": $share_rc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Update the account owner
#
# PUT /accounts/{accountId}/owner
# operationId: updateAccountOwner
export def "accounts-owner update" [
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
  --accept: string@accept-completer # Response content type
  email: string # Email address of the new owner. (format: email)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/owner") $auth.query)
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update BYOC settings
#
# PATCH /accounts/{accountId}/phone/settings
# operationId: updatePhoneSettings
# --byoc shape: {enable?: bool}
export def "accounts-phone-settings update" [
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
  --accept: string@accept-completer # Response content type
  --byoc: record # shape: {enable?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/phone/settings") $auth.query)
  let req_body = {"byoc": $byoc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Set up a Zoom Phone account
#
# POST /accounts/{accountId}/phone/setup
# operationId: setUpAccount
# --emergency_address shape: {address_line1: string, address_line2?: string, city?: string, country: string, state_code?: string, zip?: string}
export def "accounts-phone-setup update-up" [
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
  emergency_address: record # Specify emergency address for the account. — shape: {address_line1: string, address_line2?: string, city?: string, country: string, state_code?: string, zip?: string}
  extension_number: string # Specify extension number that will be associated with the owner of the account. (default: 800)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/phone/setup") $auth.query)
  let req_body = {"emergency_address": $emergency_address, "extension_number": $extension_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Assign SIP trunks
#
# POST /accounts/{accountId}/phone/sip_trunk/trunks
# operationId: postPhoneSIPTrunk
# --sip_trunks item shape: {carrier_account?: string, id?: string, name?: string}
export def "accounts-phone-sip-trunk-trunks create" [
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
  --accept: string@accept-completer # Response content type
  --sip-trunks: list # SIP trunk configurations. — item shape: {carrier_account?: string, id?: string, name?: string}
]: any -> record<sip_trunks: table<carrier_account: string, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/phone/sip_trunk/trunks") $auth.query)
  let req_body = {"sip_trunks": $sip_trunks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update SIP trunk details
#
# PATCH /accounts/{accountId}/phone/sip_trunk/trunks/{sipTrunkId}
# operationId: updatePhoneSIPTrunk
export def "accounts-phone-sip-trunk-trunks update" [
  account_id: string
  sip_trunk_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-account: string # Account associated with the carrier.
  --name: string # Name of the SIP Trunk.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($sip_trunk_id | is-empty) { error make --unspanned { msg: "path parameter 'sipTrunkId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), sip_trunk_id: (encode-path-segment $sip_trunk_id)} | format pattern "/accounts/{account_id}/phone/sip_trunk/trunks/{sip_trunk_id}") $auth.query)
  let req_body = {"carrier_account": $carrier_account, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get plan Information
#
# GET /accounts/{accountId}/plans
# operationId: accountPlans
export def "accounts-plans get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<plan_audio: record<callout_countries: string, ddi_numbers: int, next_invoice_date: string, premium_countries: string, service_effective_date: string, status: string, tollfree_countries: string, type: string>, plan_base: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_large_meeting: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_phone: record<plan_base: record<callout_countries: string, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_calling: list<record>, plan_number: list<record>>, plan_recording: string, plan_recording_next_invoice_date: string, plan_recording_service_effective_date: string, plan_recording_status: string, plan_room_connector: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_webinar: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_zoom_rooms: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Subscribe plans
#
# POST /accounts/{accountId}/plans
# operationId: accountPlanCreate
# --contact shape: {address: string, apt?: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string}
# --plan_audio shape: {callout_countries?: string, ddi_numbers?: int, premium_countries?: string, tollfree_countries?: string, type?: string}
# --plan_base shape: {hosts: int, type: string}
# --plan_large_meeting item shape: {hosts?: int, type?: string}
# --plan_phone shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
# --plan_room_connector shape: {hosts?: int, type?: string}
# --plan_webinar item shape: {hosts?: int, type?: string}
# --plan_zoom_rooms shape: {hosts?: int, type?: string}
export def "accounts-plans create" [
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
  --accept: string@accept-completer # Response content type
  --contact: record # Billing Contact object. — shape: {address: string, apt?: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string}
  --plan-audio: record # Additional audio conferencing plan type (https://marketplace.zoom.us/docs/api-reference/other-references/plans#audio-conferencing-plans). — shape: {callout_countries?: string, ddi_numbers?: int, premium_countries?: string, tollfree_countries?: string, type?: string}
  plan_base: record # Account base plan object. — shape: {hosts: int, type: string}
  --plan-large-meeting: list # Additional large meeting Plans. — item shape: {hosts?: int, type?: string}
  --plan-phone: record # Phone Plan Object — shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
  --plan-recording: string # Additional cloud recording plan.
  --plan-room-connector: record # Account plan object. — shape: {hosts?: int, type?: string}
  --plan-webinar: list # Additional webinar plans. — item shape: {hosts?: int, type?: string}
  --plan-zoom-rooms: record # Account plan object. — shape: {hosts?: int, type?: string}
]: any -> record<plan_audio: record<callout_countries: string, ddi_numbers: int, premium_countries: string, tollfree_countries: string, type: string>, plan_base: record<hosts: int, type: string>, plan_large_meeting: table<hosts: int, type: string>, plan_phone: record<plan_base: record<callout_countries: string, type: string>, plan_calling: list<record>, plan_number: list<record>>, plan_recording: string, plan_room_connector: record<hosts: int, type: string>, plan_webinar: table<hosts: int, type: string>, plan_zoom_rooms: record<hosts: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans") $auth.query)
  let req_body = {"contact": $contact, "plan_audio": $plan_audio, "plan_base": $plan_base, "plan_large_meeting": $plan_large_meeting, "plan_phone": $plan_phone, "plan_recording": $plan_recording, "plan_room_connector": $plan_room_connector, "plan_webinar": $plan_webinar, "plan_zoom_rooms": $plan_zoom_rooms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201 300]
}

# Subscribe additional plan
#
# POST /accounts/{accountId}/plans/addons
# operationId: accountPlanAddonCreate
# --plan_details shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
export def "accounts-plans-addons create" [
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
  --hosts: int # Number of hosts for this plan.
  --type: string # Account plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
  --plan-details: record # Phone Plan Object — shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/addons") $auth.query)
  let req_body = {"hosts": $hosts, "type": $type, "plan_details": $plan_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update an additional plan
#
# PUT /accounts/{accountId}/plans/addons
# operationId: accountPlanAddonUpdate
export def "accounts-plans-addons update" [
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
  hosts: int # Number of hosts for this plan.
  type: string # Account plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/addons") $auth.query)
  let req_body = {"hosts": $hosts, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# Cancel additional plans
#
# PATCH /accounts/{accountId}/plans/addons/status
# operationId: accountPlanAddonCancel
export def "accounts-plans-addons-status cancel" [
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
  --accept: string@accept-completer # Response content type
  --action: string@action-completer # The action that needs to be taken for this sub account. Value must be set to "cancel".
  --comment: string # Additional comments about the cancellation decision.
  --reason: int@reason-completer # The reason for the cancellation of plan. Reason options:`1` - I am no longer working remote.`2` - I had challenges getting the support I needed.`3` - Features in the Basic Free Plan are sufficient.`4` - The expense is too high.`5` - I purchased the wrong product. `6` - Paid purchase not needed right now, will repurchase in the future.
  --type: string # Plan [type](https://marketplace.zoom.us/docs/api-reference/other-references/plans).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/addons/status") $auth.query)
  let req_body = {"action": $action, "comment": $comment, "reason": $reason, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# Update a base plan
#
# PUT /accounts/{accountId}/plans/base
# operationId: accountPlanBaseUpdate
export def "accounts-plans-base update" [
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
  hosts: int # Account base plan number of hosts. For a Pro Plan please select a value between 1 and 9. For a Business Plan please select a value between 10 and 49. For a Education Plan please select a value between 20 and 149. For a Free Trial Plan please select a value between 1 and 9999.
  type: string # Account base plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/base") $auth.query)
  let req_body = {"hosts": $hosts, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# Cancel a base plan
#
# PATCH /accounts/{accountId}/plans/base/status
# operationId: accountPlanBaseDelete
export def "accounts-plans-base-status delete" [
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
  --accept: string@accept-completer # Response content type
  action: string # The action that needs to be taken for this sub account. Value must be set to "cancel".
  --comment: string # Additional comments about the cancellation decision.
  --reason: int@reason-completer # The reason for the cancellation of plan. Reason options:`1` - I am no longer working remote.`2` - I had challenges getting the support I needed.`3` - Features in the Basic Free Plan are sufficient.`4` - The expense is too high.`5` - I purchased the wrong product. `6` - Paid purchase not needed right now, will repurchase in the future.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/base/status") $auth.query)
  let req_body = {"action": $action, "comment": $comment, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Get plan usage
#
# GET /accounts/{accountId}/plans/usage
# operationId: getPlanUsage
export def "accounts-plans-usage get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<plan_base: table<hosts: int, type: string, usage: int>, plan_large_meeting: table<hosts: int, type: string, usage: int>, plan_recording: record<free_storage: string, free_storage_usage: string, plan_storage: string, plan_storage_exceed: string, plan_storage_usage: string, type: string>, plan_united: record<hosts: int, name: string, type: string, usage: int>, plan_webinar: table<hosts: int, type: string, usage: int>, plan_zoom_rooms: table<hosts: int, type: string, usage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/plans/usage") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List recordings of an account
#
# GET /accounts/{accountId}/recordings
# operationId: getAccountCloudRecording
export def "accounts-recordings get-cloud" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --qp-from: string # The start date in UTC for the monthly range for which you would like to retrieve recordings. The maximum range can be a month. If no value is provided for this field, the default will be current date. For example, if you make the API request on June 30, 2020, without providing the “from” and “to” parameters, by default the value of 'from' field will be “2020-06-30” and the value of the 'to' field will be “2020-07-01”. (format: date-time)
  --qp-to: string # The end date for the monthly range for which you would like to retrieve recordings. The maximum range can be a month. (format: date-time)
]: nothing -> record<from: string, meetings: table<duration: int, host_id: string, id: string, recording_count: int, recording_files: list, start_time: string, topic: string, total_size: int, uuid: string>, next_page_token: string, page_size: int, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/recordings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get settings
#
# GET /accounts/{accountId}/settings
# operationId: accountSettings
export def "accounts-settings get" [
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
  --accept: string@accept-completer # Response content type
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the account.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the account.`security`: Use this query parameter to view security settings such as password requirements for user login, two factor authentication etc., applied on the account. `meeting_security`: Use this query parameter to view meeting security settings applied on the account. (allows empty value)
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "option" $option "scalar") (serialize-qp "custom_query_fields" $custom_query_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"option": $option, "custom_query_fields": $custom_query_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update settings
#
# PATCH /accounts/{accountId}/settings
# operationId: accountSettingsUpdate
# --email_notification shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_avaliable_reminder?: bool, jbh_reminder?: bool, low_host_count_reminder?: bool, schedule_for_reminder?: bool}
# --feature shape: {meeting_capacity?: int}
# --in_meeting shape: {alert_guest_join?: bool, allow_live_streaming?: bool, allow_participants_to_rename?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", ... (34 more fields)}
# --integration shape: {box?: bool, dropbox?: bool, google_calendar?: bool, google_drive?: bool, kubi?: bool, microsoft_one_drive?: bool}
# --profile shape: {recording_storage_location?: record}
# --recording shape: {account_user_access_recording?: bool, allow_recovery_deleted_cloud_recordings?: bool, archive?: record, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, ... (7 more fields)}
# --schedule_meeting shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", require_password_for_scheduled_meetings?: bool, ... (3 more fields)}
# --security shape: {admin_change_name_pic?: bool, hide_billing_info?: bool, import_photos_from_devices?: bool, password_requirement?: record, sign_again_period_for_inactivity_on_client?: int, sign_again_period_for_inactivity_on_web?: int, sign_in_with_two_factor_auth?: "all"|"group"|"role"|"none", sign_in_with_two_factor_auth_groups?: list<string>, sign_in_with_two_factor_auth_roles?: list<string>}
# --telephony shape: {audio_conference_info?: string, telephony_regions?: record, third_party_audio?: bool}
# --tsp shape: {call_out?: bool, call_out_countries?: list, display_toll_free_numbers?: bool, show_international_numbers_link?: bool}
# --zoom_rooms shape: {auto_start_stop_scheduled_meetings?: bool, cmr_for_instant_meeting?: bool, force_private_meeting?: bool, hide_host_information?: bool, list_meetings_with_calendar?: bool, start_airplay_manually?: bool, ultrasonic?: bool, upcoming_meeting_alert?: bool, weekly_system_restart?: bool, zr_post_meeting_feedback?: bool}
# --meeting_security shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
export def "accounts-settings update" [
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
  --option: string@option-completer-1 # allows empty value
  --email-notification: record # Account Settings: Notification. — shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_avaliable_reminder?: bool, jbh_reminder?: bool, low_host_count_reminder?: bool, schedule_for_reminder?: bool}
  --feature: record # Account Settings: Feature. — shape: {meeting_capacity?: int}
  --in-meeting: record # Account Settings: In Meeting. — shape: {alert_guest_join?: bool, allow_live_streaming?: bool, allow_participants_to_rename?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", ... (34 more fields)}
  --integration: record # Account Settings: Integration. — shape: {box?: bool, dropbox?: bool, google_calendar?: bool, google_drive?: bool, kubi?: bool, microsoft_one_drive?: bool}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # Account Settings: Recording. — shape: {account_user_access_recording?: bool, allow_recovery_deleted_cloud_recordings?: bool, archive?: record, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, ... (7 more fields)}
  --schedule-meeting: record # Account Settings: Schedule Meeting. — shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", require_password_for_scheduled_meetings?: bool, ... (3 more fields)}
  --security: record # [Security settings](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_bf8a25f6-9a66-447a-befd-f02ed3404f89) of an Account. — shape: {admin_change_name_pic?: bool, hide_billing_info?: bool, import_photos_from_devices?: bool, password_requirement?: record, sign_again_period_for_inactivity_on_client?: int, sign_again_period_for_inactivity_on_web?: int, sign_in_with_two_factor_auth?: "all"|"group"|"role"|"none", sign_in_with_two_factor_auth_groups?: list<string>, sign_in_with_two_factor_auth_roles?: list<string>}
  --telephony: record # Account Settings Update: Telephony. — shape: {audio_conference_info?: string, telephony_regions?: record, third_party_audio?: bool}
  --tsp: record # Account Settings: TSP. — shape: {call_out?: bool, call_out_countries?: list, display_toll_free_numbers?: bool, show_international_numbers_link?: bool}
  --zoom-rooms: record # Account Settings: Zoom Rooms. — shape: {auto_start_stop_scheduled_meetings?: bool, cmr_for_instant_meeting?: bool, force_private_meeting?: bool, hide_host_information?: bool, list_meetings_with_calendar?: bool, start_airplay_manually?: bool, ultrasonic?: bool, upcoming_meeting_alert?: bool, weekly_system_restart?: bool, zr_post_meeting_feedback?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings") $qp $auth.query)
  let req_body = {"email_notification": $email_notification, "feature": $feature, "in_meeting": $in_meeting, "integration": $integration, "profile": $profile, "recording": $recording, "schedule_meeting": $schedule_meeting, "security": $security, "telephony": $telephony, "tsp": $tsp, "zoom_rooms": $zoom_rooms, "meeting_security": $meeting_security} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"option": $option} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# Delete virtual background files
#
# DELETE /accounts/{accountId}/settings/virtual_backgrounds
# operationId: delVB
export def "accounts-settings-virtual-backgrounds delete-vb" [
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
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "file_ids" $file_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings/virtual_backgrounds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"file_ids": $file_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Upload virtual background files
#
# POST /accounts/{accountId}/settings/virtual_backgrounds
# operationId: uploadVB
export def "accounts-settings-virtual-backgrounds upload-vb" [
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
  --accept: string@accept-completer # Response content type
  --file: string # Provide the file's path here.
]: any -> record<id: string, is_default: bool, name: string, size: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings/virtual_backgrounds") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# List internal call-out countries
#
# GET /accounts/{accountId}/sip_trunk/callout_countries
# operationId: listInternalCalloutCountries
export def "accounts-sip-trunk-callout-countries list-internal" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<callout_countries: table<code: string, id: string, name: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/callout_countries") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add internal call-out countries
#
# POST /accounts/{accountId}/sip_trunk/callout_countries
# operationId: addCalloutCountries
# --callout_countries item shape: {id: string}
export def "accounts-sip-trunk-callout-countries create" [
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
  --accept: string@accept-completer # Response content type
  callout_countries: list # List of callout countries. — item shape: {id: string}
]: any -> record<callout_countries: table<code: string, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/callout_countries") $auth.query)
  let req_body = {"callout_countries": $callout_countries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete internal call-out country
#
# DELETE /accounts/{accountId}/sip_trunk/callout_countries/{countryId}
# operationId: deleteInternalCallOutCountry
export def "accounts-sip-trunk-callout-countries delete-internal-call-out-country" [
  account_id: string
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), country_id: (encode-path-segment $country_id)} | format pattern "/accounts/{account_id}/sip_trunk/callout_countries/{country_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List internal numbers
#
# GET /accounts/{accountId}/sip_trunk/internal_numbers
# operationId: listInternalNumbers
export def "accounts-sip-trunk-internal-numbers list" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, labels: string, languages: string, number: string, type: int, visible: bool>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/internal_numbers") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add internal numbers
#
# POST /accounts/{accountId}/sip_trunk/internal_numbers
# operationId: addInternalNumbers
# --internal_numbers item shape: {allow_for_external_meetings?: bool, allow_join?: bool, country: string, display_number: string, labels: string, languages: "en-GB"|"en-US"|"de-DE", number: string, type: "0"|"1", visible?: bool}
export def "accounts-sip-trunk-internal-numbers create" [
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
  --accept: string@accept-completer # Response content type
  --internal-numbers: list # item shape: {allow_for_external_meetings?: bool, allow_join?: bool, country: string, display_number: string, labels: string, languages: "en-GB"|"en-US"|"de-DE", number: string, type: "0"|"1", visible?: bool}
]: any -> record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, id: string, labels: string, languages: string, number: string, type: int, visible: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/internal_numbers") $auth.query)
  let req_body = {"internal_numbers": $internal_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an internal number
#
# DELETE /accounts/{accountId}/sip_trunk/internal_numbers/{numberId}
# operationId: deleteInternalNumber
export def "accounts-sip-trunk-internal-numbers delete" [
  account_id: string
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($number_id | is-empty) { error make --unspanned { msg: "path parameter 'numberId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), number_id: (encode-path-segment $number_id)} | format pattern "/accounts/{account_id}/sip_trunk/internal_numbers/{number_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Delete all numbers
#
# DELETE /accounts/{accountId}/sip_trunk/numbers
# operationId: deleteAllSipNumbers
export def "accounts-sip-trunk-numbers delete-list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/numbers") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign numbers
#
# POST /accounts/{accountId}/sip_trunk/numbers
# operationId: assignSipTrunkNumbers
export def "accounts-sip-trunk-numbers assign" [
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
  --accept: string@accept-completer # Response content type
  --phone-numbers: list<string> # Phone number(s) to be assigned to the sub account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/numbers") $auth.query)
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Assign SIP trunk configuration
#
# PATCH /accounts/{accountId}/sip_trunk/settings
# operationId: assignSIPConfig
export def "accounts-sip-trunk-settings assign-config" [
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
  --accept: string@accept-completer # Response content type
  --enable: oneof<nothing, bool> # Enable or delete the configuration. The values can be one of the following: `true`: Enable configuration. `false`: Delete configuration
  --show-callout-internal-number: oneof<nothing, bool> # If the value of this option is set to `true`, the call-out numbers provided by the Zoom carrier partners will be displayed in the account's list of available call-out numbers in the Zoom Web Portal and Zoom Client.
  --show-zoom-provided-callout-countries: int # If the value of this option is set to `0`, the call-out countries list provided by Zoom will be [displayed](https://support.zoom.us/hc/en-us/articles/200942859-Using-telephone-call-out) in the account's list of available call-out countries. If the value of this option is set to `1`, the Zoom provided call-out countries will be hidden from the user's account. If the value of this option is set to `2`, all Zoom provided countries will be deleted and only internal countries (provided by carrier partners) will be used.
  --show-zoom-provided-numbers: int@show-zoom-provided-numbers-completer # If the value of this option is set to `0`, the numbers provided by Zoom will be displayed in the account's list of available call-out and call-in numbers in the Zoom Web Portal and Zoom Client. If the value of this option is set to `1`, the Zoom provided numbers will be shown in the Zoom Web Portal but will not be used unless specified by the user. If the value of this option is set to `2`, all Zoom provided numbers will be deleted and only internal numbers (provided by carrier partners) will be used.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/settings") $auth.query)
  let req_body = {"enable": $enable, "show_callout_internal_number": $show_callout_internal_number, "show_zoom_provided_callout_countries": $show_zoom_provided_callout_countries, "show_zoom_provided_numbers": $show_zoom_provided_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List SIP trunks
#
# GET /accounts/{accountId}/sip_trunk/trunks
# operationId: listSIPTrunks
export def "accounts-sip-trunk-trunks list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, outbound_caller_id: string, sip_server_address: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/trunks") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign SIP trunks
#
# POST /accounts/{accountId}/sip_trunk/trunks
# operationId: assignSIPTrunks
# --sip_trunks item shape: {dnis?: string, id?: string, outbound_caller_id?: string}
export def "accounts-sip-trunk-trunks assign" [
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
  --accept: string@accept-completer # Response content type
  --sip-trunks: list # Array of one or more SIP Trunk objects. — item shape: {dnis?: string, id?: string, outbound_caller_id?: string}
]: any -> record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, sip_server_address: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/sip_trunk/trunks") $auth.query)
  let req_body = {"sip_trunks": $sip_trunks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a SIP trunk
#
# DELETE /accounts/{accountId}/sip_trunk/trunks/{trunkId}
# operationId: deleteSIPTrunk
export def "accounts-sip-trunk-trunks delete" [
  account_id: string
  trunk_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($trunk_id | is-empty) { error make --unspanned { msg: "path parameter 'trunkId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), trunk_id: (encode-path-segment $trunk_id)} | format pattern "/accounts/{account_id}/sip_trunk/trunks/{trunk_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get trusted domains
#
# GET /accounts/{accountId}/trusted_domains
# operationId: accountTrustedDomain
export def "accounts-trusted-domains get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<trusted_domains: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/trusted_domains") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Switch a user's account
#
# PUT /accounts/{accountId}/users/{userId}/account
# operationId: switchUserAccount
export def "accounts-users-account update-switch" [
  account_id: string
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
  --accept: string@accept-completer # Response content type
  --body-account-id: string # The Account ID of the account to which you would like move the user to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}/account") $auth.query)
  let req_body = {"account_id": $body_account_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Download an invoice file
#
# GET /api/download/billing/invoices/{invoiceId}
# operationId: downloadInvoicePDF
export def "download-billing-invoices download-pdf" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/download/billing/invoices/{invoice_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List archived files
#
# GET /archive_files
# operationId: listArchivedFiles
export def "archive-files list-archived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --qp-from: string # Start date for the query in "yyyy-MM-dd'T'HH:mm:ss'Z'" format. The duration for the query defined using the "from" and "to" parameters should not exceed 7 days as this API only provides a week's data at once.
  --qp-to: string # End date for the query in "yyyy-MM-dd'T'HH:mm:ss'Z'" format.
  --query-data-type: string@query-data-type-completer # Query data type for `from` and `to`. (default: meeting_start_time)
]: nothing -> record<from: string, meetings: table<archive_files: list, duration: int, host_id: string, id: int, recording_count: int, start_time: string, timezone: string, topic: string, total_size: int, type: int, uuid: string>, next_page_token: string, page_size: int, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "query_data_type" $query_data_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive_files" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to, "query_data_type": $query_data_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a channel
#
# DELETE /chat/channels/{channelId}
# operationId: deleteUserLevelChannel
export def "chat-channels delete-user-level" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/channels/{channel_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a channel
#
# GET /chat/channels/{channelId}
# operationId: getUserLevelChannel
export def "chat-channels get-user-level" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/channels/{channel_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a channel
#
# PATCH /chat/channels/{channelId}
# operationId: updateUserLevelChannel
export def "chat-channels update-user-level" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A new name for the channel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/channels/{channel_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Leave a channel
#
# DELETE /chat/channels/{channelId}/members/me
# operationId: leaveChannel
export def "chat-channels-members-me delete-leave" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/channels/{channel_id}/members/me") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Join a channel
#
# POST /chat/channels/{channelId}/members/me
# operationId: joinChannel
export def "chat-channels-members-me create-join" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<added_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/channels/{channel_id}/members/me") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Remove a member
#
# DELETE /chat/channels/{channelId}/members/{memberId}
# operationId: removeAUserLevelChannelMember
export def "chat-channels-members delete-user-level" [
  channel_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), member_id: (encode-path-segment $member_id)} | format pattern "/chat/channels/{channel_id}/members/{member_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List user's contacts
#
# GET /chat/users/me/contacts
# operationId: getUserContacts
export def "chat-users-me-contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # The type of contact. The value can be one of the following: `company`: Contacts from the user's organization. `external`: External contacts. (default: company)
  --page-size: int # The number of records returned with a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<contacts: table<email: string, first_name: string, id: string, last_name: string>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/users/me/contacts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get user's contact details
#
# GET /chat/users/me/contacts/{contactId}
# operationId: getUserContact
export def "chat-users-me-contacts get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-presence-status: oneof<nothing, bool> # The presence status of the contact. Include this query parameter with a value of `true` to get the presence status of the contact in the response.
]: nothing -> record<direct_numbers: list<string>, email: string, extension_number: string, first_name: string, id: string, last_name: string, phone_number: string, presence_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let qp = [(serialize-qp "query_presence_status" $query_presence_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/chat/users/me/contacts/{contact_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query_presence_status": $query_presence_status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List user's channels
#
# GET /chat/users/{userId}/channels
# operationId: getChannels
export def "chat-users-channels list" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned from a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. The expiration period for this token is 15 minutes.
]: nothing -> record<channels: table<channels_settings: record, id: string, name: string, type: int>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/chat/users/{user_id}/channels") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a channel
#
# POST /chat/users/{userId}/channels
# operationId: createChannel
# --members item shape: {email: string}
export def "chat-users-channels create" [
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
  --accept: string@accept-completer # Response content type
  --members: list # Member(s) to include in the channel. A max of 5 members can be added to the channel at once with this API. — item shape: {email: string}
  --name: string # Name of the channel.
  --type: int@type-completer # Type of the channel. The value can be one of the following: `1`: Private channel. In this type of channel, members must be invited to join a channel. `2`: Private channel with members that belong to one Zoom account. Members in this channel should be invited and the members should be from the same organization. `3`: Public channel. Anyone can search for this channel and join the channel. `4`: New chat. This is an instant channel which can be created by adding members to a new chat.
]: any -> record<id: string, jid: string, name: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/chat/users/{user_id}/channels") $auth.query)
  let req_body = {"members": $members, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a channel
#
# DELETE /chat/users/{userId}/channels/{channelId}
# operationId: deleteChannel
export def "chat-users-channels delete" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a channel
#
# GET /chat/users/{userId}/channels/{channelId}
# operationId: getChannel
export def "chat-users-channels get" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a channel
#
# PATCH /chat/users/{userId}/channels/{channelId}
# operationId: updateChannel
export def "chat-users-channels update" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A new name for the channel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List channel members
#
# GET /chat/users/{userId}/channels/{channelId}/members
# operationId: listChannelMembers
export def "chat-users-channels-members list" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned with a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<members: table<email: string, first_name: string, id: string, last_name: string, role: string>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}/members") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite channel members
#
# POST /chat/users/{userId}/channels/{channelId}/members
# operationId: inviteChannelMembers
# --members item shape: {email: string}
export def "chat-users-channels-members create-invite" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # Members of a channel. You can invite up to a max number of 5 members with a single API call. — item shape: {email: string}
]: any -> record<added_at: string, ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Remove a member
#
# DELETE /chat/users/{userId}/channels/{channelId}/members/{memberId}
# operationId: removeAChannelMember
export def "chat-users-channels-members delete" [
  user_id: string
  channel_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id), member_id: (encode-path-segment $member_id)} | format pattern "/chat/users/{user_id}/channels/{channel_id}/members/{member_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List user's chat messages
#
# GET /chat/users/{userId}/messages
# operationId: getChatMessages
export def "chat-users-messages get" [
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
  --accept: string@accept-completer # Response content type
  --to-contact: string # The email address of a chat contact with whom the current user chatted. Messages that were sent and/or received between the user and the contact is displayed. Note: You must provide either `contact` or `channel` as a query parameter to retrieve messages either from an individual or a chat channel.
  --to-channel: string # The channel Id of a channel inside which the current user had chat conversations. Messages that were sent and/or received between the user and the channel is displayed. Note: You must provide either `contact` or `channel` as a query parameter to retrieve messages either from an individual or a chat channel.
  --date: string # The query date for which you would like to get the chat messages. (format: date)
  --page-size: int # The number of records returned with a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-deleted-and-edited-message: string # **Optional** Set the value of this field to `true` to include edited and deleted messages in the response.
]: nothing -> record<date: string, messages: table<date_time: string, id: string, message: string, reply_main_message_id: string, reply_main_message_timestamp: int, sender: string, status: string, timestamp: int>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "to_contact" $to_contact "scalar") (serialize-qp "to_channel" $to_channel "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_deleted_and_edited_message" $include_deleted_and_edited_message "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/chat/users/{user_id}/messages") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"to_contact": $to_contact, "to_channel": $to_channel, "date": $date, "page_size": $page_size, "next_page_token": $next_page_token, "include_deleted_and_edited_message": $include_deleted_and_edited_message} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Send a chat message
#
# POST /chat/users/{userId}/messages
# operationId: sendaChatMessage
# --at_items item shape: {at_contact?: string, at_type?: "1"|"2", end_position?: int, start_position?: int}
export def "chat-users-messages create-senda" [
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
  --accept: string@accept-completer # Response content type
  --at-items: list # [Chat mentions](https://support.zoom.us/hc/en-us/articles/360037567431-Using-chat-mentions-and-slash-commands) object. Use this object to include mentions in the message that will be sent to a channel. — item shape: {at_contact?: string, at_type?: "1"|"2", end_position?: int, start_position?: int}
  message: string # The message to be sent.
  --to-channel: string # The Channel Id of the channel where you would like to send a message.
  --to-contact: string # The email address of the contact to whom you would like to send the message.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/chat/users/{user_id}/messages") $auth.query)
  let req_body = {"at_items": $at_items, "message": $message, "to_channel": $to_channel, "to_contact": $to_contact} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a message
#
# DELETE /chat/users/{userId}/messages/{messageId}
# operationId: deleteChatMessage
export def "chat-users-messages delete" [
  user_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to-contact: string # The userId or email address of a chat contact to whom you previously sent the message. Note: You must provide either `to_contact` or `to_channel` as a query parameter to delete a message that was previously sent to either an individual or a chat channel respectively.
  --to-channel: string # The channel Id of the channel where you would like to send the message. You must provide either `to_contact` or `to_channel` as a query parameter to delete a message that was previously sent to either an individual or a chat channel
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let qp = [(serialize-qp "to_contact" $to_contact "scalar") (serialize-qp "to_channel" $to_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), message_id: (encode-path-segment $message_id)} | format pattern "/chat/users/{user_id}/messages/{message_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"to_contact": $to_contact, "to_channel": $to_channel} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update a message
#
# PUT /chat/users/{userId}/messages/{messageId}
# operationId: editMessage
export def "chat-users-messages update-edit" [
  user_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # The edited message.
  --to-channel: string # The Channel ID of the channel where you sent the message.You must provide either `to_contact` or `to_channel` parameter in the API request. Channel ID can be retrieved from List User's Channels API.
  --to-contact: string # The email address of the contact to whom the message was sent. You must provide either `to_contact` or `to_channel` parameter in the API request.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), message_id: (encode-path-segment $message_id)} | format pattern "/chat/users/{user_id}/messages/{message_id}") $auth.query)
  let req_body = {"message": $message, "to_channel": $to_channel, "to_contact": $to_contact} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Search company contacts
#
# GET /contacts
# operationId: searchCompanyContacts
export def "contacts list-company" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-key: string # Provide the keyword - either first name, last name or email of the contact whom you have to search for.
  --query-presence-status: string # Set `query_presence_status` to `true` in order to include the presence status of a contact in the response.
  --page-size: int # The number of records to be returned with a single API call. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<contacts: table<dept: string, direct_numbers: list, email: string, extension_number: string, first_name: string, id: string, im_group_id: string, im_group_name: string, job_title: string, last_name: string, location: string, phone_number: string, presence_status: string, sip_phone_number: string>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_key" $search_key "scalar") (serialize-qp "query_presence_status" $query_presence_status "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search_key": $search_key, "query_presence_status": $query_presence_status, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List groups
#
# GET /groups
# operationId: groups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<groups: table<id: string, name: string, total_members: int>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a group
#
# POST /groups
# operationId: groupCreate
export def "groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Group name.
]: any -> record<id: string, name: string, total_members: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201 300]
}

# Delete a group
#
# DELETE /groups/{groupId}
# operationId: groupDelete
export def "groups delete" [
  group_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Get a group
#
# GET /groups/{groupId}
# operationId: group
export def "groups get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, total_members: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a group
#
# PATCH /groups/{groupId}
# operationId: groupUpdate
export def "groups update" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Group name. It must be unique to one account and less than 128 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Get locked settings
#
# GET /groups/{groupId}/lock_settings
# operationId: getGroupLockSettings
export def "groups-lock-settings get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string # Specify `meeting_security` as the value of this field if you would like to view security settings applied on a meeting hosted by the users in this group.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "custom_query_fields" $custom_query_fields "scalar") (serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/lock_settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"custom_query_fields": $custom_query_fields, "option": $option} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update locked settings
#
# PATCH /groups/{groupId}/lock_settings
# operationId: groupLockedSettings
# --email_notification shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
# --in_meeting shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, original_audio?: bool, polling?: bool, post_meeting_feedback?: bool, ... (13 more fields)}
# --recording shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, recording_authentication?: string}
# --schedule_meeting shape: {audio_type?: bool, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, mute_upon_entry?: bool, participant_video?: bool, personal_meeting?: bool, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
# --telephony shape: {telephony_regions?: bool, third_party_audio?: bool}
# --meeting_security shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
export def "groups-lock-settings update-locked" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string # Specify `meeting_security` as the value of this field if you would like to view security settings applied on a meeting hosted by the users in this group.
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, original_audio?: bool, polling?: bool, post_meeting_feedback?: bool, ... (13 more fields)}
  --recording: record # shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, recording_authentication?: string}
  --schedule-meeting: record # shape: {audio_type?: bool, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, mute_upon_entry?: bool, participant_video?: bool, personal_meeting?: bool, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
  --telephony: record # shape: {telephony_regions?: bool, third_party_audio?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "custom_query_fields" $custom_query_fields "scalar") (serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/lock_settings") $qp $auth.query)
  let req_body = {"email_notification": $email_notification, "in_meeting": $in_meeting, "recording": $recording, "schedule_meeting": $schedule_meeting, "telephony": $telephony, "meeting_security": $meeting_security} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"custom_query_fields": $custom_query_fields, "option": $option} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List group members
#
# GET /groups/{groupId}/members
# operationId: groupMembers
export def "groups-members get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<members: table<email: string, first_name: string, id: string, last_name: string, type: int>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/members") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add group members
#
# POST /groups/{groupId}/members
# operationId: groupMembersCreate
# --members item shape: {email?: string, id?: string}
export def "groups-members create" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # List of Group members — item shape: {email?: string, id?: string}
]: any -> record<added_at: string, ids: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Delete a group member
#
# DELETE /groups/{groupId}/members/{memberId}
# operationId: groupMembersDelete
export def "groups-members delete" [
  group_id: string
  member_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), member_id: (encode-path-segment $member_id)} | format pattern "/groups/{group_id}/members/{member_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Update a group member
#
# PATCH /groups/{groupId}/members/{memberId}
# operationId: updateAGroupMember
export def "groups-members update" [
  group_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  action: string@action-completer-1 # Specify the type of action to be performed: `move`: Simultaneously remove a member from one group and move the member to a different group. `set_primary`: Set a primary group for the user.
  --target-group-id: string # Can be retrieved by calling [GET /groups](https://marketplace.zoom.us/docs/api-reference/zoom-api/groups/groups) API. To move a user, use this field to specify the groupId of the group where the member is to be moved. To set a primary group for the user, provide the groupId of the group which is going to be the primary group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), member_id: (encode-path-segment $member_id)} | format pattern "/groups/{group_id}/members/{member_id}") $auth.query)
  let req_body = {"action": $action, "target_group_id": $target_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a group's settings
#
# GET /groups/{groupId}/settings
# operationId: getGroupSettings
export def "groups-settings get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the group.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the group. `meeting_security`: Use this query parameter to view meeting security settings applied on the group. (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "custom_query_fields" $custom_query_fields "scalar") (serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"custom_query_fields": $custom_query_fields, "option": $option} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a group's settings
#
# PATCH /groups/{groupId}/settings
# operationId: updateGroupSettings
# --email_notification shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
# --in_meeting shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, ... (21 more fields)}
# --profile shape: {recording_storage_location?: record}
# --recording shape: {account_user_access_recording?: bool, archive?: record, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, save_chat_text?: bool, show_timestamp?: bool}
# --schedule_meeting shape: {audio_type?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, mute_upon_entry?: bool, participant_video?: bool, pstn_password_protected?: bool, require_password_for_all_meetings?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "all"|"jbh_only"|"none", require_password_for_scheduled_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
# --telephony shape: {audio_conference_info?: string, third_party_audio?: bool}
# --meeting_security shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
export def "groups-settings update" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string@option-completer-2 # allows empty value
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, ... (21 more fields)}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # shape: {account_user_access_recording?: bool, archive?: record, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, save_chat_text?: bool, show_timestamp?: bool}
  --schedule-meeting: record # shape: {audio_type?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, mute_upon_entry?: bool, participant_video?: bool, pstn_password_protected?: bool, require_password_for_all_meetings?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "all"|"jbh_only"|"none", require_password_for_scheduled_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
  --telephony: record # shape: {audio_conference_info?: string, third_party_audio?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "custom_query_fields" $custom_query_fields "scalar") (serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/settings") $qp $auth.query)
  let req_body = {"email_notification": $email_notification, "in_meeting": $in_meeting, "profile": $profile, "recording": $recording, "schedule_meeting": $schedule_meeting, "telephony": $telephony, "meeting_security": $meeting_security} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"custom_query_fields": $custom_query_fields, "option": $option} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Delete virtual background files
#
# DELETE /groups/{groupId}/settings/virtual_backgrounds
# operationId: delGroupVB
export def "groups-settings-virtual-backgrounds delete-vb" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "file_ids" $file_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/settings/virtual_backgrounds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"file_ids": $file_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Upload virtual background files
#
# POST /groups/{groupId}/settings/virtual_backgrounds
# operationId: uploadGroupVB
export def "groups-settings-virtual-backgrounds upload-vb" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
  --file: string # Provide the file's path here.
]: any -> record<id: string, is_default: bool, name: string, size: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "file_ids" $file_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/settings/virtual_backgrounds") $qp $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"file_ids": $file_ids} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# List H.323/SIP devices
#
# GET /h323/devices
# operationId: deviceList
export def "h323-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h323/devices" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a H.323/SIP device
#
# POST /h323/devices
# operationId: deviceCreate
export def "h323-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  encryption: string@encryption-completer # Device encryption:`auto` - auto.`yes` - yes.`no` - no.
  ip: string # Device IP.
  name: string # Device name.
  protocol: string@protocol-completer # Device protocol:`H.323` - H.323.`SIP` - SIP.
]: any -> record<id: string, encryption: string, ip: string, name: string, protocol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/h323/devices" $auth.query)
  let req_body = {"encryption": $encryption, "ip": $ip, "name": $name, "protocol": $protocol} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Delete a H.323/SIP device
#
# DELETE /h323/devices/{deviceId}
# operationId: deviceDelete
export def "h323-devices delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/h323/devices/{device_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Update a H.323/SIP device
#
# PATCH /h323/devices/{deviceId}
# operationId: deviceUpdate
export def "h323-devices update" [
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
  encryption: string@encryption-completer # Device encryption:`auto` - auto.`yes` - yes.`no` - no.
  ip: string # Device IP.
  name: string # Device name.
  protocol: string@protocol-completer # Device protocol:`H.323` - H.323.`SIP` - SIP.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/h323/devices/{device_id}") $auth.query)
  let req_body = {"encryption": $encryption, "ip": $ip, "name": $name, "protocol": $protocol} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# Send chatbot messages
#
# POST /im/chat/messages
# operationId: sendchatbot
export def "im-chat-messages create-sendchatbot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # Account ID of the authorized account.
  content: record # JSON template describing how the message should be displayed for the user. For more information please see our ["Send Message" templates](https://marketplace.zoom.us/docs/guides/chatbots/sending-messages#example-request).
  --is-markdown-support: oneof<nothing, bool> # **Optional** Applies the markdown parser to your chatbot message if the value of this field is set to `true`. To learn more, refer to the Chatbot message [markdown reference](https://marketplace.zoom.us/docs/guides/chatbots/customizing-messages/message-with-markdown).
  robot_jid: string # Robot JID created when enabling chatbot features on your marketplace app.
  to_jid: string # Unique JID of reciever. Can be a group or user.
  --user-jid: string # **Optional** The UserJID of the user on whose behalf the message is being sent. Use this field to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
  --visible-to-user: string # **Optional**Allow a Chatbot to send a message to a group channel, but have only one designated person in that group channel see the message by providing the person's UserID in this field.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/im/chat/messages" $auth.query)
  let req_body = {"account_id": $account_id, "content": $content, "is_markdown_support": $is_markdown_support, "robot_jid": $robot_jid, "to_jid": $to_jid, "user_jid": $user_jid, "visible_to_user": $visible_to_user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a chatbot message
#
# DELETE /im/chat/messages/{message_id}
# operationId: deleteAChatbotMessage
export def "im-chat-messages delete-chatbot" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_id: string # The AccountID of the Zoom account to which the message was sent. Retrieve this from the Chatbot request sent to your server as shown in the example [here]( https://marketplace.zoom.us/docs/guides/chatbots/sending-messages).
  robot_jid: string # The BotJID found in the Chat Subscription Section on the Features page of your App Dashboard.
  --user-jid: string # The UserJID of the user on whose behalf the message is being sent. Used to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
]: any -> record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'message_id' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/im/chat/messages/{message_id}") $auth.query)
  let req_body = {"account_id": $account_id, "robot_jid": $robot_jid, "user_jid": $user_jid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Edit a chatbot message
#
# PUT /im/chat/messages/{message_id}
# operationId: editChatbotMessage
export def "im-chat-messages update-edit-chatbot" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_id: string # The AccountID of the Zoom account to which the message was sent. Retrieve this from the Chatbot request sent to your server as shown in the example [here]( https://marketplace.zoom.us/docs/guides/chatbots/sending-messages).
  content: record # JSON template describing how the edited message should be displayed for the user. For more information please see our ["Send Message" templates](https://marketplace.zoom.us/docs/guides/chatbots/sending-messages#example-request).
  --is-markdown-support: oneof<nothing, bool> # **Optional** Enable or disable markdown parser to your chatbot message. Applies the markdown parser to your chatbot message if the value of this field is set to `true`. To learn more, refer to the Chatbot message [markdown reference](https://marketplace.zoom.us/docs/guides/chatbots/customizing-messages/message-with-markdown).
  robot_jid: string # Robot JID created when enabling chatbot features on your marketplace app.
  --user-jid: string # **Optional** The UserJID of the user on whose behalf the message is being sent. Use this field to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
]: any -> record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'message_id' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/im/chat/messages/{message_id}") $auth.query)
  let req_body = {"account_id": $account_id, "content": $content, "is_markdown_support": $is_markdown_support, "robot_jid": $robot_jid, "user_jid": $user_jid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get IM chat sessions
#
# GET /im/chat/sessions
# DEPRECATED
# operationId: imChatSessions
@deprecated
export def "im-chat-sessions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<from: string, to: string, next_page_token: string, page_size: int, sessions: table<last_message_sent_time: string, name: string, session_id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/im/chat/sessions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get IM chat messages
#
# GET /im/chat/sessions/{sessionId}
# DEPRECATED
# operationId: imChatMessages
@deprecated
export def "im-chat-sessions get-messages" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<from: string, session_id: string, to: string, next_page_token: string, page_size: int, messages: table<action: string, action_time: string, date_time: string, message: string, sender: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/im/chat/sessions/{session_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List IM directory groups
#
# GET /im/groups
# operationId: imGroups
export def "im-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/im/groups" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an IM directory group
#
# POST /im/groups
# operationId: imGroupCreate
export def "im-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --name: string # Group name: must be unique to one account.
  --search-by-account: oneof<nothing, bool> # Members can search for others under same account.
  --search-by-domain: oneof<nothing, bool> # Members can search for others in the same email domain.
  --search-by-ma-account: oneof<nothing, bool> # Members can search for others under same master account, including all sub accounts.
  --type: string@type-completer-1 # IM Group types:`normal` - Only members can see automatically see the other members of this group. Other people can search for members within this group. `shared` - Everyone under an account can see the group members automatically.`restricted` - Nobody can see the group or search for members except the members in the group. (default: normal)
]: any -> record<id: string, name: string, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, total_members: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/im/groups" $auth.query)
  let req_body = {"name": $name, "search_by_account": $search_by_account, "search_by_domain": $search_by_domain, "search_by_ma_account": $search_by_ma_account, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Delete an IM directory group
#
# DELETE /im/groups/{groupId}
# operationId: imGroupDelete
export def "im-groups delete" [
  group_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/im/groups/{group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204 300]
}

# Retrieve an IM directory group
#
# GET /im/groups/{groupId}
# operationId: imGroup
export def "im-groups get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/im/groups/{group_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Update an IM directory group
#
# PATCH /im/groups/{groupId}
# operationId: imGroupUpdate
export def "im-groups update" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Group name: must be unique to one account.
  --search-by-account: oneof<nothing, bool> # Members can search for others under same account.
  --search-by-domain: oneof<nothing, bool> # Members can search for others in the same email domain.
  --search-by-ma-account: oneof<nothing, bool> # Members can search for others under same master account, including all sub accounts.
  --type: string@type-completer-1 # IM Group types:`normal` - Only group members can automatically see others in their group. Other people can search for members in the group.`shared` - Everyone under the account can see the group and members automatically.`restricted` - Nobody can see the group or search for members except for the members in the group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/im/groups/{group_id}") $auth.query)
  let req_body = {"name": $name, "search_by_account": $search_by_account, "search_by_domain": $search_by_domain, "search_by_ma_account": $search_by_ma_account, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# List IM directory group members
#
# GET /im/groups/{groupId}/members
# operationId: imGroupMembers
export def "im-groups-members get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/im/groups/{group_id}/members") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Add IM directory group members
#
# POST /im/groups/{groupId}/members
# operationId: imGroupMembersCreate
# --members item shape: {email?: string, id?: string}
export def "im-groups-members create" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # List of IM group members. — item shape: {email?: string, id?: string}
]: any -> record<added_at: string, ids: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/im/groups/{group_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201 300]
}

# Delete an IM directory group member
#
# DELETE /im/groups/{groupId}/members/{memberId}
# operationId: imGroupMembersDelete
export def "im-groups-members delete" [
  group_id: string
  member_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), member_id: (encode-path-segment $member_id)} | format pattern "/im/groups/{group_id}/members/{member_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Send IM messages
#
# POST /im/users/me/chat/messages
# DEPRECATED
# operationId: sendimmessages
@deprecated
export def "im-users-me-chat-messages create-sendimmessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chat-user: string # The email address (registered with Zoom) or the userId of the chat user.
  --message: string # IM message content.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chat_user" $chat_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/im/users/me/chat/messages" $qp $auth.query)
  let req_body = {"message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"chat_user": $chat_user} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get user’s IM messages
#
# GET /im/users/{userId}/chat/messages
# DEPRECATED
# operationId: listimmessages
@deprecated
export def "im-users-chat-messages list-immessages" [
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
  --accept: string@accept-completer # Response content type
  --chat-user: string # Chat user's ID or email address.
  --channel: string # IM Channel's ID.
  --date: string # IM message's query date time, format as yyyy-MM-dd.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<date: string, messages: table<date_time: string, id: string, message: string, sender: string, timstamp: int>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "chat_user" $chat_user "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/im/users/{user_id}/chat/messages") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"chat_user": $chat_user, "channel": $channel, "date": $date, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use in-Meeting recording controls
#
# PATCH /live_meetings/{meetingId}/events
# operationId: inMeetingRecordingControl
export def "live-meetings-events update-in-recording-control" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --method: string # The method that you would like to control. The value of this field can be one of the following: * `recording.start`: Provide this value if you would like to start the recording. * `recording.stop`: Provide this value if you would like to stop the recording. * `recording.pause`: Provide this value if you would like to pause the recording. * `recording.resume`: Provide this value if you would like to resume the recording that was previously paused.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/live_meetings/{meeting_id}/events") $auth.query)
  let req_body = {"method": $method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a meeting
#
# DELETE /meetings/{meetingId}
# operationId: meetingDelete
export def "meetings delete" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  --schedule-for-reminder: oneof<nothing, bool> # `true`: Notify host and alternative host about the meeting cancellation via email. `false`: Do not send any email notification.
  --cancel-meeting-reminder: string # `true`: Notify registrants about the meeting cancellation via email. `false`: Do not send any email notification to meeting registrants. The default value of this field is `false`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "schedule_for_reminder" $schedule_for_reminder "scalar") (serialize-qp "cancel_meeting_reminder" $cancel_meeting_reminder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "schedule_for_reminder": $schedule_for_reminder, "cancel_meeting_reminder": $cancel_meeting_reminder} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a meeting
#
# GET /meetings/{meetingId}
# operationId: meeting
export def "meetings get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # Meeting Occurrence ID. Provide this field to view meeting details of a particular occurrence of the [recurring meeting](https://support.zoom.us/hc/en-us/articles/214973206-Scheduling-Recurring-Meetings).
  --show-previous-occurrences: oneof<nothing, bool> # Set the value of this field to `true` if you would like to view meeting details of all previous occurrences of a [recurring meeting](https://support.zoom.us/hc/en-us/articles/214973206-Scheduling-Recurring-Meetings).
]: nothing -> record<assistant_id: string, host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, encrypted_password: string, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, status: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "show_previous_occurrences" $show_previous_occurrences "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "show_previous_occurrences": $show_previous_occurrences} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a meeting
#
# PATCH /meetings/{meetingId}
# operationId: meetingUpdate
export def "meetings update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # Meeting occurrence id. Support change of agenda, start_time, duration, settings: {host_video, participant_video, join_before_host, mute_upon_entry, waiting_room, watermark, auto_recording}
  --schedule-for: string # Email or userId if you want to schedule meeting for another user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $qp $auth.query)
  let req_body = {"schedule_for": $schedule_for} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# Perform batch poll creation
#
# POST /meetings/{meetingId}/batch_polls
# operationId: createBatchPolls
# --questions item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
export def "meetings-batch-polls create" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Meeting Poll Title.
]: any -> record<polls: table<id: string, questions: list, status: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/batch_polls") $auth.query)
  let req_body = {"questions": $questions, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get meeting invitation
#
# GET /meetings/{meetingId}/invitation
# operationId: meetingInvitation
export def "meetings-invitation get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<invitation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/invitation") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get live stream details
#
# GET /meetings/{meetingId}/livestream
# operationId: getLiveStreamDetails
export def "meetings-livestream get-live-stream-details" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<page_url: string, stream_key: string, stream_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/livestream") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a live stream
#
# PATCH /meetings/{meetingId}/livestream
# operationId: meetingLiveStreamUpdate
export def "meetings-livestream update-live-stream" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-url: string # The livestream page URL. (format: uri)
  stream_key: string # Stream name and key.
  stream_url: string # Streaming URL.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/livestream") $auth.query)
  let req_body = {"page_url": $page_url, "stream_key": $stream_key, "stream_url": $stream_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# Update Live Stream Status
#
# PATCH /meetings/{meetingId}/livestream/status
# operationId: meetingLiveStreamStatusUpdate
# --settings shape: {active_speaker_name?: bool, display_name?: string}
export def "meetings-livestream-status update-live-stream" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # Update the status of a livestream. The value can be one of the following: `start`: Start a live stream. `stop`: Stop an ongoing live stream.
  --settings: record # Update the settings of a live streaming session. The settings can only be updated for a live stream that has been stopped. You can not update the settings of an ongoing live stream. — shape: {active_speaker_name?: bool, display_name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/livestream/status") $auth.query)
  let req_body = {"action": $action, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# List meeting polls
#
# GET /meetings/{meetingId}/polls
# operationId: meetingPolls
export def "meetings-polls list" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a meeting poll
#
# POST /meetings/{meetingId}/polls
# operationId: meetingPollCreate
# --questions item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
export def "meetings-polls create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/polls") $auth.query)
  let req_body = {"questions": $questions, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a meeting poll
#
# DELETE /meetings/{meetingId}/polls/{pollId}
# operationId: meetingPollDelete
export def "meetings-polls delete" [
  meeting_id: int
  poll_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/meetings/{meeting_id}/polls/{poll_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a meeting poll
#
# GET /meetings/{meetingId}/polls/{pollId}
# operationId: meetingPollGet
export def "meetings-polls get" [
  meeting_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/meetings/{meeting_id}/polls/{poll_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a meeting poll
#
# PUT /meetings/{meetingId}/polls/{pollId}
# operationId: meetingPollUpdate
# --questions item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
export def "meetings-polls update" [
  meeting_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/meetings/{meeting_id}/polls/{poll_id}") $auth.query)
  let req_body = {"questions": $questions, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete meeting recordings
#
# DELETE /meetings/{meetingId}/recordings
# operationId: recordingDelete
export def "meetings-recordings delete" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # The recording delete actions:`trash` - Move recording to trash.`delete` - Delete recording permanently. (default: trash)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"action": $action} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get meeting recordings
#
# GET /meetings/{meetingId}/recordings
# operationId: recordingGet
export def "meetings-recordings get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-fields: string # Get the `download_access_token` field for downloading meeting recordings.
  --ttl: int # Time to live (TTL) of the `download_access_token`. This is only valid if the `include_fields` query parameter contains `download_access_token`. The range is between 0-604800.
]: nothing -> record<download_access_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_fields": $include_fields, "ttl": $ttl} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List recording registrants
#
# GET /meetings/{meetingId}/recordings/registrants
# operationId: meetingRecordingRegistrants
export def "meetings-recordings-registrants get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/registrants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a recording registrant
#
# POST /meetings/{meetingId}/recordings/registrants
# operationId: meetingRecordingRegistrantCreate
# --custom_questions item shape: {title?: string, value?: string}
export def "meetings-recordings-registrants create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
]: any -> record<id: int, registrant_id: string, share_url: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/registrants") $auth.query)
  let req_body = {"address": $address, "city": $city, "comments": $comments, "country": $country, "custom_questions": $custom_questions, "email": $email, "first_name": $first_name, "industry": $industry, "job_title": $job_title, "last_name": $last_name, "no_of_employees": $no_of_employees, "org": $org, "phone": $phone, "purchasing_time_frame": $purchasing_time_frame, "role_in_purchase_process": $role_in_purchase_process, "state": $state, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get registration questions
#
# GET /meetings/{meetingId}/recordings/registrants/questions
# operationId: recordingRegistrantsQuestionsGet
export def "meetings-recordings-registrants-questions get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/registrants/questions") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update registration questions
#
# PATCH /meetings/{meetingId}/recordings/registrants/questions
# operationId: recordingRegistrantQuestionUpdate
# --custom_questions item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"|"multiple"}
# --questions item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
export def "meetings-recordings-registrants-questions update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"|"multiple"}
  --questions: list # Array of Registrant Questions — item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/registrants/questions") $auth.query)
  let req_body = {"custom_questions": $custom_questions, "questions": $questions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update registrant's status
#
# PUT /meetings/{meetingId}/recordings/registrants/status
# operationId: meetingRecordingRegistrantStatus
# --registrants item shape: {id?: string}
export def "meetings-recordings-registrants-status update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer-4
  --registrants: list # List of registrants — item shape: {id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/registrants/status") $auth.query)
  let req_body = {"action": $action, "registrants": $registrants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get meeting recording settings
#
# GET /meetings/{meetingId}/recordings/settings
# operationId: recordingSettingUpdate
export def "meetings-recordings-settings update-by-meeting-id" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<approval_type: int, authentication_domains: string, authentication_option: string, on_demand: bool, password: string, recording_authentication: bool, send_email_to_host: bool, share_recording: string, show_social_share_buttons: bool, topic: string, viewer_download: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/settings") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update meeting recording settings
#
# PATCH /meetings/{meetingId}/recordings/settings
# operationId: recordingSettingsUpdate
export def "meetings-recordings-settings update-by-meeting-id-1" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --approval-type: int@approval-type-completer # Approval type for the registration. `0`- Automatically approve the registration when a user registers. `1` - Manually approve or deny the registration of a user. `2` - No registration required to view the recording.
  --authentication-domains: string # Authentication domains.
  --authentication-option: string # Authentication Options.
  --on-demand: oneof<nothing, bool> # Determine whether registration isrequired to view the recording.
  --password: string # Enable password protection for the recording by setting a password. The password must have a minimum of **eight** characters with a mix of numbers, letters and special characters. **Note:** If the account owner or the admin has set minimum password strength requirements for recordings via Account Settings, the password value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recording-authentication: oneof<nothing, bool> # Only authenticated users can view.
  --send-email-to-host: oneof<nothing, bool> # Send an email to host when someone registers to view the recording. This applies for On-demand recordings only.
  --share-recording: string@share-recording-completer # Determine how the meeting recording is shared.
  --show-social-share-buttons: oneof<nothing, bool> # Show social share buttons on registration page. This applies for On-demand recordings only.
  --topic: string # Name of the recording.
  --viewer-download: oneof<nothing, bool> # Determine whether a viewer can download the recording file or not.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/settings") $auth.query)
  let req_body = {"approval_type": $approval_type, "authentication_domains": $authentication_domains, "authentication_option": $authentication_option, "on_demand": $on_demand, "password": $password, "recording_authentication": $recording_authentication, "send_email_to_host": $send_email_to_host, "share_recording": $share_recording, "show_social_share_buttons": $show_social_share_buttons, "topic": $topic, "viewer_download": $viewer_download} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Recover meeting recordings
#
# PUT /meetings/{meetingId}/recordings/status
# operationId: recordingStatusUpdate
export def "meetings-recordings-status update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/recordings/status") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Delete a meeting recording file
#
# DELETE /meetings/{meetingId}/recordings/{recordingId}
# operationId: recordingDeleteOne
export def "meetings-recordings delete-one" [
  meeting_id: string
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # The recording delete actions:`trash` - Move recording to trash.`delete` - Delete recording permanently. (default: trash)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($recording_id | is-empty) { error make --unspanned { msg: "path parameter 'recordingId' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), recording_id: (encode-path-segment $recording_id)} | format pattern "/meetings/{meeting_id}/recordings/{recording_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"action": $action} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Recover a single recording
#
# PUT /meetings/{meetingId}/recordings/{recordingId}/status
# operationId: recordingStatusUpdateOne
export def "meetings-recordings-status update-one" [
  meeting_id: string
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($recording_id | is-empty) { error make --unspanned { msg: "path parameter 'recordingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), recording_id: (encode-path-segment $recording_id)} | format pattern "/meetings/{meeting_id}/recordings/{recording_id}/status") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List meeting registrants
#
# GET /meetings/{meetingId}/registrants
# operationId: meetingRegistrants
export def "meetings-registrants get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/registrants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "status": $status, "page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Add meeting registrant
#
# POST /meetings/{meetingId}/registrants
# operationId: meetingRegistrantCreate
# --custom_questions item shape: {title?: string, value?: string}
export def "meetings-registrants create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-ids: string # Occurrence IDs. You can find these with the meeting get API. Multiple values separated by comma.
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
  --language: string # Registrant's language preference for confirmation emails. The value can be one of the following: `en-US`,`de-DE`,`es-ES`,`fr-FR`,`jp-JP`,`pt-PT`,`ru-RU`,`zh-CN`, `zh-TW`, `ko-KO`, `it-IT`, `vi-VN`.
  --auto-approve: oneof<nothing, bool>
]: any -> record<id: int, join_url: string, registrant_id: string, start_time: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_ids" $occurrence_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/registrants") $qp $auth.query)
  let req_body = {"address": $address, "city": $city, "comments": $comments, "country": $country, "custom_questions": $custom_questions, "email": $email, "first_name": $first_name, "industry": $industry, "job_title": $job_title, "last_name": $last_name, "no_of_employees": $no_of_employees, "org": $org, "phone": $phone, "purchasing_time_frame": $purchasing_time_frame, "role_in_purchase_process": $role_in_purchase_process, "state": $state, "zip": $zip, "language": $language, "auto_approve": $auto_approve} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"occurrence_ids": $occurrence_ids} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201 300]
}

# List registration questions
#
# GET /meetings/{meetingId}/registrants/questions
# operationId: meetingRegistrantsQuestionsGet
export def "meetings-registrants-questions get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/registrants/questions") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update registration questions
#
# PATCH /meetings/{meetingId}/registrants/questions
# operationId: meetingRegistrantQuestionUpdate
# --custom_questions item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"}
# --questions item shape: {field_name?: "address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
export def "meetings-registrants-questions update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"}
  --questions: list # Array of Registrant Questions — item shape: {field_name?: "address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/registrants/questions") $auth.query)
  let req_body = {"custom_questions": $custom_questions, "questions": $questions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update registrant's status
#
# PUT /meetings/{meetingId}/registrants/status
# operationId: meetingRegistrantStatus
# --registrants item shape: {email?: string, id?: string}
export def "meetings-registrants-status update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  action: string@action-completer-6 # Registrant Status:`approve` - Approve registrant.`cancel` - Cancel previously approved registrant's registration.`deny` - Deny registrant.
  --registrants: list # List of registrants. — item shape: {email?: string, id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/registrants/status") $qp $auth.query)
  let req_body = {"action": $action, "registrants": $registrants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# Delete a meeting registrant
#
# DELETE /meetings/{meetingId}/registrants/{registrantId}
# operationId: meetingregistrantdelete
export def "meetings-registrants delete-meetingregistrantdelete" [
  meeting_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurence ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($registrant_id | is-empty) { error make --unspanned { msg: "path parameter 'registrantId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), registrant_id: (encode-path-segment $registrant_id)} | format pattern "/meetings/{meeting_id}/registrants/{registrant_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update meeting status
#
# PUT /meetings/{meetingId}/status
# operationId: meetingStatus
export def "meetings-status update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7 # `end` - End a meeting. `recover` - [Recover](https://support.zoom.us/hc/en-us/articles/360038297111-Recover-a-deleted-meeting) a deleted meeting.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/status") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Zoom meetings client feedback
#
# GET /metrics/client/feedback
# operationId: dashboardClientFeedback
export def "metrics-client-feedback get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record<client_feedbacks: table<feedback_id: string, feedback_name: string, participants_count: int>, from: string, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/client/feedback" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get zoom meetings client feedback
#
# GET /metrics/client/feedback/{feedbackId}
# operationId: dashboardClientFeedbackDetail
export def "metrics-client-feedback get-dashboard-detail" [
  feedback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # format: date
  --qp-to: string # format: date
  --page-size: int # default: 30
  --next-page-token: string
]: nothing -> record<from: string, to: string, next_page_token: string, page_size: int, client_feedback_details: table<email: string, meeting_id: string, participant_name: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feedback_id | is-empty) { error make --unspanned { msg: "path parameter 'feedbackId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feedback_id: (encode-path-segment $feedback_id)} | format pattern "/metrics/client/feedback/{feedback_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List client meeting satisfaction
#
# GET /metrics/client/satisfaction
# operationId: listMeetingSatisfaction
export def "metrics-client-satisfaction list-meeting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # The start date for the query in “yyyy-mm-dd” format. (format: date)
  --qp-to: string # The end date for the query in “yyyy-mm-dd” format. (format: date)
]: nothing -> record<client_satisfaction: table<date: string, good_count: int, none_count: int, not_good_count: int, satisfaction_percent: int>, from: string, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/client/satisfaction" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get CRC port usage
#
# GET /metrics/crc
# operationId: dashboardCRC
export def "metrics-crc get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/crc" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get IM metrics
#
# GET /metrics/im
# operationId: dashboardIM
export def "metrics-im get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, users: table<calls_receive: int, calls_send: int, email: string, emoji_receive: int, emoji_send: int, files_receive: int, files_send: int, group_receive: int, group_send: int, images_receive: int, images_send: int, total_receive: int, total_send: int, user_id: string, user_name: string, videos_receive: int, videos_send: int, voice_receive: int, voice_send: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/im" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get top 25 Zoom Rooms with issues
#
# GET /metrics/issues/zoomrooms
# operationId: dashboardIssueZoomRoom
export def "metrics-issues-zoomrooms get-dashboard-zoom-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record<from: string, to: string, total_records: int, zoom_rooms: table<id: string, issues_count: int, room_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/issues/zoomrooms" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get issues of Zoom Rooms
#
# GET /metrics/issues/zoomrooms/{zoomroomId}
# operationId: dashboardIssueDetailZoomRoom
export def "metrics-issues-zoomrooms get-dashboard-detail-zoom-room" [
  zoomroom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, issue_details: table<issue: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zoomroom_id | is-empty) { error make --unspanned { msg: "path parameter 'zoomroomId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zoomroom_id: (encode-path-segment $zoomroom_id)} | format pattern "/metrics/issues/zoomrooms/{zoomroom_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List meetings
#
# GET /metrics/meetings
# operationId: dashboardMeetings
export def "metrics-meetings get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer # Set the value of this field to "tracking_fields" if you would like to include tracking fields of each meeting in the response.
]: nothing -> record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, tracking_fields: list, user_type: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/meetings" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token, "include_fields": $include_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get meeting details
#
# GET /metrics/meetings/{meetingId}
# operationId: dashboardMeetingDetail
export def "metrics-meetings get-dashboard-detail" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings.`live` - Live meetings. (default: live)
]: nothing -> record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/metrics/meetings/{meeting_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List meeting participants
#
# GET /metrics/meetings/{meetingId}/participants
# operationId: dashboardMeetingParticipants
export def "metrics-meetings-participants get-dashboard" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings.`live` - Live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide `registrant_id` as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [meeting registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingregistrants). This is not supported for `live` meeting types.
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, camera: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, in_room_participants: int, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, status: string, user_id: string, user_name: string, version: string, video_quality: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/metrics/meetings/{meeting_id}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token, "include_fields": $include_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List meeting participants QoS
#
# GET /metrics/meetings/{meetingId}/participants/qos
# operationId: dashboardMeetingParticipantsQOS
export def "metrics-meetings-participants-qos list" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
  --page-size: int # The number of items returned per page. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/metrics/meetings/{meeting_id}/participants/qos") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get post meeting feedback
#
# GET /metrics/meetings/{meetingId}/participants/satisfaction
# operationId: participantFeedback
export def "metrics-meetings-participants-satisfaction get-feedback" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/metrics/meetings/{meeting_id}/participants/satisfaction") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sharing/recording details
#
# GET /metrics/meetings/{meetingId}/participants/sharing
# operationId: dashboardMeetingParticipantShare
export def "metrics-meetings-participants-sharing get-dashboard-share" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceed the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/metrics/meetings/{meeting_id}/participants/sharing") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get meeting participant QoS
#
# GET /metrics/meetings/{meetingId}/participants/{participantId}/qos
# operationId: dashboardMeetingParticipantQOS
export def "metrics-meetings-participants-qos get-dashboard" [
  meeting_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
]: nothing -> record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participantId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), participant_id: (encode-path-segment $participant_id)} | format pattern "/metrics/meetings/{meeting_id}/participants/{participant_id}/qos") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List webinars
#
# GET /metrics/webinars
# operationId: dashboardWebinars
export def "metrics-webinars get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, webinars: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/webinars" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get webinar details
#
# GET /metrics/webinars/{webinarId}
# operationId: dashboardWebinarDetail
export def "metrics-webinars get-dashboard-detail" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
]: nothing -> record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/metrics/webinars/{webinar_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get webinar participants
#
# GET /metrics/webinars/{webinarId}/participants
# operationId: dashboardWebinarParticipants
export def "metrics-webinars-participants get-dashboard" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide 'registrant_id' as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [webinar registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarregistrants).
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, user_id: string, user_name: string, version: string, video_quality: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/metrics/webinars/{webinar_id}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token, "include_fields": $include_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List webinar participant QoS
#
# GET /metrics/webinars/{webinarId}/participants/qos
# operationId: dashboardWebinarParticipantsQOS
export def "metrics-webinars-participants-qos list" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
  --page-size: int # The number of items returned per page. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/metrics/webinars/{webinar_id}/participants/qos") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get post webinar feedback
#
# GET /metrics/webinars/{webinarId}/participants/satisfaction
# operationId: participantWebinarFeedback
export def "metrics-webinars-participants-satisfaction get-feedback" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-2 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/metrics/webinars/{webinar_id}/participants/satisfaction") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sharing/recording details
#
# GET /metrics/webinars/{webinarId}/participants/sharing
# operationId: dashboardWebinarParticipantShare
export def "metrics-webinars-participants-sharing get-dashboard-share" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceed the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/metrics/webinars/{webinar_id}/participants/sharing") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get webinar participant QoS
#
# GET /metrics/webinars/{webinarId}/participants/{participantId}/qos
# operationId: dashboardWebinarParticipantQOS
export def "metrics-webinars-participants-qos get-dashboard" [
  webinar_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The webinar type. (default: live)
]: nothing -> record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participantId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), participant_id: (encode-path-segment $participant_id)} | format pattern "/metrics/webinars/{webinar_id}/participants/{participant_id}/qos") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List Zoom Rooms
#
# GET /metrics/zoomrooms
# operationId: dashboardZoomRooms
export def "metrics-zoomrooms get-dashboard-zoom-rooms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/zoomrooms" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get top 25 issues of Zoom Rooms
#
# GET /metrics/zoomrooms/issues
# operationId: dashboardZoomRoomIssue
export def "metrics-zoomrooms-issues get-dashboard-zoom-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/zoomrooms/issues" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Zoom Rooms details
#
# GET /metrics/zoomrooms/{zoomroomId}
# operationId: dashboardZoomRoom
export def "metrics-zoomrooms get-dashboard-zoom-room" [
  zoomroom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zoomroom_id | is-empty) { error make --unspanned { msg: "path parameter 'zoomroomId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zoomroom_id: (encode-path-segment $zoomroom_id)} | format pattern "/metrics/zoomrooms/{zoomroom_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List past meeting's files
#
# GET /past_meetings/{meetingId}/files
# operationId: listPastMeetingFiles
export def "past-meetings-files list" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/past_meetings/{meeting_id}/files") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List ended meeting instances
#
# GET /past_meetings/{meetingId}/instances
# operationId: pastMeetings
export def "past-meetings-instances get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/past_meetings/{meeting_id}/instances") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List past meeting's poll results
#
# GET /past_meetings/{meetingId}/polls
# operationId: listPastMeetingPolls
export def "past-meetings-polls list" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/past_meetings/{meeting_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get past meeting details
#
# GET /past_meetings/{meetingUUID}
# operationId: pastMeetingDetails
export def "past-meetings get-details" [
  meeting_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<duration: int, end_time: string, host_id: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_uuid | is-empty) { error make --unspanned { msg: "path parameter 'meetingUUID' must be non-empty" } }
  let full_url = (build-url $base ({meeting_uuid: (encode-path-segment $meeting_uuid)} | format pattern "/past_meetings/{meeting_uuid}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get past meeting participants
#
# GET /past_meetings/{meetingUUID}/participants
# operationId: pastMeetingParticipants
export def "past-meetings-participants get" [
  meeting_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<id: string, name: string, user_email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_uuid | is-empty) { error make --unspanned { msg: "path parameter 'meetingUUID' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_uuid: (encode-path-segment $meeting_uuid)} | format pattern "/past_meetings/{meeting_uuid}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get webinar absentees
#
# GET /past_webinars/{WebinarUUID}/absentees
# operationId: webinarAbsentees
export def "past-webinars-absentees get" [
  webinar_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_uuid | is-empty) { error make --unspanned { msg: "path parameter 'WebinarUUID' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_uuid: (encode-path-segment $webinar_uuid)} | format pattern "/past_webinars/{webinar_uuid}/absentees") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List past webinar files
#
# GET /past_webinars/{webinarId}/files
# operationId: listPastWebinarFiles
export def "past-webinars-files list" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/past_webinars/{webinar_id}/files") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List past webinar instances
#
# GET /past_webinars/{webinarId}/instances
# operationId: pastWebinars
export def "past-webinars-instances get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/past_webinars/{webinar_id}/instances") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# List webinar participants
#
# GET /past_webinars/{webinarId}/participants
# operationId: listWebinarParticipants
export def "past-webinars-participants list" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, participants: table<id: string, name: string, user_email: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/past_webinars/{webinar_id}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List past webinar poll results
#
# GET /past_webinars/{webinarId}/polls
# operationId: listPastWebinarPollResults
export def "past-webinars-polls list-results" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/past_webinars/{webinar_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Q&A of past webinar
#
# GET /past_webinars/{webinarId}/qa
# operationId: listPastWebinarQA
export def "past-webinars-qa list" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/past_webinars/{webinar_id}/qa") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an auto receptionist
#
# POST /phone/auto_receptionists
# operationId: addAutoReceptionist
export def "phone-auto-receptionists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Provide a name to help identify the auto receptionist.
  --site-id: string # Unique identifier of the site where the auto receptionist is to be assigned. This field is required only if you have [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) enabled.
]: any -> record<extension_number: int, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/auto_receptionists" $auth.query)
  let req_body = {"name": $name, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update auto receptionist details
#
# PATCH /phone/auto_receptionists/{autoReceptionistId}
# operationId: updateAutoReceptionist
export def "phone-auto-receptionists update" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --extension-number: int # Extension number to be assigned to the auto receptionist. If site code is enabled, provide the short extension number instead.
  --name: string # Display name of the auto receptionist.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($auto_receptionist_id | is-empty) { error make --unspanned { msg: "path parameter 'autoReceptionistId' must be non-empty" } }
  let full_url = (build-url $base ({auto_receptionist_id: (encode-path-segment $auto_receptionist_id)} | format pattern "/phone/auto_receptionists/{auto_receptionist_id}") $auth.query)
  let req_body = {"extension_number": $extension_number, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Unassign all phone numbers
#
# DELETE /phone/auto_receptionists/{autoReceptionistId}/phone_numbers
# operationId: unassignAllPhoneNumsAutoReceptionist
export def "phone-auto-receptionists-phone-numbers list-unassign-nums" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($auto_receptionist_id | is-empty) { error make --unspanned { msg: "path parameter 'autoReceptionistId' must be non-empty" } }
  let full_url = (build-url $base ({auto_receptionist_id: (encode-path-segment $auto_receptionist_id)} | format pattern "/phone/auto_receptionists/{auto_receptionist_id}/phone_numbers") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign phone numbers
#
# POST /phone/auto_receptionists/{autoReceptionistId}/phone_numbers
# operationId: assignPhoneNumbersAutoReceptionist
# --phone_numbers item shape: {id?: string, number?: string}
export def "phone-auto-receptionists-phone-numbers assign" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-numbers: list # Provide either the unique identifier of the Phone Number in the `id` field or provide the phone number in the `number` field. — item shape: {id?: string, number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($auto_receptionist_id | is-empty) { error make --unspanned { msg: "path parameter 'autoReceptionistId' must be non-empty" } }
  let full_url = (build-url $base ({auto_receptionist_id: (encode-path-segment $auto_receptionist_id)} | format pattern "/phone/auto_receptionists/{auto_receptionist_id}/phone_numbers") $auth.query)
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Unassign a phone number
#
# DELETE /phone/auto_receptionists/{autoReceptionistId}/phone_numbers/{phoneNumberId}
# operationId: unassignAPhoneNumAutoReceptionist
export def "phone-auto-receptionists-phone-numbers delete-unassign-num" [
  auto_receptionist_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($auto_receptionist_id | is-empty) { error make --unspanned { msg: "path parameter 'autoReceptionistId' must be non-empty" } }
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({auto_receptionist_id: (encode-path-segment $auto_receptionist_id), phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone/auto_receptionists/{auto_receptionist_id}/phone_numbers/{phone_number_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List blocked lists
#
# GET /phone/blocked_list
# operationId: listBlockedList
export def "phone-blocked-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The total number of records returned from a single API call. (default: 30)
]: nothing -> record<blocked_list: table<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/blocked_list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a blocked list
#
# POST /phone/blocked_list
# operationId: addAnumberToBlockedList
export def "phone-blocked-list create-anumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --block-type: string@block-type-completer # State whether you want the block type to be inbound or outbound. `inbound`: Pass this value to prevent the blocked number or prefix from calling in to phone users. `outbound`: Pass this value to prevent phone users from calling the blocked number or prefix.
  --comment: string # Provide a comment to help you identify the blocked number or prefix.
  --match-type: string@match-type-completer # Specify the match type for the blocked list. The values can be one of the following: `phoneNumber`: Choose this option (Phone Number Match) if you want to block a specific phone number. Then, in the `phone_number` field, provide the phone number along with the country code. `prefix`: Choose this option (Prefix Match) if you want to block all numbers with a specific country code and area code. Next, in the `phone_number` field, enter a country code as part of the prefix. For example, entering 1907 blocks numbers with country code 1 and area code 907.
  --phone-number: string # The phone number to be blocked if you passed "phoneNumber" as the value for the `match_type` field. If you passed "prefix" as the value for the `match_type` field, provide the prefix of the phone number here including the country code. For example, entering 1905 blocks numbers with country code 1 and area code 905.
  --status: string@status-completer-1 # Enable or disable the blocking. One of the following values are allowed: `active`: Keep the blocking active. `inactive`: Disable the blocking.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/blocked_list" $auth.query)
  let req_body = {"block_type": $block_type, "comment": $comment, "match_type": $match_type, "phone_number": $phone_number, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a blocked list
#
# DELETE /phone/blocked_list/{blockedListId}
# operationId: deleteABlockedList
export def "phone-blocked-list delete" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($blocked_list_id | is-empty) { error make --unspanned { msg: "path parameter 'blockedListId' must be non-empty" } }
  let full_url = (build-url $base ({blocked_list_id: (encode-path-segment $blocked_list_id)} | format pattern "/phone/blocked_list/{blocked_list_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get blocked list details
#
# GET /phone/blocked_list/{blockedListId}
# operationId: getABlockedList
export def "phone-blocked-list get" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($blocked_list_id | is-empty) { error make --unspanned { msg: "path parameter 'blockedListId' must be non-empty" } }
  let full_url = (build-url $base ({blocked_list_id: (encode-path-segment $blocked_list_id)} | format pattern "/phone/blocked_list/{blocked_list_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a blocked list
#
# PATCH /phone/blocked_list/{blockedListId}
# operationId: updateBlockedList
export def "phone-blocked-list update" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --block-type: string@block-type-completer # State whether you want the block type to be inbound or outbound. `inbound`: Pass this value to prevent the blocked number or prefix from calling in to phone users. `outbound`: Pass this value to prevent phone users from calling the blocked number or prefix.
  --comment: string # Provide a comment to help you identify the blocked number or prefix.
  --match-type: string@match-type-completer # Specify the match type for the blocked list. The values can be one of the following: `phoneNumber`: Choose this option (Phone Number Match) if you want to block a specific phone number. Then, in the `phone_number` field, provide the phone number along with the country code. `prefix`: Choose this option (Prefix Match) if you want to block all numbers with a specific country code and area code. Next, in the `phone_number` field, enter a country code as part of the prefix. For example, entering 1907 blocks numbers with country code 1 and area code 907.
  --phone-number: string # The phone number to be blocked if you passed "phoneNumber" as the value for the `match_type` field. If you passed "prefix" as the value for the `match_type` field, provide the prefix of the phone number here including the country code. For example, entering 1905 blocks numbers with country code 1 and area code 905.
  --status: string@status-completer-1 # Enable or disable the blocking. One of the following values are allowed: `active`: Keep the blocking active. `inactive`: Disable the blocking.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($blocked_list_id | is-empty) { error make --unspanned { msg: "path parameter 'blockedListId' must be non-empty" } }
  let full_url = (build-url $base ({blocked_list_id: (encode-path-segment $blocked_list_id)} | format pattern "/phone/blocked_list/{blocked_list_id}") $auth.query)
  let req_body = {"block_type": $block_type, "comment": $comment, "match_type": $match_type, "phone_number": $phone_number, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add BYOC phone numbers
#
# POST /phone/byoc_numbers
# operationId: addBYOCNumber
export def "phone-byoc-numbers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  carrier: string # Name of the carrier.
  phone_numbers: list<string> # Phone number(s) to be added to Zoom. The value should be in e164 format.
  --site-id: string # Unique identifier of the site. This field is only required if you have enabled multiple sites in the account. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) or [Adding a site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites#h_05c88e35-1593-491f-b1a8-b7139a75dc15) for details.
]: any -> record<phone_numbers: table<id: string, number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/byoc_numbers" $auth.query)
  let req_body = {"carrier": $carrier, "phone_numbers": $phone_numbers, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201 300]
}

# Get account's call logs
#
# GET /phone/call_logs
# operationId: accountCallLogs
export def "phone-call-logs logs-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --qp-from: string # Start date from which you would like to get the call logs. The start date should be within past six months. The API only returns data pertaining to a month. Thus, the date range(defined using "from" and "to" fields) for which the call logs are to be returned must not exceed a month.
  --qp-to: string # The end date upto which you would like to get the call logs for. The end date should be within past six months.
  --type: string # The type of the call logs. The value can be either "all" or "missed".
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --path: string # Filter the API response by [path](https://support.zoom.us/hc/en-us/articles/360021114452-Viewing-and-identifying-logs#h_646b46c6-0623-4ab1-8b8b-ea5b8bcef679) of the call. The value of this field can be one of the following: `voiceMail`, `message`, `forward`, `extension`, `callQueue`, `ivrMenu`, `companyDirectory`, `autoReceptionist`, `contactCenter`, `disconnected`, `commonAreaPhone`, `pstn`, `transfer`, `sharedLines`, `sharedLineGroup`, `tollFreeBilling`, `meetingService`, `parkPickup`, `parkTimeout`, `monitor`, `takeover`, `sipGroup`
  --time-type: string@time-type-completer # Enables you to sort call logs by start or end time. Choose the sort time value. Values include `startTime` or `endTime`. (default: startTime)
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites). Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by call logs of a specific phone site.
]: nothing -> record<call_logs: table<answer_start_time: string, call_id: string, call_type: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, id: string, owner: record, path: string, rate: string, recording_id: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: string>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "time_type" $time_type "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/call_logs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "from": $qp_from, "to": $qp_to, "type": $type, "next_page_token": $next_page_token, "path": $path, "time_type": $time_type, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List call queues
#
# GET /phone/call_queues
# operationId: listCallQueues
export def "phone-call-queues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned from a single API call. (default: 30)
]: nothing -> record<call_queues: table<extension_number: int, id: string, name: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/call_queues" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a call queue
#
# POST /phone/call_queues
# operationId: createCallQueue
# --members shape: {common_area_phone_ids?: list<string>, users?: list}
export def "phone-call-queues create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the Call Queue.
  --extension-number: int # Phone extension number for the site. If a site code has been [assigned](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number instead of the original extension number..
  --members: record # A list of one or more phone users to be included in the call queue. Provide either users or common area phone(s). Provide at least one user in the users object. — shape: {common_area_phone_ids?: list<string>, users?: list}
  name: string # Name of the Call Queue.
  site_id: string # Unique identifier of the site. Required only if [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) have been enabled. This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
]: any -> record<extension_number: int, id: string, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/call_queues" $auth.query)
  let req_body = {"description": $description, "extension_number": $extension_number, "members": $members, "name": $name, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a call queue
#
# DELETE /phone/call_queues/{callQueueId}
# operationId: deleteACallQueue
export def "phone-call-queues delete" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get call queue details
#
# GET /phone/call_queues/{callQueueId}
# operationId: getACallQueue
export def "phone-call-queues get" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, name: string, phone_numbers: table<id: string, number: string, source: string>, site: record<id: string, name: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update call queue details
#
# PATCH /phone/call_queues/{callQueueId}
# operationId: updateCallQueue
export def "phone-call-queues update" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the Call Queue.
  --extension-number: int # Phone extension number for the site. If a site code has been [assigned](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number instead of the original extension number.
  --name: string # Name of the Call Queue.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) where the Call Queue is assigned.
  --status: string@status-completer-1 # Status of the Call Queue. Allowed values: `active` `inactive`
  --timezone: string # [Timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) of the Call Queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}") $auth.query)
  let req_body = {"description": $description, "extension_number": $extension_number, "name": $name, "site_id": $site_id, "status": $status, "timezone": $timezone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change call queue manager
#
# PUT /phone/call_queues/{callQueueId}/manager
# operationId: changeCallQueueManager
export def "phone-call-queues-manager update-change" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --member-id: string # Unique Identifier (userId) or email address of the user who will be the new call queue manager.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/manager") $auth.query)
  let req_body = {"member_id": $member_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Unassign all members
#
# DELETE /phone/call_queues/{callQueueId}/members
# operationId: unassignAllMembers
export def "phone-call-queues-members list-unassign" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/members") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add members to a call queue
#
# POST /phone/call_queues/{callQueueId}/members
# operationId: addMembersToCallQueue
# --members shape: {common_area_phone_ids?: list<string>, users?: list}
export def "phone-call-queues-members create" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: record # A maximum of 10 members can be added at a time. — shape: {common_area_phone_ids?: list<string>, users?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Unassign a member
#
# DELETE /phone/call_queues/{callQueueId}/members/{memberId}
# operationId: unassignMemberFromCallQueue
export def "phone-call-queues-members delete-unassign" [
  call_queue_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id), member_id: (encode-path-segment $member_id)} | format pattern "/phone/call_queues/{call_queue_id}/members/{member_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Unassign all phone numbers
#
# DELETE /phone/call_queues/{callQueueId}/phone_numbers
# operationId: unassignAPhoneNumCallQueue
export def "phone-call-queues-phone-numbers delete-unassign-num" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/phone_numbers") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign numbers to a call queue
#
# POST /phone/call_queues/{callQueueId}/phone_numbers
# operationId: assignPhoneToCallQueue
# --phone_numbers item shape: {id?: string, number?: string}
export def "phone-call-queues-phone-numbers assign" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-numbers: list # Provide either the `id` or the `number` field. Only a max of 5 numbers can be assigned to a call queue at a time. — item shape: {id?: string, number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/phone_numbers") $auth.query)
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Unassign a phone number
#
# DELETE /phone/call_queues/{callQueueId}/phone_numbers/{phoneNumberId}
# operationId: unAssignPhoneNumCallQueue
export def "phone-call-queues-phone-numbers assign-un-num" [
  call_queue_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id), phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone/call_queues/{call_queue_id}/phone_numbers/{phone_number_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get call queue recordings
#
# GET /phone/call_queues/{callQueueId}/recordings
# operationId: getCallQueueRecordings
export def "phone-call-queues-recordings get" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --qp-from: string # Start date (within a 6 month range). (format: date)
  --qp-to: string # End date (within a 6 month range). (format: date)
]: nothing -> record<from: string, next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string>, to: string, total_records: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_queue_id | is-empty) { error make --unspanned { msg: "path parameter 'callQueueId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({call_queue_id: (encode-path-segment $call_queue_id)} | format pattern "/phone/call_queues/{call_queue_id}/recordings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List calling plans
#
# GET /phone/calling_plans
# operationId: listCallingPlans
export def "phone-calling-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<calling_plans: table<assigned: int, available: int, name: string, subscribed: int, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/calling_plans" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List common area phones
#
# GET /phone/common_area_phones
# operationId: listCommonAreaPhones
export def "phone-common-area-phones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The total number of records returned from a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<common_area_phones: table<calling_plans: list, device_type: string, display_name: string, id: string, mac_address: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/common_area_phones" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a common area phone
#
# POST /phone/common_area_phones
# operationId: addCommonAreaPhone
export def "phone-common-area-phones create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the common area phone.
  display_name: string # Display name of the Common area phone.
  extension_number: int # Extension number assigned to the common area phone. If site code is enabled, provide the short extension number instead.
  mac_address: string # Mac Address (serial number) of the common area desk phone. These examples show the formats supported: `64-16-7f-37-90-92` or `64167f379092`
  --model: string # Device Model name. Refer to the "Model Name" field in [this](https://marketplace.zoom.us/docs/api-reference/other-references/zoomphone-supporteddevice) table.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672). This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
  --time-zone: string # [Timezone ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists) for the common area phone.
  type: string # Phone device manufacturer name. Refer to the "Manufacturer Name" field in [this](https://marketplace.zoom.us/docs/api-reference/other-references/zoomphone-supporteddevice) table.
]: any -> record<display_name: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/common_area_phones" $auth.query)
  let req_body = {"description": $description, "display_name": $display_name, "extension_number": $extension_number, "mac_address": $mac_address, "model": $model, "site_id": $site_id, "time_zone": $time_zone, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a common area phone
#
# DELETE /phone/common_area_phones/{commonAreaPhoneId}
# operationId: deleteCommonAreaPhone
export def "phone-common-area-phones delete" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($common_area_phone_id | is-empty) { error make --unspanned { msg: "path parameter 'commonAreaPhoneId' must be non-empty" } }
  let full_url = (build-url $base ({common_area_phone_id: (encode-path-segment $common_area_phone_id)} | format pattern "/phone/common_area_phones/{common_area_phone_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get common area phone details
#
# GET /phone/common_area_phones/{commonAreaPhoneId}
# operationId: getACommonAreaPhone
export def "phone-common-area-phones get" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<device_type: string, id: string, mac_address: string, name: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($common_area_phone_id | is-empty) { error make --unspanned { msg: "path parameter 'commonAreaPhoneId' must be non-empty" } }
  let full_url = (build-url $base ({common_area_phone_id: (encode-path-segment $common_area_phone_id)} | format pattern "/phone/common_area_phones/{common_area_phone_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update common area phone
#
# PATCH /phone/common_area_phones/{commonAreaPhoneId}
# operationId: updateCommonAreaPhone
export def "phone-common-area-phones update" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-name: string # Display name of the common area phone.
  --extension-number: int # Extension number of the phone. If site code is enabled, provide short extension number instead.
  --mac-address: string # Mac address or serial number of the device. Examples of supported format: "64-16-7f-37-90-92" or "64167f379092".
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) to which the common area desk phone is assigned.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($common_area_phone_id | is-empty) { error make --unspanned { msg: "path parameter 'commonAreaPhoneId' must be non-empty" } }
  let full_url = (build-url $base ({common_area_phone_id: (encode-path-segment $common_area_phone_id)} | format pattern "/phone/common_area_phones/{common_area_phone_id}") $auth.query)
  let req_body = {"display_name": $display_name, "extension_number": $extension_number, "mac_address": $mac_address, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change main company number
#
# PUT /phone/company_number
# operationId: changeMainCompanyNumber
export def "phone-company-number update-change-main" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-number: string # Provide either the unique identifier of the phone number (id) or the phone number itself in e164 format (e.g: +199955500123).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/company_number" $auth.query)
  let req_body = {"phone_number": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List devices
#
# GET /phone/devices
# operationId: listPhoneDevices
export def "phone-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # State of the device. The value should be either `assigned` to list devices that have been assigned to user(s) or `unassigned` to list devices that have not yet been assigned to any user in the Zoom account.
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> record<devices: table<assignee: record, device_type: string, display_name: string, id: string, mac_address: string, site: record, status: string>, next_page_token: string, page_size: int, total_records: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/devices" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a device
#
# POST /phone/devices
# operationId: addPhoneDevice
export def "phone-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --assigned-to: string # User ID or email address of the user to whom this device is to be assigned. The User ID and the email of the user can be retrieved using the [List Users](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/users) API.
  display_name: string # Display name of the desk phone.
  mac_address: string # The MAC address of the desk phone. Note: If you're using a wireless phone, enter the wired MAC address, not the wireless MAC address.
  --model: string # Model name of the device.
  --type: string # Manufacturer (brand) name of the device.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/devices" $auth.query)
  let req_body = {"assigned_to": $assigned_to, "display_name": $display_name, "mac_address": $mac_address, "model": $model, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a device
#
# DELETE /phone/devices/{deviceId}
# operationId: deleteADevice
export def "phone-devices delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/phone/devices/{device_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get device details
#
# GET /phone/devices/{deviceId}
# operationId: getADevice
export def "phone-devices get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<assignee: record<extension_number: int, id: string, name: string>, device_type: string, display_name: string, id: string, mac_address: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/phone/devices/{device_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a device
#
# PATCH /phone/devices/{deviceId}
# operationId: updateADevice
export def "phone-devices update" [
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
  --accept: string@accept-completer # Response content type
  --assigned-to: string # User ID or email address of the user to whom this device is to be assigned. The User ID and the email of the user can be retrieved using the [List Users](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/users) API.
  --display-name: string # Display name of the desk phone.
  --mac-address: string # The MAC address of the desk phone. Note: If you're using a wireless phone, enter the wired MAC address, not the wireless MAC address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/phone/devices/{device_id}") $auth.query)
  let req_body = {"assigned_to": $assigned_to, "display_name": $display_name, "mac_address": $mac_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List call logs
#
# GET /phone/metrics/call_logs
# operationId: listCallLogsMetrics
export def "phone-metrics-call-logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date for the report in `yyyy-mm-dd` format. Specify a 30 day range using the `from` and `to` parameters as the response provides a maximum of a month worth of data per API request.
  --qp-to: string # End date for the report in `yyyy-mm-dd` format.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites). Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by call logs of a specific phone site.
  --quality-type: string # Filter call logs by voice quality. Zoom uses MOS of 3.5 as a general baseline to categorize calls by call quality. A MOS greater than or equal to 3.5 means good quality, while below 3.5 means poor quality. The value of this field can be one of the following: * `good`: Retrieve call logs of the call(s) with good quality of voice. * `bad`: Retrieve call logs of the call(s) with good quality of voice. * `all`: Retrieve all call logs without filtering by voice quality.
  --page-size: int # The number of records returned within a single call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<call_logs: table<call_id: string, callee: record, caller: record, date_time: string, direction: string, duration: int, mos: string>, from: string, next_page_token: string, page_size: int, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "quality_type" $quality_type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/metrics/call_logs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "site_id": $site_id, "quality_type": $quality_type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get call QoS
#
# GET /phone/metrics/call_logs/{callId}/qos
# operationId: getCallQoS
export def "phone-metrics-call-logs-qos get-s" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<call_id: string, callee_qos: record<receiving: list<record>, sending: list<record>>, caller_qos: record<receiving: list<record>, sending: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_id | is-empty) { error make --unspanned { msg: "path parameter 'callId' must be non-empty" } }
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/phone/metrics/call_logs/{call_id}/qos") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get call details from call log
#
# GET /phone/metrics/call_logs/{call_id}
# operationId: getCallLogMetricsDetails
export def "phone-metrics-call-logs get-details" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<call_id: string, callee: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, caller: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, date_time: string, direction: string, duration: int, mos: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_id | is-empty) { error make --unspanned { msg: "path parameter 'call_id' must be non-empty" } }
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/phone/metrics/call_logs/{call_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List phone numbers
#
# GET /phone/numbers
# operationId: listAccountPhoneNumbers
export def "phone-numbers list-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --type: string@type-completer-5 # Query response by number assignment. The value can be one of the following: `assigned`: The number has been assigned to either a user, a call queue, an auto-receptionist or a common area phone in an account. `unassigned`: The number is not assigned to anyone. `all`: Include both assigned and unassigned numbers in the response. `byoc`: Include Bring Your Own Carrier (BYOC) numbers only in the response.
  --extension-type: string@extension-type-completer # The type of assignee to whom the number is assigned. The value can be one of the following: `user` `callQueue` `autoReceptionist` `commonAreaPhone`
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --number-type: string@number-type-completer # The type of phone number. The value can be either `toll` or `tollfree`.
  --pending-numbers: oneof<nothing, bool> # Include or exclude pending numbers in the response. The value can be either `true` or `false`.
  --site-id: string # Unique identifier of the site. Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by a specific phone site. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) or [Adding a site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites#h_05c88e35-1593-491f-b1a8-b7139a75dc15) for details.
]: nothing -> record<next_page_token: string, page_size: int, phone_numbers: table<assignee: record, capability: list, carrier: record, display_name: string, id: string, location: string, number: string, number_type: string, sip_group: record, site: record, source: string, status: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "extension_type" $extension_type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "number_type" $number_type "scalar") (serialize-qp "pending_numbers" $pending_numbers "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/numbers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next_page_token": $next_page_token, "type": $type, "extension_type": $extension_type, "page_size": $page_size, "number_type": $number_type, "pending_numbers": $pending_numbers, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get phone number details
#
# GET /phone/numbers/{numberId}
# operationId: getPhoneNumberDetails
export def "phone-numbers get-details" [
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<assignee: record<extension_number: int, id: string, name: string, type: string>, capability: list<string>, display_name: string, id: string, location: string, number: string, number_type: string, site: record<id: string, name: string>, source: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_id | is-empty) { error make --unspanned { msg: "path parameter 'numberId' must be non-empty" } }
  let full_url = (build-url $base ({number_id: (encode-path-segment $number_id)} | format pattern "/phone/numbers/{number_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update phone number details
#
# PATCH /phone/numbers/{numberId}
# operationId: updatePhoneNumberDetails
export def "phone-numbers update-details" [
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --capability: list<string> # Phone number capability. Values: `outgoing` or `incoming`. Add one or both.
  --display-name: string # Phone number display name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_id | is-empty) { error make --unspanned { msg: "path parameter 'numberId' must be non-empty" } }
  let full_url = (build-url $base ({number_id: (encode-path-segment $number_id)} | format pattern "/phone/numbers/{number_id}") $auth.query)
  let req_body = {"capability": $capability, "display_name": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get call recordings
#
# GET /phone/recordings
# operationId: getPhoneRecordings
export def "phone-recordings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. The default is **30**, and the maximum is **100**.
  --next-page-token: string # The current page number of returned records.
  --qp-from: string # Start date and time in **yyyy-mm-dd** format or **yyyy-MM-dd’T’HH:mm:ss’Z’** format. The date range defined by the from and to parameters should only be one month as the report includes only one month worth of data at once.
  --qp-to: string # End date and time in **yyyy-mm-dd** format or **yyyy-MM-dd’T’HH:mm:ss’Z’** format, the same formats supported by the `from` parameter.
  --owner-type: string # The owner type. The allowed values are null, `user`, or `callQueue`. The default is null. If null, returns all owner types. (default: all)
  --recording-type: string # The recording type. The allowed values are null, `OnDemand`, or `Automatic`. The default is null. If null, returns all recording types.
  --site-id: string # The site ID. The default is `All sites`. (default: All sites)
]: nothing -> record<next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string, owner: record, recording_type: string, site: record>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "owner_type" $owner_type "scalar") (serialize-qp "recording_type" $recording_type "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/recordings" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to, "owner_type": $owner_type, "recording_type": $recording_type, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get operation logs report
#
# GET /phone/reports/operationlogs
# operationId: getPSOperationLogs
export def "phone-reports-operationlogs get-ps-operation-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report provides only one month worth of data per API request.
  --qp-to: string # End date in 'yyyy-mm-dd' format.
  --category-type: string # Filter the response by the category of the action performed. By default, the value of this field is "all" and thus, the response will include log of all operations for the defined period.To only include response for a specific category type, provide a value for `category_type` from this [table](http://marketplace.zoom.us/docs/phone-operation-categories ). (default: all)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "category_type" $category_type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/reports/operationlogs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "category_type": $category_type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List setting templates
#
# GET /phone/setting_templates
# operationId: listSettingTemplates
export def "phone-setting-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # Number of records returns within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --site-id: string # Unique identifier of the site. This field is required only if multiple sites have been enabled. of the site. Required only when multiple sites are enabled. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) for details. If this is not provided, the response lists the account level setting templates.
]: nothing -> record<next_page_token: string, page_size: int, templates: table<description: string, id: string, name: string, type: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/setting_templates" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a setting template
#
# POST /phone/setting_templates
# operationId: addSettingTemplate
export def "phone-setting-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # A description of the template.
  name: string # The name of the template.
  --site-id: string # Unique identifier of the site. Required only when multiple sites are enabled. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) for details.
  type: string@type-completer-6 # The type of template. Values include `user`, `group`, `autoReceptionist`, `commonarea`, or `interop`.
]: any -> record<description: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/setting_templates" $auth.query)
  let req_body = {"description": $description, "name": $name, "site_id": $site_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get setting template details
#
# GET /phone/setting_templates/{templateId}
# operationId: getSettingTemplate
export def "phone-setting-templates get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field to use to filter the response. For example, if you provide "description" as the value of the field, you will get a response similar to the following: {“description”: “template description”}.
]: nothing -> record<description: string, id: string, name: string, policy: record<ad_hoc_call_recording: record<enable: bool, recording_start_prompt: bool, recording_transcription: bool>, auto_call_recording: record<enable: bool, recording_calls: string, recording_start_prompt: bool, recording_transcription: bool>, sms: record<enable: bool, international_sms: bool>, voicemail: record<allow_transcription: bool, enable: bool>>, profile: record<area_code: string, country: string>, type: string, user_settings: record<audio_prompt_language: string, block_calls_without_caller_id: bool, call_handling: record<business_hours: record, close_hours: record>, desk_phone: record<pin_code: string>, hold_music: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'templateId' must be non-empty" } }
  let qp = [(serialize-qp "custom_query_fields" $custom_query_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/phone/setting_templates/{template_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"custom_query_fields": $custom_query_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a setting template
#
# PATCH /phone/setting_templates/{templateId}
# operationId: updateSettingTemplate
# --policy shape: {ad_hoc_call_recording?: record, auto_call_recording?: record, sms?: record, voicemail?: record}
# --profile shape: {area_code?: string, country?: string}
# --user_settings shape: {audio_prompt_language?: string, block_calls_without_caller_id?: bool, call_handling?: record, desk_phone?: record, hold_music?: "default"|"disable"}
export def "phone-setting-templates update" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # The description of the template.
  --name: string # Specify the name of the template.
  --policy: record # shape: {ad_hoc_call_recording?: record, auto_call_recording?: record, sms?: record, voicemail?: record}
  --profile: record # shape: {area_code?: string, country?: string}
  --user-settings: record # shape: {audio_prompt_language?: string, block_calls_without_caller_id?: bool, call_handling?: record, desk_phone?: record, hold_music?: "default"|"disable"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'templateId' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/phone/setting_templates/{template_id}") $auth.query)
  let req_body = {"description": $description, "name": $name, "policy": $policy, "profile": $profile, "user_settings": $user_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List shared line groups
#
# GET /phone/shared_line_groups
# operationId: listSharedLineGroups
export def "phone-shared-line-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_size: int, shared_line_groups: table<display_name: string, extension_number: int, id: string, phone_numbers: list, site: record, status: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/shared_line_groups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a shared line group
#
# POST /phone/shared_line_groups
# operationId: createASharedLineGroup
export def "phone-shared-line-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Provide a description for the shared line group.
  display_name: string # Provide a name to help identify the shared line group.
  --extension-number: int # Extension number to be assigned to the shared line group. If a [site code has been assigned](https://support.zoom.us/hc/en-us/articles/360020809672#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) that you would like to use for the shared line group. You will only be able to add members that belong to this site to the shared line group. This field is required only if the [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) option has been enabled for the account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/shared_line_groups" $auth.query)
  let req_body = {"description": $description, "display_name": $display_name, "extension_number": $extension_number, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}
# operationId: deleteASharedLineGroup
export def "phone-shared-line-groups delete" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a shared line group
#
# GET /phone/shared_line_groups/{sharedLineGroupId}
# operationId: getASharedLineGroup
export def "phone-shared-line-groups get" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<display_name: string, extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, phone_numbers: table<id: string, number: string>, primary_number: string, site: record<id: string, name: string>, status: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a shared line group
#
# PATCH /phone/shared_line_groups/{sharedLineGroupId}
# operationId: updateASharedLineGroup
# --primary_number shape: {id?: string, number?: string}
export def "phone-shared-line-groups update" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-name: string # Display Name of the Shared Line Group.
  --extension-number: int # Extension number assigned to the Shared Line Group.
  --primary-number: record # If you have multiple direct phone numbers assigned to the shared line group, select a number from those numbers as the primary number. The primary number shares the same line as the extension number. This means if a caller is routed to the shared line group through an auto receptionist, the line associated with the primary number will be used. A pending number cannot be used as a Primary Number. — shape: {id?: string, number?: string}
  --status: string@status-completer-1 # Status of the Shared Line Group.
  --timezone: string # Timezone to be used for the Business Hours. A value should be provided from the IDs listed [here](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}") $auth.query)
  let req_body = {"display_name": $display_name, "extension_number": $extension_number, "primary_number": $primary_number, "status": $status, "timezone": $timezone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Unassign members of a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/members
# operationId: deleteMembersOfSLG
export def "phone-shared-line-groups-members delete-of-slg" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}/members") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add members to a shared line group
#
# POST /phone/shared_line_groups/{sharedLineGroupId}/members
# operationId: addMembersToSharedLineGroup
# --members shape: {common_area_phone_ids?: list<string>, users?: list}
export def "phone-shared-line-groups-members create" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: record # Members can comprise of users on the account as well as common area phones. You can add a maximum of 10 members at once. — shape: {common_area_phone_ids?: list<string>, users?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Unassign a member from a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/members/{memberId}
# operationId: deleteAMemberSLG
export def "phone-shared-line-groups-members delete-slg" [
  shared_line_group_id: string
  member_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id), member_id: (encode-path-segment $member_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}/members/{member_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign phone numbers
#
# POST /phone/shared_line_groups/{sharedLineGroupId}/phone_numbers
# operationId: assignPhoneNumbersSLG
# --phone_numbers item shape: {id?: string, number?: string}
export def "phone-shared-line-groups-phone-numbers assign-slg" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-numbers: list # Phone number(s) to be assigned to the Shared Line Group. — item shape: {id?: string, number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}/phone_numbers") $auth.query)
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Unassign a phone number
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/phone_numbers/{phoneNumberId}
# operationId: deleteAPhoneNumberSLG
export def "phone-shared-line-groups-phone-numbers delete-slg" [
  shared_line_group_id: string
  phone_number_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_line_group_id | is-empty) { error make --unspanned { msg: "path parameter 'sharedLineGroupId' must be non-empty" } }
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({shared_line_group_id: (encode-path-segment $shared_line_group_id), phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone/shared_line_groups/{shared_line_group_id}/phone_numbers/{phone_number_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List BYOC SIP trunks
#
# GET /phone/sip_trunk/trunks
# operationId: listBYOCSIPTrunk
export def "phone-sip-trunk-trunks list-byocsip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> record<byoc_sip_trunk: table<carrier: string, carrier_account: string, id: string, name: string, region: string, sbc_label: string>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/sip_trunk/trunks" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List phone sites
#
# GET /phone/sites
# operationId: listPhoneSites
export def "phone-sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_size: string, sites: table<country: record, id: string, main_auto_receptionist: record, name: string, site_code: string>, total_records: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/sites" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a phone site
#
# POST /phone/sites
# operationId: createPhoneSite
# --default_emergency_address shape: {address_line1: string, address_line2?: string, city: string, country: string, state_code: string, zip: string}
# --short_extension shape: {length?: int}
export def "phone-sites create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  auto_receptionist_name: string # Display name of the [auto-receptionist](https://support.zoom.us/hc/en-us/articles/360021121312-Managing-Auto-Receptionists-and-Integrated-Voice-Response-IVR-) for the site.
  --default-emergency-address: record # shape: {address_line1: string, address_line2?: string, city: string, country: string, state_code: string, zip: string}
  name: string # Name of the Site.
  --short-extension: record # Short extension of the phone site. — shape: {length?: int}
  --site-code: int # Identifier for a site. If site code is enabled, this field is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone/sites" $auth.query)
  let req_body = {"auto_receptionist_name": $auto_receptionist_name, "default_emergency_address": $default_emergency_address, "name": $name, "short_extension": $short_extension, "site_code": $site_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete a phone site
#
# DELETE /phone/sites/{siteId}
# operationId: deletePhoneSite
export def "phone-sites delete" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --transfer-site-id: string # The Site ID of another site where the assets of the current site (users, numbers and phones) can be transferred to.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let qp = [(serialize-qp "transfer_site_id" $transfer_site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/phone/sites/{site_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"transfer_site_id": $transfer_site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get phone site details
#
# GET /phone/sites/{siteId}
# operationId: getASite
export def "phone-sites get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<country: record<code: string, name: string>, id: string, main_auto_receptionist: record<extension_id: string, extension_number: int, id: string, name: string>, name: string, short_extension: record<length: int>, site_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/phone/sites/{site_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update phone site details
#
# PATCH /phone/sites/{siteId}
# operationId: updateSiteDetails
export def "phone-sites update-details" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the site.
  --site-code: int # [Site Code](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/phone/sites/{site_id}") $auth.query)
  let req_body = {"name": $name, "site_code": $site_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List phone users
#
# GET /phone/users
# operationId: listPhoneUsers
export def "phone-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned from a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --site-id: string # Unique Identifier of the site. This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
]: nothing -> record<next_page_token: string, page_size: int, total_records: int, users: table<calling_plans: list, email: string, extension_number: int, id: string, name: string, phone_user_id: string, site: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone/users" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get user's profile
#
# GET /phone/users/{userId}
# operationId: phoneUser
export def "phone-users get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<calling_plan: table<type: int>, email: string, extension_number: int, id: string, phone_numbers: table<id: string, number: string>, phone_user_id: string, site_admin: bool, site_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Update user's profile
#
# PATCH /phone/users/{userId}
# operationId: updateUserProfile
export def "phone-users update-profile" [
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
  --accept: string@accept-completer # Response content type
  --extension-number: string # The extension number of the user. The number must be complete (i.e. site number + short extension).
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672) where the user should be moved or assigned.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}") $auth.query)
  let req_body = {"extension_number": $extension_number, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204 300]
}

# Get user's call logs
#
# GET /phone/users/{userId}/call_logs
# operationId: phoneUserCallLogs
export def "phone-users-call-logs logs" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --type: string@type-completer-7
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --phone-number: string # Filter API responses to include call logs of only the phone number defined in this field.
  --time-type: string@time-type-completer # Enables you to sort call logs by start or end time. Choose the sort time value. Values include `startTime` or `endTime`. (default: startTime)
]: nothing -> record<call_logs: table<accepted_by: record, call_id: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, forwarded_by: record, forwarded_to: record, has_recording: bool, has_voicemail: bool, id: string, outgoing_by: record, path: string, rate: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: int>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "phone_number" $phone_number "scalar") (serialize-qp "time_type" $time_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/call_logs") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "from": $qp_from, "to": $qp_to, "type": $type, "next_page_token": $next_page_token, "phone_number": $phone_number, "time_type": $time_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Delete a user's call log
#
# DELETE /phone/users/{userId}/call_logs/{callLogId}
# operationId: deleteCallLog
export def "phone-users-call-logs delete" [
  user_id: string
  call_log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($call_log_id | is-empty) { error make --unspanned { msg: "path parameter 'callLogId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), call_log_id: (encode-path-segment $call_log_id)} | format pattern "/phone/users/{user_id}/call_logs/{call_log_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign calling plan to a user
#
# POST /phone/users/{userId}/calling_plans
# operationId: assignCallingPlan
# --calling_plans item shape: {type?: string}
export def "phone-users-calling-plans assign" [
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
  --accept: string@accept-completer # Response content type
  --calling-plans: list # item shape: {type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/calling_plans") $auth.query)
  let req_body = {"calling_plans": $calling_plans} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 300]
}

# Unassign user's calling plan
#
# DELETE /phone/users/{userId}/calling_plans/{type}
# operationId: unassignCallingPlan
export def "phone-users-calling-plans delete-unassign" [
  user_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), type: (encode-path-segment $type)} | format pattern "/phone/users/{user_id}/calling_plans/{type}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204 300]
}

# Assign phone number to user
#
# POST /phone/users/{userId}/phone_numbers
# operationId: assignPhoneNumber
# --phone_numbers item shape: {id?: string, number?: string}
export def "phone-users-phone-numbers assign" [
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
  --accept: string@accept-completer # Response content type
  --phone-numbers: list # item shape: {id?: string, number?: string}
]: any -> record<phone_numbers: table<id: string, number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/phone_numbers") $auth.query)
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 300]
}

# Unassign phone number
#
# DELETE /phone/users/{userId}/phone_numbers/{phoneNumberId}
# operationId: UnassignPhoneNumber
export def "phone-users-phone-numbers delete-unassign" [
  user_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone/users/{user_id}/phone_numbers/{phone_number_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204 300]
}

# Get user's recordings
#
# GET /phone/users/{userId}/recordings
# operationId: phoneUserRecordings
export def "phone-users-recordings get" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --qp-from: string # Start date for the query in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the response includes only one month worth of recording data. The month defined should fall within the last six months. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record<from: string, next_page_token: string, page_count: int, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: string, id: string>, to: string, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/recordings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get user's settings
#
# GET /phone/users/{userId}/settings
# operationId: phoneUserSettings
export def "phone-users-settings get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<area_code: string, company_number: string, desk_phone: record<keys_positions: record<primary_number: string>>, outbound_caller: record<number: string>, outbound_caller_ids: record<is_default: bool, name: string, number: string>, voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/settings") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Remove shared access
#
# DELETE /phone/users/{userId}/settings/{settingType}
# operationId: deleteUserSetting
export def "phone-users-settings delete" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --shared-id: string # Required only for voicemail setting type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($setting_type | is-empty) { error make --unspanned { msg: "path parameter 'settingType' must be non-empty" } }
  let qp = [(serialize-qp "shared_id" $shared_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), setting_type: (encode-path-segment $setting_type)} | format pattern "/phone/users/{user_id}/settings/{setting_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"shared_id": $shared_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update shared access
#
# PATCH /phone/users/{userId}/settings/{settingType}
# operationId: updateUserSetting
# --voice_mail shape: {access_user_id?: string, delete?: bool, download?: bool, shared_id?: string}
export def "phone-users-settings update" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voice-mail: record # Update the voicemail setting. — shape: {access_user_id?: string, delete?: bool, download?: bool, shared_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($setting_type | is-empty) { error make --unspanned { msg: "path parameter 'settingType' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), setting_type: (encode-path-segment $setting_type)} | format pattern "/phone/users/{user_id}/settings/{setting_type}") $auth.query)
  let req_body = {"voice_mail": $voice_mail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Set up shared access
#
# POST /phone/users/{userId}/settings/{settingType}
# operationId: addUserSetting
# --voice_mail shape: {access_user_id?: string, delete?: bool, download?: bool}
export def "phone-users-settings create" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voice-mail: record # Update the voicemail setting. — shape: {access_user_id?: string, delete?: bool, download?: bool}
]: any -> record<voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($setting_type | is-empty) { error make --unspanned { msg: "path parameter 'settingType' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), setting_type: (encode-path-segment $setting_type)} | format pattern "/phone/users/{user_id}/settings/{setting_type}") $auth.query)
  let req_body = {"voice_mail": $voice_mail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get user's voicemails
#
# GET /phone/users/{userId}/voice_mails
# operationId: phoneUserVoiceMails
export def "phone-users-voice-mails get" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --status: string@status-completer-2 # Status of the voice mail (default: all)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --qp-from: string # Start date for the query in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the response includes only one month worth of voicemail data. The month defined should fall within the last six months. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record<from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int, voice_mails: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, download_url: string, duration: string, id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/phone/users/{user_id}/voice_mails") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "status": $status, "next_page_token": $next_page_token, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Delete a voicemail
#
# DELETE /phone/voice_mails/{voicemailId}
# operationId: deleteVoicemail
export def "phone-voice-mails delete-voicemail" [
  voicemail_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voicemail_id | is-empty) { error make --unspanned { msg: "path parameter 'voicemailId' must be non-empty" } }
  let full_url = (build-url $base ({voicemail_id: (encode-path-segment $voicemail_id)} | format pattern "/phone/voice_mails/{voicemail_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get sign In / sign out activity report
#
# GET /report/activities
# operationId: reportSignInSignOutActivities
export def "report-activities get-sign-in-sign-out" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date for which you would like to view the activity logs report. Using the `from` and `to` parameters, specify a monthly date range for the report as the API only provides one month worth of data in one request. The specified date range should fall within the last six months. (format: date)
  --qp-to: string # End date up to which you would like to view the activity logs report. (format: date)
  --page-size: int # The number of records to be returned within a single API call
  --next-page-token: string # Next page token is used to paginate through large result sets
]: nothing -> record<activity_logs: table<client_type: string, email: string, ip_address: string, time: string, type: string, version: string>, from: string, next_page_token: string, page_size: string, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/activities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get cloud recording usage report
#
# GET /report/cloud_recording
# operationId: reportCloudRecording
export def "report-cloud-recording get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
]: nothing -> record<from: string, to: string, cloud_recording_storage: table<date: string, free_usage: string, plan_usage: string, usage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/cloud_recording" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get daily usage report
#
# GET /report/daily
# operationId: reportDaily
export def "report-daily get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --year: int # Year for this report
  --month: int # Month for this report
]: nothing -> record<dates: table<date: string, meeting_minutes: int, meetings: int, new_users: int, participants: int>, month: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/daily" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "month": $month} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get meeting detail reports
#
# GET /report/meetings/{meetingId}
# operationId: reportMeetingDetails
export def "report-meetings get-details" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/report/meetings/{meeting_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get meeting participant reports
#
# GET /report/meetings/{meetingId}/participants
# operationId: reportMeetingParticipants
export def "report-meetings-participants get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide `registrant_id` as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [meeting registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingregistrants).
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, registrant_id: string, user_email: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/report/meetings/{meeting_id}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "include_fields": $include_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get meeting poll reports
#
# GET /report/meetings/{meetingId}/polls
# operationId: reportMeetingPolls
export def "report-meetings-polls get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/report/meetings/{meeting_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get operation logs report
#
# GET /report/operationlogs
# operationId: reportOperationLogs
export def "report-operationlogs logs-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --category-type: string@category-type-completer # **Optional** Filter your response by a category type to see reports for a specific category. The value for this field can be one of the following: `all``user``user_settings``account``billing``im``recording``phone_contacts``webinar``sub_account``role``zoom_rooms`
]: nothing -> record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "category_type" $category_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/operationlogs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token, "category_type": $category_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get telephone reports
#
# GET /report/telephone
# operationId: reportTelephone
export def "report-telephone get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-8 # Audio types:`1` - Toll-free Call-in & Call-out.`2` - Toll `3` - SIP Connected Audio (default: 1)
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/telephone" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "from": $qp_from, "to": $qp_to, "page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get active/inactive host reports
#
# GET /report/users
# operationId: reportUsers
export def "report-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-9 # Active or inactive hosts.`active` - Active hosts. `inactive` - Inactive hosts.
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/users" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "from": $qp_from, "to": $qp_to, "page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get meeting reports
#
# GET /report/users/{userId}/meetings
# operationId: reportMeetings
export def "report-users-meetings get" [
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
  --accept: string@accept-completer # Response content type
  --qp-from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (format: date)
  --qp-to: string # End date. (format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --type: string@type-completer-10 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings. (default: past)
]: nothing -> record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, from: string, meetings: table<custom_keys: list, duration: int, end_time: string, id: int, participants_count: int, source: string, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string>, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/report/users/{user_id}/meetings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "page_size": $page_size, "next_page_token": $next_page_token, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get webinar detail reports
#
# GET /report/webinars/{webinarId}
# operationId: reportWebinarDetails
export def "report-webinars get-details" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/report/webinars/{webinar_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get webinar participant reports
#
# GET /report/webinars/{webinarId}/participants
# operationId: reportWebinarParticipants
export def "report-webinars-participants get" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Enter 'registrant_id' as the value for this field if you would like to see the registrant ID attribute included in the response of this API call. A registrant ID is a unique identifier of a [webinar registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarregistrants).
]: nothing -> record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, user_email: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/report/webinars/{webinar_id}/participants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "include_fields": $include_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Get webinar poll reports
#
# GET /report/webinars/{webinarId}/polls
# operationId: reportWebinarPolls
export def "report-webinars-polls get" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/report/webinars/{webinar_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get webinar Q&A report
#
# GET /report/webinars/{webinarId}/qa
# operationId: reportWebinarQA
export def "report-webinars-qa get" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/report/webinars/{webinar_id}/qa") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List roles
#
# GET /roles
# operationId: roles
export def "roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a role
#
# POST /roles
# operationId: createRole
export def "roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description of the role.
  --name: string # Name of the role.
  --privileges: list<string> # Privileges assigned to the role. Can be one or a combination of [these permissions](https://marketplace.zoom.us/docs/api-reference/other-references/privileges).
]: any -> record<description: string, id: string, name: string, privileges: list<string>, total_members: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let req_body = {"description": $description, "name": $name, "privileges": $privileges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201 300]
}

# Delete a role
#
# DELETE /roles/{roleId}
# operationId: deleteRole
export def "roles delete" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Get role information
#
# GET /roles/{roleId}
# operationId: getRoleInformation
export def "roles get-information" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<description: string, id: string, name: string, privileges: list<string>, sub_account_privileges: record<second_level: int>, total_members: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Update role information
#
# PATCH /roles/{roleId}
# operationId: updateRole
# --sub_account_privileges shape: {second_level?: int}
export def "roles update" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description of the role.
  --id: string # Role Id.
  --name: string # Name of the role.
  --privileges: list<string> # Privileges assigned to the role. Can be one or a combination of [these permissions](https://marketplace.zoom.us/docs/api-reference/other-references/privileges).
  --sub-account-privileges: record # This field will only be displayed to accounts that are enrolled in the partner plan and follow master accounts and sub accounts structure. — shape: {second_level?: int}
  --total-members: int # Total members assigned to that role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}") $auth.query)
  let req_body = {"description": $description, "id": $id, "name": $name, "privileges": $privileges, "sub_account_privileges": $sub_account_privileges, "total_members": $total_members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# List members in a role
#
# GET /roles/{roleId}/members
# operationId: roleMembers
export def "roles-members get" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-count: string # The number of pages returned for this request.
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> record<members: list<record>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let qp = [(serialize-qp "page_count" $page_count "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}/members") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_count": $page_count, "page_number": $page_number, "next_page_token": $next_page_token, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign a role
#
# POST /roles/{roleId}/members
# operationId: AddRoleMembers
# --members item shape: {email?: string, id?: string}
export def "roles-members create" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # Array of userId/user email of users to whom you would like to assign this role. Upto 30 users can be assigned a role at once. — item shape: {email?: string, id?: string}
]: any -> record<add_at: string, ids: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}/members") $auth.query)
  let req_body = {"members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Unassign a role
#
# DELETE /roles/{roleId}/members/{memberId}
# operationId: roleMemberDelete
export def "roles-members delete" [
  role_id: string
  member_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id), member_id: (encode-path-segment $member_id)} | format pattern "/roles/{role_id}/members/{member_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List Zoom Rooms
#
# GET /rooms
# operationId: listZoomRooms
export def "rooms list-zoom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # The status of the Zoom Room.
  --type: string@type-completer-11 # Type of the Zoom Rooms.
  --unassigned-rooms: oneof<nothing, bool> # Use this query parameter with a value of `true` if you would like to see Zoom Rooms in your account that have not been assigned to anyone yet. (default: false)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --location-id: string # Parent location ID of the Zoom Room.
]: nothing -> record<next_page_token: string, page_size: int, rooms: table<activation_code: string, id: string, location_id: string, name: string, room_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "unassigned_rooms" $unassigned_rooms "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "type": $type, "unassigned_rooms": $unassigned_rooms, "page_size": $page_size, "next_page_token": $next_page_token, "location_id": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Zoom Room
#
# POST /rooms
# operationId: addARoom
export def "rooms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --location-id: string # **Optional**Location ID of the lowest level location in the [location hierarchy](https://support.zoom.us/hc/en-us/articles/115000342983-Zoom-Rooms-Location-Hierarchy) where the Zoom Room is to be added. For instance if the structure of the location hierarchy is set up as “country, states, city, campus, building, floor”, a room can only be added under the floor level location. This ID can be retrieved from the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
  name: string # Name of the Zoom Room.
  type: string@type-completer-11 # Type of the Zoom Room.
]: any -> record<id: string, location_id: string, name: string, room_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms" $auth.query)
  let req_body = {"location_id": $location_id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get Zoom Room account profile
#
# GET /rooms/account_profile
# operationId: getZRAccountProfile
export def "rooms-account-profile get-zr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<basic: record<required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/account_profile" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Zoom Room account profile
#
# PATCH /rooms/account_profile
# operationId: updateZRAccProfile
# --basic shape: {required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
export def "rooms-account-profile update-zr-acc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/account_profile" $auth.query)
  let req_body = {"basic": $basic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Zoom Room account settings
#
# GET /rooms/account_settings
# operationId: getZRAccountSettings
export def "rooms-account-settings get-zr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string@setting-type-completer # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: View digital signage settings of the Zoom Rooms Account. (default: meeting)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms/account_settings" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Zoom Room account settings
#
# PATCH /rooms/account_settings
# operationId: updateZoomRoomAccSettings
# --zoom_rooms shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, email_address_prompt_before_recording?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, make_room_alternative_host?: bool, secure_connection_channel?: bool, ... (10 more fields)}
# --client_alert shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
# --digital_signage shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
# --notification shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_stable_detected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, ... (4 more fields)}
export def "rooms-account-settings update-zoom-acc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: View digital signage settings of the Zoom Rooms Account. (default: meeting)
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, email_address_prompt_before_recording?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, make_room_alternative_host?: bool, secure_connection_channel?: bool, ... (10 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_stable_detected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, ... (4 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms/account_settings" $qp $auth.query)
  let req_body = {"zoom_rooms": $zoom_rooms, "client_alert": $client_alert, "digital_signage": $digital_signage, "notification": $notification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List digital signage contents
#
# GET /rooms/digital_signage
# operationId: listDigitalSignageContent
export def "rooms-digital-signage list-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # Specify the type of digital signane resource. The value can be one of the following: * `content`: Returns information about content files. * `folder`: Returns information about the folder where the content files are located.
  --folder-id: string # Unique identifier of the folder where the content is located. Provide this field if you would like to filter the response by contents that are only available in a specific folder.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<contents: table<id: string, name: string>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "folder_id" $folder_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms/digital_signage" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "folder_id": $folder_id, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update E911 digital signage
#
# PATCH /rooms/events
# operationId: manageE911signage
# --params shape: {content?: string, target_ids?: list<string>, target_type?: "account"|"location"|"room"}
export def "rooms-events update-manage-e911signage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --method: string@method-completer # To display the emergency content on the Zoom Rooms digital signage display, set the value of this field to be `zoomroom.emergency_alert_displayed`.
  --params: record # shape: {content?: string, target_ids?: list<string>, target_type?: "account"|"location"|"room"}
]: any -> record<event_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/events" $auth.query)
  let req_body = {"method": $method, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# List Zoom Room locations
#
# GET /rooms/locations
# operationId: listZRLocations
export def "rooms-locations list-zr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --parent-location-id: string # A unique identifier of the parent location. For instance, if a Zoom Room is located in Floor 1 of Building A, the location of Building A will be the parent location of Floor 1. Use this parameter to filter the response by a specific location hierarchy level.
  --type: string # Use this field to filter the response by the type of location. The value can be one of the following: `country`, `states`, `city`, `campus`, `building`, `floor`.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<locations: table<id: string, name: string, parent_location_id: string, type: string>, next_page_token: string, page_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_location_id" $parent_location_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms/locations" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parent_location_id": $parent_location_id, "type": $type, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a location
#
# POST /rooms/locations
# operationId: addAZRLocation
export def "rooms-locations create-azr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the location. The name must be unique and shouldn't have already been used in the same account.
  --parent-location-id: string # The location ID of the location that is a level higher from the location that is being added. For example, to add a City named "City 1" as the child location under a State named "State 1", you must provide the location ID of "State 1". This can be retrieved using the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> record<id: string, name: string, parent_location_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/locations" $auth.query)
  let req_body = {"name": $name, "parent_location_id": $parent_location_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Zoom Room location structure
#
# GET /rooms/locations/structure
# operationId: getZRLocationStructure
export def "rooms-locations-structure get-zr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<structures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/locations/structure" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Zoom Rooms location structure
#
# PATCH /rooms/locations/structure
# operationId: updateZoomRoomsLocationStructure
export def "rooms-locations-structure update-zoom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --structures: list<string> # Location Structure. The value can be either one or a combination of the following strings separated by comma: `country`, `state`, `city`, `campus`, `building`, `floor`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms/locations/structure" $auth.query)
  let req_body = {"structures": $structures} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Zoom Room location profile
#
# GET /rooms/locations/{locationId}
# operationId: getZRLocationProfile
export def "rooms-locations get-zr-profile" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<basic: record<address: string, description_: string, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string, timezone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/rooms/locations/{location_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Zoom Room location profile
#
# PATCH /rooms/locations/{locationId}
# operationId: updateZRLocationProfile
# --basic shape: {address?: string, description ?: string, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string, timezone?: string}
export def "rooms-locations update-zr-profile" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {address?: string, description ?: string, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string, timezone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/rooms/locations/{location_id}") $auth.query)
  let req_body = {"basic": $basic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Change the assigned parent location
#
# PUT /rooms/locations/{locationId}/location
# operationId: changeParentLocation
export def "rooms-locations-location update-change-parent" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --parent-location-id: string # Location ID of the new Parent Location under which you the child location will be positioned. This can be retrieved from the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/rooms/locations/{location_id}/location") $auth.query)
  let req_body = {"parent_location_id": $parent_location_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get location settings
#
# GET /rooms/locations/{locationId}/settings
# operationId: getZRLocationSettings
export def "rooms-locations-settings get-zr" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: Digital signage settings of the Zoom Rooms Account. (default: meeting)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/rooms/locations/{location_id}/settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update location settings
#
# PATCH /rooms/locations/{locationId}/settings
# operationId: updateZRLocationSettings
# --meeting_security shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
# --zoom_rooms shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_accept_incoming_call_and_fecc?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_self_view?: bool, lock_speaker_volume_control?: bool, ... (13 more fields)}
# --client_alert shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
# --digital_signage shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
# --notification shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
export def "rooms-locations-settings update-zr" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: Digital signage settings. (default: meeting)
  --meeting-security: record # shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_accept_incoming_call_and_fecc?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_self_view?: bool, lock_speaker_volume_control?: bool, ... (13 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/rooms/locations/{location_id}/settings") $qp $auth.query)
  let req_body = {"meeting_security": $meeting_security, "zoom_rooms": $zoom_rooms, "client_alert": $client_alert, "digital_signage": $digital_signage, "notification": $notification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Check-in or check-out of a Zoom Room
#
# PATCH /rooms/{id}/events
# operationId: checkInRooms
# --params shape: {calendar_id?: string, change_key?: string, event_id: string, resource_email?: string}
export def "rooms-events check" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --method: string # The value of this field can be one of the following: * zoomroom.check_in * zoomroom.check_out
  --params: record # shape: {calendar_id?: string, change_key?: string, event_id: string, resource_email?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rooms/{id}/events") $auth.query)
  let req_body = {"method": $method, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Zoom Room
#
# DELETE /rooms/{roomId}
# operationId: deleteAZoomRoom
export def "rooms delete-zoom" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Zoom Room profile
#
# GET /rooms/{roomId}
# operationId: getZRProfile
export def "rooms get-zr-profile" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<basic: record<activation_code: string, hide_room_in_contacts: bool, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Zoom Room profile
#
# PATCH /rooms/{roomId}
# operationId: updateRoomProfile
# --basic shape: {hide_room_in_contacts?: bool, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
export def "rooms update-profile" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {hide_room_in_contacts?: bool, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}") $auth.query)
  let req_body = {"basic": $basic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Zoom Room devices
#
# GET /rooms/{roomId}/devices
# operationId: listZRDevices
export def "rooms-devices list-zr" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<devices: table<app_version: string, device_system: string, device_type: string, id: string, room_name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/devices") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change Zoom Rooms' app version
#
# PUT /rooms/{roomId}/devices/{deviceId}/app_version
# operationId: changeZoomRoomsAppVersion
export def "rooms-devices-app-version version-change-zoom" [
  room_id: string
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
  --accept: string@accept-completer # Response content type
  --action: string@action-completer-8 # Specify one of the following values for this field: `upgrade`: Upgrade to the latest Zoom Rooms App Version. `downgrade`: Downgrade the Zoom Rooms App Version. `cancel`: Cancel an ongoing upgrade or downgrade process.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id), device_id: (encode-path-segment $device_id)} | format pattern "/rooms/{room_id}/devices/{device_id}/app_version") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change a Zoom Room's location
#
# PUT /rooms/{roomId}/location
# operationId: changeZRLocation
export def "rooms-location update-change-zr" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --location-id: string # Location ID of the location where Zoom Room is to be assigned. This can be retrieved from the `id` property in the response of [List Zoom Rooms Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/location") $auth.query)
  let req_body = {"location_id": $location_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Zoom Room settings
#
# GET /rooms/{roomId}/settings
# operationId: getZRSettings
export def "rooms-settings get-zr" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. (default: meeting)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Zoom Room settings
#
# PATCH /rooms/{roomId}/settings
# operationId: updateZRSettings
# --meeting_security shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
# --zoom_rooms shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_share_instruction?: bool, send_whiteboard_to_internal_contact_only?: bool, show_alert_before_meeting?: bool, ... (9 more fields)}
# --client_alert shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
# --digital_signage shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
# --notification shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
export def "rooms-settings update-zr" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Room. `meeting`: Meeting settings of the Zoom Room. `signage`: Digital signage settings applied on the Zoom Room.
  --meeting-security: record # shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_share_instruction?: bool, send_whiteboard_to_internal_contact_only?: bool, show_alert_before_meeting?: bool, ... (9 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let qp = [(serialize-qp "setting_type" $setting_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/settings") $qp $auth.query)
  let req_body = {"meeting_security": $meeting_security, "zoom_rooms": $zoom_rooms, "client_alert": $client_alert, "digital_signage": $digital_signage, "notification": $notification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"setting_type": $setting_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List SIP phones
#
# GET /sip_phones
# operationId: listSipPhones
export def "sip-phones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --search-key: string # User name or email address of a user. If this parameter is provided, only the SIP phone system integration enabled for that specific user will be returned. Otherwise, all SIP phones on an account will be returned.
  --page-size: int # The number of records returned within a single API call.
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_number: int, page_size: int, phones: table<authorization_name: string, domain: string, id: string, password: string, proxy_server: string, proxy_server2: string, proxy_server3: string, register_server: string, register_server2: string, register_server3: string, registration_expire_time: int, transport_protocol: string, transport_protocol2: string, transport_protocol3: string, user_email: string, user_name: string, voice_mail: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_number" $page_number "scalar") (serialize-qp "search_key" $search_key "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sip_phones" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_number": $page_number, "search_key": $search_key, "page_size": $page_size, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Enable SIP phone
#
# POST /sip_phones
# operationId: createSIPPhone
export def "sip-phones create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authorization_name: string # Authorization name of the user registered for SIP Phone.
  domain: string # The name or IP address of your provider’s SIP domain. (example: CDC.WEB).
  password: string # The password generated for the user in the SIP account.
  proxy_server: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  --proxy-server2: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server, or empty.
  --proxy-server3: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server, or empty.
  register_server: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --register-server2: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --register-server3: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --registration-expire-time: int # The number of minutes after which the SIP registration of the Zoom client user will expire, and the client will auto register to the SIP server. (default: 60)
  --transport-protocol: string@transport-protocol-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol2: string@transport-protocol2-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol3: string@transport-protocol3-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  user_email: string # The email address of the user to associate with the SIP Phone. Can add [.win, .mac, .android, .ipad, .iphone, .linux, .pc, .mobile, .pad] at the end of the email (ex. user@test.com.mac) to add accounts for different platforms for the same user. (format: email)
  user_name: string # The phone number associated with the user in the SIP account.
  voice_mail: string # The number to dial for checking voicemail.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sip_phones" $auth.query)
  let req_body = {"authorization_name": $authorization_name, "domain": $domain, "password": $password, "proxy_server": $proxy_server, "proxy_server2": $proxy_server2, "proxy_server3": $proxy_server3, "register_server": $register_server, "register_server2": $register_server2, "register_server3": $register_server3, "registration_expire_time": $registration_expire_time, "transport_protocol": $transport_protocol, "transport_protocol2": $transport_protocol2, "transport_protocol3": $transport_protocol3, "user_email": $user_email, "user_name": $user_name, "voice_mail": $voice_mail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete SIP phone
#
# DELETE /sip_phones/{phoneId}
# operationId: deleteSIPPhone
export def "sip-phones delete" [
  phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneId' must be non-empty" } }
  let full_url = (build-url $base ({phone_id: (encode-path-segment $phone_id)} | format pattern "/sip_phones/{phone_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Update SIP phone
#
# PATCH /sip_phones/{phoneId}
# operationId: updateSIPPhone
export def "sip-phones update" [
  phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_name: string # Authorization name of the user registered for SIP Phone.
  domain: string # The name or IP address of your provider’s SIP domain. (example: CDC.WEB).
  password: string # The password generated for the user in the SIP account.
  proxy_server: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  proxy_server2: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  proxy_server3: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  register_server: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  register_server2: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  register_server3: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --registration-expire-time: int # The number of minutes after which the SIP registration of the Zoom client user will expire, and the client will auto register to the SIP server. (default: 60)
  --transport-protocol: string@transport-protocol-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol2: string@transport-protocol2-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol3: string@transport-protocol3-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  user_name: string # The phone number associated with the user in the SIP account.
  voice_mail: string # The number to dial for checking voicemail.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneId' must be non-empty" } }
  let full_url = (build-url $base ({phone_id: (encode-path-segment $phone_id)} | format pattern "/sip_phones/{phone_id}") $auth.query)
  let req_body = {"authorization_name": $authorization_name, "domain": $domain, "password": $password, "proxy_server": $proxy_server, "proxy_server2": $proxy_server2, "proxy_server3": $proxy_server3, "register_server": $register_server, "register_server2": $register_server2, "register_server3": $register_server3, "registration_expire_time": $registration_expire_time, "transport_protocol": $transport_protocol, "transport_protocol2": $transport_protocol2, "transport_protocol3": $transport_protocol3, "user_name": $user_name, "voice_mail": $voice_mail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# List SIP trunk numbers
#
# GET /sip_trunk/numbers
# operationId: listSipTrunkNumbers
export def "sip-trunk-numbers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<phone_numbers: table<country: string, number: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sip_trunk/numbers" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List tracking fields
#
# GET /tracking_fields
# operationId: trackingfieldList
export def "tracking-fields list-trackingfield" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_fields" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a tracking field
#
# POST /tracking_fields
# operationId: trackingfieldCreate
export def "tracking-fields create-trackingfield" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --field: string # Label/ Name for the tracking field.
  --recommended-values: list<string> # Array of recommended values
  --required: oneof<nothing, bool> # Tracking Field Required
  --visible: oneof<nothing, bool> # Tracking Field Visible
]: any -> record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_fields" $auth.query)
  let req_body = {"field": $field, "recommended_values": $recommended_values, "required": $required, "visible": $visible} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a tracking field
#
# DELETE /tracking_fields/{fieldId}
# operationId: trackingfieldDelete
export def "tracking-fields delete-trackingfield" [
  field_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'fieldId' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/tracking_fields/{field_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a tracking field
#
# GET /tracking_fields/{fieldId}
# operationId: trackingfieldGet
export def "tracking-fields get-trackingfield" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'fieldId' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/tracking_fields/{field_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a tracking field
#
# PATCH /tracking_fields/{fieldId}
# operationId: trackingfieldUpdate
export def "tracking-fields update-trackingfield" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field: string # Label/ Name for the tracking field.
  --recommended-values: list<string> # Array of recommended values
  --required: oneof<nothing, bool> # Tracking Field Required
  --visible: oneof<nothing, bool> # Tracking Field Visible
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'fieldId' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/tracking_fields/{field_id}") $auth.query)
  let req_body = {"field": $field, "recommended_values": $recommended_values, "required": $required, "visible": $visible} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get account's TSP information
#
# GET /tsp
# operationId: tsp
export def "tsp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<dial_in_number_unrestricted: bool, dial_in_numbers: table<code: string, number: string, type: string>, enable: bool, master_account_setting_extended: bool, modify_credential_forbidden: bool, tsp_bridge: string, tsp_enabled: bool, tsp_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsp" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update account's TSP information
#
# PATCH /tsp
# operationId: tspUpdate
export def "tsp update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dial-in-number-unrestricted: oneof<nothing, bool> # Control restriction on account users adding a TSP number outside of account's dial in numbers.
  --enable: oneof<nothing, bool> # Enable 3rd party audio conferencing for account users
  --master-account-setting-extended: oneof<nothing, bool> # For master account, extend its TSP setting to all sub accounts. For sub account, extend TSP setting from master account.
  --modify-credential-forbidden: oneof<nothing, bool> # Control restriction on account users being able to modify their TSP credentials.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
  --tsp-enabled: oneof<nothing, bool> # Enable TSP feature for account. This has to be enabled to use any other tsp settings/features.
  --tsp-provider: string # 3rd party audio conferencing provider
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsp" $auth.query)
  let req_body = {"dial_in_number_unrestricted": $dial_in_number_unrestricted, "enable": $enable, "master_account_setting_extended": $master_account_setting_extended, "modify_credential_forbidden": $modify_credential_forbidden, "tsp_bridge": $tsp_bridge, "tsp_enabled": $tsp_enabled, "tsp_provider": $tsp_provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List users
#
# GET /users
# operationId: users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-4 # User statuses:`active` - Users with an active status.`inactive` - Users who are deactivated.`pending` - Users with a pending status. (default: active)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --role-id: string # Unique identifier of the role. Provide this parameter if you would like to filter the response by a specific role. You can retrieve Role IDs from [List Roles](https://marketplace.zoom.us/docs/api-reference/zoom-api/roles/roles) API.
  --page-number: string # The page number of the current page in the returned records.
  --include-fields: string # Provide a value for this field if you would like to see the following attribute in the response of this API call: `custom_attributes`: Returns custom attributes that are associated with the user.`host_key`: Returns [host key](https://support.zoom.us/hc/en-us/articles/205172555-Using-your-host-key) of the user.
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, users: table<created_at: string, custom_attributes: list, dept: string, email: string, first_name: string, group_ids: list, host_key: string, id: string, im_group_ids: list, last_client_version: string, last_login_time: string, last_name: string, plan_united_type: string, pmi: int, role_id: string, status: string, timezone: string, type: int, verified: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "page_size": $page_size, "role_id": $role_id, "page_number": $page_number, "include_fields": $include_fields, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create users
#
# POST /users
# operationId: userCreate
# --user_info shape: {email: string, first_name?: string, last_name?: string, password?: string, type: "1"|"2"|"3"|"99"}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  action: string@action-completer-9 # Specify how to create the new user: `create` - User will get an email sent from Zoom. There is a confirmation link in this email. The user will then need to use the link to activate their Zoom account. The user can then set or change their password.`autoCreate` - This action is provided for the enterprise customer who has a managed domain. This feature is disabled by default because of the security risk involved in creating a user who does not belong to your domain.`custCreate` - Users created via this option do not have passwords and will not have the ability to log into the Zoom Web Portal or the Zoom Client. These users can still host and join meetings using the `start_url` and `join_url` respectively. To use this option, you must contact the ISV Platform Sales team at isv@zoom.us.`ssoCreate` - This action is provided for the enabled “Pre-provisioning SSO User” option. A user created in this way has no password. If not a basic user, a personal vanity URL using the user name (no domain) of the provisioning email will be generated. If the user name or PMI is invalid or occupied, it will use a random number or random personal vanity URL.
  --user-info: record # shape: {email: string, first_name?: string, last_name?: string, password?: string, type: "1"|"2"|"3"|"99"}
]: any -> record<email: string, first_name: string, id: string, last_name: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let req_body = {"action": $action, "user_info": $user_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Check a user email
#
# GET /users/email
# operationId: userEmail
export def "users-email get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address to be verified.
]: nothing -> record<existed_email: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/email" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get user's ZAK
#
# GET /users/me/zak
# operationId: userZak
export def "users-me-zak get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/zak" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check a user's PM room
#
# GET /users/vanity_name
# operationId: userVanityName
export def "users-vanity-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --vanity-name: string # Personal meeting room name.
]: nothing -> record<existed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vanity_name" $vanity_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/vanity_name" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vanity_name": $vanity_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a user
#
# DELETE /users/{userId}
# operationId: userDelete
export def "users delete" [
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
  --action: string@action-completer-10 # Delete action options:`disassociate` - Disassociate a user.`delete`- Permanently delete a user.Note: To delete pending user in the account, use `disassociate` (default: disassociate)
  --transfer-email: string # Transfer email.
  --transfer-meeting: oneof<nothing, bool> # Transfer meeting.
  --transfer-webinar: oneof<nothing, bool> # Transfer webinar.
  --transfer-recording: oneof<nothing, bool> # Transfer recording.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "transfer_email" $transfer_email "scalar") (serialize-qp "transfer_meeting" $transfer_meeting "scalar") (serialize-qp "transfer_webinar" $transfer_webinar "scalar") (serialize-qp "transfer_recording" $transfer_recording "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"action": $action, "transfer_email": $transfer_email, "transfer_meeting": $transfer_meeting, "transfer_webinar": $transfer_webinar, "transfer_recording": $transfer_recording} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a user
#
# GET /users/{userId}
# operationId: user
export def "users get" [
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
  --accept: string@accept-completer # Response content type
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
]: nothing -> record<id: string, created_at: string, dept: string, email: string, first_name: string, last_client_version: string, last_login_time: string, last_name: string, pmi: int, role_name: string, timezone: string, type: int, use_pmi: bool, account_id: string, cms_user_id: string, company: string, custom_attributes: record<key: string, name: string, value: string>, group_ids: list<string>, host_key: string, im_group_ids: list<string>, jid: string, job_title: string, language: string, location: string, login_type: int, manager: string, personal_meeting_url: string, phone_country: string, phone_number: string, phone_numbers: record<code: string, country: string, number: string, verified: bool>, pic_url: string, plan_united_type: string, role_id: string, status: string, vanity_url: string, verified: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "login_type" $login_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"login_type": $login_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a user
#
# PATCH /users/{userId}
# operationId: userUpdate
# --custom_attributes shape: {key?: string, name?: string, value?: string}
# --phone_numbers shape: {code?: string, country?: string, number?: string}
export def "users update" [
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
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
  --cms-user-id: string # Kaltura user ID.
  --company: string # User's company.
  --custom-attributes: record # Custom attribute(s) of the user. — shape: {key?: string, name?: string, value?: string}
  --dept: string # Department for user profile: use for report.
  --first-name: string # User's first name. Cannot contain more than 5 Chinese characters.
  --group-id: string # Provide unique identifier of the group that you would like to add a [pending user](https://support.zoom.us/hc/en-us/articles/201363183-Managing-users#h_13c87a2a-ecd6-40ad-be61-a9935e660edb) to. The value of this field can be retrieved from [List Groups](https://marketplace.zoom.us/docs/api-reference/zoom-api/groups/groups) API.
  --host-key: string # Host key. It should be a 6-10 digit number.
  --job-title: string # User's job title.
  --language: string # language
  --last-name: string # User's last name. Cannot contain more than 5 Chinese characters.
  --location: string # User's location.
  --manager: string # The manager for the user. (format: email)
  --phone-country: string # **Note:** This field has been **deprecated** and will not be supported in the future. Use the **country** field of the **phone_numbers** object instead to select the country for the phone number. [Country ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) of the phone number. For example, if the phone number provided in the `phone_number` field is a Brazil based number, the value of the `phone_country` field should be `BR`.
  --phone-number: string # **Note:** This field has been **deprecated** and will not be supported in the future. Use the **phone_numbers** field instead to assign phone number(s) to a user. Phone number of the user. To update a phone number, you must also provide the `phone_country` field.
  --phone-numbers: record # shape: {code?: string, country?: string, number?: string}
  --pmi: int # Personal meeting ID: length must be 10.
  --timezone: string # The time zone ID for a user profile. For this parameter value please refer to the ID value in the [timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list.
  --type: int@type-completer-12 # User types:`1` - Basic.`2` - Licensed.`3` - On-prem.`99` - None (this can only be set with `ssoCreate`).
  --use-pmi: oneof<nothing, bool> # Use Personal Meeting ID for instant meetings. (default: false)
  --vanity-name: string # Personal meeting room name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "login_type" $login_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp $auth.query)
  let req_body = {"cms_user_id": $cms_user_id, "company": $company, "custom_attributes": $custom_attributes, "dept": $dept, "first_name": $first_name, "group_id": $group_id, "host_key": $host_key, "job_title": $job_title, "language": $language, "last_name": $last_name, "location": $location, "manager": $manager, "phone_country": $phone_country, "phone_number": $phone_number, "phone_numbers": $phone_numbers, "pmi": $pmi, "timezone": $timezone, "type": $type, "use_pmi": $use_pmi, "vanity_name": $vanity_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"login_type": $login_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete user assistants
#
# DELETE /users/{userId}/assistants
# operationId: userAssistantsDelete
export def "users-assistants delete-by-user-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/assistants") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List user assistants
#
# GET /users/{userId}/assistants
# operationId: userAssistants
export def "users-assistants get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<assistants: table<email: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/assistants") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add assistants
#
# POST /users/{userId}/assistants
# operationId: userAssistantCreate
# --assistants item shape: {email?: string, id?: string}
export def "users-assistants create" [
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
  --accept: string@accept-completer # Response content type
  --assistants: list # List of User's assistants. — item shape: {email?: string, id?: string}
]: any -> record<add_at: string, ids: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/assistants") $auth.query)
  let req_body = {"assistants": $assistants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a user assistant
#
# DELETE /users/{userId}/assistants/{assistantId}
# operationId: userAssistantDelete
export def "users-assistants delete-by-user-id-assistant-id" [
  user_id: string
  assistant_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($assistant_id | is-empty) { error make --unspanned { msg: "path parameter 'assistantId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), assistant_id: (encode-path-segment $assistant_id)} | format pattern "/users/{user_id}/assistants/{assistant_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update a user's email
#
# PUT /users/{userId}/email
# operationId: userEmailUpdate
export def "users-email update" [
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
  email: string # User’s email. The length should be less than 128 characters. (format: email)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/email") $auth.query)
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List meeting templates
#
# GET /users/{userId}/meeting_templates
# operationId: listMeetingTemplates
export def "users-meeting-templates list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<templates: table<id: string, name: string, type: int>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/meeting_templates") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List meetings
#
# GET /users/{userId}/meetings
# operationId: meetings
export def "users-meetings get" [
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
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-13 # The meeting types: `scheduled` - This includes all valid past meetings (unexpired), live meetings and upcoming scheduled meetings. It is equivalent to the combined list of "Previous Meetings" and "Upcoming Meetings" displayed in the user's [Meetings page](https://zoom.us/meeting) on the Zoom Web Portal.`live` - All the ongoing meetings.`upcoming` - All upcoming meetings including live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-number: string # The page number of the current page in the returned records.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_number" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/meetings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "page_size": $page_size, "next_page_token": $next_page_token, "page_number": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a meeting
#
# POST /users/{userId}/meetings
# operationId: meetingCreate
# --recurrence shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
# --settings shape: {additional_data_center_regions?: list<string>, allow_multiple_devices?: bool, alternative_hosts?: string, alternative_hosts_email_notification?: bool, approval_type?: "0"|"1"|"2", approved_or_denied_countries_or_regions?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", breakout_room?: record, close_registration?: bool, cn_meeting?: bool, contact_email?: string, contact_name?: string, ... (16 more fields)}
# --tracking_fields item shape: {field: string, value?: string}
export def "users-meetings create" [
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
  --accept: string@accept-completer # Response content type
  --agenda: string # Meeting description.
  --duration: int # Meeting duration (minutes). Used for scheduled meetings only.
  --password: string # Passcode to join the meeting. By default, passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ *] and can have a maximum of 10 characters. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recurrence: record # Recurrence object. Use this object only for a meeting with type `8` i.e., a recurring meeting with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
  --schedule-for: string # If you would like to schedule this meeting for someone else in your account, provide the Zoom user id or email address of the user here.
  --settings: record # Meeting settings. — shape: {additional_data_center_regions?: list<string>, allow_multiple_devices?: bool, alternative_hosts?: string, alternative_hosts_email_notification?: bool, approval_type?: "0"|"1"|"2", approved_or_denied_countries_or_regions?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", breakout_room?: record, close_registration?: bool, cn_meeting?: bool, contact_email?: string, contact_name?: string, ... (16 more fields)}
  --start-time: string # Meeting start time. We support two formats for `start_time` - local time and GMT. To set time as GMT the format should be `yyyy-MM-dd`T`HH:mm:ssZ`. Example: "2020-03-31T12:02:00Z" To set time using a specific timezone, use `yyyy-MM-dd`T`HH:mm:ss` format and specify the timezone [ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) in the `timezone` field OR leave it blank and the timezone set on your Zoom account will be used. You can also set the time as UTC as the timezone field. The `start_time` should only be used for scheduled and / or recurring webinars with fixed time. (format: date-time)
  --template-id: string # Unique identifier of the **admin meeting template**. To create admin meeting templates, contact the Zoom support team. Use this field if you would like to [schedule the meeting from a admin meeting template](https://support.zoom.us/hc/en-us/articles/360036559151-Meeting-templates#h_86f06cff-0852-4998-81c5-c83663c176fb). You can retrieve the value of this field by calling the [List meeting templates](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/listmeetingtemplates) API.
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [time zone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list for supported time zones and their formats.
  --topic: string # Meeting topic.
  --tracking-fields: list # Tracking fields — item shape: {field: string, value?: string}
  --type: int@type-completer-14 # Meeting Type:`1` - Instant meeting.`2` - Scheduled meeting.`3` - Recurring meeting with no fixed time.`8` - Recurring meeting with fixed time. (default: 2)
]: any -> record<assistant_id: string, host_email: string, id: int, registration_url: string, agenda: string, created_at: string, duration: int, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/meetings") $auth.query)
  let req_body = {"agenda": $agenda, "duration": $duration, "password": $password, "recurrence": $recurrence, "schedule_for": $schedule_for, "settings": $settings, "start_time": $start_time, "template_id": $template_id, "timezone": $timezone, "topic": $topic, "tracking_fields": $tracking_fields, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201 300]
}

# List a user's PAC accounts
#
# GET /users/{userId}/pac
# operationId: userPACs
export def "users-pac get-pa-cs" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<pac_accounts: table<conference_id: int, dedicated_dial_in_number: list, global_dial_in_numbers: list, listen_only_password: string, participant_password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/pac") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a user's password
#
# PUT /users/{userId}/password
# operationId: userPassword
export def "users-password update" [
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
  password: string # User password. Should be less than 32 characters. **Note:** If the account owner or admin has enabled [enhanced password requirements](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_fa9186e4-6818-4f7a-915c-2e25c19f0acd), the value provided in this field must meet those requirements. These requirements can be retrieved by calling the [Get Account Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) and referring to the `password_requirement` field present in the `security` object.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/password") $auth.query)
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get user permissions
#
# GET /users/{userId}/permissions
# operationId: userPermission
export def "users-permissions get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/permissions") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Upload a user's profile picture
#
# POST /users/{userId}/picture
# operationId: userPicture
export def "users-picture create" [
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
  pic_file: string # The file's path. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/picture") $auth.query)
  let req_body = {"pic_file": $pic_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["pic_file"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Update a user's presence status
#
# PUT /users/{userId}/presence_status
# operationId: updatePresenceStatus
export def "users-presence-status update" [
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
  --accept: string@accept-completer # Response content type
  --duration: int # If you're updating the status to `Do_Not_Disturb`, specify a duration in minutes for which the status should remain as `Do_Not_Disturb`. The default value is 20 minutes and the maximum allowed value is 1440 minutes.
  --status: string@status-completer-5 # Presence status of the user. The value can be set to one of the following: * `Away` * `Do_Not_Disturb` * `Available` Users who are on Zoom Client with a version **lower than 5.3.0** can update the status from: * `Away` to `Do_Not_Disturb` * `Available` to `Do-Not_Disturb` Users who are on **Zoom Client 5.3.0** or higher can update the status from: * `Do_Not_Disturb` to `Away` * `Do_Not_Disturb` to `Available` * `Available` to `Away` * `Away` to `Available`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/presence_status") $auth.query)
  let req_body = {"duration": $duration, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List all recordings
#
# GET /users/{userId}/recordings
# operationId: recordingsList
export def "users-recordings list" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --mc: string # Query Metadata of Recording if an On-Premise Meeting Connector was used for the meeting. (default: false)
  --trash: oneof<nothing, bool> # Query trash. `true`: List recordings from trash. `false`: Do not list recordings from the trash. The default value is `false`. If you set it to `true`, you can use the `trash_type` property to indicate the type of Cloud recording that you need to retrieve. (default: false)
  --qp-from: string # The start date in 'yyyy-mm-dd' UTC format for the date range for which you would like to retrieve recordings. The maximum range can be a month. If no value is provided for this field, the default will be current date. For example, if you make the API request on June 30, 2020, without providing the “from” and “to” parameters, by default the value of 'from' field will be “2020-06-30” and the value of the 'to' field will be “2020-07-01”. **Note**: The "trash" files cannot be filtered by date range and thus, the "from" and "to" fields should not be used for trash files. (format: date)
  --qp-to: string # End date in 'yyyy-mm-dd' 'yyyy-mm-dd' UTC format. (format: date)
  --trash-type: string # The type of Cloud recording that you would like to retrieve from the trash. The value can be one of the following: `meeting_recordings`: List all meeting recordings from the trash. `recording_file`: List all individual recording files from the trash. (default: meeting_recordings)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "mc" $mc "scalar") (serialize-qp "trash" $trash "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "trash_type" $trash_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/recordings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "next_page_token": $next_page_token, "mc": $mc, "trash": $trash, "from": $qp_from, "to": $qp_to, "trash_type": $trash_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete user schedulers
#
# DELETE /users/{userId}/schedulers
# operationId: userSchedulersDelete
export def "users-schedulers delete-by-user-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/schedulers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List user schedulers
#
# GET /users/{userId}/schedulers
# operationId: userSchedulers
export def "users-schedulers get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<schedulers: table<email: string, id: string, pmi: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/schedulers") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a scheduler
#
# DELETE /users/{userId}/schedulers/{schedulerId}
# operationId: userSchedulerDelete
export def "users-schedulers delete-by-user-id-scheduler-id" [
  user_id: string
  scheduler_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($scheduler_id | is-empty) { error make --unspanned { msg: "path parameter 'schedulerId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), scheduler_id: (encode-path-segment $scheduler_id)} | format pattern "/users/{user_id}/schedulers/{scheduler_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get user settings
#
# GET /users/{userId}/settings
# operationId: userSettings
export def "users-settings get" [
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
  --accept: string@accept-completer # Response content type
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the user's account.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the user's account. `meeting_security`: Use this query parameter to view meeting security settings applied on the user's account. (allows empty value)
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "login_type" $login_type "scalar") (serialize-qp "option" $option "scalar") (serialize-qp "custom_query_fields" $custom_query_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/settings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"login_type": $login_type, "option": $option, "custom_query_fields": $custom_query_fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update user settings
#
# PATCH /users/{userId}/settings
# operationId: userSettingsUpdate
# --email_notification shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, jbh_reminder?: bool, schedule_for_reminder?: bool}
# --feature shape: {large_meeting?: bool, large_meeting_capacity?: int, meeting_capacity?: int, webinar?: bool, webinar_capacity?: int, zoom_phone?: bool}
# --in_meeting shape: {allow_live_streaming?: bool, annotation?: bool, attendee_on_hold?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA"|"DE"|"NL"|"LA", e2e_encryption?: bool, entry_exit_chime?: "host"|"all"|"none", far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, ... (17 more fields)}
# --profile shape: {recording_storage_location?: record}
# --recording shape: {ask_host_to_confirm_disclaimer?: bool, ask_participants_to_consent_disclaimer?: bool, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, host_pause_stop_recording?: bool, ip_address_access_control?: record, local_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, recording_disclaimer?: bool, recording_password_requirement?: record, ... (2 more fields)}
# --schedule_meeting shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", default_password_for_scheduled_meetings?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, participants_video?: bool, personal_meeting?: bool, pmi_password?: string, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", ... (4 more fields)}
# --telephony shape: {audio_conference_info?: string, show_international_numbers_link?: bool, telephony_regions?: record, third_party_audio?: bool}
# --tsp shape: {call_out?: bool, call_out_countries?: list, show_international_numbers_link?: bool}
# --meeting_security shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
export def "users-settings update" [
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
  --option: string@option-completer-3 # allows empty value
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, jbh_reminder?: bool, schedule_for_reminder?: bool}
  --feature: record # shape: {large_meeting?: bool, large_meeting_capacity?: int, meeting_capacity?: int, webinar?: bool, webinar_capacity?: int, zoom_phone?: bool}
  --in-meeting: record # shape: {allow_live_streaming?: bool, annotation?: bool, attendee_on_hold?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA"|"DE"|"NL"|"LA", e2e_encryption?: bool, entry_exit_chime?: "host"|"all"|"none", far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, ... (17 more fields)}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # shape: {ask_host_to_confirm_disclaimer?: bool, ask_participants_to_consent_disclaimer?: bool, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, host_pause_stop_recording?: bool, ip_address_access_control?: record, local_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, recording_disclaimer?: bool, recording_password_requirement?: record, ... (2 more fields)}
  --schedule-meeting: record # shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", default_password_for_scheduled_meetings?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, participants_video?: bool, personal_meeting?: bool, pmi_password?: string, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", ... (4 more fields)}
  --telephony: record # shape: {audio_conference_info?: string, show_international_numbers_link?: bool, telephony_regions?: record, third_party_audio?: bool}
  --tsp: record # Account Settings: TSP. — shape: {call_out?: bool, call_out_countries?: list, show_international_numbers_link?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "option" $option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/settings") $qp $auth.query)
  let req_body = {"email_notification": $email_notification, "feature": $feature, "in_meeting": $in_meeting, "profile": $profile, "recording": $recording, "schedule_meeting": $schedule_meeting, "telephony": $telephony, "tsp": $tsp, "meeting_security": $meeting_security} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"option": $option} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete virtual background files
#
# DELETE /users/{userId}/settings/virtual_backgrounds
# operationId: delUserVB
export def "users-settings-virtual-backgrounds delete-vb" [
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
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "file_ids" $file_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/settings/virtual_backgrounds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"file_ids": $file_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Upload virtual background files
#
# POST /users/{userId}/settings/virtual_backgrounds
# operationId: uploadVBuser
export def "users-settings-virtual-backgrounds upload-v-buser" [
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
  --accept: string@accept-completer # Response content type
  --file: string # Provide the file's path here.
]: any -> record<id: string, is_default: bool, name: string, size: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/settings/virtual_backgrounds") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Update user status
#
# PUT /users/{userId}/status
# operationId: userStatus
export def "users-status update" [
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
  action: string@action-completer-11 # The action types:`activate` - Activate a deactivated user.`deactivate` - Deactivate a user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/status") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Revoke a user's SSO token
#
# DELETE /users/{userId}/token
# operationId: userSSOTokenDelete
export def "users-token delete-sso" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/token") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a user token
#
# GET /users/{userId}/token
# operationId: userToken
export def "users-token get" [
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
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-15 # User token types:`token` - Used for starting meetings with the client SDK. This token expires in 14 days and a new token will be returned after the expiry.`zak` - Used for generating the start meeting URL. The token expiration time is two hours. For API users, the expiration time is 90 days.
  --ttl: int # Use this field in conjunction with the `type` field where the value of `type` field is `zak`. The value of this field denotes the expiry time of the `zak` token in seconds. For example, if you would like the zak token to be expired after one hour of the token generation, the value of this field should be `3600`.
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/token") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "ttl": $ttl} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List user's TSP accounts
#
# GET /users/{userId}/tsp
# operationId: userTSPs
export def "users-tsp get-ts-ps" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<tsp_accounts: table<conference_code: string, dial_in_numbers: list, id: int, leader_pin: string, tsp_bridge: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/tsp") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a user's TSP account
#
# POST /users/{userId}/tsp
# operationId: userTSPCreate
# --dial_in_numbers item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
export def "users-tsp create" [
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
  --accept: string@accept-completer # Response content type
  conference_code: string # Conference code: numeric value, length is less than 16.
  --dial-in-numbers: list # List of dial in numbers. — item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
  leader_pin: string # Leader PIN: numeric value, length is less than 16.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
]: any -> record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, leader_pin: string, tsp_bridge: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/tsp") $auth.query)
  let req_body = {"conference_code": $conference_code, "dial_in_numbers": $dial_in_numbers, "leader_pin": $leader_pin, "tsp_bridge": $tsp_bridge} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Set global dial-in URL for a TSP user
#
# PATCH /users/{userId}/tsp/settings
# operationId: tspUrlUpdate
export def "users-tsp-settings update-url" [
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
  --audio-url: string # The global dial-in URL for a TSP enabled account. The URL must be valid with a max-length of 512 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/tsp/settings") $auth.query)
  let req_body = {"audio_url": $audio_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete a user's TSP account
#
# DELETE /users/{userId}/tsp/{tspId}
# operationId: userTSPDelete
export def "users-tsp delete" [
  user_id: string
  tsp_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($tsp_id | is-empty) { error make --unspanned { msg: "path parameter 'tspId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tsp_id: (encode-path-segment $tsp_id)} | format pattern "/users/{user_id}/tsp/{tsp_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a user's TSP account
#
# GET /users/{userId}/tsp/{tspId}
# operationId: userTSP
export def "users-tsp get" [
  user_id: string
  tsp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, id: int, leader_pin: string, tsp_bridge: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($tsp_id | is-empty) { error make --unspanned { msg: "path parameter 'tspId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tsp_id: (encode-path-segment $tsp_id)} | format pattern "/users/{user_id}/tsp/{tsp_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a TSP account
#
# PATCH /users/{userId}/tsp/{tspId}
# operationId: userTSPUpdate
# --dial_in_numbers item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
export def "users-tsp update" [
  user_id: string
  tsp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  conference_code: string # Conference code: numeric value, length is less than 16.
  --dial-in-numbers: list # List of dial in numbers. — item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
  leader_pin: string # Leader PIN: numeric value, length is less than 16.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($tsp_id | is-empty) { error make --unspanned { msg: "path parameter 'tspId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tsp_id: (encode-path-segment $tsp_id)} | format pattern "/users/{user_id}/tsp/{tsp_id}") $auth.query)
  let req_body = {"conference_code": $conference_code, "dial_in_numbers": $dial_in_numbers, "leader_pin": $leader_pin, "tsp_bridge": $tsp_bridge} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List webinar templates
#
# GET /users/{userId}/webinar_templates
# operationId: listWebinarTemplates
export def "users-webinar-templates list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<templates: table<id: string, name: string>, total_records: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/webinar_templates") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List webinars
#
# GET /users/{userId}/webinars
# operationId: webinars
export def "users-webinars get" [
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
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/webinars") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page_size": $page_size, "page_number": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a webinar
#
# POST /users/{userId}/webinars
# operationId: webinarCreate
# --recurrence shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: string}
# --settings shape: {allow_multiple_devices?: bool, alternative_hosts?: string, approval_type?: "0"|"1"|"2", attendees_and_panelists_reminder_email_notification?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", close_registration?: bool, contact_email?: string, contact_name?: string, email_language?: string, enforce_login?: bool, enforce_login_domains?: string, follow_up_absentees_email_notification?: record, ... (16 more fields)}
# --tracking_fields item shape: {field: string, value?: string}
export def "users-webinars create" [
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
  --accept: string@accept-completer # Response content type
  --agenda: string # Webinar description.
  --duration: int # Webinar duration (minutes). Used for scheduled webinars only.
  --password: string # Webinar passcode. Passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ * !]. Max of 10 characters. If "Require a passcode when scheduling new meetings" setting has been **enabled** **and** [locked](https://support.zoom.us/hc/en-us/articles/115005269866-Using-Tiered-Settings#locked) for the user, the passcode field will be autogenerated for the Webinar in the response even if it is not provided in the API request. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recurrence: record # Recurrence object. Use this object only for a webinar of type `9` i.e., a recurring webinar with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: string}
  --settings: record # Create Webinar settings. — shape: {allow_multiple_devices?: bool, alternative_hosts?: string, approval_type?: "0"|"1"|"2", attendees_and_panelists_reminder_email_notification?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", close_registration?: bool, contact_email?: string, contact_name?: string, email_language?: string, enforce_login?: bool, enforce_login_domains?: string, follow_up_absentees_email_notification?: record, ... (16 more fields)}
  --start-time: string # Webinar start time. We support two formats for `start_time` - local time and GMT. To set time as GMT the format should be `yyyy-MM-dd`T`HH:mm:ssZ`. To set time using a specific timezone, use `yyyy-MM-dd`T`HH:mm:ss` format and specify the timezone [ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) in the `timezone` field OR leave it blank and the timezone set on your Zoom account will be used. You can also set the time as UTC as the timezone field. The `start_time` should only be used for scheduled and / or recurring webinars with fixed time. (format: date-time)
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list for supported time zones and their formats.
  --topic: string # Webinar topic.
  --tracking-fields: list # Tracking fields — item shape: {field: string, value?: string}
  --type: int@type-completer-16 # Webinar Types:`5` - Webinar.`6` - Recurring webinar with no fixed time.`9` - Recurring webinar with a fixed time. (default: 5)
]: any -> record<host_email: string, host_id: string, id: int, registrants_confirmation_email: bool, template_id: string, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/webinars") $auth.query)
  let req_body = {"agenda": $agenda, "duration": $duration, "password": $password, "recurrence": $recurrence, "settings": $settings, "start_time": $start_time, "timezone": $timezone, "topic": $topic, "tracking_fields": $tracking_fields, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a webinar
#
# DELETE /webinars/{webinarId}
# operationId: webinarDelete
export def "webinars delete" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  --cancel-webinar-reminder: string # `true`: Notify panelists and registrants about the webinar cancellation via email. `false`: Do not send any email notification to webinar registrants and panelists. The default value of this field is `false`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "cancel_webinar_reminder" $cancel_webinar_reminder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "cancel_webinar_reminder": $cancel_webinar_reminder} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204 300]
}

# Get a webinar
#
# GET /webinars/{webinarId}
# operationId: webinar
export def "webinars get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # Unique Identifier that identifies an occurrence of a recurring webinar. [Recurring webinars](https://support.zoom.us/hc/en-us/articles/216354763-How-to-Schedule-A-Recurring-Webinar) can have a maximum of 50 occurrences. When you create a recurring Webinar using [Create a Webinar API](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarcreate), you can retrieve the Occurrence ID from the response of the API call.
  --show-previous-occurrences: oneof<nothing, bool> # Set the value of this field to `true` if you would like to view Webinar details of all previous occurrences of a recurring Webinar.
]: nothing -> record<host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "show_previous_occurrences" $show_previous_occurrences "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "show_previous_occurrences": $show_previous_occurrences} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Update a webinar
#
# PATCH /webinars/{webinarId}
# operationId: webinarUpdate
# --recurrence shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
# --tracking_fields item shape: {field?: string, value?: string}
export def "webinars update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # Webinar occurrence id. Support change of agenda, start_time, duration, settings: {host_video, panelist_video, hd_video, watermark, auto_recording}
  --agenda: string # Webinar description.
  --duration: int # Webinar duration (minutes). Used for scheduled webinar only.
  --password: string # [Webinar passcode](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords). By default, passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ * !] and can have a maximum of 10 characters. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API. If "**Require a passcode when scheduling new meetings**" setting has been **enabled** **and** [locked](https://support.zoom.us/hc/en-us/articles/115005269866-Using-Tiered-Settings#locked) for the user, the passcode field will be autogenerated for the Webinar in the response even if it is not provided in the API request.
  --recurrence: record # Recurrence object. Use this object only for a meeting with type `8` i.e., a recurring meeting with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
  --settings: any
  --start-time: string # Webinar start time, in the format "yyyy-MM-dd'T'HH:mm:ss'Z'." Should be in GMT time. In the format "yyyy-MM-dd'T'HH:mm:ss." This should be in local time and the timezone should be specified. Only used for scheduled webinars and recurring webinars with a fixed time. (format: date-time)
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [time zone](#timezones) list for supported time zones and their formats.
  --topic: string # Webinar topic.
  --tracking-fields: list # Tracking fields — item shape: {field?: string, value?: string}
  --type: int@type-completer-16 # Webinar Types:`5` - webinar.`6` - Recurring webinar with no fixed time.`9` - Recurring webinar with a fixed time. (default: 5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}") $qp $auth.query)
  let req_body = {"agenda": $agenda, "duration": $duration, "password": $password, "recurrence": $recurrence, "settings": $settings, "start_time": $start_time, "timezone": $timezone, "topic": $topic, "tracking_fields": $tracking_fields, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204 300]
}

# Perform batch registration
#
# POST /webinars/{webinarId}/batch_registrants
# operationId: addBatchWebinarRegistrants
# --registrants item shape: {email: string, first_name: string, last_name?: string}
export def "webinars-batch-registrants create" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --auto-approve: oneof<nothing, bool> # If a meeting was scheduled with approval_type `1` (manual approval), but you would like to automatically approve the registrants that are added via this API, you can set the value of this field to `true`. You **cannot** use this field to change approval setting for a meeting that was originally scheduled with approval_type `0` (automatic approval).
  --registrants: list # item shape: {email: string, first_name: string, last_name?: string}
]: any -> record<registrants: table<email: string, join_url: string, registrant_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/batch_registrants") $auth.query)
  let req_body = {"auto_approve": $auto_approve, "registrants": $registrants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove panelists
#
# DELETE /webinars/{webinarId}/panelists
# operationId: webinarPanelistsDelete
export def "webinars-panelists delete-by-webinar-id" [
  webinar_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/panelists") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List panelists
#
# GET /webinars/{webinarId}/panelists
# operationId: webinarPanelists
export def "webinars-panelists get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/panelists") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Add panelists
#
# POST /webinars/{webinarId}/panelists
# operationId: webinarPanelistCreate
# --panelists item shape: {email?: string, name?: string}
export def "webinars-panelists create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --panelists: list # List of panelist objects. — item shape: {email?: string, name?: string}
]: any -> record<id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/panelists") $auth.query)
  let req_body = {"panelists": $panelists} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Remove a panelist
#
# DELETE /webinars/{webinarId}/panelists/{panelistId}
# operationId: webinarPanelistDelete
export def "webinars-panelists delete-by-webinar-id-panelist-id" [
  webinar_id: int
  panelist_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($panelist_id | is-empty) { error make --unspanned { msg: "path parameter 'panelistId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), panelist_id: (encode-path-segment $panelist_id)} | format pattern "/webinars/{webinar_id}/panelists/{panelist_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# List a webinar's polls
#
# GET /webinars/{webinarId}/polls
# operationId: webinarPolls
export def "webinars-polls list" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/polls") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a webinar's poll
#
# POST /webinars/{webinarId}/polls
# operationId: webinarPollCreate
# --questions item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
export def "webinars-polls create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/polls") $auth.query)
  let req_body = {"questions": $questions, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201 300]
}

# Delete a webinar poll
#
# DELETE /webinars/{webinarId}/polls/{pollId}
# operationId: webinarPollDelete
export def "webinars-polls delete" [
  webinar_id: int
  poll_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/webinars/{webinar_id}/polls/{poll_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a webinar poll
#
# GET /webinars/{webinarId}/polls/{pollId}
# operationId: webinarPollGet
export def "webinars-polls get" [
  webinar_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/webinars/{webinar_id}/polls/{poll_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a webinar poll
#
# PUT /webinars/{webinarId}/polls/{pollId}
# operationId: webinarPollUpdate
# --questions item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
export def "webinars-polls update" [
  webinar_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($poll_id | is-empty) { error make --unspanned { msg: "path parameter 'pollId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), poll_id: (encode-path-segment $poll_id)} | format pattern "/webinars/{webinar_id}/polls/{poll_id}") $auth.query)
  let req_body = {"questions": $questions, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List webinar registrants
#
# GET /webinars/{webinarId}/registrants
# operationId: webinarRegistrants
export def "webinars-registrants list" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --tracking-source-id: string # The tracking source ID for the registrants. Useful if you share the webinar registration page in multiple locations. See [Creating source tracking links for webinar registration](https://support.zoom.us/hc/en-us/articles/360000315683-Creating-source-tracking-links-for-webinar-registration) for details.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tracking_source_id" $tracking_source_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/registrants") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id, "status": $status, "tracking_source_id": $tracking_source_id, "page_size": $page_size, "page_number": $page_number, "next_page_token": $next_page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Add a webinar registrant
#
# POST /webinars/{webinarId}/registrants
# operationId: webinarRegistrantCreate
# --custom_questions item shape: {title?: string, value?: string}
export def "webinars-registrants create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-ids: string # Occurrence ID. Get this value from the webinar get API. Multiple values separated by a comma.
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
]: any -> record<id: string, join_url: string, registrant_id: string, start_time: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_ids" $occurrence_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/registrants") $qp $auth.query)
  let req_body = {"address": $address, "city": $city, "comments": $comments, "country": $country, "custom_questions": $custom_questions, "email": $email, "first_name": $first_name, "industry": $industry, "job_title": $job_title, "last_name": $last_name, "no_of_employees": $no_of_employees, "org": $org, "phone": $phone, "purchasing_time_frame": $purchasing_time_frame, "role_in_purchase_process": $role_in_purchase_process, "state": $state, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"occurrence_ids": $occurrence_ids} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201 300]
}

# List registration questions
#
# GET /webinars/{webinarId}/registrants/questions
# operationId: webinarRegistrantsQuestionsGet
export def "webinars-registrants-questions get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/registrants/questions") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update registration questions
#
# PATCH /webinars/{webinarId}/registrants/questions
# operationId: webinarRegistrantQuestionUpdate
# --custom_questions item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single_radio"|"single_dropdown"|"multiple"}
# --questions item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
export def "webinars-registrants-questions update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions. — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single_radio"|"single_dropdown"|"multiple"}
  --questions: list # Array of registration fields whose values should be provided by registrants during registration. — item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/registrants/questions") $auth.query)
  let req_body = {"custom_questions": $custom_questions, "questions": $questions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update registrant's status
#
# PUT /webinars/{webinarId}/registrants/status
# operationId: webinarRegistrantStatus
# --registrants item shape: {email?: string, id?: string}
export def "webinars-registrants-status update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  action: string@action-completer-6 # Used to approve a registrant, deny a registrant, or cancel a previously approved registrant.
  --registrants: list # List of registrants. — item shape: {email?: string, id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/registrants/status") $qp $auth.query)
  let req_body = {"action": $action, "registrants": $registrants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 300]
}

# Delete a webinar registrant
#
# DELETE /webinars/{webinarId}/registrants/{registrantId}
# operationId: deleteWebinarRegistrant
export def "webinars-registrants delete" [
  webinar_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The webinar occurence ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($registrant_id | is-empty) { error make --unspanned { msg: "path parameter 'registrantId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), registrant_id: (encode-path-segment $registrant_id)} | format pattern "/webinars/{webinar_id}/registrants/{registrant_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a webinar registrant
#
# GET /webinars/{webinarId}/registrants/{registrantId}
# operationId: webinarRegistrantGet
export def "webinars-registrants get" [
  webinar_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  if ($registrant_id | is-empty) { error make --unspanned { msg: "path parameter 'registrantId' must be non-empty" } }
  let qp = [(serialize-qp "occurrence_id" $occurrence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id), registrant_id: (encode-path-segment $registrant_id)} | format pattern "/webinars/{webinar_id}/registrants/{registrant_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"occurrence_id": $occurrence_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 300]
}

# Update webinar status
#
# PUT /webinars/{webinarId}/status
# operationId: webinarStatus
export def "webinars-status update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/status") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Get webinar tracking sources
#
# GET /webinars/{webinarId}/tracking_sources
# operationId: getTrackingSources
export def "webinars-tracking-sources get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<total_records: int, tracking_sources: table<id: string, registration_count: int, source_name: string, tracking_url: string, visitor_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webinar_id | is-empty) { error make --unspanned { msg: "path parameter 'webinarId' must be non-empty" } }
  let full_url = (build-url $base ({webinar_id: (encode-path-segment $webinar_id)} | format pattern "/webinars/{webinar_id}/tracking_sources") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
