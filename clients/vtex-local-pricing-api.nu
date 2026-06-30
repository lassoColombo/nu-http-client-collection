# Auto-generated client for Pricing API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Pricing-API/1.0/openapi.json
# Auth: --token flag or $env.PRICING_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PRICING_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://api.vtex.com/{accountName}" "https://api.vtex.com/DefaultParameterValue/pricing"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pricing-config get" } } | get name | first)
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

# Get Pricing Configuration
#
# GET /pricing/config
# operationId: GetPricingConfig
export def "pricing-config get" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<blockAccount: bool, blockedRoutes: list<string>, defaultMarkup: int, hasMigrated: bool, hasOptionalBasePrice: bool, hasPriceInheritance: bool, migrationStatus: string, minimumMarkups: record, priceInheritance: string, priceTableLimit: int, priceTableSelectionStrategy: string, priceVariation: record<lowerLimit: int, upperLimit: int>, sellersToOverride: list<any>, tradePolicyConfigs: table<minimumMarkup: int, rulesShouldAffectListPrice: bool, tradePolicyId: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  let full_url = (build-url $base "/pricing/config" $auth.query)
  let accept_val = "application/json; charset=utf-8"
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

# Get Pricing v2 Status
#
# GET /pricing/migration
# operationId: GetPricingv2Status
export def "pricing-migration get-pricingv2-status" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<hasMigrated: bool, isActive: bool> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  let full_url = (build-url $base "/pricing/migration" $auth.query)
  let accept_val = "application/json; charset=utf-8"
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

# Get all price tables and their rules
#
# GET /pricing/pipeline/catalog
# operationId: getallpricetablesandrules
export def "pricing-pipeline-catalog get-allpricetablesandrules" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<percentualModifier: int, rules: list<record>, tradePolicyId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  let full_url = (build-url $base "/pricing/pipeline/catalog" $auth.query)
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

# Get rules for a price table
#
# GET /pricing/pipeline/catalog/{priceTableId}
# operationId: Getrulesforapricetable
export def "pricing-pipeline-catalog get-rulesforapricetable" [
  price_table_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<percentualModifier: int, rules: table<context: record, id: float>, tradePolicyId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let full_url = (build-url $base ({price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/pipeline/catalog/{price_table_id}") $auth.query)
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

# Update rules for a price table
#
# PUT /pricing/pipeline/catalog/{priceTableId}
# --rules item shape: {context: record, id: int, percentualModifier: float}
export def "pricing-pipeline-catalog update" [
  price_table_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  rules: list # Array of rules for the price table. — item shape: {context: record, id: int, percentualModifier: float}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let full_url = (build-url $base ({price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/pipeline/catalog/{price_table_id}") $auth.query)
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete Price
#
# DELETE /pricing/prices/{itemId}
# operationId: DeletePrice
export def "pricing-prices delete" [
  item_id: int
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/pricing/prices/{item_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get Price
#
# GET /pricing/prices/{itemId}
# operationId: GetPrice
export def "pricing-prices get" [
  item_id: int
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<basePrice: int, costPrice: int, fixedPrices: table<dateRange: record, listPrice: float, minQuantity: int, tradePolicyId: string, value: float>, itemId: string, listPrice: int, markup: int> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/pricing/prices/{item_id}") $auth.query)
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

# Create or Update Base Price or Fixed Prices
#
# PUT /pricing/prices/{itemId}
# operationId: CreateUpdatePriceOrFixedPrice
# --fixedPrices item shape: {dateRange?: record, listPrice?: float, minQuantity: int, tradePolicyId: string, value: float}
export def "pricing-prices create-update-or-fixed" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent.
  base_price: float # SKU selling base price. If you decide to fill only the `basePrice` item, the `markup` and `costPrice` will be automatically generated to adapt to the number inserted in `basePrice`. (default: 100)
  --cost-price: float # SKU selling cost price. If you decide to fill the `costPrice` item, you must also fill the `markup` and `basePrice` will be automatically generated based on both values. (default: 35)
  --fixed-prices: list # item shape: {dateRange?: record, listPrice?: float, minQuantity: int, tradePolicyId: string, value: float}
  list_price: float # SKU's suggested selling price. (default: 50)
  markup: int # The profit percentage that is to be obtained from the sale of that SKU. If you decide to fill the `markup` item, you must also fill the `costPrice`. The `basePrice` will be automatically generated based on both values. (default: 30)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/pricing/prices/{item_id}") $auth.query)
  let req_body = {"basePrice": $base_price, "costPrice": $cost_price, "fixedPrices": $fixed_prices, "listPrice": $list_price, "markup": $markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
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

# Get Computed Price by price table or trade policy
#
# GET /pricing/prices/{itemId}/computed/{priceTableId}
# operationId: GetComputedPricebypricetable
export def "pricing-prices-computed get-pricebypricetable" [
  item_id: int
  price_table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: int # Category ID. (e.g. 1)
  --brand-id: int # Brand ID. (e.g. 3)
  --quantity: int # SKU quantity. (e.g. 2)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<costPrice: float, listPrice: int, priceValidUntil: string, sellingPrice: float, tradePolicyId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let qp = [(serialize-qp "categoryIds" $category_ids "scalar") (serialize-qp "brandId" $brand_id "scalar") (serialize-qp "quantity" $quantity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/prices/{item_id}/computed/{price_table_id}") $qp $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"categoryIds": $category_ids, "brandId": $brand_id, "quantity": $quantity} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Fixed Prices
#
# GET /pricing/prices/{itemId}/fixed
# operationId: GetFixedPrices
export def "pricing-prices-fixed get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent.
]: nothing -> table<dateRange: record<from: string, to: string>, listPrice: float, minQuantity: int, tradePolicyId: string, value: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/pricing/prices/{item_id}/fixed") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
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

# Delete Fixed Prices on a price table or trade policy
#
# DELETE /pricing/prices/{itemId}/fixed/{priceTableId}
# operationId: Deletefixedpricesonapricetableortradepolicy
export def "pricing-prices-fixed delete-fixedpricesonapricetableortradepolicy" [
  item_id: int
  price_table_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/prices/{item_id}/fixed/{price_table_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get Fixed Prices on a price table or trade policy
#
# GET /pricing/prices/{itemId}/fixed/{priceTableId}
# operationId: GetFixedPricesonapricetable
export def "pricing-prices-fixed get-pricesonapricetable" [
  item_id: int
  price_table_id: string
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
  --hdr-accept: string # e.g. application/json
]: nothing -> table<dateRange: record<from: string, to: string>, listPrice: float, minQuantity: int, tradePolicyId: string, value: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/prices/{item_id}/fixed/{price_table_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
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

# Create or Update Fixed Prices on a price table or trade policy
#
# POST /pricing/prices/{itemId}/fixed/{priceTableId}
# operationId: createorupdatefixedpricesonpricetableortradepolicy
export def "pricing-prices-fixed create-orupdatefixedpricesonpricetableortradepolicy" [
  item_id: int
  price_table_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($price_table_id | is-empty) { error make --unspanned { msg: "path parameter 'priceTableId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), price_table_id: (encode-path-segment $price_table_id)} | format pattern "/pricing/prices/{item_id}/fixed/{price_table_id}") $auth.query)
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

# List price tables
#
# GET /pricing/tables
# operationId: Listpricetables
export def "pricing-tables list-pricetables" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PRICING_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PRICING_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://api.vtex.com/DefaultParameterValue/pricing")
  let full_url = (build-url $base "/pricing/tables" $auth.query)
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
