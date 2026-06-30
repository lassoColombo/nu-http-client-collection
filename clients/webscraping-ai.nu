# Auto-generated client for WebScraping.AI v2.0.7
# Source: https://api.apis.guru/v2/specs/webscraping.ai/2.0.7/openapi.json
# Auth: --token flag or $env.WEBSCRAPING_AI_TOKEN

const BASE_URL = "https://api.webscraping.ai"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o WEBSCRAPING_AI_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.webscraping.ai"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def proxy-completer [] { ["datacenter" "residential"] }
def country-completer [] { ["ca" "de" "es" "fr" "gb" "it" "jp" "kr" "ru" "us"] }
def device-completer [] { ["desktop" "mobile" "tablet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Information about your account calls quota
#
# GET /account
# operationId: account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<remaining_api_calls: int, remaining_concurrency: int, resets_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let accept_val = "application/json"
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

# Page HTML by URL
#
# GET /html
# operationId: getHTML
export def "html get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL of the target page (e.g. https://example.com)
  --headers: record # HTTP headers to pass to the target page. Can be specified either via a nested query parameter (...&headers[One]=value1&headers=[Another]=value2) or as a JSON encoded object (...&headers={"One": "value1", "Another": "value2"}) (e.g. {"Cookie":"session=some_id"})
  --timeout: int # Maximum processing time in ms. Increase it in case of timeout errors (10000 by default, maximum is 30000) (default: 10000, e.g. 10000)
  --js: oneof<nothing, bool> # Execute on-page JavaScript using a headless browser (true by default) (default: true, e.g. true)
  --js-timeout: int # Maximum JavaScript rendering time in ms. Increase it in case if you see a loading indicator instead of data on the target page. (default: 2000, e.g. 2000)
  --proxy: string@proxy-completer # Type of proxy, use residential proxies if your site restricts traffic from datacenters (datacenter by default). Note that residential proxy requests are more expensive than datacenter, see the pricing page for details. (default: datacenter, e.g. datacenter)
  --country: string@country-completer # Country of the proxy to use (US by default). Only available on Startup and Custom plans. (default: us, e.g. us)
  --device: string@device-completer # Type of device emulation. (default: desktop, e.g. desktop)
  --error-on-404: oneof<nothing, bool> # Return error on 404 HTTP status on the target page (false by default). (default: false, e.g. false)
  --error-on-redirect: oneof<nothing, bool> # Return error on redirect on the target page (false by default). (default: false, e.g. false)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/html" $qp $auth.query)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"url": $url, "headers": $headers, "timeout": $timeout, "js": $js, "js_timeout": $js_timeout, "proxy": $proxy, "country": $country, "device": $device, "error_on_404": $error_on_404, "error_on_redirect": $error_on_redirect} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# HTML of a selected page area by URL and CSS selector
#
# GET /selected
# operationId: getSelected
export def "selected get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --selector: string # CSS selector (null by default, returns whole page HTML) (e.g. h1)
  --url: string # URL of the target page (e.g. https://example.com)
  --headers: record # HTTP headers to pass to the target page. Can be specified either via a nested query parameter (...&headers[One]=value1&headers=[Another]=value2) or as a JSON encoded object (...&headers={"One": "value1", "Another": "value2"}) (e.g. {"Cookie":"session=some_id"})
  --timeout: int # Maximum processing time in ms. Increase it in case of timeout errors (10000 by default, maximum is 30000) (default: 10000, e.g. 10000)
  --js: oneof<nothing, bool> # Execute on-page JavaScript using a headless browser (true by default) (default: true, e.g. true)
  --js-timeout: int # Maximum JavaScript rendering time in ms. Increase it in case if you see a loading indicator instead of data on the target page. (default: 2000, e.g. 2000)
  --proxy: string@proxy-completer # Type of proxy, use residential proxies if your site restricts traffic from datacenters (datacenter by default). Note that residential proxy requests are more expensive than datacenter, see the pricing page for details. (default: datacenter, e.g. datacenter)
  --country: string@country-completer # Country of the proxy to use (US by default). Only available on Startup and Custom plans. (default: us, e.g. us)
  --device: string@device-completer # Type of device emulation. (default: desktop, e.g. desktop)
  --error-on-404: oneof<nothing, bool> # Return error on 404 HTTP status on the target page (false by default). (default: false, e.g. false)
  --error-on-redirect: oneof<nothing, bool> # Return error on redirect on the target page (false by default). (default: false, e.g. false)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "selector" $selector "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/selected" $qp $auth.query)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"selector": $selector, "url": $url, "headers": $headers, "timeout": $timeout, "js": $js, "js_timeout": $js_timeout, "proxy": $proxy, "country": $country, "device": $device, "error_on_404": $error_on_404, "error_on_redirect": $error_on_redirect} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# HTML of multiple page areas by URL and CSS selectors
#
# GET /selected-multiple
# operationId: getSelectedMultiple
export def "selected-multiple get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --selectors: list<string> # Multiple CSS selectors (null by default, returns whole page HTML) (e.g. [h1])
  --url: string # URL of the target page (e.g. https://example.com)
  --headers: record # HTTP headers to pass to the target page. Can be specified either via a nested query parameter (...&headers[One]=value1&headers=[Another]=value2) or as a JSON encoded object (...&headers={"One": "value1", "Another": "value2"}) (e.g. {"Cookie":"session=some_id"})
  --timeout: int # Maximum processing time in ms. Increase it in case of timeout errors (10000 by default, maximum is 30000) (default: 10000, e.g. 10000)
  --js: oneof<nothing, bool> # Execute on-page JavaScript using a headless browser (true by default) (default: true, e.g. true)
  --js-timeout: int # Maximum JavaScript rendering time in ms. Increase it in case if you see a loading indicator instead of data on the target page. (default: 2000, e.g. 2000)
  --proxy: string@proxy-completer # Type of proxy, use residential proxies if your site restricts traffic from datacenters (datacenter by default). Note that residential proxy requests are more expensive than datacenter, see the pricing page for details. (default: datacenter, e.g. datacenter)
  --country: string@country-completer # Country of the proxy to use (US by default). Only available on Startup and Custom plans. (default: us, e.g. us)
  --device: string@device-completer # Type of device emulation. (default: desktop, e.g. desktop)
  --error-on-404: oneof<nothing, bool> # Return error on 404 HTTP status on the target page (false by default). (default: false, e.g. false)
  --error-on-redirect: oneof<nothing, bool> # Return error on redirect on the target page (false by default). (default: false, e.g. false)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "selectors" $selectors "multi") (serialize-qp "url" $url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/selected-multiple" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"selectors": $selectors, "url": $url, "headers": $headers, "timeout": $timeout, "js": $js, "js_timeout": $js_timeout, "proxy": $proxy, "country": $country, "device": $device, "error_on_404": $error_on_404, "error_on_redirect": $error_on_redirect} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
