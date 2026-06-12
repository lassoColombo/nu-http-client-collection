# Auto-generated client for Browserless v2.52.0
# Source: https://docs.browserless.io/redocusaurus/plugin-redoc-0.yaml
# Auth: --token flag or $env.BROWSERLESS_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BROWSERLESS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["image/jpeg" "image/png" "text/plain"] }
def proxyLocaleMatch-completer [] { ["0" "1" "false" "true"] }
def proxySticky-completer [] { ["0" "1" "false" "true"] }
def sitemap-completer [] { ["include" "only" "skip"] }
def proxy-completer [] { ["datacenter" "residential"] }
def tbs-completer [] { ["day" "month" "qdr:d" "qdr:m" "qdr:w" "qdr:y" "week" "year"] }
def browser-completer [] { ["chrome" "chromium" "stealth"] }
def sitemap-completer-1 [] { ["auto" "force" "skip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "chrome-content post" } } | get name | first)
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

# /chrome/content
#
# POST /chrome/content
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-content post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool> # Whether or not to allow JavaScript to run on the page.
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/content" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/download
#
# POST /chrome/download
export def "chrome-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/download" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/function
#
# POST /chrome/function
export def "chrome-function post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/function" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /json/new
#
# PUT /json/new
export def "json-new put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<description: string, devtoolsFrontendUrl: string, id: string, title: string, type: string, url: string, webSocketDebuggerUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/new")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /json/protocol
#
# GET /json/protocol
export def "json-protocol get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/protocol")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /json/version
#
# GET /json/version
export def "json-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<description: string, devtoolsFrontendUrl: string, id: string, title: string, type: string, url: string, webSocketDebuggerUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/version")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/pdf
#
# POST /chrome/pdf
# --options shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: "A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6"|"LEDGER"|"LEGAL"|"LETTER"|"Ledger"|"Legal"|"Letter"|"TABLOID"|"Tabloid"|"a0"|"a1"|"a2"|"a3"|"a4"|"a5"|"a6"|"ledger"|"legal"|"letter"|"tabloid", width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-pdf post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --options: record # shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: "A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6"|"LEDGER"|"LEGAL"|"LETTER"|"Ledger"|"Legal"|"Letter"|"TABLOID"|"Tabloid"|"a0"|"a1"|"a2"|"a3"|"a4"|"a5"|"a6"|"ledger"|"legal"|"letter"|"tabloid", width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/pdf" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, options: $options, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/performance
#
# POST /chrome/performance
export def "chrome-performance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --budgets: list
  --config: record
  --body-url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/performance" $qp)
  let body = {budgets: $budgets, config: $config, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/scrape
#
# POST /chrome/scrape
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-scrape post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --debugOpts: any
  elements: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> record<data: any, debug: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/scrape" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, debugOpts: $debugOpts, elements: $elements, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/screenshot
#
# POST /chrome/screenshot
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-screenshot post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --options: any
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --scrollPage: oneof<nothing, bool>
  --selector: string
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/screenshot" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, options: $options, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, scrollPage: $scrollPage, selector: $selector, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/content
#
# POST /chromium/content
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chromium-content post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool> # Whether or not to allow JavaScript to run on the page.
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/content" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/download
#
# POST /chromium/download
export def "chromium-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/download" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/function
#
# POST /chromium/function
export def "chromium-function post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/function" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/performance
#
# POST /chromium/performance
export def "chromium-performance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --budgets: list
  --config: record
  --body-url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/performance" $qp)
  let body = {budgets: $budgets, config: $config, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/scrape
#
# POST /chromium/scrape
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chromium-scrape post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --debugOpts: any
  elements: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> record<data: any, debug: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/scrape" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, debugOpts: $debugOpts, elements: $elements, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/content
#
# POST /edge/content
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "edge-content post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool> # Whether or not to allow JavaScript to run on the page.
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/content" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/download
#
# POST /edge/download
export def "edge-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/download" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/function
#
# POST /edge/function
export def "edge-function post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/function" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/pdf
#
# POST /edge/pdf
# --options shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: "A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6"|"LEDGER"|"LEGAL"|"LETTER"|"Ledger"|"Legal"|"Letter"|"TABLOID"|"Tabloid"|"a0"|"a1"|"a2"|"a3"|"a4"|"a5"|"a6"|"ledger"|"legal"|"letter"|"tabloid", width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "edge-pdf post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --options: record # shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: "A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6"|"LEDGER"|"LEGAL"|"LETTER"|"Ledger"|"Legal"|"Letter"|"TABLOID"|"Tabloid"|"a0"|"a1"|"a2"|"a3"|"a4"|"a5"|"a6"|"ledger"|"legal"|"letter"|"tabloid", width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/pdf" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, options: $options, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/performance
#
# POST /edge/performance
export def "edge-performance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --budgets: list
  --config: record
  --body-url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/performance" $qp)
  let body = {budgets: $budgets, config: $config, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/scrape
#
# POST /edge/scrape
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "edge-scrape post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --debugOpts: any
  elements: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> record<data: any, debug: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/scrape" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, debugOpts: $debugOpts, elements: $elements, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/screenshot
#
# POST /edge/screenshot
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "edge-screenshot post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --addScriptTag: list
  --addStyleTag: list
  --authenticate: any
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list
  --emulateMediaType: string
  --gotoOptions: any
  --html: string
  --options: any
  --rejectRequestPattern: list
  --rejectResourceTypes: list
  --requestInterceptors: list # item shape: {pattern: string, response: record}
  --scrollPage: oneof<nothing, bool>
  --selector: string
  --setExtraHTTPHeaders: record
  --setJavaScriptEnabled: oneof<nothing, bool>
  --body-url: string
  --userAgent: record # shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any
  --waitForEvent: record # shape: {event: string, timeout?: float}
  --waitForFunction: record # shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/screenshot" $qp)
  let body = {addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, options: $options, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, scrollPage: $scrollPage, selector: $selector, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /active
#
# GET /active
export def "active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/active")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /kill/+([0-9a-zA-Z-_])
#
# GET /kill/+([0-9a-zA-Z-_])
export def "kill-0-9a-z-a-z get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --browserId: string
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "browserId" $browserId "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kill/+([0-9a-zA-Z-_])" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /meta
#
# GET /meta
export def "meta get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<version: string, chromium: string, webkit: string, firefox: string, playwright: list<string>, puppeteer: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meta")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /
#
# GET /
export def "browser-web-socket-ap-is get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /devtools/browser/*
#
# GET /devtools/browser/*
export def "devtools-browser get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devtools/browser/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome
#
# GET /chrome
export def "chrome get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /function/connect/*
#
# GET /function/connect/*
export def "function-connect get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/function/connect/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /devtools/page/*
#
# GET /devtools/page/*
export def "devtools-page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devtools/page/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/playwright
#
# GET /chrome/playwright
export def "chrome-playwright get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/playwright" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium
#
# GET /chromium
export def "chromium get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/playwright
#
# GET /chromium/playwright
export def "chromium-playwright get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/playwright" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge
#
# GET /edge
export def "edge get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /edge/playwright
#
# GET /edge/playwright
export def "edge-playwright get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge/playwright" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /firefox/playwright
#
# GET /firefox/playwright
export def "firefox-playwright get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: record
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "multi") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/firefox/playwright" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /webkit/playwright
#
# GET /webkit/playwright
export def "webkit-playwright get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webkit/playwright" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /browser/*
#
# DELETE /browser/*
export def "browser delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/browser/*")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/export
#
# POST /chrome/export
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-export post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --body-url: string # The URL of the site you want to archive.
  --gotoOptions: any # An optional goto parameter object for considering when the page is done loading.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
  --headers: record # An object containing additional HTTP headers to send with every request.
  --includeResources: oneof<nothing, bool> # Whether to include all linked resources (images, CSS, JS) in a zip file. When true, the response will be a zip file containing the HTML and all resources. When false or not provided, the response will be the raw content (default behavior).
]: any -> record<html: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/export" $qp)
  let body = {bestAttempt: $bestAttempt, url: $body_url, gotoOptions: $gotoOptions, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout, headers: $headers, includeResources: $includeResources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/unblock
#
# POST /chrome/unblock
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chrome-unblock post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --body-url: string # The URL of the site you want to unblock.
  --browserWSEndpoint: oneof<nothing, bool> # Whether or not to keep the underlying browser alive and around for future reconnects. Defaults to false.
  --cookies: oneof<nothing, bool> # Whether or not to to return cookies for the site, defaults to true.
  --content: oneof<nothing, bool> # Whether or not to to return content for the site, defaults to true.
  --screenshot: oneof<nothing, bool> # Whether or not to to return a full-page screenshot for the site, defaults to true.
  --ttl: float # When the browserWSEndpoint is requested this tells browserless how long to keep this browser alive for re-connection until shutting it down completely. Maximum of 30000 for 30 seconds (30,000ms).
  --gotoOptions: any # An optional goto parameter object for considering when the page is done loading.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
]: any -> record<cookies: list<any>, content: string, browserWSEndpoint: string, ttl: float, screenshot: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/unblock" $qp)
  let body = {bestAttempt: $bestAttempt, url: $body_url, browserWSEndpoint: $browserWSEndpoint, cookies: $cookies, content: $content, screenshot: $screenshot, ttl: $ttl, gotoOptions: $gotoOptions, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/export
#
# POST /chromium/export
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "chromium-export post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --body-url: string # The URL of the site you want to archive.
  --gotoOptions: any # An optional goto parameter object for considering when the page is done loading.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
  --headers: record # An object containing additional HTTP headers to send with every request.
  --includeResources: oneof<nothing, bool> # Whether to include all linked resources (images, CSS, JS) in a zip file. When true, the response will be a zip file containing the HTML and all resources. When false or not provided, the response will be the raw content (default behavior).
]: any -> record<html: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/export" $qp)
  let body = {bestAttempt: $bestAttempt, url: $body_url, gotoOptions: $gotoOptions, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout, headers: $headers, includeResources: $includeResources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /unblock
#
# POST /unblock
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "unblock post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --body-url: string # The URL of the site you want to unblock.
  --browserWSEndpoint: oneof<nothing, bool> # Whether or not to keep the underlying browser alive and around for future reconnects. Defaults to false.
  --cookies: oneof<nothing, bool> # Whether or not to to return cookies for the site, defaults to true.
  --content: oneof<nothing, bool> # Whether or not to to return content for the site, defaults to true.
  --screenshot: oneof<nothing, bool> # Whether or not to to return a full-page screenshot for the site, defaults to true.
  --ttl: float # When the browserWSEndpoint is requested this tells browserless how long to keep this browser alive for re-connection until shutting it down completely. Maximum of 30000 for 30 seconds (30,000ms).
  --gotoOptions: any # An optional goto parameter object for considering when the page is done loading.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
]: any -> record<cookies: list<any>, content: string, browserWSEndpoint: string, ttl: float, screenshot: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/unblock" $qp)
  let body = {bestAttempt: $bestAttempt, url: $body_url, browserWSEndpoint: $browserWSEndpoint, cookies: $cookies, content: $content, screenshot: $screenshot, ttl: $ttl, gotoOptions: $gotoOptions, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /proxy/cities
#
# GET /proxy/cities
export def "proxy-cities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --country: string
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> record<countries: table<code: string, cities: list>, totalCountries: float, totalCities: float, filters: record<country: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proxy/cities" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /map
#
# POST /map
# --location shape: {country?: string, languages?: list}
export def "map post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: float
  --qp-token: string
  --body-url: string # The base URL to start mapping from (required)
  --search: string # Search query to order results by relevance
  --limit: float # Maximum number of links to return (default: 5000, max: 5000)
  --timeout: float # Request timeout in milliseconds
  --sitemap: string@sitemap-completer # Controls sitemap behavior: "include" (default), "skip", "only"
  --includeSubdomains: oneof<nothing, bool> # Whether to include URLs from subdomains (default: true)
  --ignoreQueryParameters: oneof<nothing, bool> # Exclude URLs with query parameters (default: true)
  --location: record # Geo-targeting settings — shape: {country?: string, languages?: list}
  --proxy: string@proxy-completer # Proxy network to route through: `"residential"` (default) or `"datacenter"`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/map" $qp)
  let body = {url: $body_url, search: $search, limit: $limit, timeout: $timeout, sitemap: $sitemap, includeSubdomains: $includeSubdomains, ignoreQueryParameters: $ignoreQueryParameters, location: $location, proxy: $proxy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /pdf
#
# POST /pdf
# --options shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: any, width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "pdf post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --blockConsentModals: oneof<nothing, bool> # Whether to automatically block cookie consent modals and popups.
  --options: record # PDF generation options based on Puppeteer's PDFOptions interface. Includes properties like `format`, `margin`, `printBackground`, `landscape`, etc. — shape: {scale?: float, displayHeaderFooter?: bool, headerTemplate?: string, footerTemplate?: string, printBackground?: bool, landscape?: bool, pageRanges?: string, format?: any, width?: string, height?: string, preferCSSPageSize?: bool, margin?: any, path?: string, omitBackground?: bool, tagged?: bool, outline?: bool, timeout?: float, waitForFonts?: bool, fullPage?: bool}
  --addScriptTag: list # An array of script tags to add to the page before performing actions. Each object can contain either a `url`, or a `content` property.
  --addStyleTag: list # An array of style tags to add to the page before performing actions. Each object can contain either a `url`, or a `content` property.
  --authenticate: any # Credentials for HTTP authentication. Contains `username` and `password` properties.
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list # An array of cookies to set on the page before navigation. Each cookie object should contain at least `name` and `value` properties.
  --emulateMediaType: string # Changes the CSS media type of the page. Accepts values like "screen" or "print".
  --gotoOptions: any # Options to configure the page navigation, such as `timeout` and `waitUntil`.
  --html: string # HTML content to set as the page content instead of navigating to a URL.
  --rejectRequestPattern: list # An array of patterns to match against request URLs for automatic rejection. Requests matching these patterns will be aborted.
  --rejectResourceTypes: list # An array of resource types to reject during page load. Common types include "image", "stylesheet", "font", "script", etc.
  --requestInterceptors: list # An array of request interceptors that can modify or mock network requests. Each interceptor has a `pattern` to match URLs and a `response` to return. — item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record # An object containing additional HTTP headers to send with every request.
  --setJavaScriptEnabled: oneof<nothing, bool> # Whether or not to allow JavaScript to run on the page.
  --body-url: string # The URL to navigate to before performing actions.
  --userAgent: record # The user agent string to use for the page. — shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any # The viewport dimensions and settings for the page. Includes properties like `width`, `height`, `deviceScaleFactor`, etc.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pdf" $qp)
  let body = {blockConsentModals: $blockConsentModals, options: $options, addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /screenshot
#
# POST /screenshot
# --requestInterceptors item shape: {pattern: string, response: record}
# --userAgent shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
# --waitForEvent shape: {event: string, timeout?: float}
# --waitForFunction shape: {fn: string, polling?: string, timeout?: float}
# --waitForSelector shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
export def "screenshot post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --timeout: float
  --qp-token: string
  --trackingId: string
  --blockConsentModals: oneof<nothing, bool> # Whether to automatically block cookie consent modals and popups.
  --options: any # Screenshot options based on Puppeteer's ScreenshotOptions interface. Includes properties like `type`, `quality`, `fullPage`, `clip`, etc.
  --addScriptTag: list # An array of script tags to add to the page before performing actions. Each object can contain either a `url`, or a `content` property.
  --addStyleTag: list # An array of style tags to add to the page before performing actions. Each object can contain either a `url`, or a `content` property.
  --authenticate: any # Credentials for HTTP authentication. Contains `username` and `password` properties.
  --bestAttempt: oneof<nothing, bool> # When bestAttempt is set to true, browserless will attempt to proceed when "awaited" events fail or timeout. This includes things like goto, waitForSelector, and more.
  --cookies: list # An array of cookies to set on the page before navigation. Each cookie object should contain at least `name` and `value` properties.
  --emulateMediaType: string # Changes the CSS media type of the page. Accepts values like "screen" or "print".
  --gotoOptions: any # Options to configure the page navigation, such as `timeout` and `waitUntil`.
  --html: string # HTML content to set as the page content instead of navigating to a URL.
  --rejectRequestPattern: list # An array of patterns to match against request URLs for automatic rejection. Requests matching these patterns will be aborted.
  --rejectResourceTypes: list # An array of resource types to reject during page load. Common types include "image", "stylesheet", "font", "script", etc.
  --requestInterceptors: list # An array of request interceptors that can modify or mock network requests. Each interceptor has a `pattern` to match URLs and a `response` to return. — item shape: {pattern: string, response: record}
  --setExtraHTTPHeaders: record # An object containing additional HTTP headers to send with every request.
  --setJavaScriptEnabled: oneof<nothing, bool> # Whether or not to allow JavaScript to run on the page.
  --body-url: string # The URL to navigate to before performing actions.
  --userAgent: record # The user agent string to use for the page. — shape: {userAgent?: string, userAgentMetadata?: any, platform?: string}
  --viewport: any # The viewport dimensions and settings for the page. Includes properties like `width`, `height`, `deviceScaleFactor`, etc.
  --waitForEvent: record # Options for waiting for a specific event to be fired on the page. — shape: {event: string, timeout?: float}
  --waitForFunction: record # Options for waiting for a JavaScript function to execute. — shape: {fn: string, polling?: string, timeout?: float}
  --waitForSelector: record # Options for waiting for a specific CSS selector to appear on the page. — shape: {hidden?: bool, selector: string, timeout?: float, visible?: bool}
  --waitForTimeout: float # The amount of time in milliseconds to wait before proceeding.
  --scrollPage: oneof<nothing, bool> # Whether to scroll through the entire page before capturing content. Useful for triggering lazy-loaded content.
  --selector: string # A CSS selector to target a specific element instead of the full page.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshot" $qp)
  let body = {blockConsentModals: $blockConsentModals, options: $options, addScriptTag: $addScriptTag, addStyleTag: $addStyleTag, authenticate: $authenticate, bestAttempt: $bestAttempt, cookies: $cookies, emulateMediaType: $emulateMediaType, gotoOptions: $gotoOptions, html: $html, rejectRequestPattern: $rejectRequestPattern, rejectResourceTypes: $rejectResourceTypes, requestInterceptors: $requestInterceptors, setExtraHTTPHeaders: $setExtraHTTPHeaders, setJavaScriptEnabled: $setJavaScriptEnabled, url: $body_url, userAgent: $userAgent, viewport: $viewport, waitForEvent: $waitForEvent, waitForFunction: $waitForFunction, waitForSelector: $waitForSelector, waitForTimeout: $waitForTimeout, scrollPage: $scrollPage, selector: $selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /search
#
# POST /search
# --scrapeOptions shape: {formats: list, stripNonContentTags?: bool, onlyMainContent?: bool, removeBase64Images?: bool, includeTags?: list, excludeTags?: list}
export def "search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: float
  --qp-token: string
  --body-query: string # The search query string.
  --limit: float # Maximum number of results per source. Defaults to `10`. Capped by plan limits.
  --lang: string # Language code for results (e.g., `"en"`, `"es"`, `"de"`). Defaults to `"en"`.
  --location: string # City or region to narrow geo-targeting (e.g., `"San Francisco"`). Use with `country`.
  --country: string # ISO 3166-1 alpha-2 country code for geo-targeted results (e.g., `"us"`, `"gb"`, `"de"`).
  --proxy: string@proxy-completer # Proxy network to route result scraping through: `"residential"` (default) or `"datacenter"`.
  --tbs: string@tbs-completer # Time-based filter. Accepts `"day"`, `"week"`, `"month"`, `"year"`, or raw Google TBS syntax (`"qdr:d"`, `"qdr:w"`, `"qdr:m"`, `"qdr:y"`).
  --categories: list # Content category filters. Restricts results to `"github"` repos, `"research"` papers, or `"pdf"` documents.
  --sources: list # Sources to search. Defaults to `["web"]`. Also supports `"news"` and `"images"`.
  --timeout: float # Request timeout in milliseconds.
  --scrapeOptions: record # When provided, fetches and processes each result URL into structured content. — shape: {formats: list, stripNonContentTags?: bool, onlyMainContent?: bool, removeBase64Images?: bool, includeTags?: list, excludeTags?: list}
]: any -> record<success: bool, data: any, totalResults: float, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let body = {query: $body_query, limit: $limit, lang: $lang, location: $location, country: $country, proxy: $proxy, tbs: $tbs, categories: $categories, sources: $sources, timeout: $timeout, scrapeOptions: $scrapeOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /session
#
# POST /session
# --proxy shape: {type?: "datacenter"|"residential", sticky?: bool, country?: string, city?: string, state?: string, preset?: string}
export def "session post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ttl: float # The time-to-live (TTL) for the session in milliseconds. Once reached, will be forcefully terminated and all files and processes will be cleaned up. Must be a non-negative number greater than 0.
  --processKeepAlive: float # An optional time, in milliseconds, to keep the underlying browser process alive after a connection to the session closes. If a connection happens within the keep-alive window, the browser process will remain running and the session can be reconnected to. If a connection happens after the keep-alive window has expired, a new browser process will be launched for the session, with the prior session data. Defaults to 0 (no keep-alive).
  --stealth: oneof<nothing, bool> # Whether or not to enable advanced stealth mode. Defaults to false.
  --blockAds: oneof<nothing, bool> # Whether or not to enable ad-blocking. Defaults to false.
  --headless: oneof<nothing, bool> # Whether the browser should be launched in headless mode. Ignored if `stealth` is true, defaults to "true".
  --args: list # An array of command-line arguments to pass to the browser. Defaults to an empty array.
  --browser: string@browser-completer # The type of browser to use for the session. 'stealth' uses the Brave browser with advanced anti-detection. Defaults to 'chromium'.
  --body-url: string # The underlying page URL you're attempting to automate. Some pages may required special handling in order to work correctly or unblock. This is not required, but can be useful or required for certain sites.
  --proxy: record # Proxy Parameters for the session if desired. If not specified, the session will use the default network settings. — shape: {type?: "datacenter"|"residential", sticky?: bool, country?: string, city?: string, state?: string, preset?: string}
  --replay: oneof<nothing, bool> # Whether to enable session recording for replay. When true, the session will be recorded and can be replayed later.
  --extensions: list # An array of extension IDs to load into the browser session. Extensions must be previously uploaded to the browserless extension storage. This allows sessions to start with extensions pre-loaded without specifying them in launch arguments at connection time.
  --profile: string # Optional name of an authentication profile to use as initial browser state. The profile's cookies, localStorage, and IndexedDB entries are injected via CDP before your code runs. sessionStorage is intentionally not restored — it is tab-scoped and stale values break OAuth/CSRF flows. Changes during the session do not affect the source profile.
]: any -> record<id: string, connect: string, ttl: float, stop: string, browserQL: string, cloudEndpointId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session")
  let body = {ttl: $ttl, processKeepAlive: $processKeepAlive, stealth: $stealth, blockAds: $blockAds, headless: $headless, args: $args, browser: $browser, url: $body_url, proxy: $proxy, replay: $replay, extensions: $extensions, profile: $profile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /session/*
#
# DELETE /session/*
export def "session delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --force: oneof<nothing, bool>
  --launch: string
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /smart-scrape
#
# POST /smart-scrape
export def "smart-scrape post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile: string
  --timeout: float
  --qp-token: string
  --body-url: string # The URL to scrape. Must be an http or https URL.
  --formats: list # Output formats to include in the response. Accepts an array of format strings such as `["markdown", "screenshot"]`. When `screenshot` or `pdf` is included, a browser strategy is forced. Mirrors the Firecrawl "formats" convention.  - `markdown`   – page content converted to markdown - `html`       – cleaned HTML (returned by default in `content`, this is a no-op convenience value) - `screenshot` – full-page screenshot as base64-encoded PNG (forces browser strategy) - `pdf`        – PDF of the page as base64-encoded string (forces browser strategy) - `links`      – list of links extracted from the page (default: [html])
  --proxy: string@proxy-completer # The proxy network to route the scrape through. Defaults to `residential`. Use `datacenter` for the cheaper datacenter pool.
]: any -> record<ok: bool, statusCode: float, content: any, contentType: string, headers: any, strategy: string, attempted: list<string>, message: string, screenshot: string, pdf: string, markdown: string, links: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smart-scrape" $qp)
  let body = {url: $body_url, formats: $formats, proxy: $proxy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /stealth/bql?(/*)
#
# POST /stealth/bql?(/*)
export def "stealth-bql post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body-query: string # The BrowserQL query string to execute.
  --operationName: string # The name of the operation to execute if the query contains multiple operations.
  --body-variables: record # Variables to pass to the BrowserQL query.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stealth/bql?(/*)" $qp)
  let body = {query: $body_query, operationName: $operationName, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /stealth/bql?(/*)
#
# GET /stealth/bql?(/*)
export def "stealth-bql get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stealth/bql?(/*)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/bql?(/*)
#
# POST /chrome/bql?(/*)
export def "chrome-bql post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body-query: string # The BrowserQL query string to execute.
  --operationName: string # The name of the operation to execute if the query contains multiple operations.
  --body-variables: record # Variables to pass to the BrowserQL query.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/bql?(/*)" $qp)
  let body = {query: $body_query, operationName: $operationName, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/bql?(/*)
#
# GET /chrome/bql?(/*)
export def "chrome-bql get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/bql?(/*)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/bql?(/*)
#
# POST /chromium/bql?(/*)
export def "chromium-bql post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body-query: string # The BrowserQL query string to execute.
  --operationName: string # The name of the operation to execute if the query contains multiple operations.
  --body-variables: record # Variables to pass to the BrowserQL query.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/bql?(/*)" $qp)
  let body = {query: $body_query, operationName: $operationName, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/bql?(/*)
#
# GET /chromium/bql?(/*)
export def "chromium-bql get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/bql?(/*)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /session/bql/*
#
# POST /session/bql/*
export def "session-bql post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --profile: string
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body-query: string # The GraphQL query string to execute against the browser session.  Example queries: - Get browser info: `query { version browser }` - Navigate and get content: `mutation { goto(url: "https://example.com") { status } title { title } url { url } }` - Fill form and submit: `mutation { goto(url: "https://example.com") { status } type(selector: "input[name='email']", text: "user@example.com") { time } click(selector: "button[type='submit']") { time } }` - Extract data: `mutation { querySelector(selector: "h1") { innerHTML } querySelectorAll(selector: ".product") { innerHTML className } }`
  --body-variables: record # Variables to pass to the GraphQL query. Useful for dynamic values.  Example: `{ "url": "https://example.com", "selector": "h1", "text": "Hello World" }`
  --operationName: string # The name of the operation to execute if the query contains multiple operations. Optional - only needed when query has multiple named operations.
]: any -> record<data: any, errors: table<message: string, locations: list, path: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session/bql/*" $qp)
  let body = {query: $body_query, variables: $body_variables, operationName: $operationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /crawl/*
#
# DELETE /crawl/*
export def "crawl delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crawl/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /crawl/*
#
# GET /crawl/*
export def "crawl get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: float
  --qp-token: string
  --body: record
]: any -> record<status: any, total: float, completed: float, failed: float, expiresAt: string, next: string, data: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crawl/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /crawl
#
# GET /crawl
export def "crawl get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string
  --limit: float
  --status: string
  --qp-token: string
  --body: record
]: any -> record<crawls: list<any>, nextCursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crawl" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /crawl
#
# POST /crawl
# --scrapeOptions shape: {formats?: list, onlyMainContent?: bool, includeTags?: list, excludeTags?: list, waitFor?: float, headers?: record, timeout?: float, proxy?: "datacenter"|"residential"}
# --webhook shape: {url: string, events?: list}
export def "crawl post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile: string
  --qp-token: string
  --body-url: string # The URL to crawl. Must be a valid http or https URL.
  --limit: float # Maximum number of pages to crawl. Clamped to your plan's limit. (default: 100)
  --maxDepth: float # Maximum link-follow depth from the root URL. (default: 5)
  --maxRetries: float # Number of retry attempts per failed page. (default: 1)
  --allowExternalLinks: oneof<nothing, bool> # Whether to follow links to external domains. (default: false)
  --allowSubdomains: oneof<nothing, bool> # Whether to follow links to subdomains of the root URL. (default: false)
  --sitemap: string@sitemap-completer-1 # Sitemap handling strategy. (default: auto)
  --includePaths: list # Regex patterns for URL paths to include. (default: [])
  --excludePaths: list # Regex patterns for URL paths to exclude. (default: [])
  --delay: float # Delay between requests in milliseconds. (default: 200)
  --scrapeOptions: record # Options controlling how each page is scraped. — shape: {formats?: list, onlyMainContent?: bool, includeTags?: list, excludeTags?: list, waitFor?: float, headers?: record, timeout?: float, proxy?: "datacenter"|"residential"}
  --webhook: record # Webhook configuration for crawl event notifications. — shape: {url: string, events?: list}
]: any -> record<success: bool, id: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crawl" $qp)
  let body = {url: $body_url, limit: $limit, maxDepth: $maxDepth, maxRetries: $maxRetries, allowExternalLinks: $allowExternalLinks, allowSubdomains: $allowSubdomains, sitemap: $sitemap, includePaths: $includePaths, excludePaths: $excludePaths, delay: $delay, scrapeOptions: $scrapeOptions, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile
#
# POST /profile
# --proxy shape: {type?: "datacenter"|"residential", sticky?: bool, country?: string, city?: string, state?: string, preset?: string}
export def "profile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A user-visible name for the profile. Must be unique per token.
  --stealth: oneof<nothing, bool> # Whether or not to enable advanced stealth mode. Defaults to false.
  --browser: string@browser-completer # The type of browser to use. Defaults to 'stealth'.
  --args: list # An array of command-line arguments to pass to the browser.
  --proxy: record # Proxy parameters for the profile creation session. — shape: {type?: "datacenter"|"residential", sticky?: bool, country?: string, city?: string, state?: string, preset?: string}
]: any -> record<id: string, name: string, connect: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let body = {name: $name, stealth: $stealth, browser: $browser, args: $args, proxy: $proxy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile/*
#
# DELETE /profile/*
export def "profile delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<success: bool, message: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/*")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile/*
#
# GET /profile/*
export def "profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: string, name: string, cookieCount: float, originCount: float, lastUsedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/*")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile/*
#
# PUT /profile/*
export def "profile put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The new name for the profile.
]: any -> record<id: string, name: string, cookieCount: float, originCount: float, lastUsedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/*")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profiles
#
# GET /profiles
export def "profiles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --launch: string
  --limit: float
  --offset: float
  --profile: string
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profiles" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile/refresh
#
# POST /profile/refresh
export def "profile-refresh post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the existing profile to refresh. Must already exist for the requesting token.
  state: any # Pre-captured authentication state. Same shape as `POST /profile/upload`.
]: any -> record<diagnostics: any, id: string, name: string, cookieCount: float, originCount: float, lastUsedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/refresh")
  let body = {name: $name, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /profile/upload
#
# POST /profile/upload
export def "profile-upload post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A user-visible name for the profile. Must be unique per token.
  state: any # Pre-captured authentication state. An object with two arrays — `cookies` (browser cookies) and `origins` (per-origin localStorage and IndexedDB).
]: any -> record<diagnostics: any, id: string, name: string, cookieCount: float, originCount: float, lastUsedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/upload")
  let body = {name: $name, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /stealth
#
# GET /stealth
export def "stealth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stealth" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/live/*
#
# GET /chrome/live/*
export def "chrome-live get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chrome/live/*")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chrome/stealth
#
# GET /chrome/stealth
export def "chrome-stealth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chrome/stealth" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/cli
#
# GET /chromium/cli
export def "chromium-cli get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/cli" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /live/*
#
# GET /live/*
export def "live get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live/*")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/stealth
#
# GET /chromium/stealth
export def "chromium-stealth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --externalProxyServer: string
  --integrations: string
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --record: oneof<nothing, bool>
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "record" $record "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/stealth" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /reconnect/*
#
# GET /reconnect/*
export def "reconnect get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --integrations: string
  --launch: string
  --profile: string
  --replay: oneof<nothing, bool>
  --solveCaptchas: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "integrations" $integrations "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "solveCaptchas" $solveCaptchas "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reconnect/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /session/connect/*
#
# GET /session/connect/*
export def "session-connect get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --launch: string
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "launch" $launch "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session/connect/*" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /chromium/agent
#
# GET /chromium/agent
export def "chromium-agent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blockAds: oneof<nothing, bool>
  --blockConsentModals: oneof<nothing, bool>
  --externalProxyServer: string
  --humanlike: oneof<nothing, bool>
  --launch: string
  --profile: string
  --proxy: string
  --proxyCity: string
  --proxyCountry: string
  --proxyLocaleMatch: string@proxyLocaleMatch-completer
  --proxyPreset: string
  --proxyState: string
  --proxySticky: string@proxySticky-completer
  --replay: oneof<nothing, bool>
  --timeout: float
  --qp-token: string
  --trackingId: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockAds" $blockAds "scalar") (serialize-qp "blockConsentModals" $blockConsentModals "scalar") (serialize-qp "externalProxyServer" $externalProxyServer "scalar") (serialize-qp "humanlike" $humanlike "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "proxyCity" $proxyCity "scalar") (serialize-qp "proxyCountry" $proxyCountry "scalar") (serialize-qp "proxyLocaleMatch" $proxyLocaleMatch "scalar") (serialize-qp "proxyPreset" $proxyPreset "scalar") (serialize-qp "proxyState" $proxyState "scalar") (serialize-qp "proxySticky" $proxySticky "scalar") (serialize-qp "replay" $replay "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chromium/agent" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
