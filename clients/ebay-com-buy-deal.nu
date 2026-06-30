# Auto-generated client for Deal API vv1.3.0
# Source: https://api.apis.guru/v2/specs/ebay.com/buy-deal/v1.3.0/openapi.json
# Auth: --token flag or $env.DEAL_API_TOKEN

const BASE_URL = "https://api.ebay.com/buy/deal/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DEAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.ebay.com/buy/deal/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deal-item get" } } | get name | first)
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

# This method retrieves a paginated set of deal items. The result set contains all deal items associated with the specified search criteria and marketplace ID. Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /deal_item
# operationId: getDealItems
export def "deal-item get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: string # The unique identifier of the eBay category for the search.
  --commissionable: string # A filter for commissionable deals. Restriction: This filter is currently only supported for the US marketplace.
  --delivery-country: string # A filter for items that can be shipped to the specified country.
  --limit: string # The maximum number of items, from the current result set, returned on a single page.
  --offset: string # The number of items that will be skipped in the result set. This is used with the limit field to control the pagination of the output. For example, if the offset is set to 0 and the limit is set to 10, the method will retrieve items 1 through 10 from the list of items returned. If the offset is set to 10 and the limit is set to 10, the method will retrieve items 11 through 20 from the list of items returned. Default: 0
  --x-ebay-c-marketplace-id: string # A header used to specify the eBay marketplace ID.
]: nothing -> record<dealItems: table<additionalImages: list, categoryAncestorIds: list, categoryId: string, commissionable: bool, dealAffiliateWebUrl: string, dealEndDate: string, dealStartDate: string, dealWebUrl: string, energyEfficiencyClass: string, image: record, itemAffiliateWebUrl: string, itemGroupId: string, itemGroupType: string, itemId: string, itemWebUrl: string, legacyItemId: string, marketingPrice: record, price: record, qualifiedPrograms: list, shippingOptions: list, title: string, unitPrice: record, unitPricingMeasure: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "commissionable" $commissionable "scalar") (serialize-qp "delivery_country" $delivery_country "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deal_item" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category_ids": $category_ids, "commissionable": $commissionable, "delivery_country": $delivery_country, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method returns paginated results containing all eBay events for the specified marketplace. Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /event
# operationId: getEvents
export def "event list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # The maximum number of items, from the current result set, returned on a single page. Default: 20 Maximum Value: 100
  --offset: string # The number of items that will be skipped in the result set. This is used with the limit field to control the pagination of the output. For example, if the offset is set to 0 and the limit is set to 10, the method will retrieve items 1 through 10 from the list of items returned. If the offset is set to 10 and the limit is set to 10, the method will retrieve items 11 through 20 from the list of items returned. Default: 0
  --x-ebay-c-marketplace-id: string # A header used to specify the eBay marketplace ID.
]: nothing -> record<events: table<applicableCoupons: list, description: string, endDate: string, eventAffiliateWebUrl: string, eventId: string, eventWebUrl: string, images: list, startDate: string, terms: record, title: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method retrieves the details for an eBay event. The result set contains detailed information associated with the specified event ID, such as applicable coupons, start and end dates, and event terms. Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /event/{event_id}
# operationId: getEvent
export def "event get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # A header used to specify the eBay marketplace ID.
]: nothing -> record<applicableCoupons: table<redemptionCode: string, terms: record>, description: string, endDate: string, eventAffiliateWebUrl: string, eventId: string, eventWebUrl: string, images: table<height: string, imageUrl: string, text: string, width: string>, startDate: string, terms: record<fullText: string, summary: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/event/{event_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
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

# This method returns a paginated set of event items. The result set contains all event items associated with the specified search criteria and marketplace ID. Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /event_item
# operationId: getEventItems
export def "event-item get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: string # The unique identifier of the eBay category for the search. Maximum Value: 1
  --delivery-country: string # A filter for items that can be shipped to the specified country.
  --event-ids: string # The unique identifiers for the eBay events. Maximum Value: 1
  --limit: string # The maximum number of items, from the current result set, returned on a single page. Default: 20
  --offset: string # The number of items that will be skipped in the result set. This is used with the limit field to control the pagination of the output. For example, if the offset is set to 0 and the limit is set to 10, the method will retrieve items 1 through 10 from the list of items returned. If the offset is set to 10 and the limit is set to 10, the method will retrieve items 11 through 20 from the list of items returned. Default: 0
  --x-ebay-c-marketplace-id: string # A header used to specify the eBay marketplace ID.
]: nothing -> record<eventItems: table<additionalImages: list, categoryAncestorIds: list, categoryId: string, energyEfficiencyClass: string, eventId: string, image: record, itemAffiliateWebUrl: string, itemGroupId: string, itemGroupType: string, itemId: string, itemWebUrl: string, legacyItemId: string, marketingPrice: record, price: record, qualifiedPrograms: list, shippingOptions: list, title: string, unitPrice: record, unitPricingMeasure: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "delivery_country" $delivery_country "scalar") (serialize-qp "event_ids" $event_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event_item" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category_ids": $category_ids, "delivery_country": $delivery_country, "event_ids": $event_ids, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
