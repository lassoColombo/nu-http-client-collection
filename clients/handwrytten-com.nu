# Auto-generated client for Handwrytten API v1.0.0
# Source: https://api.apis.guru/v2/specs/handwrytten.com/1.0.0/swagger.json
# Auth: --token flag or $env.HANDWRYTTEN_API_TOKEN

const BASE_URL = "https://api.handwrytten.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HANDWRYTTEN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.handwrytten.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-authorization create-login" } } | get name | first)
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

# Logs in to an existing account
#
# POST /auth/authorization
# operationId: login
export def "auth-authorization create-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string # email address (e.g. john@jjf.com)
  password: string # e.g. 8yfqwiuy@!$
]: any -> record<anet_customer_id: string, free_cards: int, status: string, uid: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/authorization")
  let req_body = {"login": $login, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# changes a user's password
#
# POST /auth/changePassword
# operationId: changePassword
export def "auth-change-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new password (e.g. myn3wp455w0rd!)
  --old-password: string # the existing password (e.g. myoldpassword1234!)
  --uid: string # the authorized UID of the session (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/changePassword")
  let req_body = {"new_password": $new_password, "old_password": $old_password, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# logs out a session uid
#
# POST /auth/logout
# operationId: logout
export def "auth-logout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # the authorized UID of the session (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/logout")
  let req_body = {"uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Registers a new account
#
# POST /auth/register
# operationId: register
export def "auth-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --discount-code: string # optional discount code
  fname: string # first name (e.g. John)
  lname: string # last name (e.g. Smith)
  login: string # email address (e.g. john@jjf.com)
  password: string # e.g. 8yfqwiuy@!$
]: any -> record<status: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/register")
  let req_body = {"discount_code": $discount_code, "fname": $fname, "lname": $lname, "login": $login, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# resets a user's password
#
# POST /auth/resetPasswordRequest
# operationId: resetPasswordRequest
export def "auth-reset-password-request reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # the email address of the user (e.g. joe@bloggs.com)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/resetPasswordRequest")
  let req_body = {"login": $login} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a new custom card
#
# POST /cards/createCustomCard
# operationId: CreateCustomCard
export def "cards-create-custom-card create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: int # the card id of the card template you're starting with. You can find this by logging into Handwrytten, clicking "customize" next to any customizable card, and pulling the card ID from the end of the URL (e.g. 243)
  --cover-id: int # the id of the image you want to use for the "cover". The cover is the large image on the front of the flat card. (e.g. 42)
  --cover-size-percent: int # the size of the image to use as the cover. (e.g. 100)
  --footer-align: string # set to "left", "center", or "right" to align the footer appropriately (e.g. center)
  --footer-font-id: int # font ID of the text in the footer, found by using ListFontForCustomizer (e.g. 1)
  --footer-font-size: int # Font size of the text in the footer (e.g. 16)
  --footer-text: string # optional text for the footer of the customizable card (e.g. Sample text for the footer)
  --header-align: string # set to "left", "center", or "right" to align the header appropriately (e.g. center)
  --header-auto-size: oneof<nothing, bool> # if set to true, the header will be maximized to fill the header area
  --header-font-id: int # font ID of the text in the header, found by using ListFontForCustomizer (e.g. 8)
  --header-font-size: int # font size of the text in the header of the card (e.g. 20)
  --header-text: string # text in the header, if type is set to "text" (e.g. Sample text for the header)
  --logo-id: int # Optional. If setting "type" to "logo", set the id of the logo here. (e.g. 20)
  --logo-size-percent: int # set to the desired scaling of the logo on the header (e.g. 100)
  --name: string # the name of the new card (e.g. my custom card design)
  --type: string # Defines the top of the back of the card. Set to either "logo" or "text". (e.g. logo)
  --uid: string # authorized UID of the session. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/createCustomCard")
  let req_body = {"card_id": $card_id, "cover_id": $cover_id, "cover_size_percent": $cover_size_percent, "footer_align": $footer_align, "footer_font_id": $footer_font_id, "footer_font_size": $footer_font_size, "footer_text": $footer_text, "header_align": $header_align, "header_auto_size": $header_auto_size, "header_font_id": $header_font_id, "header_font_size": $header_font_size, "header_text": $header_text, "logo_id": $logo_id, "logo_size_percent": $logo_size_percent, "name": $name, "type": $type, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists information on cards
#
# GET /cards/list
# operationId: simpleListCards
export def "cards-list list-simple" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists information on cards
#
# POST /cards/list
# operationId: listCards
export def "cards-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # optional category id filter (e.g. 14)
  --uid: string # optional authorized UID of the session. By providing this, the card list will include user-specific cards. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> table<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/list")
  let req_body = {"category_id": $category_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# upload logo or cover image for card
#
# POST /cards/uploadCustomLogo
# operationId: uploadCustomLogo
export def "cards-upload-custom-logo upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: path # upload images for customc cards
  type: string # set to cover or header
  uid: string # uid of the user
]: any -> record<id: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/uploadCustomLogo")
  let req_body = {"file": $file, "type": $type, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Provides full information on a specific card
#
# POST /cards/view
# operationId: filterableCardDetails
export def "cards-view create-filterable-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: int # the card id to view (e.g. 14)
  --uid: string # optional authorized UID of the session. By providing this, the card details can provide user-specific cards (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, images: table<array: list, name: string>, name: string, orientation: string, price: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/view")
  let req_body = {"card_id": $card_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the countries to which Handwritten can mail, their associated country ID and any costs
#
# GET /countries/list
export def "countries-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<aliases: string, delivery_cost: float, id: int, states: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/countries/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists Handwryting styles available for use
#
# GET /fonts/list
# operationId: fontsList
export def "fonts-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, image: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fonts/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists fonts available for use with the card customizer
#
# GET /fonts/listForCustomizer
# operationId: fontsListForCustomizer
export def "fonts-list-for-customizer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fonts/listForCustomizer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists information on gift cards
#
# GET /giftCards/view
# operationId: getGiftCardDetails
export def "gift-cards-view get-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<denominations: list<record>, id: int, image: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/giftCards/view")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists information on gift cards
#
# POST /giftCards/view
# operationId: giftCardDetails
export def "gift-cards-view create-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<denominations: list<record>, id: int, image: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/giftCards/view")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# sends an order in a single step. This is much easier than using other order commands
#
# POST /orders/singleStepOrder
# operationId: singleStepOrder
export def "orders-single-step-order create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: int # the id of the card you want to send (e.g. 3404)
  --credit-card-id: int # the credit card id to charge for the order. Currently this is required, even for invoiced accounts, it just won't be charged. (e.g. 34124)
  --denomination-id: int # Optional. Use if sending a gift card (e.g. 12)
  --font-label: string # the colloquial name of the font, such as 'Fancy Jenna' or 'Casual David' (e.g. Chill Charity)
  message: string # the full message body. Use '\n' for new lines (e.g. Dear Frank, Thank you so much for your interest in our services. Yours, Joe)
  --recipient-address1: string # the first address line of the return address (e.g. 123 E Main Street)
  --recipient-address2: string # the second line of the address, such as suite, apartment, building, etc. Optional (e.g. Second Floor)
  --recipient-business-name: string # the second line of the recipient address. Optional. (e.g. Spacely Space Sprockets)
  --recipient-city: string # the city of the recipient, to appear in the address (e.g. Burlington)
  --recipient-country: string # the country of the recipient. Optional and defaults to usa (e.g. Canada)
  --recipient-country-id: int # alternate way to specify country. Optional and defaults to 1 (e.g. 2)
  --recipient-name: string # the name on the recipient address (e.g. Cosmo Spacely)
  --recipient-state: string # the ABBREVIATED state or province of the recipient. This is required for US and Canada addresses and optional for all other countries (e.g. ON)
  --recipient-zip: string # the zip code or postal code of the recipient (e.g. L7L 0E9)
  --sender-address1: string # the first address line of the return address (e.g. 1430 E Indian School Road)
  --sender-address2: string # the second line of the address, such as suite, apartment, building, etc. Optional (e.g. Suite 100)
  --sender-business-name: string # the second line of the return address. Optional. (e.g. Handwrytten)
  --sender-city: string # the city of the sender, to appear in the return address (e.g. Phoenix)
  --sender-country: string # the country of the recipient. Optional and defaults to usa (e.g. United States)
  --sender-country-id: int # alternate way to specify country. Optional and defaults to 1 (e.g. 1)
  --sender-name: string # the name on the return address (e.g. Joe Sender)
  --sender-state: string # the ABBREVIATED state or province of the sender. This is required for US and Canada addresses and optional for all other countries (e.g. AZ)
  --sender-zip: string # The postal code or zip code of the sender. (e.g. 12345)
  uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<response: record<address_from: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, card: record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float>, date_created: string, for_free: bool, id: int, message: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/singleStepOrder")
  let req_body = {"card_id": $card_id, "credit_card_id": $credit_card_id, "denomination_id": $denomination_id, "font_label": $font_label, "message": $message, "recipient_address1": $recipient_address1, "recipient_address2": $recipient_address2, "recipient_business_name": $recipient_business_name, "recipient_city": $recipient_city, "recipient_country": $recipient_country, "recipient_country_id": $recipient_country_id, "recipient_name": $recipient_name, "recipient_state": $recipient_state, "recipient_zip": $recipient_zip, "sender_address1": $sender_address1, "sender_address2": $sender_address2, "sender_business_name": $sender_business_name, "sender_city": $sender_city, "sender_country": $sender_country, "sender_country_id": $sender_country_id, "sender_name": $sender_name, "sender_state": $sender_state, "sender_zip": $sender_zip, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# gets the user's return address information
#
# POST /profile/address
# operationId: userAddress
export def "profile-address create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # authorized UID of the session. By providing this, the card list will include user-specific cards. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/address")
  let req_body = {"uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deletes an existing recipient address
#
# POST /profile/deleteRecipient
# operationId: deleteRecipient
export def "profile-delete-recipient delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: int # the id of the address to delete (e.g. 549494)
  uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/deleteRecipient")
  let req_body = {"address_id": $address_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# add a new recipient address
#
# POST /profile/profileAddRecipient
# operationId: addRecipientAddress
export def "profile-profile-add-recipient create-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the second (optional) line of the address (e.g. Suite 100)
  --business-name: string # the optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the city of the address (e.g. Phoenix)
  --country: string # the name of the country of the address, or use country_id (e.g. United States)
  --country-id: int # the country id code of the recipient
  --name: string # the name on the address (e.g. Joe Smith)
  --state: string # the abbreviated state or province of the address (e.g. AZ)
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the zip or postal code of the address (e.g. 85014)
]: any -> record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/profileAddRecipient")
  let req_body = {"address1": $address1, "address2": $address2, "business_name": $business_name, "city": $city, "country": $country, "country_id": $country_id, "name": $name, "state": $state, "uid": $uid, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# list the addresses in the user's account
#
# POST /profile/recipientsList
# operationId: recipientsList
export def "profile-recipients-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
]: any -> table<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/recipientsList")
  let req_body = {"uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# update the user's return address information
#
# POST /profile/updateAddress
# operationId: updateUserAddress
export def "profile-update-address update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the second (optional) line of the address (e.g. Suite 100)
  address_id: int # the address you are updating (e.g. 42)
  --business-name: string # the optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the city of the address (e.g. Phoenix)
  --country: string # the name of the country of the address (e.g. United States)
  --country-id: int # the id of the country of the address. do not use with "country" parameter (e.g. 2)
  --name: string # the name on the address (e.g. Joe Smith)
  --state: string # the abbreviated state or province of the address (e.g. AZ)
  uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the zip or postal code of the address (e.g. 85014)
]: any -> record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/updateAddress")
  let req_body = {"address1": $address1, "address2": $address2, "address_id": $address_id, "business_name": $business_name, "city": $city, "country": $country, "country_id": $country_id, "name": $name, "state": $state, "uid": $uid, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updates an existing new recipient address
#
# POST /profile/updateRecipient
# operationId: updateRecipient
export def "profile-update-recipient update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the updated first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the updated second (optional) line of the address (e.g. Suite 100)
  --business-name: string # the updated optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the updated city of the address (e.g. Phoenix)
  --country: string # the updated name of the country of the address, or use country_id (e.g. United States)
  --country-id: int # the country id of the address
  --id: int # the id of the address to update (e.g. 549494)
  --name: string # the updated name on the address (e.g. Joe Smith)
  --state: string # the updated abbreviated state or province of the address (e.g. AZ)
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the updated zip or postal code of the address (e.g. 85014)
]: any -> record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/updateRecipient")
  let req_body = {"address1": $address1, "address2": $address2, "business_name": $business_name, "city": $city, "country": $country, "country_id": $country_id, "id": $id, "name": $name, "state": $state, "uid": $uid, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List template categories
#
# GET /templateCategories/list
# operationId: getTemplateCategories
export def "template-categories-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, price: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templateCategories/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List template categories
#
# POST /templateCategories/list
# operationId: getTemplateCategoriesAuthorized
export def "template-categories-list get-authorized" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # optional authorized UID of the session. By providing this, the template list will include user-specific template categories (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> table<id: int, name: string, price: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templateCategories/list")
  let req_body = {"uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a New Template in the User’s Account
#
# POST /templates/create
# operationId: createTemplate
export def "templates-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. How do I love thee?  Let me count the ways
  --name: string # the new name of the template (e.g. My custom template)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> table<category_id: int, id: int, message: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/create")
  let req_body = {"message": $message, "name": $name, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a users template
#
# POST /templates/delete
# operationId: deleteTemplate
export def "templates-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-id: int # the ID of the template to delete (e.g. 12)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/delete")
  let req_body = {"template_id": $template_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List template categories
#
# GET /templates/list
# operationId: getTemplates
export def "templates-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category_id: int, id: int, message: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List template categories
#
# POST /templates/list
# operationId: getTemplatessAuthorized
export def "templates-list get-templatess-authorized" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # optional category to filter the templates (e.g. 12)
  --uid: string # optional authorized UID of the session. By providing this, the template list will include user-specific template categories (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> table<category_id: int, id: int, message: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/list")
  let req_body = {"category_id": $category_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an Existing Template in the User’s Account
#
# POST /templates/update
# operationId: updateTemplate
export def "templates-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. How do I love thee?  Let me count the ways
  --name: string # the new name of the template (e.g. My custom template)
  --template-id: int # the ID of the template to update (e.g. 12)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> table<category_id: int, id: int, message: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/update")
  let req_body = {"message": $message, "name": $name, "template_id": $template_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get all info on a template
#
# POST /templates/view
# operationId: getTemplateDetail
export def "templates-view get-detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-id: int # the ID of the template to view (e.g. 12)
  --uid: string # optional authorized UID of the session. By providing this, the user can specify user-sepecific templates (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> record<category_id: int, id: int, message: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/view")
  let req_body = {"template_id": $template_id, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
