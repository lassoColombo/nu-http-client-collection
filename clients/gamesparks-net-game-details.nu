# Auto-generated client for GameSparks Game Details API vv2
# Source: https://api.apis.guru/v2/specs/gamesparks.net/game-details/v2/openapi.json
# Auth: --token flag or $env.GAMESPARKS_GAME_DETAILS_API_TOKEN

const BASE_URL = "http://localhost//config2.gamesparks.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GAMESPARKS_GAME_DETAILS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "accesstoken" => { {scheme: $scheme, headers: {accessToken: $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "jwt" => { {scheme: $scheme, headers: {jwt: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://localhost//config2.gamesparks.net"] }
def auth-scheme-completer [] { ["accesstoken" "basic" "jwt" "basic-credentials"] }

# Completers for enum parameters
def stage-completer [] { ["LIVE" "PREVIEW"] }
def data-type-completer [] { ["activeDevices" "activeLocations" "activeUsers" "averageBandwidthPerUser" "averageDauOverMau" "averageJsExecutionTime" "averageRequestsPerUser" "averageResponseTime" "averageResponseTimePerType" "connectedUsers" "customAnalyticTotal" "customAnalyticUser" "scriptLogLevelsCount" "sessionAnalytic" "sessionAnalyticTotal" "storagePerUser" "timedAnalyticTotal"] }
def precision-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }
def query-name-completer [] { ["activeUsersNow" "averageDailyActiveUsers" "averageSessionDuration" "dailyActiveUsers" "lastMonthlyActiveUsers" "monthlyActiveUsers"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "restv2-game-regions list" } } | get name | first)
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

# getRegionOptions
#
# GET /restv2/game/regions
# operationId: getRegionOptionsUsingGET
export def "restv2-game-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/game/regions")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the results of executed query defined by the parameters passed in
#
# GET /restv2/game/{apiKey}/admin/analytics
# operationId: getAnalyticsDataUsingGET
export def "restv2-game-admin-analytics get-data-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --data-type: string@data-type-completer # dataType
  --precision: string@precision-completer # precision
  --start-date: string # yyyy-MM-dd (format: date)
  --end-date: string # yyyy-MM-dd (format: date)
  --keys: string # the keys to select. For example "ReturningUsers", "NewUsers", etc
]: nothing -> table<_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "dataType" $data_type "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stage": $stage, "dataType": $data_type, "precision": $precision, "startDate": $start_date, "endDate": $end_date, "keys": $keys} | compact), body: null}
}

# Returns the count of executed query
#
# GET /restv2/game/{apiKey}/admin/analytics/count
# operationId: getDataCountUsingGET
export def "restv2-game-admin-analytics-count get-data-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --query-name: string@query-name-completer # queryName
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "queryName" $query_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics/count") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stage": $stage, "queryName": $query_name} | compact), body: null}
}

# Returns the percentage of user retention over the last 30 days
#
# GET /restv2/game/{apiKey}/admin/analytics/rollingRetention
# operationId: getRetentionUsingGET
export def "restv2-game-admin-analytics-rolling-retention get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "stage" $stage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics/rollingRetention") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stage": $stage} | compact), body: null}
}

# Retrieves the Billing Details
#
# GET /restv2/game/{apiKey}/admin/billingDetails
# operationId: getBillingDetails
export def "restv2-game-admin-billing-details get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/billingDetails"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the Billing Details
#
# PUT /restv2/game/{apiKey}/admin/billingDetails
# operationId: putBillingDetails
export def "restv2-game-admin-billing-details update" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  building: string
  city: string
  company_name: string
  country: string
  email1: string
  --email2: string
  --email3: string
  first_name1: string
  --first-name2: string
  --first-name3: string
  last_name1: string
  --last-name2: string
  --last-name3: string
  postcode: string
  --state: string
  street: string
  --tax-number: string
]: any -> record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/billingDetails"))
  let req_body = {"building": $building, "city": $city, "companyName": $company_name, "country": $country, "email1": $email1, "email2": $email2, "email3": $email3, "firstName1": $first_name1, "firstName2": $first_name2, "firstName3": $first_name3, "lastName1": $last_name1, "lastName2": $last_name2, "lastName3": $last_name3, "postcode": $postcode, "state": $state, "street": $street, "taxNumber": $tax_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# getGameSummary
#
# GET /restv2/game/{apiKey}/admin/notifications/summary
# operationId: getGameSummaryUsingGET
export def "restv2-game-admin-notifications-summary get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --start-date: string # yyyy-MM-dd (format: date)
  --end-date: string # yyyy-MM-dd (format: date)
]: nothing -> record<logLevelData: list<record>, logLevelSummary: table<count: int, level: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/notifications/summary") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stage": $stage, "startDate": $start_date, "endDate": $end_date} | compact), body: null}
}

# testPushAmazonNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/amazon
# operationId: testPushAmazonNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-amazon create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/amazon"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testPushAppleDevNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/development
# operationId: testPushAppleDevNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-apple-development create-dev-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/apple/development"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testPushAppleProdNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/production
# operationId: testPushAppleProdNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-apple-production create-prod-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/apple/production"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testPushGoogleNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/google
# operationId: testPushGoogleNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-google create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/google"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testWindows8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windows8
# operationId: testWindows8NotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-microsoft-windows8 create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/microsoft/windows8"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testWindowsPhone8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windowsPhone8
# operationId: testWindowsPhone8NotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-microsoft-windows-phone8 create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/microsoft/windowsPhone8"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testViberIntegrationNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/integration
# operationId: testViberIntegrationNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-viber-integration create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/viber/integration"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# testViberProductionNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/production
# operationId: testViberProductionNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-viber-production create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/viber/production"))
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# getScriptDifferences
#
# GET /restv2/game/{apiKey}/admin/scripts/differences/{snapshotId1}/{snapshotId2}
# operationId: getScriptDifferencesUsingGET
export def "restv2-game-admin-scripts-differences get-using" [
  api_key: string
  snapshot_id1: string
  snapshot_id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id1 | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId1' must be non-empty" } }
  if ($snapshot_id2 | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId2' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id1: (encode-path-segment $snapshot_id1), snapshot_id2: (encode-path-segment $snapshot_id2)} | format pattern "/restv2/game/{api_key}/admin/scripts/differences/{snapshot_id1}/{snapshot_id2}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# exportZip
#
# GET /restv2/game/{apiKey}/admin/scripts/export
# operationId: exportZipUsingGET
export def "restv2-game-admin-scripts-export get-zip-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# importAccept
#
# POST /restv2/game/{apiKey}/admin/scripts/import/accept
# operationId: importAcceptUsingPOST
export def "restv2-game-admin-scripts-import-accept create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # body
  file: string # file (format: binary)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "body" $body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/import/accept") $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"body": $body} | compact), body: $req_body}
}

# importZip
#
# POST /restv2/game/{apiKey}/admin/scripts/import/preview
# operationId: importZipUsingPOST
export def "restv2-game-admin-scripts-import-preview create-zip-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # file (format: binary)
]: any -> record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/import/preview"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions
# operationId: getScriptVersionsUsingGET_1
export def "restv2-game-admin-scripts-versions get-using-by-api-key" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 100)
]: nothing -> record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/versions") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageSize": $page_size} | compact), body: null}
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions/{page}
# operationId: getScriptVersionsUsingGET
export def "restv2-game-admin-scripts-versions get-using" [
  api_key: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 100)
]: nothing -> record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), page: (encode-path-segment $page)} | format pattern "/restv2/game/{api_key}/admin/scripts/versions/{page}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageSize": $page_size} | compact), body: null}
}

# getSegmentQueryFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters
# operationId: getSegmentQueryFiltersUsingGET
export def "restv2-game-admin-segment-query-filters get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filters: table<key: string, name: string, options: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSegmentQueryFiltersConfig
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: getSegmentQueryFiltersConfigUsingGET
export def "restv2-game-admin-segment-query-filters-config get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/config"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateSegmentQueryFiltersConfig
#
# PUT /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: updateSegmentQueryFiltersConfigUsingPUT
# --customFilters item shape: {key?: string, name?: string, options?: list, type?: string}
export def "restv2-game-admin-segment-query-filters-config update-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-filters: list # item shape: {key?: string, name?: string, options?: list, type?: string}
  --hidden-filters: list<string>
]: any -> record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/config"))
  let req_body = {"customFilters": $custom_filters, "hiddenFilters": $hidden_filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# getSegmentQueryStandardFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/standardFilters
# operationId: getSegmentQueryStandardFiltersUsingGET
export def "restv2-game-admin-segment-query-filters-standard-filters get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filters: table<key: string, name: string, options: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/standardFilters"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots
# operationId: getSnapshotsUsingGET_1
export def "restv2-game-admin-snapshots get-using-by-api-key" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 20)
]: nothing -> table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageSize": $page_size} | compact), body: null}
}

# createSnapshots
#
# POST /restv2/game/{apiKey}/admin/snapshots
# operationId: createSnapshotsUsingPOST
export def "restv2-game-admin-snapshots create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots"))
  let req_body = {"description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# getLiveSnapshotId
#
# GET /restv2/game/{apiKey}/admin/snapshots/liveSnapshotId
# operationId: getLiveSnapshotIdUsingGET
export def "restv2-game-admin-snapshots-live-snapshot-id get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots/liveSnapshotId"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots/page/{page}
# operationId: getSnapshotsUsingGET
export def "restv2-game-admin-snapshots-page get-using" [
  api_key: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 20)
]: nothing -> table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), page: (encode-path-segment $page)} | format pattern "/restv2/game/{api_key}/admin/snapshots/page/{page}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageSize": $page_size} | compact), body: null}
}

# revertToSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/revert/to/{snapshotId}
# operationId: revertToSnapshotUsingPOST
export def "restv2-game-admin-snapshots-revert-to create-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/revert/to/{snapshot_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE_1
export def "restv2-game-admin-snapshots delete-using-by-api-key-snapshot-id" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSnapshot
#
# GET /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: getSnapshotUsingGET
export def "restv2-game-admin-snapshots get-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# copySnapshotToNewGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy
# operationId: copySnapshotToNewGameUsingPOST
export def "restv2-game-admin-snapshots-copy create-to-new-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-game-config: oneof<nothing, bool> # includeGameConfig (default: true)
  --include-metadata: oneof<nothing, bool> # includeMetadata (default: true)
  --include-binaries: oneof<nothing, bool> # includeBinaries (default: true)
  --include-collaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> record<targetGameApiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "includeGameConfig" $include_game_config "scalar") (serialize-qp "includeMetadata" $include_metadata "scalar") (serialize-qp "includeBinaries" $include_binaries "scalar") (serialize-qp "includeCollaborators" $include_collaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/copy") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeGameConfig": $include_game_config, "includeMetadata": $include_metadata, "includeBinaries": $include_binaries, "includeCollaborators": $include_collaborators} | compact), body: null}
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST_1
export def "restv2-game-admin-snapshots-copy-to create-existing-using-by-api-key-snapshot-id-target-api-key" [
  api_key: string
  snapshot_id: string
  target_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-game-config: oneof<nothing, bool> # includeGameConfig (default: true)
  --include-metadata: oneof<nothing, bool> # includeMetadata (default: true)
  --include-binaries: oneof<nothing, bool> # includeBinaries (default: true)
  --include-collaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> record<targetGameApiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($target_api_key | is-empty) { error make --unspanned { msg: "path parameter 'targetApiKey' must be non-empty" } }
  let qp = [(serialize-qp "includeGameConfig" $include_game_config "scalar") (serialize-qp "includeMetadata" $include_metadata "scalar") (serialize-qp "includeBinaries" $include_binaries "scalar") (serialize-qp "includeCollaborators" $include_collaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id), target_api_key: (encode-path-segment $target_api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/copy/to/{target_api_key}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeGameConfig": $include_game_config, "includeMetadata": $include_metadata, "includeBinaries": $include_binaries, "includeCollaborators": $include_collaborators} | compact), body: null}
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST_1
export def "restv2-game-admin-snapshots-publish create-using-by-api-key-snapshot-id" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# unpublishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/unpublish
# operationId: unpublishSnapshotUsingPOST
export def "restv2-game-admin-snapshots-unpublish create-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/unpublish"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getTestHarnessScenarios
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: getTestHarnessScenariosUsingGET
export def "restv2-game-admin-test-harness-scenarios list" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<scenarioJson: record, scenarioName: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createTestHarnessScenario
#
# POST /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: createTestHarnessScenarioUsingPOST
export def "restv2-game-admin-test-harness-scenarios create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenario-json: record
  --scenario-name: string
]: any -> record<scenarioJson: record, scenarioName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios"))
  let req_body = {"scenarioJson": $scenario_json, "scenarioName": $scenario_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteTestHarnessScenario
#
# DELETE /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: deleteTestHarnessScenarioUsingDELETE
export def "restv2-game-admin-test-harness-scenarios delete-using" [
  api_key: string
  scenario_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getTestHarnessScenario
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: getTestHarnessScenarioUsingGET
export def "restv2-game-admin-test-harness-scenarios get-using" [
  api_key: string
  scenario_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<scenarioJson: record, scenarioName: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateTestHarnessScenario
#
# PUT /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: updateTestHarnessScenarioUsingPUT
export def "restv2-game-admin-test-harness-scenarios update-using" [
  api_key: string
  scenario_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenario-json: record
  --body-scenario-name: string
]: any -> record<scenarioJson: record, scenarioName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}"))
  let req_body = {"scenarioJson": $scenario_json, "scenarioName": $body_scenario_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resets the secret of a credential
#
# POST /restv2/game/{apiKey}/config/~credentials/{credentialName}/resetSecret
# operationId: updateCredentialSecretUsingPOST
export def "restv2-game-config-credentials-reset-secret update-credential-using-create" [
  api_key: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($credential_name | is-empty) { error make --unspanned { msg: "path parameter 'credentialName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), credential_name: (encode-path-segment $credential_name)} | format pattern "/restv2/game/{api_key}/config/~credentials/{credential_name}/resetSecret"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getGamesEndpoints
#
# GET /restv2/game/{apiKey}/endpoints
# operationId: getGamesEndpointsUsingGET
export def "restv2-game-endpoints get-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<liveElasticSearch: string, liveNosql: string, previewElasticSearch: string, previewNosql: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/endpoints"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getExperiments
#
# GET /restv2/game/{apiKey}/manage/experiments
# operationId: getExperimentsUsingGET
export def "restv2-game-manage-experiments list" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/experiments"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments
# operationId: createExperimentUsingPOST
# --config shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
export def "restv2-game-manage-experiments create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --changed-fields-and-initial-values: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --end-date: string # format: date-time
  --id: int # format: int64
  --measurements: string
  --measurements-es-query: string
  --name: string
  --percent-hash: string
  --published-stages: list<string>
  --start-date: string # format: date-time
]: any -> record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/experiments"))
  let req_body = {"active": $active, "changedFieldsAndInitialValues": $changed_fields_and_initial_values, "complete": $complete, "config": $config, "endDate": $end_date, "id": $id, "measurements": $measurements, "measurementsEsQuery": $measurements_es_query, "name": $name, "percentHash": $percent_hash, "publishedStages": $published_stages, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteExperiment
#
# DELETE /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: deleteExperimentUsingDELETE
export def "restv2-game-manage-experiments delete-using" [
  api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getExperiment
#
# GET /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: getExperimentUsingGET
export def "restv2-game-manage-experiments get-using" [
  api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateExperiment
#
# PUT /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: updateExperimentUsingPUT
# --config shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
export def "restv2-game-manage-experiments update-using" [
  api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --changed-fields-and-initial-values: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --end-date: string # format: date-time
  --body-id: int # format: int64
  --measurements: string
  --measurements-es-query: string
  --name: string
  --percent-hash: string
  --published-stages: list<string>
  --start-date: string # format: date-time
]: any -> record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}"))
  let req_body = {"active": $active, "changedFieldsAndInitialValues": $changed_fields_and_initial_values, "complete": $complete, "config": $config, "endDate": $end_date, "id": $body_id, "measurements": $measurements, "measurementsEsQuery": $measurements_es_query, "name": $name, "percentHash": $percent_hash, "publishedStages": $published_stages, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# doActionExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments/{id}/{action}
# operationId: doActionExperimentUsingPOST
export def "restv2-game-manage-experiments create-do-using" [
  api_key: string
  id: int
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id), action: (encode-path-segment $action)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}/{action}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# listQueries
#
# GET /restv2/game/{apiKey}/manage/queries
# operationId: listQueriesUsingGET
export def "restv2-game-manage-queries list-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, shortCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/queries"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createQuery
#
# POST /restv2/game/{apiKey}/manage/queries
# operationId: createQueryUsingPOST
export def "restv2-game-manage-queries create-list-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --es-rules: string
  --name: string
  --qb-rules: string
  --short-code: string
]: any -> record<esRules: string, name: string, qbRules: string, shortCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/queries"))
  let req_body = {"esRules": $es_rules, "name": $name, "qbRules": $qb_rules, "shortCode": $short_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteQuery
#
# DELETE /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: deleteQueryUsingDELETE
export def "restv2-game-manage-queries delete-list-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getQuery
#
# GET /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: getQueryUsingGET
export def "restv2-game-manage-queries get-list-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<esRules: string, name: string, qbRules: string, shortCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateQuery
#
# PUT /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: updateQueryUsingPUT
export def "restv2-game-manage-queries update-list-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --es-rules: string
  --name: string
  --qb-rules: string
  --body-short-code: string
]: any -> record<esRules: string, name: string, qbRules: string, shortCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}"))
  let req_body = {"esRules": $es_rules, "name": $name, "qbRules": $qb_rules, "shortCode": $body_short_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# listScreens
#
# GET /restv2/game/{apiKey}/manage/screens
# operationId: listScreensUsingGET
export def "restv2-game-manage-screens list-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, shortCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createScreen
#
# POST /restv2/game/{apiKey}/manage/screens
# operationId: createScreenUsingPOST
export def "restv2-game-manage-screens create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --short-code: string
  --template: string
]: any -> record<groups: list<string>, name: string, shortCode: string, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens"))
  let req_body = {"groups": $groups, "name": $name, "shortCode": $short_code, "template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# listExecutableScreens
#
# GET /restv2/game/{apiKey}/manage/screens/executable
# operationId: listExecutableScreensUsingGET
export def "restv2-game-manage-screens-executable list-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, shortCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens/executable"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# deleteScreen
#
# DELETE /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: deleteScreenUsingDELETE
export def "restv2-game-manage-screens delete-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getScreen
#
# GET /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: getScreenUsingGET
export def "restv2-game-manage-screens get-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: list<string>, name: string, shortCode: string, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateScreen
#
# PUT /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: updateScreenUsingPUT
export def "restv2-game-manage-screens update-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --body-short-code: string
  --template: string
]: any -> record<groups: list<string>, name: string, shortCode: string, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}"))
  let req_body = {"groups": $groups, "name": $name, "shortCode": $body_short_code, "template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# listSnapshots
#
# GET /restv2/game/{apiKey}/manage/snapshots
# operationId: listSnapshotsUsingGET
export def "restv2-game-manage-snapshots list-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<date: string, description: string, id: string, published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots
# operationId: createSnapshotUsingPOST
export def "restv2-game-manage-snapshots create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> record<date: string, description: string, id: string, published: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots"))
  let req_body = {"description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/manage/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE
export def "restv2-game-manage-snapshots delete-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST
export def "restv2-game-manage-snapshots-copy-to create-existing-using" [
  api_key: string
  snapshot_id: string
  target_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($target_api_key | is-empty) { error make --unspanned { msg: "path parameter 'targetApiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id), target_api_key: (encode-path-segment $target_api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/copy/to/{target_api_key}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST
export def "restv2-game-manage-snapshots-publish create-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/publish"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# revertSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/revert
# operationId: revertSnapshotUsingPOST
export def "restv2-game-manage-snapshots-revert create-using" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/revert"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# listSnippets
#
# GET /restv2/game/{apiKey}/manage/snippets
# operationId: listSnippetsUsingGET
export def "restv2-game-manage-snippets list-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, shortCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snippets"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# createSnippet
#
# POST /restv2/game/{apiKey}/manage/snippets
# operationId: createSnippetUsingPOST
export def "restv2-game-manage-snippets create-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --script: string
  --script-data: string
  --short-code: string
  --template: string
]: any -> record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snippets"))
  let req_body = {"groups": $groups, "name": $name, "script": $script, "scriptData": $script_data, "shortCode": $short_code, "template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# deleteSnippet
#
# DELETE /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: deleteSnippetUsingDELETE
export def "restv2-game-manage-snippets delete-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getSnippet
#
# GET /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: getSnippetUsingGET
export def "restv2-game-manage-snippets get-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# updateSnippet
#
# PUT /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: updateSnippetUsingPUT
export def "restv2-game-manage-snippets update-using" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --script: string
  --script-data: string
  --body-short-code: string
  --template: string
]: any -> record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}"))
  let req_body = {"groups": $groups, "name": $name, "script": $script, "scriptData": $script_data, "shortCode": $body_short_code, "template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# restoreDeletedGame
#
# POST /restv2/game/{apiKey}/restore
# operationId: restoreDeletedGameUsingPOST
export def "restv2-game-restore create-deleted-using" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/restore"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# setGameRegion
#
# POST /restv2/game/{gameApiKey}/region/{regionCode}
# operationId: setGameRegionUsingPOST
export def "restv2-game-region update-using-create" [
  game_api_key: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($game_api_key | is-empty) { error make --unspanned { msg: "path parameter 'gameApiKey' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'regionCode' must be non-empty" } }
  let full_url = (build-url $base ({game_api_key: (encode-path-segment $game_api_key), region_code: (encode-path-segment $region_code)} | format pattern "/restv2/game/{game_api_key}/region/{region_code}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getGameRegionOptions
#
# GET /restv2/game/{gameApiKey}/regions
# operationId: getGameRegionOptionsUsingGET
export def "restv2-game-regions get-options-using" [
  game_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($game_api_key | is-empty) { error make --unspanned { msg: "path parameter 'gameApiKey' must be non-empty" } }
  let full_url = (build-url $base ({game_api_key: (encode-path-segment $game_api_key)} | format pattern "/restv2/game/{game_api_key}/regions"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# list
#
# GET /restv2/games
# operationId: listUsingGET
export def "restv2-games list-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<_id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# listDeleted
#
# GET /restv2/games/deleted
# operationId: listDeletedUsingGET
export def "restv2-games-deleted list-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<apiKey: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games/deleted")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
