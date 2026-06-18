# Auto-generated client for Browshot API v1.17.0
# Source: https://api.apis.guru/v2/specs/browshot.com/1.17.0/swagger.json
# Auth: --token flag or $env.BROWSHOT_API_TOKEN

const BASE_URL = "https://api.browshot.com/api/v1"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BROWSHOT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-key" => { {headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)"} }
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

def base-url-completer [] { ["https://api.browshot.com/api/v1"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def hosting-completer [] { ["s3"] }
def size-completer [] { ["page" "screen"] }
def format-completer [] { ["jpeg" "png"] }
def hosting-completer-1 [] { ["browshot" "s3"] }
def status-completer [] { ["error" "finished" "in_process"] }
def ratio-completer [] { ["fill" "fit"] }
def accept-completer [] { ["image/jpeg" "image/png"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-info get" } } | get name | first)
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

# Get information about your account
#
# GET /account/info
# operationId: GetAccountInfo
export def "account-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: int # level of information returned (default: 1)
]: nothing -> record<balance: int, browsers: table<flash: int, id: int, javascript: int, mobile: int, name: string>, free_screenshots_left: int, hosting_browshot: int, instances: table<browser: record, country: string, height: int, id: int, load: float, screenshot_cost: int, type: string, width: int>, private_instances: int, screenshots: table<cookie: string, cost: int, delay: int, details: int, error: string, final_url: string, flash_delay: int, height: int, id: int, instance_id: int, post_data: string, priority: int, referer: string, scale: float, screenshot_url: any, script: string, shared_url: string, size: string, status: string, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Requests thousands of screenshtos at once
#
# POST /batch/ceate
# operationId: CreateBatch
export def "batch-ceate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hosting: string@hosting-completer # hosting option - s3 or browshot
  --hosting-height: int # maximum height of the thumbnail to host
  --hosting-width: int # maximum height of the thumbnail to host
  --hosting-scale: float # scale of the thumbnail to host (format: float, default: 1)
  --hosting-bucket: string # S3 bucket to upload the screenshot or thumbnail (required for S3)
  --hosting-file: string # file name to use (for S3 only)
  --hosting-headers: string # list of headers to add to the S3 object (for S3 only)
  instance_id: int # instance ID to use
  --file: path # text file to use
  --size: string@size-completer # screenshots size - "screen" (default) or "page"
  --name: string # name of the batch
  --width: int # thumbnail width.
  --height: int # thumbnail height
  --delay: int # number of seconds to wait after the page has loaded. This is used to let JavaScript run longer before taking the screenshot. Use delay=0 to take screenshots faster.
  --flash-delay: int # number of seconds to wait after the page has loaded if Flash elements are present. Use flash_delay=0 to take screenshots faster.
  --screen-width: int # width of the browser window. For desktop browsers only.
  --screen-height: int # height of the browser window. For desktop browsers only. (Note: full-page screenshots can have a height of up to 15,000px)
  --priority: int # assign priority to the screenshot (for private instances only)
  --referer: string # use a custom referrer header - paid screenshots only
  --post-data: string # send a POST requests with post_data, useful for filling out forms - paid screenshots only
  --cookie: string # set a cookie for the URL requested (see Custom POST Data, Referer and Cookie) Cookies should be separated by a ; - paid screenshots only
  --script: string # URL of javascript file to execute after the page load event
  --details: int # level of information available with screenshot/info
  --html: int # saves the HTML of the rendered page which can be retrieved by the API call screenshot/html. This feature costs *1 credit* per screenshot.
  --max-wait: int # maximum number of seconds to wait before triggering the PageLoad event. Note that delay will still be used. (default: 0 = disabled)
  --headers: string # any custom HTTP headers. (Not supported with Internet Explorer)
  --format: string@format-completer # image as PNG or JPEG
]: any -> table<count: int, failed: int, finished: int, id: int, processed: int, started: int, status: string, urls: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hosting" $hosting "scalar") (serialize-qp "hosting_height" $hosting_height "scalar") (serialize-qp "hosting_width" $hosting_width "scalar") (serialize-qp "hosting_scale" $hosting_scale "scalar") (serialize-qp "hosting_bucket" $hosting_bucket "scalar") (serialize-qp "hosting_file" $hosting_file "scalar") (serialize-qp "hosting_headers" $hosting_headers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch/ceate" $qp)
  let req_body = {"instance_id": $instance_id, "file": $file, "size": $size, "name": $name, "width": $width, "height": $height, "delay": $delay, "flash_delay": $flash_delay, "screen_width": $screen_width, "screen_height": $screen_height, "priority": $priority, "referer": $referer, "post_data": $post_data, "cookie": $cookie, "script": $script, "details": $details, "html": $html, "max_wait": $max_wait, "headers": $headers, "format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get the batch status
#
# GET /batch/info
# operationId: GetBatchInfo
export def "batch-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # batch ID
]: nothing -> record<count: int, failed: int, finished: int, id: int, processed: int, started: int, status: string, urls: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get information about a browser
#
# GET /browser/info
# operationId: GetBrowserInfo
export def "browser-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # browser ID
]: nothing -> record<flash: int, id: int, javascript: int, mobile: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all browsers
#
# GET /browser/list
# operationId: GetBrowsersInfo
export def "browser-list get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<default: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/browser/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get information about an instance
#
# GET /instance/info
# operationId: GetInstanceInfo
export def "instance-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # instance ID
]: nothing -> record<browser: record<flash: int, id: int, javascript: int, mobile: int, name: string>, country: string, height: int, id: int, load: float, screenshot_cost: int, type: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/instance/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all instances
#
# GET /instance/list
# operationId: GetInstancesInfo
export def "instance-list get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<free: table<browser: record, country: string, height: int, id: int, load: float, screenshot_cost: int, type: string, width: int>, private: table<browser: record, country: string, height: int, id: int, load: float, screenshot_cost: int, type: string, width: int>, shared: table<browser: record, country: string, height: int, id: int, load: float, screenshot_cost: int, type: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Request a screenshot
#
# GET /screenshot/create
# operationId: CreateScreenshot
export def "screenshot-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL of the page to get a screenshot for
  --instance-id: int # instance ID to use
  --size: string@size-completer # screenshot size - "screen" (default) or "page" (default: screen)
  --cache: int # use a previous screenshot (same URL, same instance) if it was done within <cache_value> seconds. The default value is 24hours. Specify cache=0 if you want a new screenshot. (default: 86400)
  --delay: int # number of seconds to wait after the page has loaded. This is used to let JavaScript run longer before taking the screenshot. Use delay=0 to take screenshots faster. (default: 5)
  --flash-delay: int # number of seconds to wait after the page has loaded if Flash elements are present. Use flash_delay=0 to take screenshots faster. (default: 10)
  --screen-width: int # width of the browser window. For desktop browsers only. (default: 1024)
  --screen-height: int # height of the browser window. For desktop browsers only. (Note: full-page screenshots can have a height of up to 15,000px) (default: 768)
  --priority: int # assign priority to the screenshot (for private instances only)
  --referer: string # use a custom referrer header - paid screenshots only
  --post-data: string # send a POST requests with post_data, useful for filling out forms - paid screenshots only
  --cookie: string # set a cookie for the URL requested (see Custom POST Data, Referer and Cookie) Cookies should be separated by a ; - paid screenshots only
  --script: string # URL of javascript file to execute after the page load event
  --details: int # level of information available with screenshot/info (default: 2)
  --html: int # saves the HTML of the rendered page which can be retrieved by the API call screenshot/html. This feature costs *1 credit* per screenshot. (default: 0)
  --max-wait: int # maximum number of seconds to wait before triggering the PageLoad event. Note that delay will still be used. (default: 0 = disabled) (default: 0)
  --headers: string # any custom HTTP headers. (Not supported with Internet Explorer)
  --shots: int # take multiple screenshots of the same page. This costs 1 additional credit for every 2 additional screenshots. (default: 1)
  --shot-interval: int # number of seconds between 2 screenshots (default: 5)
  --hosting: string@hosting-completer-1 # hosting option - s3 or browshot
  --hosting-height: int # maximum height of the thumbnail to host
  --hosting-width: int # maximum height of the thumbnail to host
  --hosting-scale: float # scale of the thumbnail to host (format: float, default: 1)
  --hosting-bucket: string # S3 bucket to upload the screenshot or thumbnail (required for S3)
  --hosting-file: string # file name to use (for S3 only)
  --hosting-headers: string # list of headers to add to the S3 object (for S3 only)
]: nothing -> record<cookie: string, cost: int, delay: int, details: int, error: string, final_url: string, flash_delay: int, height: int, id: int, instance_id: int, post_data: string, priority: int, referer: string, scale: float, screenshot_url: any, script: string, shared_url: string, size: string, status: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "instance_id" $instance_id "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "cache" $cache "scalar") (serialize-qp "delay" $delay "scalar") (serialize-qp "flash_delay" $flash_delay "scalar") (serialize-qp "screen_width" $screen_width "scalar") (serialize-qp "screen_height" $screen_height "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "referer" $referer "scalar") (serialize-qp "post_data" $post_data "scalar") (serialize-qp "cookie" $cookie "scalar") (serialize-qp "script" $script "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "html" $html "scalar") (serialize-qp "max_wait" $max_wait "scalar") (serialize-qp "headers" $headers "scalar") (serialize-qp "shots" $shots "scalar") (serialize-qp "shot_interval" $shot_interval "scalar") (serialize-qp "hosting" $hosting "scalar") (serialize-qp "hosting_height" $hosting_height "scalar") (serialize-qp "hosting_width" $hosting_width "scalar") (serialize-qp "hosting_scale" $hosting_scale "scalar") (serialize-qp "hosting_bucket" $hosting_bucket "scalar") (serialize-qp "hosting_file" $hosting_file "scalar") (serialize-qp "hosting_headers" $hosting_headers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete screenshot data
#
# GET /screenshot/delete
# operationId: DeleteScreenshot
export def "screenshot-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # screenshot ID
  --data: string # data to remove. You can specify multiple of them (separated by a ,): *image* (image files), *url* (url requested), *metadata* (time added, time finished, post data, cookie and referer used for the screenshot), *all* (all data and files) (default: image)
]: nothing -> table<id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Host thumbnails on your own S3 account or on Browshot.
#
# GET /screenshot/host
# operationId: HostScreenshot
export def "screenshot-host get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # screenshot ID
  --hosting: string@hosting-completer-1 # hosting option: s3 or browshot
  --width: int # width of the thumbnail
  --height: int # height of the thumbnail
  --scale: float # scale of the thumbnail (format: double, default: 1)
  --bucket: string # S3 bucket to upload the screenshot or thumbnail - required with hosting=s3
  --file: string # file name to use - optional, used with hosting=s3
  --headers: string # HTTP headers to add to your S3 object - optional, used with hosting=s3
]: nothing -> table<id: int, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "hosting" $hosting "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "headers" $headers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/host" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the HTML code
#
# GET /screenshot/html
# operationId: GetHTML
export def "screenshot-html get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # screenshot ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/html" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query screenshot status
#
# GET /screenshot/info
# operationId: GetScreenshotInfo
export def "screenshot-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # screenshot ID received from /api/v1/screenshot/create
  --details: int # level of details about the screenshot and the page (default: 2)
]: nothing -> table<cookie: string, cost: int, delay: int, details: int, error: string, final_url: string, flash_delay: int, height: int, id: int, instance_id: int, post_data: string, priority: int, referer: string, scale: float, screenshot_url: any, script: string, shared_url: string, size: string, status: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get information about screenshots
#
# GET /screenshot/list
# operationId: GetMultipleScreenshotsInfo
export def "screenshot-list get-multiple-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum number of screenshots' information to return (default: 100)
  --status: string@status-completer # get list of screenshot in a given status (error, finished, in_process)
]: nothing -> table<default: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Request multiple screenshots
#
# GET /screenshot/multiple
# operationId: CreateMultipleScreenshots
export def "screenshot-multiple create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL of the page to get a screenshot for. You can specify multiple url parameters (up to 10).
  --instance-id: int # instance ID to use. You can specify multiple instance_id parameters (up to 10).
  --size: string@size-completer # screenshot size - "screen" (default) or "page" (default: screen)
  --cache: int # use a previous screenshot (same URL, same instance) if it was done within <cache_value> seconds. The default value is 24hours. Specify cache=0 if you want a new screenshot. (default: 86400)
  --delay: int # number of seconds to wait after the page has loaded. This is used to let JavaScript run longer before taking the screenshot. Use delay=0 to take screenshots faster. (default: 5)
  --flash-delay: int # number of seconds to wait after the page has loaded if Flash elements are present. Use flash_delay=0 to take screenshots faster. (default: 10)
  --screen-width: int # width of the browser window. For desktop browsers only. (default: 1024)
  --screen-height: int # height of the browser window. For desktop browsers only. (Note: full-page screenshots can have a height of up to 15,000px) (default: 768)
  --priority: int # assign priority to the screenshot (for private instances only)
  --referer: string # use a custom referrer header - paid screenshots only
  --post-data: string # send a POST requests with post_data, useful for filling out forms - paid screenshots only
  --cookie: string # set a cookie for the URL requested (see Custom POST Data, Referer and Cookie) Cookies should be separated by a ; - paid screenshots only
  --script: string # URL of javascript file to execute after the page load event
  --details: int # level of information available with screenshot/info (default: 2)
  --html: int # saves the HTML of the rendered page which can be retrieved by the API call screenshot/html. This feature costs *1 credit* per screenshot. (default: 0)
  --max-wait: int # maximum number of seconds to wait before triggering the PageLoad event. Note that delay will still be used. (default: 0 = disabled) (default: 0)
  --headers: string # any custom HTTP headers. (Not supported with Internet Explorer)
  --hosting: string@hosting-completer-1 # hosting option - s3 or browshot
  --hosting-height: int # maximum height of the thumbnail to host
  --hosting-width: int # maximum height of the thumbnail to host
  --hosting-scale: float # scale of the thumbnail to host (format: float, default: 1)
  --hosting-bucket: string # S3 bucket to upload the screenshot or thumbnail (required for S3)
  --hosting-file: string # file name to use (for S3 only)
  --hosting-headers: string # list of headers to add to the S3 object (for S3 only)
]: nothing -> record<default: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "instance_id" $instance_id "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "cache" $cache "scalar") (serialize-qp "delay" $delay "scalar") (serialize-qp "flash_delay" $flash_delay "scalar") (serialize-qp "screen_width" $screen_width "scalar") (serialize-qp "screen_height" $screen_height "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "referer" $referer "scalar") (serialize-qp "post_data" $post_data "scalar") (serialize-qp "cookie" $cookie "scalar") (serialize-qp "script" $script "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "html" $html "scalar") (serialize-qp "max_wait" $max_wait "scalar") (serialize-qp "headers" $headers "scalar") (serialize-qp "hosting" $hosting "scalar") (serialize-qp "hosting_height" $hosting_height "scalar") (serialize-qp "hosting_width" $hosting_width "scalar") (serialize-qp "hosting_scale" $hosting_scale "scalar") (serialize-qp "hosting_bucket" $hosting_bucket "scalar") (serialize-qp "hosting_file" $hosting_file "scalar") (serialize-qp "hosting_headers" $hosting_headers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/multiple" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search for screenshots
#
# GET /screenshot/search
# operationId: SearchScreenshot
export def "screenshot-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # look for a string matching the URL requested
  --limit: int # maximum number of screenshots' information to return (default: 50)
  --status: string@status-completer # get list of screenshot in a given status (error, finished, in_process)
]: nothing -> table<default: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Share a screenshot
#
# GET /screenshot/share
# operationId: ShareScreenshot
export def "screenshot-share get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # screenshot ID
  --note: string # note to add on the sharing page
]: nothing -> table<id: int, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "note" $note "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/share" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve a thumbnail image
#
# GET /screenshot/thumbnail
# operationId: GetThumbnail
export def "screenshot-thumbnail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # screenshot ID
  --width: int # width of the thumbnail
  --height: int # height of the thumbnail
  --scale: float # scale of the thumbnail (format: double, default: 1)
  --zoom: int # zoom 1 to 100 percent (default: 100)
  --ratio: string@ratio-completer # Use fit to keep the original page ration, and fill to get a thumbnail for the exact width and height. specified. If you provide both width and height, you need to specify the ratio: fit to keep the original width/height ratio (the thumbnail might be smaller than the specified width and height), or fill to crop the image if necessary. (default: fit)
  --left: int # left edge of the area to be cropped (default: 0)
  --right: int # right edge of the area to be cropped (default: 0)
  --top: int # top edge of the area to be cropped (default: 0)
  --bottom: int # bottom edge of the area to be cropped
  --format: string@format-completer # image as PNG or JPEG (default: png)
  --shot: int # get the second or third screenshot if multiple screenshots were requested (default: 1)
  --quality: int # JPEG quality factor (for JPEG thumbnails only) (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "zoom" $zoom "scalar") (serialize-qp "ratio" $ratio "scalar") (serialize-qp "left" $left "scalar") (serialize-qp "right" $right "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "bottom" $bottom "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "shot" $shot "scalar") (serialize-qp "quality" $quality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot/thumbnail" $qp)
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
