# Auto-generated client for Promotions & Taxes API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Promotions-/1.0/openapi.json
# Auth: --token flag or $env.PROMOTIONS_TAXES_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PROMOTIONS_TAXES_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "http://example.com/.exampleParameterValue.com.br/api/rnb" "https://rnb.vtexcommercestable.com.br/api/pricing/pvt" "https://rnb.exampleParameterValue.com.br/api/pricing/pvt" "http://example.com/.vtexcommercestable.com.br/api/rnb"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["Promotion" "Tax"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rnb-pub-notifications create-usagenotification" } } | get name | first)
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

# Usage notification
#
# POST /api/rnb/pub/notifications
# operationId: Usagenotification
export def "rnb-pub-notifications create-usagenotification" [
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
  account_id: string
  calculator_ids: list<string>
  coupon: string
  items_count: int # format: int32
  order_id: string
  profile_id: string
  --used: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.exampleParameterValue.com.br/api/rnb")
  let full_url = (build-url $base "/api/rnb/pub/notifications" $auth.query)
  let req_body = {"accountId": $account_id, "calculatorIds": $calculator_ids, "coupon": $coupon, "itemsCount": $items_count, "orderId": $order_id, "profileId": $profile_id, "used": $used} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# List Archived Promotions
#
# GET /api/rnb/pvt/archive/benefits/calculatorConfiguration
# operationId: GetArchivedPromotions
export def "rnb-pvt-archive-benefits-calculator-configuration get-archived-promotions" [
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
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/benefits/calculatorConfiguration" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Archive Promotion or Tax
#
# POST /api/rnb/pvt/archive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: ArchivePromotion
export def "rnb-pvt-archive-calculator-configuration archive-promotion" [
  id_calculator_configuration: string
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id_calculator_configuration | is-empty) { error make --unspanned { msg: "path parameter 'idCalculatorConfiguration' must be non-empty" } }
  let full_url = (build-url $base ({id_calculator_configuration: (encode-path-segment $id_calculator_configuration)} | format pattern "/api/rnb/pvt/archive/calculatorConfiguration/{id_calculator_configuration}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Get archived coupon by coupon code
#
# GET /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Getarchivedbycouponcode
export def "rnb-pvt-archive-coupon get-archivedbycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($coupon_code | is-empty) { error make --unspanned { msg: "path parameter 'couponCode' must be non-empty" } }
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/api/rnb/pvt/archive/coupon/{coupon_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Archive coupon by coupon code
#
# POST /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Archivebycouponcode
export def "rnb-pvt-archive-coupon create-archivebycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> oneof<string, record, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($coupon_code | is-empty) { error make --unspanned { msg: "path parameter 'couponCode' must be non-empty" } }
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/api/rnb/pvt/archive/coupon/{coupon_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List Archived Taxes
#
# GET /api/rnb/pvt/archive/taxes/calculatorConfiguration
# operationId: GetArchivedTaxes
export def "rnb-pvt-archive-taxes-calculator-configuration get-archived" [
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
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/taxes/calculatorConfiguration" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get All Promotions
#
# GET /api/rnb/pvt/benefits/calculatorconfiguration
# operationId: GetAllBenefits
export def "rnb-pvt-benefits-calculatorconfiguration get-list" [
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
]: nothing -> record<archivedItems: list<string>, disabledItems: list<any>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>, limitConfigurationMaxPrice: record<activesCount: int, limit: int>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/benefits/calculatorconfiguration" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Create or Update Promotion or Tax
#
# POST /api/rnb/pvt/calculatorconfiguration
# operationId: CreateOrUpdateCalculatorConfiguration
# --affiliates item shape: {id?: string, name?: string}
# --brands item shape: {id?: string, name?: string}
# --categories item shape: {id?: string, name?: string}
# --collections item shape: {id?: string, name?: string}
# --paymentsMethods item shape: {id?: string, name?: string}
# --products item shape: {id?: string, name?: string}
# --skus item shape: {id?: string, name?: string}
# --skusGift shape: {gifts?: list, quantitySelectable?: int}
# --zipCodeRanges item shape: {inclusive?: bool}
@deprecated --flag card-issuers
@deprecated --flag collections2-buy-together
@deprecated --flag coupon
@deprecated --flag disable-deal
@deprecated --flag installment
@deprecated --flag max-prices-per-items
@deprecated --flag merchants
@deprecated --flag payments-rules
@deprecated --flag products-specifications
@deprecated --flag stores
@deprecated --flag stores-are-inclusive
@deprecated --flag total-value-include-all-items
export def "rnb-pvt-calculatorconfiguration create-or-update-calculator-configuration" [
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
  --absolute-shipping-discount-value: float # Maximum shipping value. (e.g. 0)
  --accumulate-with-manual-price: oneof<nothing, bool> # Allows the promotion to apply to products whose prices have been manually added by a call-center operator. (e.g. false)
  --activate-gifts-multiplier: oneof<nothing, bool> # If set as `true`, it activates gifts Multiplier. (e.g. false)
  --active-days-of-week: list<string> # Defines which days of the week the Promotion or Tax will applied.
  --affiliates: list # Marketplace order identifier. The discount will apply to selected affiliates. — item shape: {id?: string, name?: string}
  --apply-to-all-shippings: oneof<nothing, bool> # Promotion or Tax will be applied to all kind of shipping. (e.g. false)
  --are-sales-channel-ids-exclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any trade policies present on the `idsSalesChannel` field. If set to `true`, trade policies present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --begin-date-utc: string # Promotion or Tax Begin Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --brands: list # Object composed by the brands that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --brands-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any brand present on the `brands` field. If set to `false`, brands present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --campaigns: list # Campaign Audiences that activate this Promotion or Tax. (e.g. [Campaign Audience test])
  --card-issuers: list # DEPRECATED
  --categories: list # Object composed by the categories that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --categories-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any category present on the `categories` field. If set to `false`, categories present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --cluster-expressions: list<string> # An expression to use with clusters.
  --collections: list # Object composed by the collections that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --collections1-buy-together: list<string> # Collections that will generate the Promotion, type **Buy Together**, **More for less**, **Progressive Discount**, **Buy One Get One**.
  --collections2-buy-together: list # DEPRECATED
  --collections-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any collection present on the `collections` field. If set to `false`, collections present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --compare-list-price-and-price: oneof<nothing, bool> # If the **List Price** and **Price** are the same. (e.g. false)
  --conditions-ids: list<string> # Array with conditions IDs.
  --coupon: list # DEPRECATED
  --cumulative: oneof<nothing, bool> # Defines if a Promotion or Tax can accumulate with another one. (`true`) or not (`false`). (e.g. false)
  --days-ago-of-purchases: int # Number of days that are considered to add the purchase history. (e.g. 0)
  --description: string # Internal description of the Promotion or Tax. (e.g. Description of the promotion.)
  --disable-deal: oneof<nothing, bool> # DEPRECATED
  --discount-type: string # The type of discount that will apply to the promotion. (e.g. percentual)
  --enable-buy-together-per-sku: oneof<nothing, bool> # Enable **Buy Together** per SKU. (e.g. false)
  --end-date-utc: string # Promotion or Tax End Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --first-buy-is-profile-optimistic: oneof<nothing, bool> # Applies the discount even if the user is not logged. (e.g. false)
  --gift-list-types: list<string> # Gifts List Type.
  --id-calculator-configuration: string # Promotion ID or Tax ID. (e.g. ba087fa9-8587-44b3-8ef1-ade8d053e9e9)
  --id-seller: string # Seller Name. (e.g. 1)
  --id-seller-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any seller present on the `idSeller` field. If set to `false`, sellers present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --ids-sales-channel: list<string> # List of Trade Policies that activate this Promotion or Tax.
  --installment: int # DEPRECATED
  --is-active: oneof<nothing, bool> # If set as `true` the Promotion or Tax is activated. If set as `false` the Promotion or Tax is deactivated. (e.g. true)
  --is-archived: oneof<nothing, bool> # If set as `true` the Promotion or Tax is archived. If set as `false` the Promotion or Tax is not archived. (e.g. false)
  --is-different-list-price-and-price: oneof<nothing, bool> # Applies the Promotion or Tax only if the list price and price is different. (e.g. false)
  --is-featured: oneof<nothing, bool> # Insert a flag with the promotion name used in the product's window display and page. (e.g. true)
  --is-first-buy: oneof<nothing, bool> # Applies the discount only if it's a first buy. (e.g. false)
  --is-min-max-installments: oneof<nothing, bool> # Set if the Promotion or Tax will be applied considering a minimum and maximum values for installments. (e.g. false)
  --is-sla-selected: oneof<nothing, bool> # Applies selected discount only when one of the defined shipping method is selected by the customer. (e.g. false)
  --item-max-price: float # Maximum price of the item. (e.g. 0)
  --item-min-price: float # Minimum price of the item. (e.g. 0)
  --last-modified: string # Date when the Promotion or Tax was last modified. (e.g. 2021-02-23T20:58:38.7963862Z)
  --list-sku1-buy-together: list # SKU first list for the promotion **Buy Together**. (e.g. [SKU])
  --list-sku2-buy-together: list # SKU second list for the promotion **Buy Together**. (e.g. [SKU])
  --marketing-tags: list<string> # Promotion or Tax Marketing tags.
  --marketing-tags-are-not-inclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any marketing tag present on the `marketingTags` field. If set to `true`, marketing tags present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --max-installment: int # Maximum value for installment. (e.g. 0)
  --max-number-of-affected-items: int # The maximum number of affected items for a promotion. (e.g. 0)
  --max-number-of-affected-items-group-key: string # The maximum number of affected items by group key for a promotion. (e.g. perCart)
  --max-prices-per-items: list # DEPRECATED
  --max-usage: int # Defines how many times the Promotion or Tax can be used. (e.g. 0)
  --max-usage-per-client: int # Defines if the promotion can be used multiple times per client. (e.g. 0)
  --maximum-unit-price-discount: float # The maximum price for each item of the purchase will be the price set up. (e.g. 0)
  --merchants: list # DEPRECATED
  --min-installment: int # Minimum value for installment. (e.g. 0)
  --minimum-quantity-buy-together: int # Minimum quantity for **Buy Together** promotion. (e.g. 0)
  --multiple-use-per-client: oneof<nothing, bool> # Defines if the promotion can be used multiple times per client. (e.g. false)
  --name: string # Promotion name or Tax name. (e.g. Promoção Social Seller)
  --new-offset: float # New time offset from UTC in seconds. (e.g. -3)
  --nominal-discount-value: float # Exact discount to be applied for the total purchase value. (e.g. 0)
  --nominal-reward-value: float # Nominal value for rewards program. (e.g. 0)
  --nominal-shipping-discount-value: float # Exact discount to be applied for the shipping value. (e.g. 0)
  --nominal-tax: float # Nominal Tax. (e.g. 0)
  --offset: int # Time offset from UTC in seconds. (e.g. -3)
  --order-status-reward-value: string # Order status reward value. (e.g. invoiced)
  --origin: string # Origin of the Promotion or Tax, `marketplace` or `Fulfillment`. Read [Difference between orders with marketplace and fulfillment sources](https://help.vtex.com/en/tutorial/what-are-orders-with-marketplace-source-and-orders-with-fulfillment-source--6eVYrmUAwMOeKICU2KuG06) for more information. (e.g. marketplace)
  --payments-methods: list # Array composed by all the Payments Methods that activate this Promotion or Tax. — item shape: {id?: string, name?: string}
  --payments-rules: list # DEPRECATED
  --percentual-discount-value: float # Percentage discount to be applied for total purchase value. (e.g. 10)
  --percentual-discount-value-list: list<float> # Percentual discount value list.
  --percentual-discount-value-list1: float # Valid discounts for the SKUs in `listSku1BuyTogether`, discount list used for Buy Together Promotions. (e.g. 0)
  --percentual-discount-value-list2: float # Equivalent to `percentualDiscountValueList1`. (e.g. 0)
  --percentual-reward-value: float # Percentage value for rewards program. (e.g. 0)
  --percentual-shipping-discount-value: float # Percentage discount to be applied for shipping value. (e.g. 0)
  --percentual-tax: float # Percentual Tax over purchase total value. (e.g. 0)
  --products: list # Object composed by the products that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --products-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any product present on the `products` field. If set to `false`, products present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --products-specifications: list # DEPRECATED
  --quantity-to-affect-buy-together: int # Quantity to affect **Buy Together** promotion. (e.g. 0)
  --rebate-percentual-discount-value: float # Percentual Shipping Discount Value. (e.g. 0)
  --restrictions-bins: list<string> # The discount will be granted if the card's BIN is given.
  --shipping-percentual-tax: float # Shipping Percentual Tax over purchase total value. (e.g. 0)
  --should-distribute-discount-among-matched-items: oneof<nothing, bool> # Should distribute discount among matched items. (e.g. false)
  --skus: list # Object composed by the SKUs that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --skus-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any SKU present on the `skus` field. If set to `false`, SKUs present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --skus-gift: record # SKU Gift Object. Total discount on the product value set as a gift. — shape: {gifts?: list, quantitySelectable?: int}
  --slas-ids: list<string> # The discount will be granted if the shipping method is the same as the one given.
  --stores: list # DEPRECATED
  --stores-are-inclusive: oneof<nothing, bool> # DEPRECATED
  --total-value-celing: float # Maximum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-floor: float # Minimum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-include-all-items: oneof<nothing, bool> # DEPRECATED
  --total-value-mode: string # Defines if products that already are receiving a promotion will be considered on the chart total value. There are three options available: `IncludeMatchedItems`, `ExcludeMatchedItems`, `AllItems`. (e.g. IncludeMatchedItems)
  --total-value-purchase: float # Total value a client must have in past orders to activate the Promotion or Tax. (e.g. 0)
  --type: string # Defines what is the type of the promotion or indicates if it is a tax. Possible values: `regular` ([Regular Promotion](https://help.vtex.com/tutorial/regular-promotion--tutorials_327)), `combo` ([Buy Together](https://help.vtex.com/en/tutorial/buy-together--tutorials_323)), `forThePriceOf` ([More for Less](https://help.vtex.com/en/tutorial/creating-a-more-for-less-promotion--tutorials_325)), `progressive` ([Progressive Discount](https://help.vtex.com/en/tutorial/progressive-discount--tutorials_324)), `buyAndWin` ([Buy One Get One](https://help.vtex.com/en/tutorial/buy-one-get-one--tutorials_322)), `maxPricePerItem` (Deprecated), `campaign` ([Campaign Promotion](https://help.vtex.com/en/tutorial/campaign-promotion--1ChYXhK2AQGuS6wAqS8Ume)), `tax` (Tax), `multipleEffects` (Multiple Effects). (e.g. regular)
  --use-new-progressive-algorithm: oneof<nothing, bool> # Use new progressive algorithm. (e.g. false)
  --utm-campaign: string # Coupon utmCampaign code. (e.g. testSource)
  --utm-source: string # Coupon utmSource code. (e.g. testSource)
  --zip-code-ranges: list # Range of the zip code that applies the promotion. — item shape: {inclusive?: bool}
]: any -> record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: list<any>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/calculatorconfiguration" $auth.query)
  let req_body = {"absoluteShippingDiscountValue": $absolute_shipping_discount_value, "accumulateWithManualPrice": $accumulate_with_manual_price, "activateGiftsMultiplier": $activate_gifts_multiplier, "activeDaysOfWeek": $active_days_of_week, "affiliates": $affiliates, "applyToAllShippings": $apply_to_all_shippings, "areSalesChannelIdsExclusive": $are_sales_channel_ids_exclusive, "beginDateUtc": $begin_date_utc, "brands": $brands, "brandsAreInclusive": $brands_are_inclusive, "campaigns": $campaigns, "cardIssuers": $card_issuers, "categories": $categories, "categoriesAreInclusive": $categories_are_inclusive, "clusterExpressions": $cluster_expressions, "collections": $collections, "collections1BuyTogether": $collections1_buy_together, "collections2BuyTogether": $collections2_buy_together, "collectionsIsInclusive": $collections_is_inclusive, "compareListPriceAndPrice": $compare_list_price_and_price, "conditionsIds": $conditions_ids, "coupon": $coupon, "cumulative": $cumulative, "daysAgoOfPurchases": $days_ago_of_purchases, "description": $description, "disableDeal": $disable_deal, "discountType": $discount_type, "enableBuyTogetherPerSku": $enable_buy_together_per_sku, "endDateUtc": $end_date_utc, "firstBuyIsProfileOptimistic": $first_buy_is_profile_optimistic, "giftListTypes": $gift_list_types, "idCalculatorConfiguration": $id_calculator_configuration, "idSeller": $id_seller, "idSellerIsInclusive": $id_seller_is_inclusive, "idsSalesChannel": $ids_sales_channel, "installment": $installment, "isActive": $is_active, "isArchived": $is_archived, "isDifferentListPriceAndPrice": $is_different_list_price_and_price, "isFeatured": $is_featured, "isFirstBuy": $is_first_buy, "isMinMaxInstallments": $is_min_max_installments, "isSlaSelected": $is_sla_selected, "itemMaxPrice": $item_max_price, "itemMinPrice": $item_min_price, "lastModified": $last_modified, "listSku1BuyTogether": $list_sku1_buy_together, "listSku2BuyTogether": $list_sku2_buy_together, "marketingTags": $marketing_tags, "marketingTagsAreNotInclusive": $marketing_tags_are_not_inclusive, "maxInstallment": $max_installment, "maxNumberOfAffectedItems": $max_number_of_affected_items, "maxNumberOfAffectedItemsGroupKey": $max_number_of_affected_items_group_key, "maxPricesPerItems": $max_prices_per_items, "maxUsage": $max_usage, "maxUsagePerClient": $max_usage_per_client, "maximumUnitPriceDiscount": $maximum_unit_price_discount, "merchants": $merchants, "minInstallment": $min_installment, "minimumQuantityBuyTogether": $minimum_quantity_buy_together, "multipleUsePerClient": $multiple_use_per_client, "name": $name, "newOffset": $new_offset, "nominalDiscountValue": $nominal_discount_value, "nominalRewardValue": $nominal_reward_value, "nominalShippingDiscountValue": $nominal_shipping_discount_value, "nominalTax": $nominal_tax, "offset": $offset, "orderStatusRewardValue": $order_status_reward_value, "origin": $origin, "paymentsMethods": $payments_methods, "paymentsRules": $payments_rules, "percentualDiscountValue": $percentual_discount_value, "percentualDiscountValueList": $percentual_discount_value_list, "percentualDiscountValueList1": $percentual_discount_value_list1, "percentualDiscountValueList2": $percentual_discount_value_list2, "percentualRewardValue": $percentual_reward_value, "percentualShippingDiscountValue": $percentual_shipping_discount_value, "percentualTax": $percentual_tax, "products": $products, "productsAreInclusive": $products_are_inclusive, "productsSpecifications": $products_specifications, "quantityToAffectBuyTogether": $quantity_to_affect_buy_together, "rebatePercentualDiscountValue": $rebate_percentual_discount_value, "restrictionsBins": $restrictions_bins, "shippingPercentualTax": $shipping_percentual_tax, "shouldDistributeDiscountAmongMatchedItems": $should_distribute_discount_among_matched_items, "skus": $skus, "skusAreInclusive": $skus_are_inclusive, "skusGift": $skus_gift, "slasIds": $slas_ids, "stores": $stores, "storesAreInclusive": $stores_are_inclusive, "totalValueCeling": $total_value_celing, "totalValueFloor": $total_value_floor, "totalValueIncludeAllItems": $total_value_include_all_items, "totalValueMode": $total_value_mode, "totalValuePurchase": $total_value_purchase, "type": $type, "useNewProgressiveAlgorithm": $use_new_progressive_algorithm, "utmCampaign": $utm_campaign, "utmSource": $utm_source, "zipCodeRanges": $zip_code_ranges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get Promotion or Tax by ID
#
# GET /api/rnb/pvt/calculatorconfiguration/{idCalculatorConfiguration}
# operationId: GetCalculatorConfigurationById
export def "rnb-pvt-calculatorconfiguration get-calculator-configuration" [
  id_calculator_configuration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleSkusCause: record, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: table<inclusive: bool, zipCodeFrom: string, zipCodeTo: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id_calculator_configuration | is-empty) { error make --unspanned { msg: "path parameter 'idCalculatorConfiguration' must be non-empty" } }
  let full_url = (build-url $base ({id_calculator_configuration: (encode-path-segment $id_calculator_configuration)} | format pattern "/api/rnb/pvt/calculatorconfiguration/{id_calculator_configuration}") $auth.query)
  let accept_val = ($accept | default "Promotion")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get all campaign audiences
#
# GET /api/rnb/pvt/campaignConfiguration
# operationId: Getcampaignaudiences
export def "rnb-pvt-campaign-configuration get-campaignaudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> table<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: list<record>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Create campaign audience
#
# POST /api/rnb/pvt/campaignConfiguration
# operationId: Setcampaignconfiguration
# --lastModified shape: {dateUtc?: string, user?: string}
# --targetConfigurations item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list<string>, clusterOperator?: string, collections?: list, collections1BuyTogether?: list<string>, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, ... (48 more fields)}
export def "rnb-pvt-campaign-configuration create-setcampaignconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --begin-date-utc: string # Start date of the campaign audience in UTC format. (e.g. 2020-05-01T21:30:00Z)
  --end-date-utc: string # End date of the campaign audience in UTC format. (e.g. 2020-05-02T01:30:00Z)
  --id: string # Campaign audience ID. (e.g. dd270d06-1ed1-47fc-b04e-a2431121b5a4)
  --is-active: oneof<nothing, bool> # Defines if the campaign audience is active (`true`) or not (`false`). (e.g. true)
  --is-and-operator: oneof<nothing, bool> # When `true`, determines that all the `targetConfigurations` need to be valid for the campaign audience to be active. When `false`, determines that if at least one of the `targetConfigurations` is valid, the campaign audience will be active. (e.g. true)
  --is-archived: oneof<nothing, bool> # Defines if the campaign audience is archived (`true`) or not (`false`). (e.g. false)
  --last-modified: record # Object with information about the last update of the campaign audience. — shape: {dateUtc?: string, user?: string}
  --name: string # Campaign audience name. (e.g. Interna)
  --target-configurations: list # Array that contains all target audience that the campaign audience will be valid. — item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list<string>, clusterOperator?: string, collections?: list, collections1BuyTogether?: list<string>, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, ... (48 more fields)}
]: any -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, clusterOperator: string, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration" $auth.query)
  let req_body = {"beginDateUtc": $begin_date_utc, "endDateUtc": $end_date_utc, "id": $id, "isActive": $is_active, "isAndOperator": $is_and_operator, "isArchived": $is_archived, "lastModified": $last_modified, "name": $name, "targetConfigurations": $target_configurations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get campaign audience configuration
#
# GET /api/rnb/pvt/campaignConfiguration/{campaignId}
# operationId: Getcampaignconfiguration
export def "rnb-pvt-campaign-configuration get-campaignconfiguration" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaignId' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/api/rnb/pvt/campaignConfiguration/{campaign_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get all coupons
#
# GET /api/rnb/pvt/coupon
# operationId: Getall
export def "rnb-pvt-coupon get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Update coupon
#
# POST /api/rnb/pvt/coupon
# operationId: Update
export def "rnb-pvt-coupon update" [
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
  coupon_code: string # Coupon code. (e.g. test)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  --is-archived: oneof<nothing, bool> # Defines if the coupon is archived (`true`) or not (`false`). (e.g. false)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  utm_campaign: string # UTM campaign code. (e.g. coupon3)
  utm_source: string # UTM source code. (e.g. coupon3)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon" $auth.query)
  let req_body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "isArchived": $is_archived, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Create coupon
#
# POST /api/rnb/pvt/coupon/
export def "rnb-pvt-coupon create" [
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
  coupon_code: string # Coupon code. (e.g. summersale10)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  --utm-campaign: string # UTM campaign code. (e.g. summer)
  utm_source: string # UTM source code. (e.g. email)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon/" $auth.query)
  let req_body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Get coupon usage
#
# GET /api/rnb/pvt/coupon/usage/{couponCode}
# operationId: Getusage
export def "rnb-pvt-coupon-usage get" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, hostName: string, profileUsages: record<profileId: record<orderUsage: list>>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($coupon_code | is-empty) { error make --unspanned { msg: "path parameter 'couponCode' must be non-empty" } }
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/api/rnb/pvt/coupon/usage/{coupon_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get coupon by coupon code
#
# GET /api/rnb/pvt/coupon/{couponCode}
# operationId: Getbycouponcode
export def "rnb-pvt-coupon get-bycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($coupon_code | is-empty) { error make --unspanned { msg: "path parameter 'couponCode' must be non-empty" } }
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/api/rnb/pvt/coupon/{coupon_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Coupon Massive Generation
#
# POST /api/rnb/pvt/coupons
# operationId: MassiveGeneration
export def "rnb-pvt-coupons create-massive-generation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity of coupons to generate (e.g. 10)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  coupon_code: string # Coupon code. (e.g. ctest)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Defines if the coupon is archived (`true`) or not (`false`). (e.g. 1)
  utm_campaign: string # UTM campaign code. (e.g. cupom3)
  utm_source: string # UTM source code. (e.g. cupom3)
]: any -> list<string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rnb/pvt/coupons" $qp $auth.query)
  let req_body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"quantity": $quantity} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create Multiple SKU Promotion
#
# POST /api/rnb/pvt/import/calculatorConfiguration
export def "rnb-pvt-import-calculator-configuration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --x-vtex-calculator-name: string # Promotion Name. (e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/import/calculatorConfiguration" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "X-VTEX-calculator-name": $x_vtex_calculator_name, "X-VTEX-cumulative": $x_vtex_cumulative, "X-VTEX-cluster-operator": $x_vtex_cluster_operator, "X-VTEX-cluster-expression": $x_vtex_cluster_expression, "X-VTEX-start-date": $x_vtex_start_date, "X-VTEX-end-date": $x_vtex_end_date, "X-VTEX-accumulate-with-manual-prices": $x_vtex_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "text/csv")
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

# Update Multiple SKU Promotion
#
# PUT /api/rnb/pvt/import/calculatorConfiguration/{promotionId}
export def "rnb-pvt-import-calculator-configuration update" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --x-vtex-calculator-name: string # Promotion Name. (e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotionId' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/api/rnb/pvt/import/calculatorConfiguration/{promotion_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "X-VTEX-calculator-name": $x_vtex_calculator_name, "X-VTEX-cumulative": $x_vtex_cumulative, "X-VTEX-cluster-operator": $x_vtex_cluster_operator, "X-VTEX-cluster-expression": $x_vtex_cluster_expression, "X-VTEX-start-date": $x_vtex_start_date, "X-VTEX-end-date": $x_vtex_end_date, "X-VTEX-accumulate-with-manual-prices": $x_vtex_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "text/csv")
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
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [202]
}

# Create multiple coupons
#
# POST /api/rnb/pvt/multiple-coupons
export def "rnb-pvt-multiple-coupons create" [
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
]: any -> list<string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/multiple-coupons" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get All Taxes
#
# GET /api/rnb/pvt/taxes/calculatorconfiguration
# operationId: GetAllTaxes
export def "rnb-pvt-taxes-calculatorconfiguration get-list" [
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
]: nothing -> record<archivedItems: list<string>, disabledItems: list<string>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/taxes/calculatorconfiguration" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Unarchive Promotion or Tax
#
# POST /api/rnb/pvt/unarchive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: UnarchivePromotion
export def "rnb-pvt-unarchive-calculator-configuration unarchive-promotion" [
  id_calculator_configuration: string
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id_calculator_configuration | is-empty) { error make --unspanned { msg: "path parameter 'idCalculatorConfiguration' must be non-empty" } }
  let full_url = (build-url $base ({id_calculator_configuration: (encode-path-segment $id_calculator_configuration)} | format pattern "/api/rnb/pvt/unarchive/calculatorConfiguration/{id_calculator_configuration}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Unarchive coupon by coupon code
#
# POST /api/rnb/pvt/unarchive/coupon/{couponCode}
# operationId: Unarchivebycouponcode
export def "rnb-pvt-unarchive-coupon create-unarchivebycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> oneof<string, record, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($coupon_code | is-empty) { error make --unspanned { msg: "path parameter 'couponCode' must be non-empty" } }
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/api/rnb/pvt/unarchive/coupon/{coupon_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Save Price
#
# POST /price-sheet
# operationId: Saveprice
export def "price-sheet create-saveprice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.vtexcommercestable.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get all paged prices
#
# GET /price-sheet/all/{page}/{pageSize}
# operationId: Getallpaged
export def "price-sheet-all get-allpaged" [
  page: string
  page_size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.vtexcommercestable.com.br/api/pricing/pvt")
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  if ($page_size | is-empty) { error make --unspanned { msg: "path parameter 'pageSize' must be non-empty" } }
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({page: (encode-path-segment $page), page_size: (encode-path-segment $page_size)} | format pattern "/price-sheet/all/{page}/{page_size}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Price by context
#
# POST /price-sheet/context
# operationId: Pricebycontext
export def "price-sheet-context create-pricebycontext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  id: int # format: int32
  item_id: int # format: int32
  sales_channel: int # format: int32
  seller_id: string
  valid_from: string
  valid_to: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.vtexcommercestable.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet/context" $qp $auth.query)
  let req_body = {"id": $id, "itemId": $item_id, "salesChannel": $sales_channel, "sellerId": $seller_id, "validFrom": $valid_from, "validTo": $valid_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete Price by SKU Id
#
# DELETE /price-sheet/{skuId}
# operationId: DeletebyskuId
export def "price-sheet delete-bysku" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.exampleParameterValue.com.br/api/pricing/pvt")
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/price-sheet/{sku_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get Price by SKU ID
#
# GET /price-sheet/{skuId}
# operationId: PricebyskuId
export def "price-sheet get-pricebysku" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.vtexcommercestable.com.br/api/pricing/pvt")
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/price-sheet/{sku_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Price by SKU ID and Trade Policy
#
# GET /price-sheet/{skuId}/{tradePolicy}
# operationId: PricebyskuIdandtradePolicy
export def "price-sheet get-pricebysku-idandtrade-policy" [
  sku_id: string
  trade_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://rnb.vtexcommercestable.com.br/api/pricing/pvt")
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($trade_policy | is-empty) { error make --unspanned { msg: "path parameter 'tradePolicy' must be non-empty" } }
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), trade_policy: (encode-path-segment $trade_policy)} | format pattern "/price-sheet/{sku_id}/{trade_policy}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"an": $an} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Calculate discounts and taxes (Bundles)
#
# POST /pub/bundles
# operationId: Calculatediscountsandtaxes(Bundles)
# --items item shape: {id: string, index: int, isGift: bool, logisticsInfos: list<string>, measurementUnit: string, params: list, priceSheet: list<string>, priceTags: list<string>, productSpecifications: list<string>, quantity: int, sellerId: string, unitMultiplier: int}
# --params item shape: {name: string, value: string}
export def "pub-bundles create-calculatediscountsandtaxesbundles" [
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
  --is-shopping-cart: oneof<nothing, bool>
  items: list # item shape: {id: string, index: int, isGift: bool, logisticsInfos: list<string>, measurementUnit: string, params: list, priceSheet: list<string>, priceTags: list<string>, productSpecifications: list<string>, quantity: int, sellerId: string, unitMultiplier: int}
  origin: string
  params: list # item shape: {name: string, value: string}
  profile_id: string
  sales_channel: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROMOTIONS_TAXES_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROMOTIONS_TAXES_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.vtexcommercestable.com.br/api/rnb")
  let full_url = (build-url $base "/pub/bundles" $auth.query)
  let req_body = {"isShoppingCart": $is_shopping_cart, "items": $items, "origin": $origin, "params": $params, "profileId": $profile_id, "salesChannel": $sales_channel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
