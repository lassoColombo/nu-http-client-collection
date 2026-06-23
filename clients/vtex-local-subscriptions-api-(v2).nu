# Auto-generated client for Subscriptions API (v2 - DEPRECATED) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Subscriptions-API-(v2)/1.0/openapi.json
# Auth: --token flag or $env.SUBSCRIPTIONS_API_V2_DEPRECATED_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br/api/rns"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "report-report-status get-reportstatusby" } } | get name | first)
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

# Get report status by ID
#
# GET /report/reportStatus/{reportId}
# operationId: GetreportstatusbyID
export def "report-report-status get-reportstatusby" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/report/reportStatus/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve Subscription report by date
#
# GET /report/subscriptionsByDate
# operationId: Requestreportbydate
export def "report-subscriptions-by-date get-requestreportbydate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requester-email: string # Email that the report will be sent to (e.g. user@vtex.com.br)
  --begin-date: int # begin date of report interval, use format yyyyMMdd (format: int32, e.g. 20190101)
  --end-date: int # end date of report interval, use format yyyyMMdd (format: int32, e.g. 20190701)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requesterEmail" $requester_email "scalar") (serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/subscriptionsByDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"requesterEmail": $requester_email, "beginDate": $begin_date, "endDate": $end_date} | compact), body: null}
}

# Retrieve Subscription report by Status
#
# GET /report/subscriptionsByStatus
# operationId: RequestreportbyStatus
export def "report-subscriptions-by-status get-requestreportby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requester-email: string # Email that the report will be sent to (e.g. user@vtex.com.br)
  --status: int # Binary OR of the following status: 1 - ACTIVE; 2 - PAUSED; 4 - CANCELED; 8 - EXPIRED (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requesterEmail" $requester_email "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/subscriptionsByStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"requesterEmail": $requester_email, "status": $status} | compact), body: null}
}

# Retrieve Subscription report by order date
#
# GET /report/subscriptionsOrderByDate
# operationId: Requestreportbyorderdate
export def "report-subscriptions-order-by-date get-requestreportbyorderdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requester-email: string # Email that the report will be sent to (e.g. user@vtex.com.br)
  --begin-date: int # begin date of report interval, use format yyyyMMdd (format: int32, e.g. 20190101)
  --end-date: int # end date of report interval, use format yyyyMMdd (format: int32, e.g. 20190701)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requesterEmail" $requester_email "scalar") (serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/subscriptionsOrderByDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"requesterEmail": $requester_email, "beginDate": $begin_date, "endDate": $end_date} | compact), body: null}
}

# Retrieve Subscription report by schedule
#
# GET /report/subscriptionsScheduled
# operationId: Requestreportbyschedule
export def "report-subscriptions-scheduled get-requestreportbyschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requester-email: string # Email that the report will be sent to (e.g. user@vtex.com.br)
  --begin-date: int # begin date of report interval, use format yyyyMMdd (format: int32, e.g. 20190101)
  --end-date: int # end date of report interval, use format yyyyMMdd (format: int32, e.g. 20190701)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requesterEmail" $requester_email "scalar") (serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/subscriptionsScheduled" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"requesterEmail": $requester_email, "beginDate": $begin_date, "endDate": $end_date} | compact), body: null}
}

# Request report by update
#
# GET /report/subscriptionsUpdated
# operationId: Requestreportbyupdate
export def "report-subscriptions-updated get-requestreportbyupdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requester-email: string # Email that the report will be sent to (e.g. user@vtex.com.br)
  --begin-date: int # begin date of report interval, use format yyyyMMdd (format: int32, e.g. 20190101)
  --end-date: int # end date of report interval, use format yyyyMMdd (format: int32, e.g. 20190701)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requesterEmail" $requester_email "scalar") (serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/subscriptionsUpdated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"requesterEmail": $requester_email, "beginDate": $begin_date, "endDate": $end_date} | compact), body: null}
}

# Get Subscriptions Settings
#
# GET /settings
# operationId: GetSettings
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit Subscriptions settings
#
# POST /settings
# operationId: EditSettings
export def "settings create-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --default-sla: string # Default delivery method. (nullable)
  delivery_channels: list<string> # Array containing delivery channels. (default: [], e.g. delivery)
  execution_hour_in_utc: int # Indicates the time future subscription orders will be generated. (default: 0, e.g. 9)
  --is-multiple-installments-enabled-on-creation: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is created. (default: false, e.g. false)
  --is-multiple-installments-enabled-on-update: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is updated. (default: false, e.g. false)
  --is-using-v3: oneof<nothing, bool> # Indicates whether or not Subscriptions V3 is enabled. (default: false, e.g. true)
  --manual-price-allowed: oneof<nothing, bool> # When set to `true`, this property enables manual price configuration in subscription items. This is valid for all existing subscriptions, provided that there is a manual price configured and that `isUsingV3` is `true`. (default: false, e.g. false)
  --on-migration-process: oneof<nothing, bool> # Indicates whether or not the account is in the migration process to Subscriptions V3. (default: false, e.g. false)
  order_custom_data_app_id: string # When filled, this field passes along the `customData` infomration in the order to the future recurrent subscription orders.
  --postpone-expiration: oneof<nothing, bool> # Defines whether or not the expiration of subscriptions can be postponed. (default: false, e.g. false)
  --random-id-generation: oneof<nothing, bool> # Defines whether or not the subscription order IDs will be randomly generated. (default: false, e.g. false)
  sla_option: string # Delivery method. (default: , e.g. NONE)
  --use-item-price-from-original-order: oneof<nothing, bool> # When set to `true`, this property enables using the manual price for each item from the original subscription order. This is only valid for new subscriptions, created from the moment this configuration is enabled. For this to work, it is mandatory that the `manualPriceAllowed` property is set to `true` and that `isUsingV3` is `true`. (default: false, e.g. false)
  workflow_version: string # Workflow version. (default: , e.g. 1.1)
]: any -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let req_body = {"defaultSla": $default_sla, "deliveryChannels": $delivery_channels, "executionHourInUtc": $execution_hour_in_utc, "isMultipleInstallmentsEnabledOnCreation": $is_multiple_installments_enabled_on_creation, "isMultipleInstallmentsEnabledOnUpdate": $is_multiple_installments_enabled_on_update, "isUsingV3": $is_using_v3, "manualPriceAllowed": $manual_price_allowed, "onMigrationProcess": $on_migration_process, "orderCustomDataAppId": $order_custom_data_app_id, "postponeExpiration": $postpone_expiration, "randomIdGeneration": $random_id_generation, "slaOption": $sla_option, "useItemPriceFromOriginalOrder": $use_item_price_from_original_order, "workflowVersion": $workflow_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Retrieve customer's subscriptions
#
# GET /subscriptions
# operationId: Getsubscriptionstocustomer
export def "subscriptions get-subscriptionstocustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Customer ID. (e.g. user@vtex.com.br)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customerId" $customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customerId": $customer_id} | compact), body: null}
}

# List All subscription groups
#
# GET /subscriptions-group
# operationId: GetAllsubscriptiongroup
export def "subscriptions-group get-allsubscriptiongroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions-group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get subscription group list
#
# GET /subscriptions-group/list
# operationId: Getsubscriptiongrouplist
export def "subscriptions-group-list get-subscriptiongrouplist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions-group/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Next purchase
#
# GET /subscriptions-group/nextPurchase/{dateStr}
# operationId: GetNextpurchase
export def "subscriptions-group-next-purchase get-nextpurchase" [
  date_str: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($date_str | is-empty) { error make --unspanned { msg: "path parameter 'dateStr' must be non-empty" } }
  let full_url = (build-url $base ({date_str: (encode-path-segment $date_str)} | format pattern "/subscriptions-group/nextPurchase/{date_str}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Simulation by subscription-group
#
# GET /subscriptions-group/simulate/{groupId}
# operationId: GetSimulatebysubscription-group
export def "subscriptions-group-simulate get-simulatebysubscription" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/simulate/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Subscription by groupId
#
# GET /subscriptions-group/{groupId}
# operationId: GetSubscriptionbygroupId
export def "subscriptions-group get-subscriptionbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Subscription by groupId
#
# PATCH /subscriptions-group/{groupId}
# operationId: UpdateSubscriptionbygroupId
# --item item shape: {SubscriptionId: string, createdAt: string, cycleCount: int, endpoint: string, isSkipped: bool, lastUpdate: string, metadata: list, originalItemIndex: int, originalOrderId: string, priceAtSubscriptionDate: int, quantity: int, sellingPrice: int, sku: record, status: string}
# --metadata item shape: {name: string, properties: record}
# --plan shape: {frequency: record, type: string, validity: record}
# --purchaseSettings shape: {currencyCode: string, paymentMethod: record, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string}
# --shippingAddress shape: {additionalComponents: list, addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: list<int>, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string}
export def "subscriptions-group update-subscriptionbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-skipped: oneof<nothing, bool>
  item: list # item shape: {SubscriptionId: string, createdAt: string, cycleCount: int, endpoint: string, isSkipped: bool, lastUpdate: string, metadata: list, originalItemIndex: int, originalOrderId: string, priceAtSubscriptionDate: int, quantity: int, sellingPrice: int, sku: record, status: string}
  metadata: list # item shape: {name: string, properties: record}
  plan: record # e.g. {frequency: {interval: 0, periodicity: string}, type: string, validity: {begin: 2019-07-04T14:40:30.819Z, end: 2019-07-04T14:40:30.819Z}} — shape: {frequency: record, type: string, validity: record}
  purchase_settings: record # e.g. {currencyCode: string, paymentMethod: {paymentAccountId: string, paymentSystem: string}, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string} — shape: {currencyCode: string, paymentMethod: record, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string}
  shipping_address: record # e.g. {additionalComponents: [{longName: string, shortName: string, types: [string]}], addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: [0], neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string} — shape: {additionalComponents: list, addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: list<int>, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string}
  status: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}"))
  let req_body = {"isSkipped": $is_skipped, "item": $item, "metadata": $metadata, "plan": $plan, "purchaseSettings": $purchase_settings, "shippingAddress": $shipping_address, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add Subscription item by groupId
#
# POST /subscriptions-group/{groupId}/additem
# operationId: Additemsubscription-groupId
# --sku shape: {detailUrl: string, id: string, imageUrl: string, name: string, nameComplete: string, productName: string}
export def "subscriptions-group-additem create-additemsubscription" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  endpoint: string
  price_at_subscription_date: int # format: int32
  quantity: int # format: int32
  selling_price: int # format: int32
  sku: record # e.g. {detailUrl: string, id: string, imageUrl: string, name: string, nameComplete: string, productName: string} — shape: {detailUrl: string, id: string, imageUrl: string, name: string, nameComplete: string, productName: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/additem"))
  let req_body = {"endpoint": $endpoint, "priceAtSubscriptionDate": $price_at_subscription_date, "quantity": $quantity, "sellingPrice": $selling_price, "sku": $sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get addresses by groupId
#
# GET /subscriptions-group/{groupId}/addresses
# operationId: GetaddressesbygroupId
export def "subscriptions-group-addresses get-addressesbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/addresses"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Insert Addresses by groupId
#
# POST /subscriptions-group/{groupId}/addresses
# operationId: InsertAddressesbygroupId
# --additionalComponents item shape: {longName: string, shortName: string, types: list<string>}
export def "subscriptions-group-addresses create-addressesbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  additional_components: list # item shape: {longName: string, shortName: string, types: list<string>}
  address_id: string
  address_name: string
  address_type: string
  city: string
  complement: string
  country: string
  formatted_address: string
  geo_coordinate: list<int>
  neighborhood: string
  number: string
  postal_code: string
  receiver_name: string
  reference: string
  state: string
  street: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/addresses"))
  let req_body = {"additionalComponents": $additional_components, "addressId": $address_id, "addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "formattedAddress": $formatted_address, "geoCoordinate": $geo_coordinate, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Cancel Subscription by groupId
#
# PATCH /subscriptions-group/{groupId}/cancel
# operationId: CancelSubscriptionbygroupId
export def "subscriptions-group-cancel cancel-subscriptionbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Subscription group's Configuration
#
# GET /subscriptions-group/{groupId}/config
# operationId: GetConfigsubscriptionsgroup
export def "subscriptions-group-config get-configsubscriptionsgroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Conversation Message by groupId
#
# GET /subscriptions-group/{groupId}/conversation-message
# operationId: GetConversationMessagebygroupId
export def "subscriptions-group-conversation-message get-messagebygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/conversation-message"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get frequency options by groupId
#
# GET /subscriptions-group/{groupId}/frequency-options
# operationId: GetfrequencyoptionsbygroupId
export def "subscriptions-group-frequency-options get-frequencyoptionsbygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/frequency-options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get payment System by groupId
#
# GET /subscriptions-group/{groupId}/payment-systems
# operationId: GetpaymentSystembygroupId
export def "subscriptions-group-payment-systems get-systembygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/payment-systems"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List 'Will create' by groupId
#
# GET /subscriptions-group/{groupId}/will-create
# operationId: GetwillcreatebygroupId
export def "subscriptions-group-will-create get-willcreatebygroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions-group/{group_id}/will-create"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retry subscription by groupId
#
# POST /subscriptions-group/{groupid}/instances/{instanceId}/retry
# operationId: RetrysubscriptionbygroupId
export def "subscriptions-group-instances-retry create-retrysubscriptionbygroup" [
  groupid: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instanceId' must be non-empty" } }
  let full_url = (build-url $base ({groupid: (encode-path-segment $groupid), instance_id: (encode-path-segment $instance_id)} | format pattern "/subscriptions-group/{groupid}/instances/{instance_id}/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Subscription List
#
# GET /subscriptions/list
# operationId: GetSubscriptionList
export def "subscriptions-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve subscription by ID
#
# GET /subscriptions/{subscriptionId}
# operationId: GetsubscriptionbyId
export def "subscriptions get-subscriptionby" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Subscriptions by SubscriptionId
#
# PATCH /subscriptions/{subscriptionId}
# operationId: UpdateSubscriptionsbySubscriptionId
# --item shape: {endpoint: string, priceAtSubscriptionDate: int, quantity: int, sellingPrice: int, sku: record}
# --metadata item shape: {name: string, properties: record}
# --plan shape: {frequency: record, type: string, validity: record}
# --purchaseSettings shape: {currencyCode: string, paymentMethod: record, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string}
# --shippingAddress shape: {additionalComponents: list, addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: list<int>, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string}
export def "subscriptions update-subscriptionsby" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --is-skipped: oneof<nothing, bool>
  item: record # e.g. {endpoint: string, priceAtSubscriptionDate: 0, quantity: 0, sellingPrice: 0, sku: {detailUrl: string, id: string, imageUrl: string, name: string, nameComplete: string, productName: string}} — shape: {endpoint: string, priceAtSubscriptionDate: int, quantity: int, sellingPrice: int, sku: record}
  metadata: list # item shape: {name: string, properties: record}
  plan: record # e.g. {frequency: {interval: 0, periodicity: string}, type: string, validity: {begin: 2019-07-04T14:40:30.819Z, end: 2019-07-04T14:40:30.819Z}} — shape: {frequency: record, type: string, validity: record}
  purchase_settings: record # e.g. {currencyCode: string, paymentMethod: {paymentAccountId: string, paymentSystem: string}, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string} — shape: {currencyCode: string, paymentMethod: record, purchaseDay: string, salesChannel: string, selectedSla: string, seller: string}
  shipping_address: record # e.g. {additionalComponents: [{longName: string, shortName: string, types: [string]}], addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: [0], neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string} — shape: {additionalComponents: list, addressId: string, addressName: string, addressType: string, city: string, complement: string, country: string, formattedAddress: string, geoCoordinate: list<int>, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string}
  status: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}"))
  let req_body = {"isSkipped": $is_skipped, "item": $item, "metadata": $metadata, "plan": $plan, "purchaseSettings": $purchase_settings, "shippingAddress": $shipping_address, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Insert Addresses for Subscription
#
# POST /subscriptions/{subscriptionId}/addresses
# operationId: InsertAddressesforSubscription
export def "subscriptions-addresses create-addressesfor" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/addresses"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Cancel Subscriptions by SubscriptionId
#
# PATCH /subscriptions/{subscriptionId}/cancel
# operationId: CancelSubscriptionsbySubscriptionId
export def "subscriptions-cancel cancel-subscriptionsby" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get frequency options by subscriptionId
#
# GET /subscriptions/{subscriptionId}/frequency-options
# operationId: GetfrequencyoptionsbysubscriptionId
export def "subscriptions-frequency-options get-frequencyoptionsbysubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V2_DEPRECATED_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/frequency-options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
