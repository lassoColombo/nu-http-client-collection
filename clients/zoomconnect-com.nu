# Auto-generated client for www.zoomconnect.com v1
# Source: https://api.apis.guru/v2/specs/zoomconnect.com/1/swagger.json
# Auth: --token flag or $env.WWW_ZOOMCONNECT_COM_TOKEN

const BASE_URL = "https://www.zoomconnect.com/app"
const DEFAULT_AUTH = "email"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WWW_ZOOMCONNECT_COM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "email" => { {headers: {email: $token_val}, query: ""} }
    "token" => { {headers: {token: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
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

def base-url-completer [] { ["https://www.zoomconnect.com/app"] }
def auth-scheme-completer [] { ["email" "token"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def type-completer [] { ["INBOUND" "OUTBOUND"] }
def status-completer [] { ["DELIVERED" "FAILED" "FAILED_OPTOUT" "FAILED_REFUNDED" "SCHEDULED" "SENT" "UNKNOWN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-account-balance get" } } | get name | first)
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

# balance
#
# GET /api/rest/v1/account/balance
# operationId: getBalance
export def "rest-account-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creditBalance: float, links: table<href: string, rel: string, templated: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/account/balance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# statistics
#
# GET /api/rest/v1/account/statistics
# operationId: getStatistics
export def "rest-account-statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # date format: dd-MM-yyyy (format: date-time)
  --qp-to: string # date format: dd-MM-yyyy (format: date-time)
  --user-email-address: string # optional email address of user to return statistics for a single user, default is to return statistics for all users if administrator, or statistics for your own account if not an administrator
  --campaign: string # optional campaign name
  --include-refunded-and-optout: oneof<nothing, bool> # optionally include refunded and optout counts, default is false
  --calculate-credit-value: oneof<nothing, bool> # optionally calculate using credit value rather than message count, default is false
]: nothing -> record<from: string, grandTotal: record<delivered: float, failed: float, failedOptout: float, failedRefunded: float, sent: float, total: float>, showingCreditValue: bool, to: string, users: table<campaigns: list, total: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "userEmailAddress" $user_email_address "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "includeRefundedAndOptout" $include_refunded_and_optout "scalar") (serialize-qp "calculateCreditValue" $calculate_credit_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/account/statistics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# transfer
#
# POST /api/rest/v1/account/transfer
# operationId: transfer
export def "rest-account-transfer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --number-of-credits-to-transfer: int # format: int32
  --transfer-from-email-address: string
  --transfer-to-email-address: string
]: any -> record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/account/transfer")
  let req_body = {"numberOfCreditsToTransfer": $number_of_credits_to_transfer, "transferFromEmailAddress": $transfer_from_email_address, "transferToEmailAddress": $transfer_to_email_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# search
#
# GET /api/rest/v1/account/user
# operationId: search
export def "rest-account-user list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-email: string # search by email address
]: nothing -> record<webServiceUserList: table<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchEmail" $search_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/account/user" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# create
#
# PUT /api/rest/v1/account/user
export def "rest-account-user update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --company: string
  --contact-number: string
  --credit-balance: float # format: double
  --email-address: string
  --first-name: string
  --last-name: string
  --password: string
  --user-id: int # format: int64
]: any -> record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/account/user")
  let req_body = {"company": $company, "contactNumber": $contact_number, "creditBalance": $credit_balance, "emailAddress": $email_address, "firstName": $first_name, "lastName": $last_name, "password": $password, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getUser
#
# GET /api/rest/v1/account/user/{userId}
# operationId: getUser
export def "rest-account-user get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/rest/v1/account/user/{user_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# update
#
# POST /api/rest/v1/account/user/{userId}
export def "rest-account-user create" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --company: string
  --contact-number: string
  --credit-balance: float # format: double
  --email-address: string
  --first-name: string
  --last-name: string
  --password: string
  --body-user-id: int # format: int64
]: any -> record<company: string, contactNumber: string, creditBalance: float, emailAddress: string, firstName: string, lastName: string, password: string, userId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/rest/v1/account/user/{user_id}"))
  let req_body = {"company": $company, "contactNumber": $contact_number, "creditBalance": $credit_balance, "emailAddress": $email_address, "firstName": $first_name, "lastName": $last_name, "password": $password, "userId": $body_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# all
#
# GET /api/rest/v1/contacts/all
export def "rest-contacts-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, rel: string, templated: bool>, webServiceContacts: table<contactId: string, contactNumber: string, firstName: string, lastName: string, links: list, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/contacts/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# create
#
# POST /api/rest/v1/contacts/create
# --links item shape: {href?: string, rel?: string, templated?: bool}
export def "rest-contacts-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contact-id: string
  --contact-number: string
  --first-name: string
  --last-name: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --title: string
]: any -> record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/contacts/create")
  let req_body = {"contactId": $contact_id, "contactNumber": $contact_number, "firstName": $first_name, "lastName": $last_name, "links": $links, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# delete
#
# DELETE /api/rest/v1/contacts/{contactId}
export def "rest-contacts delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/contacts/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# get
#
# GET /api/rest/v1/contacts/{contactId}
export def "rest-contacts get" [
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
]: nothing -> record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/contacts/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# update
#
# POST /api/rest/v1/contacts/{contactId}
# --links item shape: {href?: string, rel?: string, templated?: bool}
export def "rest-contacts create" [
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
  --body-contact-id: string
  --contact-number: string
  --first-name: string
  --last-name: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --title: string
]: any -> record<contactId: string, contactNumber: string, firstName: string, lastName: string, links: table<href: string, rel: string, templated: bool>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/contacts/{contact_id}"))
  let req_body = {"contactId": $body_contact_id, "contactNumber": $contact_number, "firstName": $first_name, "lastName": $last_name, "links": $links, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# removeFromGroup
#
# GET /api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}
export def "rest-contacts-add-from-group get" [
  contact_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/contacts/{contact_id}/addFromGroup/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# removeFromGroup
#
# POST /api/rest/v1/contacts/{contactId}/addFromGroup/{groupId}
export def "rest-contacts-add-from-group create" [
  contact_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/contacts/{contact_id}/addFromGroup/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addToGroup
#
# GET /api/rest/v1/contacts/{contactId}/addToGroup/{groupId}
export def "rest-contacts-add-to-group get" [
  contact_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/contacts/{contact_id}/addToGroup/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addToGroup
#
# POST /api/rest/v1/contacts/{contactId}/addToGroup/{groupId}
export def "rest-contacts-add-to-group create" [
  contact_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/contacts/{contact_id}/addToGroup/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# all
#
# GET /api/rest/v1/groups/all
export def "rest-groups-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, rel: string, templated: bool>, webServiceGroups: table<groupId: string, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/groups/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# create
#
# POST /api/rest/v1/groups/create
# --links item shape: {href?: string, rel?: string, templated?: bool}
export def "rest-groups-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-id: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --name: string
]: any -> record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/groups/create")
  let req_body = {"groupId": $group_id, "links": $links, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# delete
#
# DELETE /api/rest/v1/groups/{groupId}
export def "rest-groups delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/groups/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# get
#
# GET /api/rest/v1/groups/{groupId}
export def "rest-groups get" [
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
]: nothing -> record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/groups/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# update
#
# POST /api/rest/v1/groups/{groupId}
# --links item shape: {href?: string, rel?: string, templated?: bool}
export def "rest-groups create" [
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
  --body-group-id: string
  --links: list # item shape: {href?: string, rel?: string, templated?: bool}
  --name: string
]: any -> record<groupId: string, links: table<href: string, rel: string, templated: bool>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/api/rest/v1/groups/{group_id}"))
  let req_body = {"groupId": $body_group_id, "links": $links, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addContact
#
# GET /api/rest/v1/groups/{groupId}/addContact/{contactId}
export def "rest-groups-add-contact get" [
  group_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/groups/{group_id}/addContact/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addContact
#
# POST /api/rest/v1/groups/{groupId}/addContact/{contactId}
export def "rest-groups-add-contact create" [
  group_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/groups/{group_id}/addContact/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# removeContact
#
# GET /api/rest/v1/groups/{groupId}/removeContact/{contactId}
export def "rest-groups-remove-contact get" [
  group_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/groups/{group_id}/removeContact/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# removeContact
#
# POST /api/rest/v1/groups/{groupId}/removeContact/{contactId}
export def "rest-groups-remove-contact create" [
  group_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/api/rest/v1/groups/{group_id}/removeContact/{contact_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# all
#
# GET /api/rest/v1/messages/all
export def "rest-messages-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # number of elements to return at a time (format: int32, default: 100)
  --page: int # page number (format: int32, default: 1)
  --type: string@type-completer # filter by message type
  --status: string@status-completer # filter by message status
  --from-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --from-date-time-received: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-received: string # date format: yyyyMMdd (format: date-time)
  --from-number: string # phone number the message was sent from
  --to-number: string # phone number the message was sent to
  --message: string # search matching message text
  --campaign: string # search by campaign
  --data-field: string # search by data field
  --deleted: oneof<nothing, bool> # return only deleted / not deleted messages
  --read: oneof<nothing, bool> # return only read / unread messages (inbox messages only)
  --replies-to-message-id: string # return only inbox messages which are a reply to the message with the given message id
]: nothing -> record<elements: int, links: table<href: string, rel: string, templated: bool>, page: int, pageSize: int, totalElements: int, totalPages: int, webServiceMessages: table<campaign: string, contact: record, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: list, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record, toNumber: string, userDataField: string>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "fromDateTimeSent" $from_date_time_sent "scalar") (serialize-qp "toDateTimeSent" $to_date_time_sent "scalar") (serialize-qp "fromDateTimeReceived" $from_date_time_received "scalar") (serialize-qp "toDateTimeReceived" $to_date_time_received "scalar") (serialize-qp "fromNumber" $from_number "scalar") (serialize-qp "toNumber" $to_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "read" $read "scalar") (serialize-qp "repliesToMessageId" $replies_to_message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/messages/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# analyse-full
#
# POST /api/rest/v1/messages/analyse/full
# operationId: analyse-full
export def "rest-messages-analyse-full create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> record<characterAnalysis: list<list<any>>, messageCreditCost: float, messageEncoding: string, messageLength: int, messageLengthWithinMaximumAllowed: bool, numberOfMessages: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/full")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# analyse-message-credit-cost
#
# POST /api/rest/v1/messages/analyse/message-credit-cost
# operationId: analyse-message-credit-cost
export def "rest-messages-analyse-message-credit-cost create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> float {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/message-credit-cost")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# analyse-message-encoding
#
# POST /api/rest/v1/messages/analyse/message-encoding
# operationId: analyse-message-encoding
export def "rest-messages-analyse-message-encoding create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/message-encoding")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# analyse-message-length
#
# POST /api/rest/v1/messages/analyse/message-length
# operationId: analyse-message-length
export def "rest-messages-analyse-message-length create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/message-length")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# analyse-
#
# POST /api/rest/v1/messages/analyse/message-length-within-max-allowed
# operationId: analyse-
export def "rest-messages-analyse-message-length-within-max-allowed create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/message-length-within-max-allowed")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# analyse-number-of-messages
#
# POST /api/rest/v1/messages/analyse/number-of-messages
# operationId: analyse-number-of-messages
export def "rest-messages-analyse-number-of-messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string
  --recipient-number: string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/messages/analyse/number-of-messages")
  let req_body = {"message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# delete
#
# DELETE /api/rest/v1/messages/{messageId}
export def "rest-messages delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# get
#
# GET /api/rest/v1/messages/{messageId}
export def "rest-messages get" [
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
]: nothing -> record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# markRead
#
# POST /api/rest/v1/messages/{messageId}/markRead
export def "rest-messages-mark-read create" [
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
]: nothing -> record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}/markRead"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# markRead
#
# PUT /api/rest/v1/messages/{messageId}/markRead
export def "rest-messages-mark-read update" [
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
]: nothing -> record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}/markRead"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# markUnread
#
# POST /api/rest/v1/messages/{messageId}/markUnread
export def "rest-messages-mark-unread create" [
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
]: nothing -> record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}/markUnread"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# markUnread
#
# PUT /api/rest/v1/messages/{messageId}/markUnread
export def "rest-messages-mark-unread update" [
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
]: nothing -> record<campaign: string, contact: record<contactId: string, links: list<record>>, creditCost: float, dateTimeReceived: string, dateTimeScheduled: string, dateTimeSent: string, deleted: bool, fromNumber: string, links: table<href: string, rel: string, templated: bool>, message: string, messageId: string, messageStatus: string, messageType: string, numberOfMessages: int, read: bool, repliedToMessage: record<links: list<record>, messageId: string>, toNumber: string, userDataField: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/messages/{message_id}/markUnread"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send
#
# GET /api/rest/v1/sms/send
export def "rest-sms-send get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/sms/send")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send
#
# POST /api/rest/v1/sms/send
export def "rest-sms-send create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --campaign: string
  --data-field: string
  --date-to-send: string # format: date-time
  --message: string
  --recipient-number: string
]: any -> record<error: string, messageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/sms/send")
  let req_body = {"campaign": $campaign, "dataField": $data_field, "dateToSend": $date_to_send, "message": $message, "recipientNumber": $recipient_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# send-bulk
#
# GET /api/rest/v1/sms/send-bulk
export def "rest-sms-send-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<defaultDateToSend: string, messagesPerMinute: int, sendSmsRequests: table<campaign: string, dataField: string, dateToSend: string, message: string, recipientNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/sms/send-bulk")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send-bulk
#
# POST /api/rest/v1/sms/send-bulk
# --sendSmsRequests item shape: {campaign?: string, dataField?: string, dateToSend?: string, message?: string, recipientNumber?: string}
export def "rest-sms-send-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --default-date-to-send: string # format: date-time
  --messages-per-minute: int # format: int32
  --send-sms-requests: list # item shape: {campaign?: string, dataField?: string, dateToSend?: string, message?: string, recipientNumber?: string}
]: any -> record<sendSmsResponses: table<error: string, messageId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/sms/send-bulk")
  let req_body = {"defaultDateToSend": $default_date_to_send, "messagesPerMinute": $messages_per_minute, "sendSmsRequests": $send_sms_requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# send-url-parameters
#
# GET /api/rest/v1/sms/send-url-parameters
export def "rest-sms-send-url-parameters get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recipient-number: string # the phone number of the recipient to send to
  --message: string # the message to send
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientNumber" $recipient_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "dateToSend" $date_to_send "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/sms/send-url-parameters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send-url-parameters
#
# POST /api/rest/v1/sms/send-url-parameters
export def "rest-sms-send-url-parameters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recipient-number: string # the phone number of the recipient to send to
  --message: string # the message to send
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientNumber" $recipient_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "dateToSend" $date_to_send "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/sms/send-url-parameters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send-url
#
# GET /api/rest/v1/sms/send-url/{token}
export def "rest-sms-send-url get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recipient-number: string # the phone number of the recipient to send to
  --message: string # the message to send
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientNumber" $recipient_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "dateToSend" $date_to_send "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/api/rest/v1/sms/send-url/{token_arg}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# send-url
#
# POST /api/rest/v1/sms/send-url/{token}
export def "rest-sms-send-url create" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recipient-number: string # the phone number of the recipient to send to
  --message: string # the message to send
  --date-to-send: string # date format: yyyyMMddHHmm (format: date-time)
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientNumber" $recipient_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "dateToSend" $date_to_send "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/api/rest/v1/sms/send-url/{token_arg}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# all
#
# GET /api/rest/v1/templates/all
export def "rest-templates-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, rel: string, templated: bool>, webServiceTemplates: table<data: string, links: list, name: string, templateId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/templates/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# delete
#
# DELETE /api/rest/v1/templates/{templateId}
export def "rest-templates delete" [
  template_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/api/rest/v1/templates/{template_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# get
#
# GET /api/rest/v1/templates/{templateId}
export def "rest-templates get" [
  template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<data: string, links: table<href: string, rel: string, templated: bool>, name: string, templateId: int> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/api/rest/v1/templates/{template_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# all
#
# GET /api/rest/v1/voice/all
export def "rest-voice-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # number of elements to return at a time (format: int32, default: 100)
  --page: int # page number (format: int32, default: 1)
  --status: string@status-completer # filter by message status
  --from-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-date-time-sent: string # date format: yyyyMMdd (format: date-time)
  --to-number: string # phone number the message was sent to
  --message: string # search matching message text
  --campaign: string # search by campaign
  --data-field: string # search by data field
  --deleted: oneof<nothing, bool> # return only deleted / not deleted messages
]: nothing -> record<elements: int, links: table<href: string, rel: string, templated: bool>, messages: table<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: list, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string>, page: int, pageSize: int, totalElements: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "fromDateTimeSent" $from_date_time_sent "scalar") (serialize-qp "toDateTimeSent" $to_date_time_sent "scalar") (serialize-qp "toNumber" $to_number "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/voice/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# single-audio
#
# POST /api/rest/v1/voice/single-audio
# operationId: single-audio
export def "rest-voice-single-audio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recipient-number: string # the phone number of the recipient to send to
  --campaign: string # optional campaign name
  --data-field: string # optional extra data
  --retry-count: int # optional number of times to retry unanswered call (format: int32)
  --retry-minimum-interval: int # optional minimum interval in minutes between retry attempts (format: int32)
  --retry-maximum-interval: int # optional maximum interval in minutes between retry attempts (format: int32)
  file: path # audio file to play, supports MP3 or WAV format
]: any -> record<error: string, voiceMessageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientNumber" $recipient_number "scalar") (serialize-qp "campaign" $campaign "scalar") (serialize-qp "dataField" $data_field "scalar") (serialize-qp "retryCount" $retry_count "scalar") (serialize-qp "retryMinimumInterval" $retry_minimum_interval "scalar") (serialize-qp "retryMaximumInterval" $retry_maximum_interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/voice/single-audio" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# single-text
#
# POST /api/rest/v1/voice/single-text
# operationId: single-text
export def "rest-voice-single-text create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --campaign: string
  --data-field: string
  --language: string
  --message: string
  --recipient-number: string
  --retry-count: int # format: int32
  --retry-maximum-interval: int # format: int32
  --retry-minimum-interval: int # format: int32
]: any -> record<error: string, voiceMessageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/voice/single-text")
  let req_body = {"campaign": $campaign, "dataField": $data_field, "language": $language, "message": $message, "recipientNumber": $recipient_number, "retryCount": $retry_count, "retryMaximumInterval": $retry_maximum_interval, "retryMinimumInterval": $retry_minimum_interval} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# delete
#
# DELETE /api/rest/v1/voice/{messageId}
export def "rest-voice delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/voice/{message_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# get
#
# GET /api/rest/v1/voice/{messageId}
export def "rest-voice get" [
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
]: nothing -> record<audioFileUrl: string, campaign: string, dateTimeSent: string, deleted: bool, language: string, links: table<href: string, rel: string, templated: bool>, message: string, messageStatus: string, toNumber: string, userDataField: string, voiceMessageId: string> {
  let auth = (build-auth $token ($auth_scheme | default "email"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/rest/v1/voice/{message_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
