# Auto-generated client for Pricing Hub v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Pricing-Hub/1.0/openapi.json
# Auth: --token flag or $env.PRICING_HUB_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PRICING_HUB_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://prchub.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pricing-hub-prices post" } } | get name | first)
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

# Get Prices
#
# POST /api/pricing-hub/prices
# --items item shape: {brandId: string, categoriesIds: list, index: int, priceTableIds: list, quantity: int, sellerId: string, skuId: string}
export def "pricing-hub-prices post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Describes the type of the content being sent
  --X-VTEX-API-AppKey: string # The AppKey configured by the merchant
  --X-VTEX-API-AppToken: string # The AppToken configured by the merchant
  --UtmCampaign: string # Campaign name, represented by the `utm_campaign` value in the URL that led to the order. If there is no value, use `null` (default: summer)
  --UtmInternalCampaign: string # Internal campaign name, represented by the `utmi_cp` value in the URL that led to the order. If there is no value, use `null` (default: sale)
  --UtmMedium: string # Medium that indicates what type of traffic the customer originated from, represented by the `utm_medium` value in the URL that led to the order. If there is no value, use `null` (default: social)
  --UtmSource: string # Traffic source, indicates where the traffic originated from according to the `utm_source` value in the URL that led to the order. If there is no value, use `null` (default: facebook)
  email: string # The customer's email address. If there is no value, use an empty string (default: customer@email.com)
  items: list # The list of items that are to be priced by Pricing Hub — item shape: {brandId: string, categoriesIds: list, index: int, priceTableIds: list, quantity: int, sellerId: string, skuId: string}
  salesChannel: string # Represents Checkout's sales channel (default: 1)
]: any -> record<items: table<costPrice: float, index: int, listPrice: float, price: float, priceTable: string, priceValidUntil: string, skuId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $accountName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pricing-hub/prices" $qp)
  let body = {UtmCampaign: $UtmCampaign, UtmInternalCampaign: $UtmInternalCampaign, UtmMedium: $UtmMedium, UtmSource: $UtmSource, email: $email, items: $items, salesChannel: $salesChannel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "X-VTEX-API-AppKey": $X_VTEX_API_AppKey, "X-VTEX-API-AppToken": $X_VTEX_API_AppToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure External Price Source
#
# PUT /config
# operationId: ConfigExternalPriceSource
export def "config ConfigExternalPriceSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Name of the VTEX account (e.g. apiexamples)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Describes the type of the content being sent
  --X-VTEX-API-AppKey: string # The AppKey configured by the merchant
  --X-VTEX-API-AppToken: string # The AppToken configured by the merchant
  --active: oneof<nothing, bool> # Defines if the external price source is active (`true`) or not (`false`). If not set, the default value will be `false`. (default: false)
  appName: string # Name of the app that communicates with the external pricing source
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/config" $qp)
  let body = {active: $active, appName: $appName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "X-VTEX-API-AppKey": $X_VTEX_API_AppKey, "X-VTEX-API-AppToken": $X_VTEX_API_AppToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
