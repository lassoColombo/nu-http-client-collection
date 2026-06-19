# Auto-generated client for link.fish API v2018-07-05
# Source: https://api.apis.guru/v2/specs/link.fish/2018-07-05/swagger.json
# Auth: --token flag or $env.LINK_FISH_API_TOKEN

const BASE_URL = "https://api.link.fish"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LINK_FISH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.link.fish"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def item-format-completer [] { ["flat" "normal"] }
def screenshot-completer [] { ["full" "none" "normal"] }
def screenshot-file-format-completer [] { ["jpg" "png"] }
def type-completer [] { ["full" "normal"] }
def file-format-completer [] { ["jpg" "png"] }
def accept-completer-1 [] { ["image/jpeg" "image/png"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "urls-apps get" } } | get name | first)
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

# Get mobile apps
#
# GET /Urls/apps
export def "urls-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL of the website to query
  --return-urls: oneof<nothing, bool> # Returns app URLs instead of the identifiers (default: false)
  --browser-render: oneof<nothing, bool> # If the page should be fully rendered with a browser to extract data. The request will then cost 5 credits instead of 1! (default: false)
]: nothing -> record<android: string, ios: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "return_urls" $return_urls "scalar") (serialize-qp "browser_render" $browser_render "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/apps" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "return_urls": $return_urls, "browser_render": $browser_render} | compact), body: null}
}

# Extract data (browser)
#
# GET /Urls/browser-data
export def "urls-browser-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL of the website to query
  --item-format: string@item-format-completer # If the items should be return "normal" with multiple levels or "flat" with just one level and linked instead. (default: normal)
  --simplify-special-types: oneof<nothing, bool> # Some types like "PropertyValue" do save key and value in separate properties which makes the data harder to process. If this option gets set it converts them automatically into the regular key -> value format. (default: false)
  --include-raw-html: oneof<nothing, bool> # Returns additionally also the raw HTML as property "rawHtml". (default: false)
  --screenshot: string@screenshot-completer # If and what kind of screenshot should be returned. Do only request screenshot generation when really needed because it will increase the response time significantly. (default: none)
  --screenshot-width: int # The widh of the screenshot in pixel. (default: 640)
  --screenshot-file-format: string@screenshot-file-format-completer # The file format of the screenshot (default: png)
]: nothing -> record<additionalData: record<locality: record<country: string, language: string>>, favicon: string, items: table<_type: string>, screenshot: string, statusCode: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "item_format" $item_format "scalar") (serialize-qp "simplify_special_types" $simplify_special_types "scalar") (serialize-qp "include_raw_html" $include_raw_html "scalar") (serialize-qp "screenshot" $screenshot "scalar") (serialize-qp "screenshot_width" $screenshot_width "scalar") (serialize-qp "screenshot_file_format" $screenshot_file_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/browser-data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "item_format": $item_format, "simplify_special_types": $simplify_special_types, "include_raw_html": $include_raw_html, "screenshot": $screenshot, "screenshot_width": $screenshot_width, "screenshot_file_format": $screenshot_file_format} | compact), body: null}
}

# Generate screenshot (browser)
#
# GET /Urls/browser-screenshot
export def "urls-browser-screenshot get" [
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
  --url: string # The URL of the website to create screenshot of
  --type: string@type-completer # What kind of screenshot should be returned. If it should be a regular 16:9 screenshot or one with the full page height (default: normal)
  --file-format: string@file-format-completer # The file format of the screenshot (default: png)
  --width: int # The widh of the screenshot in pixel. (default: 640)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "file_format" $file_format "scalar") (serialize-qp "width" $width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/browser-screenshot" $qp)
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "type": $type, "file_format": $file_format, "width": $width} | compact), body: null}
}

# Extract data
#
# GET /Urls/data
export def "urls-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL of the website to query
  --item-format: string@item-format-completer # If the items should be return "normal" with multiple levels or "flat" with just one level and linked instead. (default: normal)
  --simplify-special-types: oneof<nothing, bool> # Some types like "PropertyValue" do save key and value in separate properties which makes the data harder to process. If this option gets set it converts them automatically into the regular key -> value format. (default: false)
  --include-raw-html: oneof<nothing, bool> # Returns additionally also the raw HTML as property "rawHtml". (default: false)
  --browser-render: oneof<nothing, bool> # If the page should be fully rendered with a browser to extract data. The request will then cost 5 credits instead of 1! (default: false)
]: nothing -> record<additionalData: record<locality: record<country: string, language: string>>, favicon: string, items: table<_type: string>, statusCode: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "item_format" $item_format "scalar") (serialize-qp "simplify_special_types" $simplify_special_types "scalar") (serialize-qp "include_raw_html" $include_raw_html "scalar") (serialize-qp "browser_render" $browser_render "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "item_format": $item_format, "simplify_special_types": $simplify_special_types, "include_raw_html": $include_raw_html, "browser_render": $browser_render} | compact), body: null}
}

# Return data of JSON/XML
#
# GET /Urls/data-raw
export def "urls-data-raw get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL to get the data of
]: nothing -> record<data: record, sourceFormat: string, statusCode: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/data-raw" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url} | compact), body: null}
}

# Return tabular data
#
# GET /Urls/data-tabular
export def "urls-data-tabular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL to get the data of
  --selector: string # CSS selector to define tabular data which should get returned
  --browser-render: oneof<nothing, bool> # If the page should be fully rendered with a browser to extract data. The request will then cost 5 credits instead of 1! (default: false)
]: nothing -> record<data: record<data: list<list>, metadata: record>, statusCode: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "selector" $selector "scalar") (serialize-qp "browser_render" $browser_render "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/data-tabular" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "selector": $selector, "browser_render": $browser_render} | compact), body: null}
}

# Get geo coordinates
#
# GET /Urls/geo-coordinates
export def "urls-geo-coordinates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL of the website to query
  --browser-render: oneof<nothing, bool> # If the page should be fully rendered with a browser to extract data. The request will then cost 5 credits instead of 1! (default: false)
]: nothing -> record<latitude: float, longitude: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "browser_render" $browser_render "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/geo-coordinates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "browser_render": $browser_render} | compact), body: null}
}

# Get social media accounts
#
# GET /Urls/social-media
export def "urls-social-media get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The URL of the website to query
  --return-urls: oneof<nothing, bool> # Returns profile URLs instead of the profile names/ids (default: false)
  --browser-render: oneof<nothing, bool> # If the page should be fully rendered with a browser to extract data. The request will then cost 5 credits instead of 1! (default: false)
]: nothing -> record<facebookPage: string, githubUser: string, linkedInCompany: string, twitter: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "return_urls" $return_urls "scalar") (serialize-qp "browser_render" $browser_render "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Urls/social-media" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "return_urls": $return_urls, "browser_render": $browser_render} | compact), body: null}
}
