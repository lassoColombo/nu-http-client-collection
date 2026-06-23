# Auto-generated client for GiftCard Hub API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/GiftCard-Hub-API/1.0/openapi.json
# Auth: --token flag or $env.GIFTCARD_HUB_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GIFTCARD_HUB_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br/api"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "giftcardproviders list-gift-card-providers" } } | get name | first)
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

# List All GiftCard Providers
#
# GET /giftcardproviders
# operationId: ListAllGiftCardProviders
export def "giftcardproviders list-gift-card-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --rest-range: string # Pagination control. This query variable must follow the format _resources={from}-{to}_.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/giftcardproviders")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "REST-Range": $rest_range, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete GiftCard Provider by ID
#
# DELETE /giftcardproviders/{giftCardProviderID}
# operationId: DeleteGiftCardProviderbyID
export def "giftcardproviders delete-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create/Update GiftCard Provider by ID
#
# PUT /giftcardproviders/{giftCardProviderID}
# operationId: Create/UpdateGiftCardProviderbyID
export def "giftcardproviders create-update-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: any
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Create GiftCard in GiftCard Provider
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards
# operationId: CreateGiftCardinGiftCardProvider
export def "giftcardproviders-giftcards create-gift-cardin-gift-card-provider" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: any
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get GiftCard from GiftCard Provider
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/_search
# operationId: GetGiftCardfromGiftCardProvider
export def "giftcardproviders-giftcards-search get-gift-cardfrom-gift-card-provider" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --rest-range: string # Range of documents to show.
  --body: any
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/_search"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get GiftCard from GiftCard Provider by ID
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}
# operationId: GetGiftCardfromGiftCardProviderbyID
export def "giftcardproviders-giftcards get-gift-cardfrom-gift-card-providerby" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List All GiftCard Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions
# operationId: ListAllGiftCardTransactions
export def "giftcardproviders-giftcards-transactions list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create GiftCard Transaction
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions
# operationId: CreateGiftCardTransaction
export def "giftcardproviders-giftcards-transactions create-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: any
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# List All GiftCard Cancellation Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/cancellations
# operationId: ListAllGiftCardCancellationTransactions
export def "giftcardproviders-giftcards-transactions-cancellations list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($t_id | is-empty) { error make --unspanned { msg: "path parameter 'tId' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/cancellations"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create GiftCard Cancellation Transaction
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/cancellations
# operationId: CreateGiftCardCancellationTransaction
export def "giftcardproviders-giftcards-transactions-cancellations create-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: any
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($t_id | is-empty) { error make --unspanned { msg: "path parameter 'tId' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/cancellations"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# List All GiftCard Settlement Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/settlements
# operationId: ListAllGiftCardSettlementTransactions
export def "giftcardproviders-giftcards-transactions-settlements list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($t_id | is-empty) { error make --unspanned { msg: "path parameter 'tId' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/settlements"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create GiftCard Settlement Transaction
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/settlements
# operationId: CreateGiftCardSettlementTransaction
# --cart shape: {discounts: int, grandTotal: int, items: list, itemsTotal: int, redemptionCode: string, relationName: string, shipping: int, taxes: int}
# --client shape: {document: string, email: string, id: string}
export def "giftcardproviders-giftcards-transactions-settlements create-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  cart: record # e.g. {discounts: -20, grandTotal: 182, items: [{id: 2000002, name: , price: 200, productId: 2000000, quantity: 1, refId: MEV41}], itemsTotal: 200, redemptionCode: FASD-ASDS-ASDA-ASDA, relationName: loyalty-program, shipping: 2, taxes: 0} — shape: {discounts: int, grandTotal: int, items: list, itemsTotal: int, redemptionCode: string, relationName: string, shipping: int, taxes: int}
  client: record # default: {document: 42151783120, email: email@domain.com, id: 3b1ab} — shape: {document: string, email: string, id: string}
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($t_id | is-empty) { error make --unspanned { msg: "path parameter 'tId' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/settlements"))
  let req_body = {"cart": $cart, "client": $client} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json;charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get GiftCard Transaction by ID
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{transactionID}
# operationId: GetGiftCardTransactionbyID
export def "giftcardproviders-giftcards-transactions get-gift-card-transactionby" [
  gift_card_provider_id: string
  gift_card_id: string
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
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{transaction_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get GiftCard Authorization Transaction
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{transactionID}/authorization
# operationId: GetGiftCardAuthorizationTransaction
export def "giftcardproviders-giftcards-transactions-authorization get-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
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
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderID' must be non-empty" } }
  if ($gift_card_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardID' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionID' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{transaction_id}/authorization"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get GiftCard Provider by ID
#
# GET /giftcardproviders/{giftCardProviderId}
# operationId: GetGiftCardProviderbyID
export def "giftcardproviders get-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o GIFTCARD_HUB_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o GIFTCARD_HUB_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($gift_card_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'giftCardProviderId' must be non-empty" } }
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
