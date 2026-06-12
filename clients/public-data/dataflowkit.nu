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
def paperSize-completer [] { ["A3" "A4" "A5" "A6" "Legal" "Letter" "Tabloid"] }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "convert-url-pdf url-to-pdf" } } | get name | first)
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
export def "convert-url-pdf url-to-pdf" [
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
  --ignoreHTTPStatusErrCodes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initialCookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --landscape: oneof<nothing, bool> # Paper orientation. Parameter landscape = false means portrait orientation. Set landscape to true for landscape page oriantation. (default: false)
  --marginBottom: float # Bottom Margin of the PDF (in inches) (default: 0.4)
  --marginLeft: float # Left Margin of the PDF (in inches) (default: 0.4)
  --marginRight: float # Right Margin of the PDF (in inches) (default: 0.4)
  --marginTop: float # Top Margin of the PDF (in inches) (default: 0.4)
  --output: string@output-completer # If set to _file_, the resulted PDF is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, PDF content is returned in the response body. (default: buffer)
  --pageRanges: string # Specify page ranges to convert. Defaults to the empty value, which means convert all pages. (e.g. 1-4, 6, 10-12)
  --paperSize: string@paperSize-completer # Page size parameter consists of the most popular page formats. (default: A4)
  --printBackground: oneof<nothing, bool> # Print background graphics in the PDF. (default: false)
  --printHeaderFooter: oneof<nothing, bool> # printHeaderFooter  parameter consists of the date, name of the web page, the page URL, and how many pages the document you are printing. (default: false)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  --scale: float # By default, PDF document content is generated according to dimensions of the original web page content. Using the `scale` parameter, you can specify a custom zoom factor from 0.1 to 5.0 of the webpage rendering. (default: 1)
  --body-url: string # The full URL address (including HTTP/HTTPS) of a web page that you want to save as PDF
  --waitDelay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. (default: 0.5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/url/pdf")
  let body = {actions: $actions, ignoreHTTPStatusErrCodes: $ignoreHTTPStatusErrCodes, initialCookies: $initialCookies, landscape: $landscape, marginBottom: $marginBottom, marginLeft: $marginLeft, marginRight: $marginRight, marginTop: $marginTop, output: $output, pageRanges: $pageRanges, paperSize: $paperSize, printBackground: $printBackground, printHeaderFooter: $printHeaderFooter, proxy: $proxy, scale: $scale, url: $body_url, waitDelay: $waitDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Capture web page Screenshots.
#
# POST /convert/url/screenshot
# operationId: url-to-screenshot
# --initialCookies item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
export def "convert-url-screenshot url-to-screenshot" [
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
  --clipSelector: string # Captures a screenshot of specified CSS element on a web page. (e.g. #css-element)
  --format: string@format-completer # Sets the Format of output image (default: png)
  --fullPage: oneof<nothing, bool> # takes a screenshot of a full web page. It ignores offsetX, offsety, width and height argument values. (default: false)
  --height: int # Rectangle height in device independent pixels (dip). (default: 600)
  --ignoreHTTPStatusErrCodes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initialCookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --offsetx: int # X offset in device independent pixels (dip). (default: 0)
  --offsety: int # Y offset in device independent pixels (dip). (default: 0)
  --output: string@output-completer # If set to _file_, the resulted screenshot is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, web site screenshot is returned in the response body. (default: buffer)
  --printBackground: oneof<nothing, bool> # Print background graphics in the PDF. (default: false)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  --quality: int # Sets the Quality of output image. Compression quality from range [0..100] (jpeg only). (default: 80)
  --scale: float # Image scale factor. range [0.1 .. 3] (default: 1)
  --body-url: string # The full URL address (including HTTP/HTTPS) of a web page that you want to capture
  --waitDelay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. (default: 0.5)
  --width: int # Rectangle width in device independent pixels (dip). (default: 800)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/url/screenshot")
  let body = {actions: $actions, clipSelector: $clipSelector, format: $format, fullPage: $fullPage, height: $height, ignoreHTTPStatusErrCodes: $ignoreHTTPStatusErrCodes, initialCookies: $initialCookies, offsetx: $offsetx, offsety: $offsety, output: $output, printBackground: $printBackground, proxy: $proxy, quality: $quality, scale: $scale, url: $body_url, waitDelay: $waitDelay, width: $width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "image/jpeg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download web page content
#
# POST /fetch
# operationId: fetch
# --initialCookies item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
export def "fetch fetch" [
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
  --ignoreHTTPStatusErrCodes: oneof<nothing, bool> # The HTTP 200 OK success status response code indicates that the request has succeeded. Sometimes a server returns normal HTML content even with an erroneous Non-200 HTTP response status code. The IgnoreHTTPStatusCode option is useful when you need to force the return of HTML content. Defaults to "false."
  --initialCookies: list # The "Initial Cookies" option is useful for crawling websites that require a login. The simplest solution to get an array of cookies for specific websites is to use a web browser "EditThisCookie" extension. Copy a cookie array with "EditThisCookie" and paste it into the "Initial cookie" field. (default: []) — item shape: {domain?: string, expirationDate?: float, hostOnly?: bool, httpOnly?: bool, id?: float, name?: string, path?: string, sameSite?: "unspecified"|"strict"|"lax"|"no_restriction", secure?: bool, session?: bool, storeID?: string, value?: string}
  --output: string@output-completer # If set to _file_, the content of downloaded HTML is uploaded to Dataflow Kit Storage first. Then the link to this file is returned. Overwise, downloaded content is returned in the response body. (default: buffer)
  --proxy: string # Specify proxy by adding [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-sk)
  type: string@type-completer # If set to `base`, the Base fetcher is used for downloading web page content. Use `chrome` for fetching content with a Headless chrome browser. If omitted `base` fetcher is used by default.
  --body-url: string # Specify URL to download.
  --waitDelay: float # Specify a wait delay (in seconds). This may be useful if certain elements of the web site need to be rendered after the initial page load. _(Chrome fetcher type only)_
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch")
  let body = {actions: $actions, ignoreHTTPStatusErrCodes: $ignoreHTTPStatusErrCodes, initialCookies: $initialCookies, output: $output, proxy: $proxy, type: $type, url: $body_url, waitDelay: $waitDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/html; charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Extract structured data from web pages
#
# POST /parse
# operationId: parse
# --fields item shape: {attrs: list, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
# --paginator shape: {nextPageSelector?: string, pageNum?: int}
# --request shape: {actions?: list, ignoreHTTPStatusErrCodes?: bool, initialCookies?: list, output?: "buffer"|"file", proxy?: string, type: "base"|"chrome", url: string, waitDelay?: float}
export def "parse parse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commonParent: string # Specifies common ancestor block for a set of fields used to extract data from a web page. _(CSS Selector)_ (e.g. .common-block)
  --body-fields: list # Define a  set of fields used to extract data from a web page. A Field represents a given chunk of extracted data from every block on each page. — item shape: {attrs: list, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
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
  let body = {commonParent: $commonParent, fields: $body_fields, format: $format, name: $name, paginator: $paginator, path: $path, request: $request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Collect search results from search engines
#
# POST /serp
# operationId: serp
# --fields item shape: {attrs: list, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
export def "serp serp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --body-fields: list # Specify CSS selectors (patterns) used to gather data from Search Engine Result Pages.  Ready-to-use payloads for collecting search results from the most popular Search Engines are available. These payloads are customizable, though. — item shape: {attrs: list, details?: any, filters?: list, name: string, selector: string, type: "0"|"1"|"2"}
  format: string@format-completer-1 # Extracted data is returned either in CSV, MS Excel, JSON, JSON(Lines) or XML format.
  name: string # Collection name.
  --pageNum: int # Specify number of pages to crawl. (default: 1)
  proxy: string # Always specify proxy for sending SERP requests. Add choosen [country ISO code](https://en.wikipedia.org/wiki/ISO_3166-2) to `country-` value to send requests through a proxy in the specified country. Use `country-any` to use random geo-targets. (e.g. country-any)
  type: string # For SERP requests you should _always_ use `chrome` type to fetch content with a Headless chrome browser (e.g. chrome)
  --body-url: string # url holds the link to a Search Engine to use, and other optional parameters like languages or country.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/serp")
  let body = {fields: $body_fields, format: $format, name: $name, pageNum: $pageNum, proxy: $proxy, type: $type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
