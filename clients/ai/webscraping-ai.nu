# Auto-generated client for WebScraping.AI v2.0.7
# Source: https://api.apis.guru/v2/specs/webscraping.ai/2.0.7/openapi.json
# Auth: --token flag or $env.WEBSCRAPING_AI_TOKEN

const BASE_URL = "https://api.webscraping.ai"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEBSCRAPING_AI_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.webscraping.ai"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def proxy-completer [] { ["datacenter" "residential"] }
def country-completer [] { ["ca" "de" "es" "fr" "gb" "it" "jp" "kr" "ru" "us"] }
def device-completer [] { ["desktop" "mobile" "tablet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account account" } } | get name | first)
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
export def "account account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<remaining_api_calls: int, remaining_concurrency: int, resets_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # URL of the target page (e.g. https://example.com)
  --headers: record # HTTP headers to pass to the target page. Can be specified either via a nested query parameter (...&headers[One]=value1&headers=[Another]=value2) or as a JSON encoded object (...&headers={"One": "value1", "Another": "value2"}) (e.g. {"Cookie":"session=some_id"})
  --timeout: int # Maximum processing time in ms. Increase it in case of timeout errors (10000 by default, maximum is 30000) (default: 10000, e.g. 10000)
  --js: oneof<nothing, bool> # Execute on-page JavaScript using a headless browser (true by default) (default: true, e.g. true)
  --js-timeout: int # Maximum JavaScript rendering time in ms. Increase it in case if you see a loading indicator instead of data on the target page. (default: 2000, e.g. 2000)
  --proxy: string@proxy-completer # Type of proxy, use residential proxies if your site restricts traffic from datacenters (datacenter by default). Note that residential proxy requests are more expensive than datacenter, see the pricing page for details. (default: datacenter, e.g. datacenter)
  --country: string@country-completer # Country of the proxy to use (US by default). Only available on Startup and Custom plans. (default: us, e.g. us)
  --device: string@device-completer # Type of device emulation. (default: desktop, e.g. desktop)
  --error-on-404: oneof<nothing, bool> # Return error on 404 HTTP status on the target page (false by default). (default: false, e.g. false)
  --error-on-redirect: oneof<nothing, bool> # Return error on redirect on the target page (false by default). (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/html" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --selector: string # CSS selector (null by default, returns whole page HTML) (e.g. h1)
  --qp-url: string # URL of the target page (e.g. https://example.com)
  --headers: record # HTTP headers to pass to the target page. Can be specified either via a nested query parameter (...&headers[One]=value1&headers=[Another]=value2) or as a JSON encoded object (...&headers={"One": "value1", "Another": "value2"}) (e.g. {"Cookie":"session=some_id"})
  --timeout: int # Maximum processing time in ms. Increase it in case of timeout errors (10000 by default, maximum is 30000) (default: 10000, e.g. 10000)
  --js: oneof<nothing, bool> # Execute on-page JavaScript using a headless browser (true by default) (default: true, e.g. true)
  --js-timeout: int # Maximum JavaScript rendering time in ms. Increase it in case if you see a loading indicator instead of data on the target page. (default: 2000, e.g. 2000)
  --proxy: string@proxy-completer # Type of proxy, use residential proxies if your site restricts traffic from datacenters (datacenter by default). Note that residential proxy requests are more expensive than datacenter, see the pricing page for details. (default: datacenter, e.g. datacenter)
  --country: string@country-completer # Country of the proxy to use (US by default). Only available on Startup and Custom plans. (default: us, e.g. us)
  --device: string@device-completer # Type of device emulation. (default: desktop, e.g. desktop)
  --error-on-404: oneof<nothing, bool> # Return error on 404 HTTP status on the target page (false by default). (default: false, e.g. false)
  --error-on-redirect: oneof<nothing, bool> # Return error on redirect on the target page (false by default). (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "selector" $selector "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/selected" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --selectors: list # Multiple CSS selectors (null by default, returns whole page HTML) (e.g. [h1])
  --qp-url: string # URL of the target page (e.g. https://example.com)
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
  let qp = [(serialize-qp "selectors" $selectors "multi") (serialize-qp "url" $qp_url "scalar") (serialize-qp "headers" $headers "multi") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "js" $js "scalar") (serialize-qp "js_timeout" $js_timeout "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "error_on_404" $error_on_404 "scalar") (serialize-qp "error_on_redirect" $error_on_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/selected-multiple" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
