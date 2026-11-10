# Auto-generated client for GameSparks Game Details API v2
# Source: https://api.apis.guru/v2/specs/gamesparks.net/game-details/v2/openapi.json
# Auth: --token flag or $env.GAMESPARKS_GAME_DETAILS_API_TOKEN

const BASE_URL = "http://localhost//config2.gamesparks.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GAMESPARKS_GAME_DETAILS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "accesstoken" => { {scheme: $scheme, headers: {"accessToken": $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {"Authorization": $"Basic ($token_val)"}, query: "", location: "header"} }
    "jwt" => { {scheme: $scheme, headers: {"jwt": $token_val}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
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
def action-completer [] { ["publish" "start" "stop" "unpublish"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-region-options-using-get" "get-analytics-data-using-get" "get-data-count-using-get" "get-retention-using-get" "get-billing-details" "put-billing-details" "get-game-summary-using-get" "test-push-amazon-notifications-using-post" "test-push-apple-dev-notifications-using-post" "test-push-apple-prod-notifications-using-post" "test-push-google-notifications-using-post" "test-windows8-notifications-using-post" "test-windows-phone8-notifications-using-post" "test-viber-integration-notifications-using-post" "test-viber-production-notifications-using-post" "get-script-differences-using-get" "export-zip-using-get" "import-accept-using-post" "import-zip-using-post" "get-script-versions-using-get-1" "get-script-versions-using-get" "get-segment-query-filters-using-get" "get-segment-query-filters-config-using-get" "update-segment-query-filters-config-using-put" "get-segment-query-standard-filters-using-get" "get-snapshots-using-get-1" "create-snapshots-using-post" "get-live-snapshot-id-using-get" "get-snapshots-using-get" "revert-to-snapshot-using-post" "delete-snapshot-using-delete-1" "get-snapshot-using-get" "copy-snapshot-to-new-game-using-post" "copy-snapshot-to-existing-game-using-post-1" "publish-snapshot-using-post-1" "unpublish-snapshot-using-post" "get-test-harness-scenarios-using-get" "create-test-harness-scenario-using-post" "delete-test-harness-scenario-using-delete" "get-test-harness-scenario-using-get" "update-test-harness-scenario-using-put" "update-credential-secret-using-post" "get-games-endpoints-using-get" "get-experiments-using-get" "create-experiment-using-post" "delete-experiment-using-delete" "get-experiment-using-get" "update-experiment-using-put" "do-action-experiment-using-post" "list-queries-using-get" "create-query-using-post" "delete-query-using-delete" "get-query-using-get" "update-query-using-put" "list-screens-using-get" "create-screen-using-post" "list-executable-screens-using-get" "delete-screen-using-delete" "get-screen-using-get" "update-screen-using-put" "list-snapshots-using-get" "create-snapshot-using-post" "delete-snapshot-using-delete" "copy-snapshot-to-existing-game-using-post" "publish-snapshot-using-post" "revert-snapshot-using-post" "list-snippets-using-get" "create-snippet-using-post" "delete-snippet-using-delete" "get-snippet-using-get" "update-snippet-using-put" "restore-deleted-game-using-post" "set-game-region-using-post" "get-game-region-options-using-get" "list-using-get" "list-deleted-using-get" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "get-region-options-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/game/regions" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Returns the results of executed query defined by the parameters passed in
#
# GET /restv2/game/{apiKey}/admin/analytics
# operationId: getAnalyticsDataUsingGET
export def "get-analytics-data-using-get" [
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
  --stage: string@stage-completer # stage (required)
  --data-type: string@data-type-completer # dataType (required)
  --precision: string@precision-completer # precision (required)
  --start-date: string # yyyy-MM-dd (required, format: date)
  --end-date: string # yyyy-MM-dd (required, format: date)
  --keys: string # the keys to select. For example "ReturningUsers", "NewUsers", etc
]: nothing -> oneof<table<_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($stage == null) { error make --unspanned { msg: "required query parameter 'stage' missing: pass --stage" } }
  if ($data_type == null) { error make --unspanned { msg: "required query parameter 'dataType' missing: pass --data-type" } }
  if ($precision == null) { error make --unspanned { msg: "required query parameter 'precision' missing: pass --precision" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "dataType" $data_type "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stage": $stage, "dataType": $data_type, "precision": $precision, "startDate": $start_date, "endDate": $end_date, "keys": $keys} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the count of executed query
#
# GET /restv2/game/{apiKey}/admin/analytics/count
# operationId: getDataCountUsingGET
export def "get-data-count-using-get" [
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
  --stage: string@stage-completer # stage (required)
  --query-name: string@query-name-completer # queryName (required)
]: nothing -> oneof<record<result: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($stage == null) { error make --unspanned { msg: "required query parameter 'stage' missing: pass --stage" } }
  if ($query_name == null) { error make --unspanned { msg: "required query parameter 'queryName' missing: pass --query-name" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "queryName" $query_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics/count") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stage": $stage, "queryName": $query_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the percentage of user retention over the last 30 days
#
# GET /restv2/game/{apiKey}/admin/analytics/rollingRetention
# operationId: getRetentionUsingGET
export def "get-retention-using-get" [
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
  --stage: string@stage-completer # stage (required)
]: nothing -> oneof<record<result: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($stage == null) { error make --unspanned { msg: "required query parameter 'stage' missing: pass --stage" } }
  let qp = [(serialize-qp "stage" $stage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/analytics/rollingRetention") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stage": $stage} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves the Billing Details
#
# GET /restv2/game/{apiKey}/admin/billingDetails
# operationId: getBillingDetails
export def "get-billing-details" [
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
]: nothing -> oneof<record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/billingDetails") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates the Billing Details
#
# PUT /restv2/game/{apiKey}/admin/billingDetails
# operationId: putBillingDetails
export def "put-billing-details" [
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
]: any -> oneof<record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/billingDetails") $auth.query)
  let req_body = {"building": $building, "city": $city, "companyName": $company_name, "country": $country, "email1": $email1, "email2": $email2, "email3": $email3, "firstName1": $first_name1, "firstName2": $first_name2, "firstName3": $first_name3, "lastName1": $last_name1, "lastName2": $last_name2, "lastName3": $last_name3, "postcode": $postcode, "state": $state, "street": $street, "taxNumber": $tax_number} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# getGameSummary
#
# GET /restv2/game/{apiKey}/admin/notifications/summary
# operationId: getGameSummaryUsingGET
export def "get-game-summary-using-get" [
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
  --stage: string@stage-completer # stage (required)
  --start-date: string # yyyy-MM-dd (required, format: date)
  --end-date: string # yyyy-MM-dd (required, format: date)
]: nothing -> oneof<record<logLevelData: list<record>, logLevelSummary: table<count: int, level: string>, message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($stage == null) { error make --unspanned { msg: "required query parameter 'stage' missing: pass --stage" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/notifications/summary") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stage": $stage, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# testPushAmazonNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/amazon
# operationId: testPushAmazonNotificationsUsingPOST
export def "test-push-amazon-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/amazon") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testPushAppleDevNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/development
# operationId: testPushAppleDevNotificationsUsingPOST
export def "test-push-apple-dev-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/apple/development") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testPushAppleProdNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/production
# operationId: testPushAppleProdNotificationsUsingPOST
export def "test-push-apple-prod-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/apple/production") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testPushGoogleNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/google
# operationId: testPushGoogleNotificationsUsingPOST
export def "test-push-google-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/google") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testWindows8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windows8
# operationId: testWindows8NotificationsUsingPOST
export def "test-windows8-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/microsoft/windows8") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testWindowsPhone8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windowsPhone8
# operationId: testWindowsPhone8NotificationsUsingPOST
export def "test-windows-phone8-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/microsoft/windowsPhone8") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testViberIntegrationNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/integration
# operationId: testViberIntegrationNotificationsUsingPOST
export def "test-viber-integration-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/viber/integration") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# testViberProductionNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/production
# operationId: testViberProductionNotificationsUsingPOST
export def "test-viber-production-notifications-using-post" [
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
]: any -> oneof<record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/pushNotifications/test/viber/production") $auth.query)
  let req_body = {"customJson": $custom_json, "messageId": $message_id, "pushId": $push_id, "subtitle": $subtitle, "summary": $summary, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# getScriptDifferences
#
# GET /restv2/game/{apiKey}/admin/scripts/differences/{snapshotId1}/{snapshotId2}
# operationId: getScriptDifferencesUsingGET
export def "get-script-differences-using-get" [
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
]: nothing -> oneof<record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id1 | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId1' must be non-empty" } }
  if ($snapshot_id2 | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId2' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id1: (encode-path-segment $snapshot_id1), snapshot_id2: (encode-path-segment $snapshot_id2)} | format pattern "/restv2/game/{api_key}/admin/scripts/differences/{snapshot_id1}/{snapshot_id2}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# exportZip
#
# GET /restv2/game/{apiKey}/admin/scripts/export
# operationId: exportZipUsingGET
export def "export-zip-using-get" [
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
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/export") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# importAccept
#
# POST /restv2/game/{apiKey}/admin/scripts/import/accept
# operationId: importAcceptUsingPOST
export def "import-accept-using-post" [
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
  --qp-body: string # body (required) (spec name: body)
  file: string # file (format: binary)
]: any -> oneof<record<message: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($qp_body == null) { error make --unspanned { msg: "required query parameter 'body' missing: pass --qp-body" } }
  let qp = [(serialize-qp "body" $qp_body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/import/accept") $qp $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["file"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: ({"body": $qp_body} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# importZip
#
# POST /restv2/game/{apiKey}/admin/scripts/import/preview
# operationId: importZipUsingPOST
export def "import-zip-using-post" [
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
]: any -> oneof<record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/import/preview") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["file"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions
# operationId: getScriptVersionsUsingGET_1
export def "get-script-versions-using-get-1" [
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
]: nothing -> oneof<record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/scripts/versions") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions/{page}
# operationId: getScriptVersionsUsingGET
export def "get-script-versions-using-get" [
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
]: nothing -> oneof<record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), page: (encode-path-segment $page)} | format pattern "/restv2/game/{api_key}/admin/scripts/versions/{page}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# getSegmentQueryFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters
# operationId: getSegmentQueryFiltersUsingGET
export def "get-segment-query-filters-using-get" [
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
]: nothing -> oneof<record<filters: table<key: string, name: string, options: list, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getSegmentQueryFiltersConfig
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: getSegmentQueryFiltersConfigUsingGET
export def "get-segment-query-filters-config-using-get" [
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
]: nothing -> oneof<record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/config") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateSegmentQueryFiltersConfig
#
# PUT /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: updateSegmentQueryFiltersConfigUsingPUT
export def "update-segment-query-filters-config-using-put" [
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
]: any -> oneof<record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/config") $auth.query)
  let req_body = {"customFilters": $custom_filters, "hiddenFilters": $hidden_filters} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# getSegmentQueryStandardFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/standardFilters
# operationId: getSegmentQueryStandardFiltersUsingGET
export def "get-segment-query-standard-filters-using-get" [
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
]: nothing -> oneof<record<filters: table<key: string, name: string, options: list, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/segmentQueryFilters/standardFilters") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots
# operationId: getSnapshotsUsingGET_1
export def "get-snapshots-using-get-1" [
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
]: nothing -> oneof<table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# createSnapshots
#
# POST /restv2/game/{apiKey}/admin/snapshots
# operationId: createSnapshotsUsingPOST
export def "create-snapshots-using-post" [
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
]: any -> oneof<record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots") $auth.query)
  let req_body = {"description": $description} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# getLiveSnapshotId
#
# GET /restv2/game/{apiKey}/admin/snapshots/liveSnapshotId
# operationId: getLiveSnapshotIdUsingGET
export def "get-live-snapshot-id-using-get" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots/liveSnapshotId") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots/page/{page}
# operationId: getSnapshotsUsingGET
export def "get-snapshots-using-get" [
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
]: nothing -> oneof<table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), page: (encode-path-segment $page)} | format pattern "/restv2/game/{api_key}/admin/snapshots/page/{page}") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# revertToSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/revert/to/{snapshotId}
# operationId: revertToSnapshotUsingPOST
export def "revert-to-snapshot-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/revert/to/{snapshot_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE_1
export def "delete-snapshot-using-delete-1" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getSnapshot
#
# GET /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: getSnapshotUsingGET
export def "get-snapshot-using-get" [
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
]: nothing -> oneof<record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# copySnapshotToNewGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy
# operationId: copySnapshotToNewGameUsingPOST
export def "copy-snapshot-to-new-game-using-post" [
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
]: nothing -> oneof<record<targetGameApiKey: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "includeGameConfig" $include_game_config "scalar") (serialize-qp "includeMetadata" $include_metadata "scalar") (serialize-qp "includeBinaries" $include_binaries "scalar") (serialize-qp "includeCollaborators" $include_collaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/copy") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"includeGameConfig": $include_game_config, "includeMetadata": $include_metadata, "includeBinaries": $include_binaries, "includeCollaborators": $include_collaborators} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST_1
export def "copy-snapshot-to-existing-game-using-post-1" [
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
]: nothing -> oneof<record<targetGameApiKey: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($target_api_key | is-empty) { error make --unspanned { msg: "path parameter 'targetApiKey' must be non-empty" } }
  let qp = [(serialize-qp "includeGameConfig" $include_game_config "scalar") (serialize-qp "includeMetadata" $include_metadata "scalar") (serialize-qp "includeBinaries" $include_binaries "scalar") (serialize-qp "includeCollaborators" $include_collaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id), target_api_key: (encode-path-segment $target_api_key)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/copy/to/{target_api_key}") $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"includeGameConfig": $include_game_config, "includeMetadata": $include_metadata, "includeBinaries": $include_binaries, "includeCollaborators": $include_collaborators} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST_1
export def "publish-snapshot-using-post-1" [
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
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/publish") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# unpublishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/unpublish
# operationId: unpublishSnapshotUsingPOST
export def "unpublish-snapshot-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/admin/snapshots/{snapshot_id}/unpublish") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# getTestHarnessScenarios
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: getTestHarnessScenariosUsingGET
export def "get-test-harness-scenarios-using-get" [
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
]: nothing -> oneof<table<scenarioJson: record, scenarioName: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createTestHarnessScenario
#
# POST /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: createTestHarnessScenarioUsingPOST
export def "create-test-harness-scenario-using-post" [
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
]: any -> oneof<record<scenarioJson: record, scenarioName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios") $auth.query)
  let req_body = {"scenarioJson": $scenario_json, "scenarioName": $scenario_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# deleteTestHarnessScenario
#
# DELETE /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: deleteTestHarnessScenarioUsingDELETE
export def "delete-test-harness-scenario-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getTestHarnessScenario
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: getTestHarnessScenarioUsingGET
export def "get-test-harness-scenario-using-get" [
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
]: nothing -> oneof<record<scenarioJson: record, scenarioName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateTestHarnessScenario
#
# PUT /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: updateTestHarnessScenarioUsingPUT
export def "update-test-harness-scenario-using-put" [
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
  --body-scenario-name: string # (spec name: scenarioName)
]: any -> oneof<record<scenarioJson: record, scenarioName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($scenario_name | is-empty) { error make --unspanned { msg: "path parameter 'scenarioName' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), scenario_name: (encode-path-segment $scenario_name)} | format pattern "/restv2/game/{api_key}/admin/testHarness/scenarios/{scenario_name}") $auth.query)
  let req_body = {"scenarioJson": $scenario_json, "scenarioName": $body_scenario_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Resets the secret of a credential
#
# POST /restv2/game/{apiKey}/config/~credentials/{credentialName}/resetSecret
# operationId: updateCredentialSecretUsingPOST
export def "update-credential-secret-using-post" [
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
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), credential_name: (encode-path-segment $credential_name)} | format pattern "/restv2/game/{api_key}/config/~credentials/{credential_name}/resetSecret") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# getGamesEndpoints
#
# GET /restv2/game/{apiKey}/endpoints
# operationId: getGamesEndpointsUsingGET
export def "get-games-endpoints-using-get" [
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
]: nothing -> oneof<record<liveElasticSearch: string, liveNosql: string, previewElasticSearch: string, previewNosql: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/endpoints") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getExperiments
#
# GET /restv2/game/{apiKey}/manage/experiments
# operationId: getExperimentsUsingGET
export def "get-experiments-using-get" [
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
]: nothing -> oneof<table<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/experiments") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments
# operationId: createExperimentUsingPOST
export def "create-experiment-using-post" [
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
]: any -> oneof<record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/experiments") $auth.query)
  let req_body = {"active": $active, "changedFieldsAndInitialValues": $changed_fields_and_initial_values, "complete": $complete, "config": $config, "endDate": $end_date, "id": $id, "measurements": $measurements, "measurementsEsQuery": $measurements_es_query, "name": $name, "percentHash": $percent_hash, "publishedStages": $published_stages, "startDate": $start_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# deleteExperiment
#
# DELETE /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: deleteExperimentUsingDELETE
export def "delete-experiment-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getExperiment
#
# GET /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: getExperimentUsingGET
export def "get-experiment-using-get" [
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
]: nothing -> oneof<record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateExperiment
#
# PUT /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: updateExperimentUsingPUT
export def "update-experiment-using-put" [
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
  --body-id: int # format: int64 (spec name: id)
  --measurements: string
  --measurements-es-query: string
  --name: string
  --percent-hash: string
  --published-stages: list<string>
  --start-date: string # format: date-time
]: any -> oneof<record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}") $auth.query)
  let req_body = {"active": $active, "changedFieldsAndInitialValues": $changed_fields_and_initial_values, "complete": $complete, "config": $config, "endDate": $end_date, "id": $body_id, "measurements": $measurements, "measurementsEsQuery": $measurements_es_query, "name": $name, "percentHash": $percent_hash, "publishedStages": $published_stages, "startDate": $start_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# doActionExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments/{id}/{action}
# operationId: doActionExperimentUsingPOST
export def "do-action-experiment-using-post" [
  api_key: string
  id: int
  action: string@action-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), id: (encode-path-segment $id), action: (encode-path-segment $action)} | format pattern "/restv2/game/{api_key}/manage/experiments/{id}/{action}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# listQueries
#
# GET /restv2/game/{apiKey}/manage/queries
# operationId: listQueriesUsingGET
export def "list-queries-using-get" [
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
]: nothing -> oneof<table<name: string, shortCode: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/queries") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createQuery
#
# POST /restv2/game/{apiKey}/manage/queries
# operationId: createQueryUsingPOST
export def "create-query-using-post" [
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
]: any -> oneof<record<esRules: string, name: string, qbRules: string, shortCode: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/queries") $auth.query)
  let req_body = {"esRules": $es_rules, "name": $name, "qbRules": $qb_rules, "shortCode": $short_code} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# deleteQuery
#
# DELETE /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: deleteQueryUsingDELETE
export def "delete-query-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getQuery
#
# GET /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: getQueryUsingGET
export def "get-query-using-get" [
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
]: nothing -> oneof<record<esRules: string, name: string, qbRules: string, shortCode: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateQuery
#
# PUT /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: updateQueryUsingPUT
export def "update-query-using-put" [
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
  --body-short-code: string # (spec name: shortCode)
]: any -> oneof<record<esRules: string, name: string, qbRules: string, shortCode: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/queries/{short_code}") $auth.query)
  let req_body = {"esRules": $es_rules, "name": $name, "qbRules": $qb_rules, "shortCode": $body_short_code} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# listScreens
#
# GET /restv2/game/{apiKey}/manage/screens
# operationId: listScreensUsingGET
export def "list-screens-using-get" [
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
]: nothing -> oneof<table<name: string, shortCode: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createScreen
#
# POST /restv2/game/{apiKey}/manage/screens
# operationId: createScreenUsingPOST
export def "create-screen-using-post" [
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
]: any -> oneof<record<groups: list<string>, name: string, shortCode: string, template: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens") $auth.query)
  let req_body = {"groups": $groups, "name": $name, "shortCode": $short_code, "template": $template} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# listExecutableScreens
#
# GET /restv2/game/{apiKey}/manage/screens/executable
# operationId: listExecutableScreensUsingGET
export def "list-executable-screens-using-get" [
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
]: nothing -> oneof<table<name: string, shortCode: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/screens/executable") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# deleteScreen
#
# DELETE /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: deleteScreenUsingDELETE
export def "delete-screen-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getScreen
#
# GET /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: getScreenUsingGET
export def "get-screen-using-get" [
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
]: nothing -> oneof<record<groups: list<string>, name: string, shortCode: string, template: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateScreen
#
# PUT /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: updateScreenUsingPUT
export def "update-screen-using-put" [
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
  --body-short-code: string # (spec name: shortCode)
  --template: string
]: any -> oneof<record<groups: list<string>, name: string, shortCode: string, template: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/screens/{short_code}") $auth.query)
  let req_body = {"groups": $groups, "name": $name, "shortCode": $body_short_code, "template": $template} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# listSnapshots
#
# GET /restv2/game/{apiKey}/manage/snapshots
# operationId: listSnapshotsUsingGET
export def "list-snapshots-using-get" [
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
]: nothing -> oneof<table<date: string, description: string, id: string, published: bool>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots
# operationId: createSnapshotUsingPOST
export def "create-snapshot-using-post" [
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
]: any -> oneof<record<date: string, description: string, id: string, published: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots") $auth.query)
  let req_body = {"description": $description} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/manage/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE
export def "delete-snapshot-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 201]
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST
export def "copy-snapshot-to-existing-game-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($target_api_key | is-empty) { error make --unspanned { msg: "path parameter 'targetApiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id), target_api_key: (encode-path-segment $target_api_key)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/copy/to/{target_api_key}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST
export def "publish-snapshot-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/publish") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# revertSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/revert
# operationId: revertSnapshotUsingPOST
export def "revert-snapshot-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/restv2/game/{api_key}/manage/snapshots/{snapshot_id}/revert") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# listSnippets
#
# GET /restv2/game/{apiKey}/manage/snippets
# operationId: listSnippetsUsingGET
export def "list-snippets-using-get" [
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
]: nothing -> oneof<table<name: string, shortCode: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snippets") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# createSnippet
#
# POST /restv2/game/{apiKey}/manage/snippets
# operationId: createSnippetUsingPOST
export def "create-snippet-using-post" [
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
]: any -> oneof<record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/manage/snippets") $auth.query)
  let req_body = {"groups": $groups, "name": $name, "script": $script, "scriptData": $script_data, "shortCode": $short_code, "template": $template} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# deleteSnippet
#
# DELETE /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: deleteSnippetUsingDELETE
export def "delete-snippet-using-delete" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# getSnippet
#
# GET /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: getSnippetUsingGET
export def "get-snippet-using-get" [
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
]: nothing -> oneof<record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# updateSnippet
#
# PUT /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: updateSnippetUsingPUT
export def "update-snippet-using-put" [
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
  --body-short-code: string # (spec name: shortCode)
  --template: string
]: any -> oneof<record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  if ($short_code | is-empty) { error make --unspanned { msg: "path parameter 'shortCode' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), short_code: (encode-path-segment $short_code)} | format pattern "/restv2/game/{api_key}/manage/snippets/{short_code}") $auth.query)
  let req_body = {"groups": $groups, "name": $name, "script": $script, "scriptData": $script_data, "shortCode": $body_short_code, "template": $template} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# restoreDeletedGame
#
# POST /restv2/game/{apiKey}/restore
# operationId: restoreDeletedGameUsingPOST
export def "restore-deleted-game-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'apiKey' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/restv2/game/{api_key}/restore") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# setGameRegion
#
# POST /restv2/game/{gameApiKey}/region/{regionCode}
# operationId: setGameRegionUsingPOST
export def "set-game-region-using-post" [
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
]: nothing -> oneof<record<message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($game_api_key | is-empty) { error make --unspanned { msg: "path parameter 'gameApiKey' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'regionCode' must be non-empty" } }
  let full_url = (build-url $base ({game_api_key: (encode-path-segment $game_api_key), region_code: (encode-path-segment $region_code)} | format pattern "/restv2/game/{game_api_key}/region/{region_code}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# getGameRegionOptions
#
# GET /restv2/game/{gameApiKey}/regions
# operationId: getGameRegionOptionsUsingGET
export def "get-game-region-options-using-get" [
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
]: nothing -> oneof<record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  if ($game_api_key | is-empty) { error make --unspanned { msg: "path parameter 'gameApiKey' must be non-empty" } }
  let full_url = (build-url $base ({game_api_key: (encode-path-segment $game_api_key)} | format pattern "/restv2/game/{game_api_key}/regions") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# list
#
# GET /restv2/games
# operationId: listUsingGET
export def "list-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<_id: string, name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# listDeleted
#
# GET /restv2/games/deleted
# operationId: listDeletedUsingGET
export def "list-deleted-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<apiKey: string, name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games/deleted" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
