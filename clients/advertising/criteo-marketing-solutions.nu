# Auto-generated client for Criteo API v2023-10
# Source: https://api.criteo.com/2023-10/marketingsolutions/open-api-specifications.json
# Auth: --token flag or $env.CRITEO_API_TOKEN

const BASE_URL = "https://api.criteo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CRITEO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.criteo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/html"] }
def accept-completer-2 [] { ["application/json" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "text/csv" "text/xml"] }
def format-completer [] { ["csv" "excel" "json" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2023-10-advertisers-me ListAdvertisers" } } | get name | first)
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

# /2023-10/advertisers/me
#
# GET /2023-10/advertisers/me
# operationId: ListAdvertisers
export def "2023-10-advertisers-me ListAdvertisers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<attributes: record, id: string, meta: record, type: string>, errors: table<code: string, detail: string, instance: string, source: record, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/advertisers/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/log-level/advertisers/{advertiser-id}/report
#
# POST /2023-10/log-level/advertisers/{advertiser-id}/report
# operationId: GetTransparencyReport
export def "2023-10-log-level-advertisers-report GetTransparencyReport" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  endDate: string # End date of the report. Date component of ISO 8061 format, any time or timezone component is ignored. (format: date-time)
  --shouldDisplayProductIds: oneof<nothing, bool> # Specify if the product ids are displayed in the report. (default: false)
  startDate: string # Start date of the report. Date component of ISO 8061 format, any time or timezone component is ignored. (format: date-time)
]: any -> record<data: table<attributes: record, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/log-level/advertisers/($advertiser_id)/report")
  let body = {endDate: $endDate, shouldDisplayProductIds: $shouldDisplayProductIds, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ad-sets/{ad-set-id}/audience
#
# PUT /2023-10/marketing-solutions/ad-sets/{ad-set-id}/audience
# operationId: UpdateAdSetAudience
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-ad-sets-audience UpdateAdSetAudience" [
  ad_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API (nullable) — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<audienceId: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ad-sets/($ad_set_id)/audience")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ad-sets/{ad-set-id}/category-bids
#
# GET /2023-10/marketing-solutions/ad-sets/{ad-set-id}/category-bids
# operationId: GetAdSetCategoryBids
export def "2023-10-marketing-solutions-ad-sets-category-bids GetAdSetCategoryBids" [
  ad_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ad-sets/($ad_set_id)/category-bids")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/ad-sets/{ad-set-id}/category-bids
#
# PATCH /2023-10/marketing-solutions/ad-sets/{ad-set-id}/category-bids
# operationId: PatchAdSetCategoryBids
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-ad-sets-category-bids PatchAdSetCategoryBids" [
  ad_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # nullable — item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ad-sets/($ad_set_id)/category-bids")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ad-sets/{ad-set-id}/display-multipliers
#
# GET /2023-10/marketing-solutions/ad-sets/{ad-set-id}/display-multipliers
# operationId: GetDisplayMultipliers
export def "2023-10-marketing-solutions-ad-sets-display-multipliers GetDisplayMultipliers" [
  ad_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ad-sets/($ad_set_id)/display-multipliers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/ad-sets/{ad-set-id}/display-multipliers
#
# PATCH /2023-10/marketing-solutions/ad-sets/{ad-set-id}/display-multipliers
# operationId: PatchDisplayMultipliers
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-ad-sets-display-multipliers PatchDisplayMultipliers" [
  ad_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # nullable — item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ad-sets/($ad_set_id)/display-multipliers")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ad-sets/start
#
# POST /2023-10/marketing-solutions/ad-sets/start
# operationId: StartAdSets
# --data item shape: {id?: string, type?: string}
export def "2023-10-marketing-solutions-ad-sets-start StartAdSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # nullable — item shape: {id?: string, type?: string}
]: any -> record<data: table<id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/ad-sets/start")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ad-sets/stop
#
# POST /2023-10/marketing-solutions/ad-sets/stop
# operationId: StopAdSets
# --data item shape: {id?: string, type?: string}
export def "2023-10-marketing-solutions-ad-sets-stop StopAdSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # nullable — item shape: {id?: string, type?: string}
]: any -> record<data: table<id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/ad-sets/stop")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/ads/{id}
#
# DELETE /2023-10/marketing-solutions/ads/{id}
# operationId: DeleteAd
export def "2023-10-marketing-solutions-ads DeleteAd" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/ads/{id}
#
# GET /2023-10/marketing-solutions/ads/{id}
# operationId: GetAd
export def "2023-10-marketing-solutions-ads GetAd" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<adSetId: string, creativeId: string, description: string, endDate: string, id: string, inventoryType: string, name: string, startDate: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/ads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/ads
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/ads
# operationId: GetAdvertiserAds
export def "2023-10-marketing-solutions-advertisers-ads GetAdvertiserAds" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of ads to be returned. The default is 50. (nullable, format: int32)
  --offset: int # The (zero-based) offset into the collection of ads. The default is 0. (nullable, format: int32)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/ads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/ads
#
# POST /2023-10/marketing-solutions/advertisers/{advertiser-id}/ads
# operationId: CreateAdvertiserAd
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-advertisers-ads CreateAdvertiserAd" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API. — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<adSetId: string, creativeId: string, description: string, endDate: string, id: string, inventoryType: string, name: string, startDate: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/ads")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons
# operationId: GetAdvertiserCoupons
export def "2023-10-marketing-solutions-advertisers-coupons GetAdvertiserCoupons" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of coupons to be returned. The default is 50. (nullable, format: int32)
  --offset: int # The (zero-based) offset into the collection of coupons. The default is 0. (nullable, format: int32)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons
#
# POST /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons
# operationId: CreateAdvertiserCoupon
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-advertisers-coupons CreateAdvertiserCoupon" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API. — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<adSetId: string, advertiserId: string, author: string, description: string, endDate: string, format: string, id: string, images: list, landingPageUrl: string, name: string, rotationsNumber: int, showDuration: int, showEvery: int, startDate: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons-supported-sizes
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons-supported-sizes
# operationId: GetAdvertiserCouponSupportedSizes
export def "2023-10-marketing-solutions-advertisers-coupons-supported-sizes GetAdvertiserCouponSupportedSizes" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-set-id: string # The ad set id on which you want to check the Coupon supported sizes.
]: nothing -> record<data: record<attributes: record<fullFrame: list, logoZone: list>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad-set-id" $ad_set_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons-supported-sizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
#
# DELETE /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
# operationId: DeleteAdvertiserCoupon
export def "2023-10-marketing-solutions-advertisers-coupons DeleteAdvertiserCoupon" [
  advertiser_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
# operationId: GetAdvertiserCoupon
export def "2023-10-marketing-solutions-advertisers-coupons GetAdvertiserCoupon" [
  advertiser_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<adSetId: string, advertiserId: string, author: string, description: string, endDate: string, format: string, id: string, images: list, landingPageUrl: string, name: string, rotationsNumber: int, showDuration: int, showEvery: int, startDate: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
#
# PUT /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}
# operationId: EditAdvertiserCoupon
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-advertisers-coupons EditAdvertiserCoupon" [
  advertiser_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API. — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<adSetId: string, advertiserId: string, author: string, description: string, endDate: string, format: string, id: string, images: list, landingPageUrl: string, name: string, rotationsNumber: int, showDuration: int, showEvery: int, startDate: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons/($id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}/preview
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/coupons/{id}/preview
# operationId: GetAdvertiserCouponPreview
export def "2023-10-marketing-solutions-advertisers-coupons-preview GetAdvertiserCouponPreview" [
  advertiser_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --height: int # The height of the coupon to preview. (format: int32)
  --width: int # The width of the coupon to preview. (format: int32)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/coupons/($id)/preview" $qp)
  let accept_val = ($accept | default "text/html")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/creatives
#
# GET /2023-10/marketing-solutions/advertisers/{advertiser-id}/creatives
# operationId: GetAdvertiserCreatives
export def "2023-10-marketing-solutions-advertisers-creatives GetAdvertiserCreatives" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of creatives to be returned. The default is 50. (nullable, format: int32)
  --offset: int # The (zero-based) offset into the collection of creatives. The default is 0. (nullable, format: int32)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/creatives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/advertisers/{advertiser-id}/creatives
#
# POST /2023-10/marketing-solutions/advertisers/{advertiser-id}/creatives
# operationId: CreateAdvertiserCreative
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-advertisers-creatives CreateAdvertiserCreative" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API. — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<adaptiveAttributes: record, advertiserId: string, author: string, datasetId: string, description: string, dynamicAttributes: record, format: string, htmlTagAttributes: record, id: string, imageAttributes: record, name: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/advertisers/($advertiser_id)/creatives")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments
#
# PATCH /2023-10/marketing-solutions/audience-segments
# operationId: UpdateAudienceSegments
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audience-segments UpdateAudienceSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list
#
# DELETE /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list
# operationId: DeleteContactListByAudienceSegment
export def "2023-10-marketing-solutions-audience-segments-contact-list DeleteContactListByAudienceSegment" [
  audience_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<description: string, name: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: list, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: list, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/audience-segments/($audience_segment_id)/contact-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list
#
# PATCH /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list
# operationId: UpdateContactListByAudienceSegment
# --data shape: {attributes: record, type: string}
export def "2023-10-marketing-solutions-audience-segments-contact-list UpdateContactListByAudienceSegment" [
  audience_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Parameters for the amendment of a contactlist — shape: {attributes: record, type: string}
]: any -> record<data: record<attributes: record<contactListId: int, identifierType: string, nbInvalidIdentifiers: int, nbValidIdentifiers: int, operation: string, requestDate: string, sampleInvalidIdentifiers: list>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: list, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: list, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/audience-segments/($audience_segment_id)/contact-list")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list/statistics
#
# GET /2023-10/marketing-solutions/audience-segments/{audience-segment-id}/contact-list/statistics
# operationId: GetAudienceSegmentContactListStatistics
export def "2023-10-marketing-solutions-audience-segments-contact-list-statistics GetAudienceSegmentContactListStatistics" [
  audience_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<matchRate: float, numberOfIdentifiers: int, numberOfMatches: int>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/audience-segments/($audience_segment_id)/contact-list/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/audience-segments/compute-sizes
#
# POST /2023-10/marketing-solutions/audience-segments/compute-sizes
# operationId: ComputeAudienceSegmentsSizes
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audience-segments-compute-sizes ComputeAudienceSegmentsSizes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/compute-sizes")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/create
#
# POST /2023-10/marketing-solutions/audience-segments/create
# operationId: CreateAudienceSegments
# --data item shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audience-segments-create CreateAudienceSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/create")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/delete
#
# POST /2023-10/marketing-solutions/audience-segments/delete
# operationId: DeleteAudienceSegments
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audience-segments-delete DeleteAudienceSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/estimate-size
#
# POST /2023-10/marketing-solutions/audience-segments/estimate-size
# operationId: EstimateAudienceSegmentsSizes
# --data shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audience-segments-estimate-size EstimateAudienceSegmentsSizes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A top-level object that encapsulates a Criteo API response for a single value — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<size: int>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/estimate-size")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audience-segments/in-market-brands
#
# GET /2023-10/marketing-solutions/audience-segments/in-market-brands
# operationId: GetAudienceSegmentsInMarketBrands
export def "2023-10-marketing-solutions-audience-segments-in-market-brands GetAudienceSegmentsInMarketBrands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertiser-id: string # The advertiser ID.
  --country: string # The ISO 3166-1 alpha-2 country code.
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "advertiser-id" $advertiser_id "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/in-market-brands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/audience-segments/in-market-interests
#
# GET /2023-10/marketing-solutions/audience-segments/in-market-interests
# operationId: GetAudienceSegmentsInMarketInterests
export def "2023-10-marketing-solutions-audience-segments-in-market-interests GetAudienceSegmentsInMarketInterests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertiser-id: string # The advertiser ID.
  --country: string # The ISO 3166-1 alpha-2 country code.
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "advertiser-id" $advertiser_id "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/in-market-interests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/audience-segments/search
#
# POST /2023-10/marketing-solutions/audience-segments/search
# operationId: SearchAudienceSegments
# --data shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audience-segments-search SearchAudienceSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of elements to be returned. The default is 50 and the maximum is 100. (format: int32, default: 50)
  --offset: int # The (zero-based) offset into the collection. The default is 0. (format: int32, default: 0)
  --data: record # A top-level object that encapsulates a Criteo API response for a single value — shape: {attributes?: record, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, meta: record<limit: int, offset: int, totalItems: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/marketing-solutions/audience-segments/search" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences
#
# PATCH /2023-10/marketing-solutions/audiences
# operationId: UpdateAudiences
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audiences UpdateAudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences/compute-sizes
#
# POST /2023-10/marketing-solutions/audiences/compute-sizes
# operationId: ComputeAudiencesSizes
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audiences-compute-sizes ComputeAudiencesSizes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences/compute-sizes")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences/create
#
# POST /2023-10/marketing-solutions/audiences/create
# operationId: CreateAudiences
# --data item shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audiences-create CreateAudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences/create")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences/delete
#
# POST /2023-10/marketing-solutions/audiences/delete
# operationId: DeleteAudiences
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-audiences-delete DeleteAudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences/estimate-size
#
# POST /2023-10/marketing-solutions/audiences/estimate-size
# operationId: EstimateAudiencesSizes
# --data shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audiences-estimate-size EstimateAudiencesSizes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A top-level object that encapsulates a Criteo API response for a single value — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<size: int>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences/estimate-size")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/audiences/search
#
# POST /2023-10/marketing-solutions/audiences/search
# operationId: SearchAudiences
# --data shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-audiences-search SearchAudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of elements to be returned. The default is 50 and the maximum is 100. (format: int32, default: 50)
  --offset: int # The (zero-based) offset into the collection. The default is 0. (format: int32, default: 0)
  --data: record # A top-level object that encapsulates a Criteo API response for a single value — shape: {attributes?: record, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, meta: record<limit: int, offset: int, totalItems: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/marketing-solutions/audiences/search" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/campaigns
#
# PATCH /2023-10/marketing-solutions/campaigns
# operationId: PatchCampaigns
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-campaigns PatchCampaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # nullable — item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/campaigns")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/campaigns
#
# POST /2023-10/marketing-solutions/campaigns
# operationId: CreateCampaign
# --data shape: {attributes?: record, type?: string}
export def "2023-10-marketing-solutions-campaigns CreateCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # Data model for a Resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<advertiserId: string, budgetAutomation: record, goal: string, id: string, name: string, spendLimit: record>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/campaigns")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/creatives/{id}
#
# DELETE /2023-10/marketing-solutions/creatives/{id}
# operationId: DeleteCreative
export def "2023-10-marketing-solutions-creatives DeleteCreative" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/creatives/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/creatives/{id}
#
# GET /2023-10/marketing-solutions/creatives/{id}
# operationId: GetCreative
export def "2023-10-marketing-solutions-creatives GetCreative" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<adaptiveAttributes: record, advertiserId: string, author: string, datasetId: string, description: string, dynamicAttributes: record, format: string, htmlTagAttributes: record, id: string, imageAttributes: record, name: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/creatives/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/creatives/{id}
#
# PUT /2023-10/marketing-solutions/creatives/{id}
# operationId: EditCreative
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-marketing-solutions-creatives EditCreative" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A class that represents a domain entity exposed by an API. — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<adaptiveAttributes: record, advertiserId: string, author: string, datasetId: string, description: string, dynamicAttributes: record, format: string, htmlTagAttributes: record, id: string, imageAttributes: record, name: string, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/marketing-solutions/creatives/($id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/marketing-solutions/creatives/{id}/preview
#
# POST /2023-10/marketing-solutions/creatives/{id}/preview
# operationId: GenerateCreativePreview
export def "2023-10-marketing-solutions-creatives-preview GenerateCreativePreview" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --height: int # The height of the Creative to preview. (format: int32)
  --width: int # The width of the Creative to preview. (format: int32)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/marketing-solutions/creatives/($id)/preview" $qp)
  let accept_val = ($accept | default "text/html")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/marketing-solutions/me
#
# GET /2023-10/marketing-solutions/me
# operationId: GetCurrentApplication
export def "2023-10-marketing-solutions-me GetCurrentApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<applicationId: int, criteoService: string, description: string, name: string, organizationId: int>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/marketing-solutions/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /2023-10/placements/report
#
# POST /2023-10/placements/report
# operationId: GetPlacementsReport
# --data item shape: {attributes?: record, type?: string}
export def "2023-10-placements-report GetPlacementsReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --data: list # nullable — item shape: {attributes?: record, type?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/placements/report")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/statistics/report
#
# POST /2023-10/statistics/report
# operationId: GetAdsetReport
export def "2023-10-statistics-report GetAdsetReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --adSetIds: list # list of adSets ids. If empty, all the adSets will be fetched (nullable)
  --adSetNames: list # list of adSets names. If empty, all the adSets will be fetched (nullable)
  --adSetStatus: list # list of adSets status. If empty, all the adSets will be fetched (nullable)
  --advertiserIds: string # The comma-separated list of advertiser ids. If empty, all the advertisers in the portfolio will be used (nullable)
  currency: string # The currency used for the report. ISO 4217 code (three-letter capitals).
  dimensions: list # The dimensions for the report.
  endDate: string # End date of the report. Date component of ISO 8061 format, any time or timezone component is ignored. (format: date-time)
  --format: string@format-completer # The file format of the generated report (default: json)
  metrics: list # The list of metrics to report.
  startDate: string # Start date of the report. Date component of ISO 8061 format, any time or timezone component is ignored. (format: date-time)
  --timezone: string # The timezone used for the report. Timezone Database format (Tz). (nullable, default: UTC)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/statistics/report")
  let body = {adSetIds: $adSetIds, adSetNames: $adSetNames, adSetStatus: $adSetStatus, advertiserIds: $advertiserIds, currency: $currency, dimensions: $dimensions, endDate: $endDate, format: $format, metrics: $metrics, startDate: $startDate, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /2023-10/transactions/report
#
# POST /2023-10/transactions/report
# operationId: GetTransactionsReport
# --data item shape: {attributes?: record, type?: string}
export def "2023-10-transactions-report GetTransactionsReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --data: list # nullable — item shape: {attributes?: record, type?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/transactions/report")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
