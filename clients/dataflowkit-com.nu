# Auto-generated client for Dataflow Kit Web Scraper v1.3
# Source: https://api.apis.guru/v2/specs/dataflowkit.com/1.3/openapi.json
# Auth: --token flag or $env.DATAFLOW_KIT_WEB_SCRAPER_TOKEN

const BASE_URL = "https://api.dataflowkit.com/v1"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATAFLOW_KIT_WEB_SCRAPER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://api.dataflowkit.com/v1"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def output-completer [] { ["buffer" "file"] }
def paper-size-completer [] { ["A3" "A4" "A5" "A6" "Legal" "Letter" "Tabloid"] }
def accept-completer [] { ["application/pdf" "text/plain; charset=utf-8"] }
def format-completer [] { ["jpeg" "png"] }
def accept-completer-1 [] { ["image/jpeg" "image/png" "text/plain; charset=utf-8"] }
def type-completer [] { ["base" "chrome"] }
def accept-completer-2 [] { ["text/html; charset=utf-8" "text/plain; charset=utf-8"] }
def format-completer-1 [] { ["csv" "excel" "json" "jsonl" "xml"] }
def accept-completer-3 [] { ["application/json" "application/x-ndjson" "text/csv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "convert-url-pdf create" } } | get name | first)
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

# Save web page as PDF
#
# POST /convert/url/pdf
# operationId: url-to-pdf
# --initialCookies item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
export def "convert-url-pdf create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --actions: list # Use actions to automate manual workflows while rendering web pages. They simulate real-world human interaction with pages. (default: [])
  --ignore-http-status-err-codes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initial-cookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --landscape: oneof<nothing, bool> # Paper orientation. Parameter landscape = false means portrait orientation. Set landscape to true for landscape page oriantation. (default: false)
  --margin-bottom: float # Bottom Margin of the PDF (in inches) (default: 0.4)
  --margin-left: float # Left Margin of the PDF (in inches) (default: 0.4)
  --margin-right: float # Right Margin of the PDF (in inches) (default: 0.4)
  --margin-top: float # Top Margin of the PDF (in inches) (default: 0.4)
  --output: string@output-completer # If set to _file_, the resulted PDF is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, PDF content is returned in the response body. (default: buffer)
  --page-ranges: string # Specify page ranges to convert. Defaults to the empty value, which means convert all pages. (e.g. 1-4, 6, 10-12)
  --paper-size: string@paper-size-completer # Page size parameter consists of the most popular page formats. (default: A4)
  --print-background: oneof<nothing, bool> # Print background graphics in the PDF. (default: false)
  --print-header-footer: oneof<nothing, bool> # printHeaderFooter parameter consists of the date, name of the web page, the page URL, and how many pages the document you are printing. (default: false)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  --scale: float # By default, PDF document content is generated according to dimensions of the original web page content. Using the `scale` parameter, you can specify a custom zoom factor from 0.1 to 5.0 of the webpage rendering. (default: 1)
  url: string # The full URL address (including HTTP/HTTPS) of a web page that you want to save as PDF
  --wait-delay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. (default: 0.5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/url/pdf")
  let req_body = {"actions": $actions, "ignoreHTTPStatusErrCodes": $ignore_http_status_err_codes, "initialCookies": $initial_cookies, "landscape": $landscape, "marginBottom": $margin_bottom, "marginLeft": $margin_left, "marginRight": $margin_right, "marginTop": $margin_top, "output": $output, "pageRanges": $page_ranges, "paperSize": $paper_size, "printBackground": $print_background, "printHeaderFooter": $print_header_footer, "proxy": $proxy, "scale": $scale, "url": $url, "waitDelay": $wait_delay} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Capture web page Screenshots.
#
# POST /convert/url/screenshot
# operationId: url-to-screenshot
# --initialCookies item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
export def "convert-url-screenshot create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --actions: list # Use actions to automate manual workflows while rendering web pages. They simulate real-world human interaction with pages. (default: [])
  --clip-selector: string # Captures a screenshot of specified CSS element on a web page. (e.g. #css-element)
  --format: string@format-completer # Sets the Format of output image (default: png)
  --full-page: oneof<nothing, bool> # takes a screenshot of a full web page. It ignores offsetX, offsety, width and height argument values. (default: false)
  --height: int # Rectangle height in device independent pixels (dip). (default: 600)
  --ignore-http-status-err-codes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initial-cookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --offsetx: int # X offset in device independent pixels (dip). (default: 0)
  --offsety: int # Y offset in device independent pixels (dip). (default: 0)
  --output: string@output-completer # If set to _file_, the resulted screenshot is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, web site screenshot is returned in the response body. (default: buffer)
  --print-background: oneof<nothing, bool> # Print background graphics in the PDF. (default: false)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  --quality: int # Sets the Quality of output image. Compression quality from range [0..100] (jpeg only). (default: 80)
  --scale: float # Image scale factor. range [0.1 .. 3] (default: 1)
  url: string # The full URL address (including HTTP/HTTPS) of a web page that you want to capture
  --wait-delay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. (default: 0.5)
  --width: int # Rectangle width in device independent pixels (dip). (default: 800)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/url/screenshot")
  let req_body = {"actions": $actions, "clipSelector": $clip_selector, "format": $format, "fullPage": $full_page, "height": $height, "ignoreHTTPStatusErrCodes": $ignore_http_status_err_codes, "initialCookies": $initial_cookies, "offsetx": $offsetx, "offsety": $offsety, "output": $output, "printBackground": $print_background, "proxy": $proxy, "quality": $quality, "scale": $scale, "url": $url, "waitDelay": $wait_delay, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "image/jpeg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Download web page content
#
# POST /fetch
# operationId: fetch
# --initialCookies item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
export def "fetch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --actions: list # Use actions to automate manual workflows while rendering web pages. They simulate real-world human interaction with pages. _(Chrome fetcher type only)_ (default: [])
  --ignore-http-status-err-codes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initial-cookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --output: string@output-completer # If set to _file_, the content of downloaded HTML is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, downloaded content is returned in the response body. (default: buffer)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-sk)
  type: string@type-completer # If set to `base`, the Base fetcher is used for downloading web page content. Use `chrome` for fetching content with a Headless chrome browser. If omitted `base` fetcher is used by default.
  url: string # Specify URL to download.
  --wait-delay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. _(Chrome fetcher type only)_
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch")
  let req_body = {"actions": $actions, "ignoreHTTPStatusErrCodes": $ignore_http_status_err_codes, "initialCookies": $initial_cookies, "output": $output, "proxy": $proxy, "type": $type, "url": $url, "waitDelay": $wait_delay} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "text/html; charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Extract structured data from web pages
#
# POST /parse
# operationId: parse
# --fields item shape: {attrs: list<string>, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
# --paginator shape: {nextPageSelector?: string, pageNum?: int}
# --request shape: {actions?: list, ignoreHTTPStatusErrCodes?: bool, initialCookies?: list, output?: "buffer"|"file", proxy?: string, type: "base"|"chrome", url: string, waitDelay?: float}
export def "parse create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --common-parent: string # Specifies common ancestor block for a set of fields used to extract data from a web page. _(CSS Selector)_ (e.g. .common-block)
  fields: list # Define a set of fields used to extract data from a web page. A Field represents a given chunk of extracted data from every block on each page. — item shape: {attrs: list<string>, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
  format: string@format-completer-1 # Extracted data is returned either in CSV, MS Excel, JSON, JSON(Lines) or XML format.
  name: string # Collection name.
  --paginator: record # Specify _Next link_ paginator on pages containing a link pointing to the next page. The next page link is extracted from a document by querying href attribute of a given element's CSS selector. — shape: {nextPageSelector?: string, pageNum?: int}
  --path: oneof<nothing, bool> # Path is a special parameter specifying navigation pages only. It collects information from detailed pages. No results from the current page return. Defaults to false. (default: false)
  --request: record # e.g. {actions: [{waitFor: {waitForSelector: :root}}], output: buffer, proxy: country-any, type: base, url: https://ipapi.co/json/} — shape: {actions?: list, ignoreHTTPStatusErrCodes?: bool, initialCookies?: list, output?: "buffer"|"file", proxy?: string, type: "base"|"chrome", url: string, waitDelay?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parse")
  let req_body = {"commonParent": $common_parent, "fields": $fields, "format": $format, "name": $name, "paginator": $paginator, "path": $path, "request": $request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Collect search results from search engines
#
# POST /serp
# operationId: serp
# --fields item shape: {attrs: list<string>, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
export def "serp create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --fields: list # Specify CSS selectors (patterns) used to gather data from Search Engine Result Pages. Ready-to-use payloads for collecting search results from the most popular Search Engines are available. These payloads are customizable, though. — item shape: {attrs: list<string>, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
  format: string@format-completer-1 # Extracted data is returned either in CSV, MS Excel, JSON, JSON(Lines) or XML format.
  name: string # Collection name.
  --page-num: int # Specify number of pages to crawl. (default: 1)
  proxy: string # Always specify proxy for sending SERP requests. Add choosen [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  type: string # For SERP requests you should _always_ use `chrome` type to fetch content with a Headless chrome browser (e.g. chrome)
  url: string # url holds the link to a Search Engine to use, and other optional parameters like languages or country.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/serp")
  let req_body = {"fields": $fields, "format": $format, "name": $name, "pageNum": $page_num, "proxy": $proxy, "type": $type, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
