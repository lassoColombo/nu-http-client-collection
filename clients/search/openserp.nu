# Auto-generated client for OpenSERP API v2.2.0
# Source: https://raw.githubusercontent.com/karust/openserp/main/docs/openapi.yaml
# Auth: --token flag or $env.OPENSERP_API_TOKEN

const BASE_URL = "http://127.0.0.1:7000"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENSERP_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://127.0.0.1:7000"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def extract-mode-completer [] { ["auto" "fast" "rendered"] }
def format-completer [] { ["json" "markdown" "ndjson" "text"] }
def accept-completer [] { ["application/json" "application/x-ndjson" "text/markdown" "text/plain"] }
def mode-completer [] { ["any" "balanced" "fast"] }
def mode-completer-1 [] { ["auto" "fast" "rendered"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search searchWeb" } } | get name | first)
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

# Search web results from a specific engine
#
# GET /{engine}/search
# operationId: searchWeb
export def "search searchWeb" [
  engine: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --text: string # Search query text. At least one of `text`, `site`, or `file` must be non-empty.  (e.g. golang)
  --lang: string # Language code (engine-specific behavior). (e.g. EN)
  --region: string # Market/location hint. Country or locale-style values such as `US`, `DE`, or `en-GB` are shared by engines that support them. Google also accepts city names such as `Berlin` or `New York` and sends them as `uule`. Yandex accepts numeric `lr` region IDs such as `213`; those IDs are engine-specific and are ignored by other engines.
  --date: string # Date interval in `YYYYMMDD..YYYYMMDD` format. (e.g. 20250101..20250131)
  --file: string # File extension filter (for engines that support it). (e.g. PDF)
  --site: string # Site/domain filter. (e.g. github.com)
  --limit: int # Maximum organic results to return (1-100). Ads may be returned in addition. Omitted or small limits (<=10) parse only the first SERP page; larger limits may paginate when an engine supports it. (default: 10, e.g. 10)
  --start: int # Pagination offset (must be >= 0). (default: 0, e.g. 20)
  --filter: oneof<nothing, bool> # Duplicate filtering flag (primarily used by Google parser behavior). (default: true)
  --features: oneof<nothing, bool> # Populate the top-level serp_features array (AI summaries, answer boxes, people-also-ask, related searches) from the live browser search when supported by the engine.  (default: true)
  --extract: oneof<nothing, bool> # Fetch and embed cleaned target-page content for top web results. (default: false)
  --extract-top: int # Number of top organic results to enrich when `extract=true`. (default: 3)
  --extract-mode: string@extract-mode-completer # Extraction strategy for target pages. (default: auto)
  --min-runes: int # Auto-mode escalation floor: if the fast (raw) pass yields fewer extracted-text runes than this, escalate to a browser render. `0` (default) uses the built-in floor. Ignored in `fast` and `rendered` modes.
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --X-Use-Proxy: string # Request-scoped proxy override. Use `direct` to disable proxy or a tag name to force a specific proxy pool.
  --X-Proxy-URL: string # Per-request proxy URL supplied by an upstream balancer. Honored only when `proxies.allow_request_proxy_url: true` is set on the worker; otherwise the request is rejected with `400 bad_request` and `reason=REQUEST_PROXY_URL_DISABLED`. Authenticated SOCKS proxies are rejected in browser mode (`reason=UNSUPPORTED_PROXY_SCHEME`). Credentials are never logged or returned. Precedence: `X-Use-Proxy: direct` > `X-Proxy-URL` > `X-Use-Proxy: <tag>` > per-engine configured tag > `proxies.global` > direct.  (e.g. http://user:pass@proxy.example:8080)
  --X-Proxy-Country: string # Two-letter market country code for the supplied proxy. Used as part of the cache key so different markets do not share results.  (e.g. us)
  --X-Proxy-Class: string # Proxy class identifier (e.g. `datacenter`, `residential`, `mobile`). Part of the cache key. (e.g. residential)
  --X-Proxy-Provider: string # Upstream proxy provider identifier (e.g. `webshare`, `brightdata`). Part of the cache key. (e.g. webshare)
  --X-Proxy-Session-ID: string # Sticky session identifier minted by the balancer. Reusing the same value lets OpenSERP reuse cookies and browser profile for that lane. Lanes are LRU-bounded by `proxies.lanes.max_lanes`. Rotating the session ID gives a clean lane.  (e.g. sid-123)
  --X-Tenant: string # Optional tenant scope used to namespace sticky lane state across multi-tenant deployments. When present, lanes are keyed by `tenant + engine + session_id`.
]: nothing -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, url: string, display_url: string, snippet: string, domain: string, favicon: string, position: record, engine: string, domain_info: record, classification: record, extracted: record>, serp_features: table<id: string, engine: string, type: string, title: string, text: string, items: list, links: list, source_result_ids: list, position: record, confidence: float, extracted_at: string>, pagination: record<page: int, has_more: bool, next_start: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "extract" $extract "scalar") (serialize-qp "extract_top" $extract_top "scalar") (serialize-qp "extract_mode" $extract_mode "scalar") (serialize-qp "min_runes" $min_runes "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($engine)/search" $qp)
  let extra_headers = {"X-Use-Proxy": $X_Use_Proxy, "X-Proxy-URL": $X_Proxy_URL, "X-Proxy-Country": $X_Proxy_Country, "X-Proxy-Class": $X_Proxy_Class, "X-Proxy-Provider": $X_Proxy_Provider, "X-Proxy-Session-ID": $X_Proxy_Session_ID, "X-Tenant": $X_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search image results from a specific engine
#
# GET /{engine}/image
# operationId: searchImages
export def "image searchImages" [
  engine: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Search query text. At least one of `text`, `site`, or `file` must be non-empty.  (e.g. golang)
  --lang: string # Language code (engine-specific behavior). (e.g. EN)
  --region: string # Market/location hint. Country or locale-style values such as `US`, `DE`, or `en-GB` are shared by engines that support them. Google also accepts city names such as `Berlin` or `New York` and sends them as `uule`. Yandex accepts numeric `lr` region IDs such as `213`; those IDs are engine-specific and are ignored by other engines.
  --date: string # Date interval in `YYYYMMDD..YYYYMMDD` format. (e.g. 20250101..20250131)
  --file: string # File extension filter (for engines that support it). (e.g. PDF)
  --site: string # Site/domain filter. (e.g. github.com)
  --limit: int # Maximum organic results to return (1-100). Ads may be returned in addition. Omitted or small limits (<=10) parse only the first SERP page; larger limits may paginate when an engine supports it. (default: 10, e.g. 10)
  --start: int # Pagination offset (must be >= 0). (default: 0, e.g. 20)
  --filter: oneof<nothing, bool> # Duplicate filtering flag (primarily used by Google parser behavior). (default: true)
  --features: oneof<nothing, bool> # Populate the top-level serp_features array (AI summaries, answer boxes, people-also-ask, related searches) from the live browser search when supported by the engine.  (default: true)
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --X-Use-Proxy: string # Request-scoped proxy override. Use `direct` to disable proxy or a tag name to force a specific proxy pool.
  --X-Proxy-URL: string # Per-request proxy URL supplied by an upstream balancer. Honored only when `proxies.allow_request_proxy_url: true` is set on the worker; otherwise the request is rejected with `400 bad_request` and `reason=REQUEST_PROXY_URL_DISABLED`. Authenticated SOCKS proxies are rejected in browser mode (`reason=UNSUPPORTED_PROXY_SCHEME`). Credentials are never logged or returned. Precedence: `X-Use-Proxy: direct` > `X-Proxy-URL` > `X-Use-Proxy: <tag>` > per-engine configured tag > `proxies.global` > direct.  (e.g. http://user:pass@proxy.example:8080)
  --X-Proxy-Country: string # Two-letter market country code for the supplied proxy. Used as part of the cache key so different markets do not share results.  (e.g. us)
  --X-Proxy-Class: string # Proxy class identifier (e.g. `datacenter`, `residential`, `mobile`). Part of the cache key. (e.g. residential)
  --X-Proxy-Provider: string # Upstream proxy provider identifier (e.g. `webshare`, `brightdata`). Part of the cache key. (e.g. webshare)
  --X-Proxy-Session-ID: string # Sticky session identifier minted by the balancer. Reusing the same value lets OpenSERP reuse cookies and browser profile for that lane. Lanes are LRU-bounded by `proxies.lanes.max_lanes`. Rotating the session ID gives a clean lane.  (e.g. sid-123)
  --X-Tenant: string # Optional tenant scope used to namespace sticky lane state across multi-tenant deployments. When present, lanes are keyed by `tenant + engine + session_id`.
]: nothing -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, image: record, source: record, engine: string>, pagination: record<page: int, has_more: bool, next_start: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($engine)/image" $qp)
  let extra_headers = {"X-Use-Proxy": $X_Use_Proxy, "X-Proxy-URL": $X_Proxy_URL, "X-Proxy-Country": $X_Proxy_Country, "X-Proxy-Class": $X_Proxy_Class, "X-Proxy-Provider": $X_Proxy_Provider, "X-Proxy-Session-ID": $X_Proxy_Session_ID, "X-Tenant": $X_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Parse a Google SERP HTML document into structured results
#
# POST /google/parse
# operationId: parseGoogleHTML
export def "google-parse parseGoogleHTML" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --body: record
]: any -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, url: string, display_url: string, snippet: string, domain: string, favicon: string, position: record, engine: string, domain_info: record, classification: record, extracted: record>, serp_features: table<id: string, engine: string, type: string, title: string, text: string, items: list, links: list, source_result_ids: list, position: record, confidence: float, extracted_at: string>, pagination: record<page: int, has_more: bool, next_start: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/google/parse" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/html" $body
}

# Parse a Bing SERP HTML document into structured results
#
# POST /bing/parse
# operationId: parseBingHTML
export def "bing-parse parseBingHTML" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --body: record
]: any -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, url: string, display_url: string, snippet: string, domain: string, favicon: string, position: record, engine: string, domain_info: record, classification: record, extracted: record>, serp_features: table<id: string, engine: string, type: string, title: string, text: string, items: list, links: list, source_result_ids: list, position: record, confidence: float, extracted_at: string>, pagination: record<page: int, has_more: bool, next_start: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bing/parse" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/html" $body
}

# Search across multiple engines with selectable execution mode
#
# GET /mega/search
# operationId: megaSearch
export def "mega-search megaSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --text: string # Search query text. At least one of `text`, `site`, or `file` must be non-empty.  (e.g. golang)
  --lang: string # Language code (engine-specific behavior). (e.g. EN)
  --region: string # Market/location hint. Country or locale-style values such as `US`, `DE`, or `en-GB` are shared by engines that support them. Google also accepts city names such as `Berlin` or `New York` and sends them as `uule`. Yandex accepts numeric `lr` region IDs such as `213`; those IDs are engine-specific and are ignored by other engines.
  --date: string # Date interval in `YYYYMMDD..YYYYMMDD` format. (e.g. 20250101..20250131)
  --file: string # File extension filter (for engines that support it). (e.g. PDF)
  --site: string # Site/domain filter. (e.g. github.com)
  --limit: int # Maximum organic results to return (1-100). Ads may be returned in addition. Omitted or small limits (<=10) parse only the first SERP page; larger limits may paginate when an engine supports it. (default: 10, e.g. 10)
  --start: int # Pagination offset (must be >= 0). (default: 0, e.g. 20)
  --filter: oneof<nothing, bool> # Duplicate filtering flag (primarily used by Google parser behavior). (default: true)
  --features: oneof<nothing, bool> # Populate the top-level serp_features array (AI summaries, answer boxes, people-also-ask, related searches) from the live browser search when supported by the engine.  (default: true)
  --engines: string # Comma-separated engine list for mega endpoints. If omitted, all available engines are used.  (e.g. google,bing,duckduckgo)
  --mode: string@mode-completer # Mega execution mode. `balanced` (default) runs all selected engines in parallel. `any` runs selected engines sequentially in request order until first success. `fast` runs only one engine: the fastest by circuit-breaker average response time.  (default: balanced)
  --dedupe: oneof<nothing, bool> # Enable deduplication by normalized URL. Default `true`.  (default: true)
  --merge: oneof<nothing, bool> # Merge results from all successful engines into one flat list. Default `true`. When `false`, only the first requested engine that returned results is kept.  (default: true)
  --extract: oneof<nothing, bool> # Fetch and embed cleaned target-page content for top web results. (default: false)
  --extract-top: int # Number of top organic results to enrich when `extract=true`. (default: 3)
  --extract-mode: string@extract-mode-completer # Extraction strategy for target pages. (default: auto)
  --min-runes: int # Auto-mode escalation floor: if the fast (raw) pass yields fewer extracted-text runes than this, escalate to a browser render. `0` (default) uses the built-in floor. Ignored in `fast` and `rendered` modes.
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --X-Use-Proxy: string # Request-scoped proxy override. Use `direct` to disable proxy or a tag name to force a specific proxy pool.
  --X-Proxy-URL: string # Per-request proxy URL supplied by an upstream balancer. Honored only when `proxies.allow_request_proxy_url: true` is set on the worker; otherwise the request is rejected with `400 bad_request` and `reason=REQUEST_PROXY_URL_DISABLED`. Authenticated SOCKS proxies are rejected in browser mode (`reason=UNSUPPORTED_PROXY_SCHEME`). Credentials are never logged or returned. Precedence: `X-Use-Proxy: direct` > `X-Proxy-URL` > `X-Use-Proxy: <tag>` > per-engine configured tag > `proxies.global` > direct.  (e.g. http://user:pass@proxy.example:8080)
  --X-Proxy-Country: string # Two-letter market country code for the supplied proxy. Used as part of the cache key so different markets do not share results.  (e.g. us)
  --X-Proxy-Class: string # Proxy class identifier (e.g. `datacenter`, `residential`, `mobile`). Part of the cache key. (e.g. residential)
  --X-Proxy-Provider: string # Upstream proxy provider identifier (e.g. `webshare`, `brightdata`). Part of the cache key. (e.g. webshare)
  --X-Proxy-Session-ID: string # Sticky session identifier minted by the balancer. Reusing the same value lets OpenSERP reuse cookies and browser profile for that lane. Lanes are LRU-bounded by `proxies.lanes.max_lanes`. Rotating the session ID gives a clean lane.  (e.g. sid-123)
  --X-Tenant: string # Optional tenant scope used to namespace sticky lane state across multi-tenant deployments. When present, lanes are keyed by `tenant + engine + session_id`.
]: nothing -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, url: string, display_url: string, snippet: string, domain: string, favicon: string, position: record, engine: string, domain_info: record, classification: record, extracted: record>, serp_features: table<id: string, engine: string, type: string, title: string, text: string, items: list, links: list, source_result_ids: list, position: record, confidence: float, extracted_at: string>, pagination: record<page: int, has_more: bool, next_start: int>, clusters: table<id: string, canonical_url: string, domain: string, title: string, occurrences: list, engines_count: int, best_rank: int, score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "engines" $engines "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "dedupe" $dedupe "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "extract" $extract "scalar") (serialize-qp "extract_top" $extract_top "scalar") (serialize-qp "extract_mode" $extract_mode "scalar") (serialize-qp "min_runes" $min_runes "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mega/search" $qp)
  let extra_headers = {"X-Use-Proxy": $X_Use_Proxy, "X-Proxy-URL": $X_Proxy_URL, "X-Proxy-Country": $X_Proxy_Country, "X-Proxy-Class": $X_Proxy_Class, "X-Proxy-Provider": $X_Proxy_Provider, "X-Proxy-Session-ID": $X_Proxy_Session_ID, "X-Tenant": $X_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Image search across multiple engines with selectable execution mode
#
# GET /mega/image
# operationId: megaImageSearch
export def "mega-image megaImageSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Search query text. At least one of `text`, `site`, or `file` must be non-empty.  (e.g. golang)
  --lang: string # Language code (engine-specific behavior). (e.g. EN)
  --region: string # Market/location hint. Country or locale-style values such as `US`, `DE`, or `en-GB` are shared by engines that support them. Google also accepts city names such as `Berlin` or `New York` and sends them as `uule`. Yandex accepts numeric `lr` region IDs such as `213`; those IDs are engine-specific and are ignored by other engines.
  --date: string # Date interval in `YYYYMMDD..YYYYMMDD` format. (e.g. 20250101..20250131)
  --file: string # File extension filter (for engines that support it). (e.g. PDF)
  --site: string # Site/domain filter. (e.g. github.com)
  --limit: int # Maximum organic results to return (1-100). Ads may be returned in addition. Omitted or small limits (<=10) parse only the first SERP page; larger limits may paginate when an engine supports it. (default: 10, e.g. 10)
  --start: int # Pagination offset (must be >= 0). (default: 0, e.g. 20)
  --filter: oneof<nothing, bool> # Duplicate filtering flag (primarily used by Google parser behavior). (default: true)
  --features: oneof<nothing, bool> # Populate the top-level serp_features array (AI summaries, answer boxes, people-also-ask, related searches) from the live browser search when supported by the engine.  (default: true)
  --engines: string # Comma-separated engine list for mega endpoints. If omitted, all available engines are used.  (e.g. google,bing,duckduckgo)
  --mode: string@mode-completer # Mega execution mode. `balanced` (default) runs all selected engines in parallel. `any` runs selected engines sequentially in request order until first success. `fast` runs only one engine: the fastest by circuit-breaker average response time.  (default: balanced)
  --dedupe: oneof<nothing, bool> # Enable deduplication by normalized URL. Default `true`.  (default: true)
  --merge: oneof<nothing, bool> # Merge results from all successful engines into one flat list. Default `true`. When `false`, only the first requested engine that returned results is kept.  (default: true)
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --X-Use-Proxy: string # Request-scoped proxy override. Use `direct` to disable proxy or a tag name to force a specific proxy pool.
  --X-Proxy-URL: string # Per-request proxy URL supplied by an upstream balancer. Honored only when `proxies.allow_request_proxy_url: true` is set on the worker; otherwise the request is rejected with `400 bad_request` and `reason=REQUEST_PROXY_URL_DISABLED`. Authenticated SOCKS proxies are rejected in browser mode (`reason=UNSUPPORTED_PROXY_SCHEME`). Credentials are never logged or returned. Precedence: `X-Use-Proxy: direct` > `X-Proxy-URL` > `X-Use-Proxy: <tag>` > per-engine configured tag > `proxies.global` > direct.  (e.g. http://user:pass@proxy.example:8080)
  --X-Proxy-Country: string # Two-letter market country code for the supplied proxy. Used as part of the cache key so different markets do not share results.  (e.g. us)
  --X-Proxy-Class: string # Proxy class identifier (e.g. `datacenter`, `residential`, `mobile`). Part of the cache key. (e.g. residential)
  --X-Proxy-Provider: string # Upstream proxy provider identifier (e.g. `webshare`, `brightdata`). Part of the cache key. (e.g. webshare)
  --X-Proxy-Session-ID: string # Sticky session identifier minted by the balancer. Reusing the same value lets OpenSERP reuse cookies and browser profile for that lane. Lanes are LRU-bounded by `proxies.lanes.max_lanes`. Rotating the session ID gives a clean lane.  (e.g. sid-123)
  --X-Tenant: string # Optional tenant scope used to namespace sticky lane state across multi-tenant deployments. When present, lanes are keyed by `tenant + engine + session_id`.
]: nothing -> record<query: record<text: string, lang: string, region: string, engines_requested: list<string>>, meta: record<request_id: string, requested_at: string, took_ms: int, engines_failed: list<string>, engine_errors: list<record>, version: string>, results: table<id: string, rank: int, type: string, title: string, image: record, source: record, engine: string>, pagination: record<page: int, has_more: bool, next_start: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "engines" $engines "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "dedupe" $dedupe "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mega/image" $qp)
  let extra_headers = {"X-Use-Proxy": $X_Use_Proxy, "X-Proxy-URL": $X_Proxy_URL, "X-Proxy-Country": $X_Proxy_Country, "X-Proxy-Class": $X_Proxy_Class, "X-Proxy-Provider": $X_Proxy_Provider, "X-Proxy-Session-ID": $X_Proxy_Session_ID, "X-Tenant": $X_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available engines and runtime state
#
# GET /mega/engines
# operationId: listMegaEngines
export def "mega-engines listMegaEngines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<engines: table<name: string, initialized: bool, circuit_state: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mega/engines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract clean content from one URL
#
# GET /extract
# operationId: extractURL
export def "extract extractURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-url: string # Absolute URL to fetch and extract. (format: uri)
  --mode: string@mode-completer-1 # Extraction strategy for one URL. (default: auto)
  --min-runes: int # Auto-mode escalation floor: if the fast (raw) pass yields fewer extracted-text runes than this, escalate to a browser render. `0` (default) uses the built-in floor. Ignored in `fast` and `rendered` modes.
  --lang: string # Language code (engine-specific behavior). (e.g. EN)
  --clean: oneof<nothing, bool> # Article-only extraction (default). Set `false` for whole-readable-body extraction that keeps nav/feature/landing content trafilatura would otherwise strip — useful for landing pages, doc indexes, and dashboards.  (default: true)
  --use-llms-txt: oneof<nothing, bool> # When the URL is a site root, probe `/llms-full.txt` then `/llms.txt` and return that LLM-optimized markdown instead of scraping HTML (see https://llmstxt.org/). Falls through to normal extraction when absent. Ignored for non-root URLs, where it would miss the requested page's own content.  (default: false)
  --format: string@format-completer # Output format. `json` (default) returns the envelope. `markdown` returns a Markdown document suitable for Slack/email. `text` returns a minimal plain-text block optimised for LLM context windows. `ndjson` returns one result object per line with no envelope. The `Accept` header is also checked (`text/markdown`, `text/plain`, `application/x-ndjson`).  (default: json)
  --X-Use-Proxy: string # Request-scoped proxy override. Use `direct` to disable proxy or a tag name to force a specific proxy pool.
  --X-Proxy-URL: string # Per-request proxy URL supplied by an upstream balancer. Honored only when `proxies.allow_request_proxy_url: true` is set on the worker; otherwise the request is rejected with `400 bad_request` and `reason=REQUEST_PROXY_URL_DISABLED`. Authenticated SOCKS proxies are rejected in browser mode (`reason=UNSUPPORTED_PROXY_SCHEME`). Credentials are never logged or returned. Precedence: `X-Use-Proxy: direct` > `X-Proxy-URL` > `X-Use-Proxy: <tag>` > per-engine configured tag > `proxies.global` > direct.  (e.g. http://user:pass@proxy.example:8080)
]: nothing -> record<url: string, title: string, description: string, markdown: string, text: string, headings: table<level: int, text: string>, links: table<text: string, url: string>, canonical: string, lang: string, schema_org: list<record>, og_tags: record, meta: record<mode_used: string, fetched_at: string, bytes: int, took_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "min_runes" $min_runes "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "use_llms_txt" $use_llms_txt "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extract" $qp)
  let extra_headers = {"X-Use-Proxy": $X_Use_Proxy, "X-Proxy-URL": $X_Proxy_URL} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract clean content from one URL
#
# POST /extract
# operationId: extractURLPost
export def "extract extractURLPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # format: uri
  --mode: string@mode-completer-1 # default: auto
  --clean: oneof<nothing, bool> # Article-only extraction (default). Set `false` for whole-readable-body extraction that keeps nav/feature/landing content trafilatura would otherwise strip.  (default: true)
  --use-llms-txt: oneof<nothing, bool> # When the URL is a site root, probe `/llms-full.txt` then `/llms.txt` and return that LLM-optimized markdown instead of scraping HTML. Falls through to normal extraction when absent.  (default: false)
  --min-runes: int # Auto-mode escalation floor: if the fast (raw) pass yields fewer extracted-text runes than this, escalate to a browser render. `0` (default) uses the built-in floor. Ignored in `fast` and `rendered` modes.
]: any -> record<url: string, title: string, description: string, markdown: string, text: string, headings: table<level: int, text: string>, links: table<text: string, url: string>, canonical: string, lang: string, schema_org: list<record>, og_tags: record, meta: record<mode_used: string, fetched_at: string, bytes: int, took_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extract")
  let body = {url: $body_url, mode: $mode, clean: $clean, use_llms_txt: $use_llms_txt, min_runes: $min_runes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Service health status
#
# GET /health
# operationId: healthCheck
export def "health healthCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, uptime: string, engines: table<name: string, initialized: bool, status: string>, system: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Service readiness status
#
# GET /ready
# operationId: readinessCheck
export def "ready readinessCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Combined cache, proxy, and circuit-breaker stats
#
# GET /stats
# operationId: getStats
export def "stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cache: any, proxy: record<configured_count: int, healthy_count: int, unhealthy_count: int, request_proxy_url_enabled: bool, lanes: record<active: int, evicted_lru: int, cookies_dropped: int>, browser_processes: record<active: int, max: int, evicted_lru: int, evicted_idle: int>, tags: record, entries: list<record>, engines: record>, circuit_breakers: table<engine: string, state: string, failure_count: int, last_changed: string, retry_in: int, avg_response_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cache statistics only
#
# GET /stats/cache
# operationId: getCacheStats
export def "stats-cache get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Proxy pool and per-engine proxy policy statistics
#
# GET /stats/proxy
# operationId: getProxyStats
export def "stats-proxy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<configured_count: int, healthy_count: int, unhealthy_count: int, request_proxy_url_enabled: bool, lanes: record<active: int, evicted_lru: int, cookies_dropped: int>, browser_processes: record<active: int, max: int, evicted_lru: int, evicted_idle: int>, tags: record, entries: table<proxy: string, tags: list, healthy: bool, failures: int, disabled: bool>, engines: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/proxy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Circuit breaker state per engine
#
# GET /stats/cb
# operationId: getCircuitBreakerStats
export def "stats-cb get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<circuit_breakers: table<engine: string, state: string, failure_count: int, last_changed: string, retry_in: int, avg_response_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/cb")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get raw OpenAPI YAML
#
# GET /openapi.yaml
# operationId: getOpenAPISpec
export def "openapiyaml get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openapi.yaml")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Swagger UI for interactive API docs
#
# GET /docs
# operationId: getSwaggerUI
export def "docs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/docs")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
