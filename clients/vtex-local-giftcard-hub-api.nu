# Auto-generated client for GiftCard Hub API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/GiftCard-Hub-API/1.0/openapi.json
# Auth: --token flag or $env.GIFTCARD_HUB_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GIFTCARD_HUB_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br/api"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "giftcardproviders list-list-gift-card-providers" } } | get name | first)
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
export def "giftcardproviders list-list-gift-card-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --rest-range: string # Pagination control. This query variable must follow the format _resources={from}-{to}_.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/giftcardproviders")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "REST-Range": $rest_range, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete GiftCard Provider by ID
#
# DELETE /giftcardproviders/{giftCardProviderID}
# operationId: DeleteGiftCardProviderbyID
export def "giftcardproviders delete-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update GiftCard Provider by ID
#
# PUT /giftcardproviders/{giftCardProviderID}
# operationId: Create/UpdateGiftCardProviderbyID
export def "giftcardproviders create-update-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Create GiftCard in GiftCard Provider
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards
# operationId: CreateGiftCardinGiftCardProvider
export def "giftcardproviders-giftcards create-gift-cardin-gift-card-provider" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Get GiftCard from GiftCard Provider
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/_search
# operationId: GetGiftCardfromGiftCardProvider
export def "giftcardproviders-giftcards-search get-gift-cardfrom-gift-card-provider" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --rest-range: string # Range of documents to show.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/_search"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Get GiftCard from GiftCard Provider by ID
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}
# operationId: GetGiftCardfromGiftCardProviderbyID
export def "giftcardproviders-giftcards get-gift-cardfrom-gift-card-providerby" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All GiftCard Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions
# operationId: ListAllGiftCardTransactions
export def "giftcardproviders-giftcards-transactions list-list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create GiftCard Transaction
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions
# operationId: CreateGiftCardTransaction
export def "giftcardproviders-giftcards-transactions create-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# List All GiftCard Cancellation Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/cancellations
# operationId: ListAllGiftCardCancellationTransactions
export def "giftcardproviders-giftcards-transactions-cancellations list-list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/cancellations"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/cancellations"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/vnd.vtex.giftcardproviders.v1+json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# List All GiftCard Settlement Transactions
#
# GET /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/settlements
# operationId: ListAllGiftCardSettlementTransactions
export def "giftcardproviders-giftcards-transactions-settlements list-list-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/settlements"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create GiftCard Settlement Transaction
#
# POST /giftcardproviders/{giftCardProviderID}/giftcards/{giftCardID}/transactions/{tId}/settlements
# operationId: CreateGiftCardSettlementTransaction
export def "giftcardproviders-giftcards-transactions-settlements create-gift-card" [
  gift_card_provider_id: string
  gift_card_id: string
  t_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), t_id: (encode-path-segment $t_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{t_id}/settlements"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json;charset=utf-8")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{transaction_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id), gift_card_id: (encode-path-segment $gift_card_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}/giftcards/{gift_card_id}/transactions/{transaction_id}/authorization"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get GiftCard Provider by ID
#
# GET /giftcardproviders/{giftCardProviderId}
# operationId: GetGiftCardProviderbyID
export def "giftcardproviders get-gift-card-providerby" [
  gift_card_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json.
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json.
  --x-vtex-api-app-key: string # VTEX API AppKey
  --x-vtex-api-app-token: string # VTEX API AppToken
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_provider_id: (encode-path-segment $gift_card_provider_id)} | format pattern "/giftcardproviders/{gift_card_provider_id}"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-VTEX-API-AppKey": $x_vtex_api_app_key, "X-VTEX-API-AppToken": $x_vtex_api_app_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
