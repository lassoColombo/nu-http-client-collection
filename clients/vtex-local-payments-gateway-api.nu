# Auto-generated client for Payments Gateway API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Payments-Gateway-API/1.0/openapi.json
# Auth: --token flag or $env.PAYMENTS_GATEWAY_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYMENTS_GATEWAY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let qp = [(serialize-qp "orderId" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pub/transactions/{transaction_id}/payments") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"orderId": $order_id} | compact), body: $req_body}
}

# Affiliations
#
# GET /api/pvt/affiliations
# operationId: Affiliations
export def "pvt-affiliations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Insert Affiliation
#
# POST /api/pvt/affiliations
# operationId: InsertAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let req_body = {"configuration": $configuration, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Affiliation By Id
#
# GET /api/pvt/affiliations/{affiliationId}
# operationId: AffiliationById
export def "pvt-affiliations get" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($affiliation_id | is-empty) { error make --unspanned { msg: "path parameter 'affiliationId' must be non-empty" } }
  let full_url = (build-url $base ({affiliation_id: (encode-path-segment $affiliation_id)} | format pattern "/api/pvt/affiliations/{affiliation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Affiliation
#
# PUT /api/pvt/affiliations/{affiliationId}
# operationId: UpdateAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations update" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($affiliation_id | is-empty) { error make --unspanned { msg: "path parameter 'affiliationId' must be non-empty" } }
  let full_url = (build-url $base ({affiliation_id: (encode-path-segment $affiliation_id)} | format pattern "/api/pvt/affiliations/{affiliation_id}"))
  let req_body = {"configuration": $configuration, "id": $id, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Installments options
#
# GET /api/pvt/installments
# operationId: Installmentsoptions
export def "pvt-installments get-installmentsoptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request.value" $request_value "scalar") (serialize-qp "request.salesChannel" $request_sales_channel "scalar") (serialize-qp "request.paymentDetails[0].id" $request_payment_details_0_id "scalar") (serialize-qp "request.paymentDetails[0].value" $request_payment_details_0_value "scalar") (serialize-qp "request.paymentDetails[0].bin" $request_payment_details_0_bin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvt/installments" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"request.value": $request_value, "request.salesChannel": $request_sales_channel, "request.paymentDetails[0].id": $request_payment_details_0_id, "request.paymentDetails[0].value": $request_payment_details_0_value, "request.paymentDetails[0].bin": $request_payment_details_0_bin} | compact), body: null}
}

# Available Payment Methods
#
# GET /api/pvt/merchants/payment-systems
# operationId: AvailablePaymentMethods
export def "pvt-merchants-payment-systems get-available-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/merchants/payment-systems")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rules
#
# GET /api/pvt/rules
# operationId: Rules
export def "pvt-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let req_body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "installmentOptions": $installment_options, "installmentsService": $installments_service, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "requiresAuthentication": $requires_authentication, "salesChannels": $sales_channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Delete Rule
#
# DELETE /api/pvt/rules/{ruleId}
# operationId: Rule
export def "pvt-rules delete" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rule By Id
#
# GET /api/pvt/rules/{ruleId}
# operationId: RuleById
export def "pvt-rules get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/api/pvt/rules/{rule_id}"))
  let req_body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "id": $id, "installmentOptions": $installment_options, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "salesChannels": $sales_channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# 1. Starts a new transaction
#
# POST /api/pvt/transactions
# operationId: 1.Createanewtransaction
export def "pvt-transactions create-anewtransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/transactions")
  let req_body = {"channel": $channel, "referenceId": $reference_id, "salesChannel": $sales_channel, "urn": $urn, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Transaction Details
#
# GET /api/pvt/transactions/{transactionId}
# operationId: TransactionDetails
export def "pvt-transactions get-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# 3. Send Additional Data
#
# POST /api/pvt/transactions/{transactionId}/additional-data
# operationId: 3.SendAdditionalData
export def "pvt-transactions-additional-data send" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/additional-data"))
  let req_body = {"name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Do authorization
#
# POST /api/pvt/transactions/{transactionId}/authorization-request
# operationId: 4.Doauthorization
export def "pvt-transactions-authorization-request create-doauthorization" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/authorization-request"))
  let req_body = {"prepareForRecurrency": $prepare_for_recurrency, "softDescriptor": $soft_descriptor, "transactionId": $body_transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Cancel the transaction
#
# POST /api/pvt/transactions/{transactionId}/cancellation-request
# operationId: Cancelthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-cancellation-request create-cancelthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/cancellation-request"))
  let req_body = {"minicart": $minicart, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# 2.2 Send Payments With Saved Credit Card
#
# POST /api/pvt/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsWithSavedCreditCard
export def "pvt-transactions-payments send-with-saved-credit-card" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/payments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Payment Details
#
# GET /api/pvt/transactions/{transactionId}/payments/{paymentId}
# operationId: PaymentDetails
export def "pvt-transactions-payments get-details" [
  transaction_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/api/pvt/transactions/{transaction_id}/payments/{payment_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refund the transaction
#
# POST /api/pvt/transactions/{transactionId}/refunding-request
# operationId: Refundthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-refunding-request create-refundthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/refunding-request"))
  let req_body = {"minicart": $minicart, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Settle the transaction
#
# POST /api/pvt/transactions/{transactionId}/settlement-request
# operationId: Settlethetransaction
export def "pvt-transactions-settlement-request create-settlethetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/settlement-request"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Transaction Settlement Details
#
# GET /api/pvt/transactions/{transactionId}/settlements
# operationId: TransactionSettlementDetails
export def "pvt-transactions-settlements get-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/pvt/transactions/{transaction_id}/settlements"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
