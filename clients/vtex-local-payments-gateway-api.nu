# Auto-generated client for Payments Gateway API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Payments-Gateway-API/1.0/openapi.json
# Auth: --token flag or $env.PAYMENTS_GATEWAY_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PAYMENTS_GATEWAY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.vtexpayments.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pub-transactions-payments send-public" } } | get name | first)
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

# 2.1 Send Payments Information Public
#
# POST /api/pub/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsPublic
export def "pub-transactions-payments send-public" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # e.g. {{orderId}}
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let qp = [(serialize-qp "orderId" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pub/transactions/{transaction_id}/payments") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"orderId": $order_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Affiliations
#
# GET /api/pvt/affiliations
# operationId: Affiliations
export def "pvt-affiliations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Insert Affiliation
#
# POST /api/pvt/affiliations
# operationId: InsertAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations" $auth.query)
  let req_body = {"configuration": $configuration, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Affiliation By Id
#
# GET /api/pvt/affiliations/{affiliationId}
# operationId: AffiliationById
export def "pvt-affiliations get" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($affiliation_id | is-empty) { error make --unspanned { msg: "path parameter 'affiliationId' must be non-empty" } }
  let full_url = (build-url $base ({affiliation_id: (encode-path-segment $affiliation_id)} | format pattern "/api/pvt/affiliations/{affiliation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update Affiliation
#
# PUT /api/pvt/affiliations/{affiliationId}
# operationId: UpdateAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations update" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  id: string
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($affiliation_id | is-empty) { error make --unspanned { msg: "path parameter 'affiliationId' must be non-empty" } }
  let full_url = (build-url $base ({affiliation_id: (encode-path-segment $affiliation_id)} | format pattern "/api/pvt/affiliations/{affiliation_id}") $auth.query)
  let req_body = {"configuration": $configuration, "id": $id, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Installments options
#
# GET /api/pvt/installments
# operationId: Installmentsoptions
export def "pvt-installments get-installmentsoptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-value: int # format: int32, e.g. 10
  --request-sales-channel: int # format: int32, e.g. 1
  --request-payment-details-0-id: int # format: int32, e.g. 2
  --request-payment-details-0-value: int # format: int32, e.g. 10
  --request-payment-details-0-bin: int # format: int32, e.g. 411111
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<installments: table<options: list, payment: record>, value: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request.value" $request_value "scalar") (serialize-qp "request.salesChannel" $request_sales_channel "scalar") (serialize-qp "request.paymentDetails[0].id" $request_payment_details_0_id "scalar") (serialize-qp "request.paymentDetails[0].value" $request_payment_details_0_value "scalar") (serialize-qp "request.paymentDetails[0].bin" $request_payment_details_0_bin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvt/installments" $qp $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"request.value": $request_value, "request.salesChannel": $request_sales_channel, "request.paymentDetails[0].id": $request_payment_details_0_id, "request.paymentDetails[0].value": $request_payment_details_0_value, "request.paymentDetails[0].bin": $request_payment_details_0_bin} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Available Payment Methods
#
# GET /api/pvt/merchants/payment-systems
# operationId: AvailablePaymentMethods
export def "pvt-merchants-payment-systems get-available-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> table<affiliationId: string, allowCommercialCondition: bool, allowCommercialPolicy: bool, allowCountry: bool, allowInstallments: bool, allowIssuer: bool, allowMultiple: bool, allowNotification: bool, allowPeriod: bool, antifraudConnectorImplementation: string, connectorId: int, connectorImplementation: string, description: string, dueDate: string, fields: string, groupName: string, id: int, implementation: string, isAvailable: bool, isCustom: bool, isSelfAuthorized: bool, name: string, requiresDocument: bool, requiresPhone: bool, rules: list<record>, validator: record<cardCodeMask: string, cardCodeRegex: string, mask: string, regex: string, useBillingAddress: bool, useCardHolderName: bool, useCvv: bool, useExpirationDate: bool, validCardLengths: string, weights: list>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/merchants/payment-systems" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Rules
#
# GET /api/pvt/rules
# operationId: Rules
export def "pvt-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Insert Rule
#
# POST /api/pvt/rules
# operationId: InsertRule
# --antifraud shape: {affiliationId: string, implementation: string}
# --connector shape: {affiliationId: string, implementation: string}
# --issuer shape: {name: string}
# --paymentSystem shape: {id: int, implementation: string, name: string}
# --salesChannels item shape: {id: string}
export def "pvt-rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  antifraud: record # e.g. {affiliationId: , implementation: } — shape: {affiliationId: string, implementation: string}
  --begin-date: string # nullable
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  --end-date: string # nullable
  --installment-options: string # nullable
  --installments-service: string # nullable
  --is-default: oneof<nothing, bool>
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  --requires-authentication: string # nullable
  sales_channels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules" $auth.query)
  let req_body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "installmentOptions": $installment_options, "installmentsService": $installments_service, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "requiresAuthentication": $requires_authentication, "salesChannels": $sales_channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete Rule
#
# DELETE /api/pvt/rules/{ruleId}
# operationId: Rule
export def "pvt-rules delete" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Rule By Id
#
# GET /api/pvt/rules/{ruleId}
# operationId: RuleById
export def "pvt-rules get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Rule By Id
#
# PUT /api/pvt/rules/{ruleId}
# operationId: PutRuleById
# --antifraud shape: {affiliationId: string}
# --connector shape: {affiliationId: string, implementation: string}
# --installmentOptions shape: {interestRateMethod: string}
# --issuer shape: {name: string}
# --paymentSystem shape: {id: int, implementation: string, name: string}
# --salesChannels item shape: {id: string}
export def "pvt-rules update" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  antifraud: record # e.g. {affiliationId: f952588c-8b41-41cc-a06f-c0f48f7320ef} — shape: {affiliationId: string}
  begin_date: string
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  end_date: string
  id: string
  installment_options: record # e.g. {interestRateMethod: } — shape: {interestRateMethod: string}
  --is-default: string # nullable
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  sales_channels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}") $auth.query)
  let req_body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "id": $id, "installmentOptions": $installment_options, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "salesChannels": $sales_channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# 1. Starts a new transaction
#
# POST /api/pvt/transactions
# operationId: 1.Createanewtransaction
export def "pvt-transactions create-anewtransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  channel: string
  reference_id: string
  sales_channel: string
  --urn: string
  value: int # format: int32
]: any -> record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/transactions" $auth.query)
  let req_body = {"channel": $channel, "referenceId": $reference_id, "salesChannel": $sales_channel, "urn": $urn, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Transaction Details
#
# GET /api/pvt/transactions/{transactionId}
# operationId: TransactionDetails
export def "pvt-transactions get-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# 3. Send Additional Data
#
# POST /api/pvt/transactions/{transactionId}/additional-data
# operationId: 3.SendAdditionalData
export def "pvt-transactions-additional-data send" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --name: string # Type of data that will be added to the transaction.
  --value: string # Data to be added to the transaction.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/additional-data") $auth.query)
  let req_body = {"name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Do authorization
#
# POST /api/pvt/transactions/{transactionId}/authorization-request
# operationId: 4.Doauthorization
export def "pvt-transactions-authorization-request create-doauthorization" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --prepare-for-recurrency: oneof<nothing, bool>
  soft_descriptor: string
  --body-transaction-id: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/authorization-request") $auth.query)
  let req_body = {"prepareForRecurrency": $prepare_for_recurrency, "softDescriptor": $soft_descriptor, "transactionId": $body_transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Cancel the transaction
#
# POST /api/pvt/transactions/{transactionId}/cancellation-request
# operationId: Cancelthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-cancellation-request create-cancelthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/cancellation-request") $auth.query)
  let req_body = {"minicart": $minicart, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# 2.2 Send Payments With Saved Credit Card
#
# POST /api/pvt/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsWithSavedCreditCard
export def "pvt-transactions-payments send-with-saved-credit-card" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/payments") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Payment Details
#
# GET /api/pvt/transactions/{transactionId}/payments/{paymentId}
# operationId: PaymentDetails
export def "pvt-transactions-payments get-details" [
  transaction_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<ConnectorResponses: string, ShowConnectorResponses: bool, allowInstallments: bool, allowIssuer: bool, allowNotification: bool, connector: string, connectorResponse: string, currencyCode: string, description: string, fields: table<name: string, value: string>, group: string, id: string, installments: int, installmentsInterestRate: int, installmentsValue: int, isAvailable: bool, isCustom: bool, merchantName: string, paymentSystem: int, paymentSystemName: string, provider: string, referenceValue: int, returnCode: string, returnMessage: string, self: record<href: string>, sheets: string, status: string, tid: string, value: int> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/api/pvt/transactions/{transaction_id}/payments/{payment_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Refund the transaction
#
# POST /api/pvt/transactions/{transactionId}/refunding-request
# operationId: Refundthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-refunding-request create-refundthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/refunding-request") $auth.query)
  let req_body = {"minicart": $minicart, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Settle the transaction
#
# POST /api/pvt/transactions/{transactionId}/settlement-request
# operationId: Settlethetransaction
export def "pvt-transactions-settlement-request create-settlethetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  value: int # format: int32
]: any -> record<cancelledValue: int, connectorRefundedValue: int, message: string, processingDate: string, refundedToken: string, refundedValue: int, status: int, statusDetail: string, token: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/settlement-request") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Transaction Settlement Details
#
# GET /api/pvt/transactions/{transactionId}/settlements
# operationId: TransactionSettlementDetails
export def "pvt-transactions-settlements get-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<actions: table<connectorResponse: string, date: string, payment: record, paymentId: string, type: string, value: int>, requests: table<date: string, id: string, value: int>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PAYMENTS_GATEWAY_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/settlements") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
