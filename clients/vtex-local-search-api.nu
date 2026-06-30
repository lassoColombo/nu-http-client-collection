# Auto-generated client for Legacy Search API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Search-API/1.0/openapi.json
# Auth: --token flag or $env.LEGACY_SEARCH_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LEGACY_SEARCH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories" "http://example.com/.DefaultParameterValue.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "catalog-system-pub-facets-category get" } } | get name | first)
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

# Get Category Facets
#
# GET /api/catalog_system/pub/facets/category/{categoryId}
export def "catalog-system-pub-facets-category get" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<Id: int, Name: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog_system/pub/facets/category/{category_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"_from": $qp_from, "_to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search by Store Facets
#
# GET /api/catalog_system/pub/facets/search/{term}
# operationId: Facetscategory
export def "catalog-system-pub-facets-search get-facetscategory" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --map: string # Mapping of the term. It can be `c` for a category, `b` for a brand, or `specificationFilter_{specificationId}` for a specification. You need to include a map for each term you are searching for in the same term's order. (e.g. c)
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> record<Brands: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, CategoriesTrees: table<Children: list, Id: int, Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, Departments: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, PriceRanges: list<any>, SpecificationFilters: record, Summary: record<Brands: record<DisplayedItems: int, TotalItems: int>, CategoriesTrees: record<DisplayedItems: int, TotalItems: int>, Departments: record<DisplayedItems: int, TotalItems: int>, PriceRanges: record<DisplayedItems: int, TotalItems: int>, SpecificationFilters: record>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "map" $map "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({term: (encode-path-segment $term)} | format pattern "/api/catalog_system/pub/facets/search/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"map": $map, "_from": $qp_from, "_to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Product Search of Accessories
#
# GET /api/catalog_system/pub/products/crossselling/accessories/{productId}
# operationId: ProductSearchAccessories
export def "catalog-system-pub-products-crossselling-accessories list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/accessories/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Show Together
#
# GET /api/catalog_system/pub/products/crossselling/showtogether/{productId}
# operationId: ProductSearchShowTogether
export def "catalog-system-pub-products-crossselling-showtogether list-show-together" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/showtogether/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Similars
#
# GET /api/catalog_system/pub/products/crossselling/similars/{productId}
# operationId: ProductSearchSimilars
export def "catalog-system-pub-products-crossselling-similars list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/similars/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Suggestions
#
# GET /api/catalog_system/pub/products/crossselling/suggestions/{productId}
# operationId: ProductSearchSuggestions
export def "catalog-system-pub-products-crossselling-suggestions list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/suggestions/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Who Bought Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whoboughtalsobought/{productId}
# operationId: ProductSearchWhoBoughtAlsoBought
export def "catalog-system-pub-products-crossselling-whoboughtalsobought list-who-bought-also-bought" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whoboughtalsobought/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Who Saw Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsobought/{productId}
# operationId: ProductSearchWhoSawAlsoBought
export def "catalog-system-pub-products-crossselling-whosawalsobought list-who-saw-also-bought" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whosawalsobought/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Get Product Search of Who Saw Also Saw
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsosaw/{productId}
# operationId: ProductSearchWhoSawAlsoSaw
export def "catalog-system-pub-products-crossselling-whosawalsosaw list-who-saw-also-saw" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whosawalsosaw/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Search Product offers
#
# GET /api/catalog_system/pub/products/offers/{productId}
export def "catalog-system-pub-products-offers get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/offers/{product_id}") $auth.query)
  let accept_val = "application/json"
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

# Search SKU offers
#
# GET /api/catalog_system/pub/products/offers/{productId}/sku/{skuId}
export def "catalog-system-pub-products-offers-sku get" [
  product_id: string
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
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog_system/pub/products/offers/{product_id}/sku/{sku_id}") $auth.query)
  let accept_val = "application/json"
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

# Search for Products with Filter, Order and Pagination
#
# GET /api/catalog_system/pub/products/search
# operationId: ProductSearchFilteredandOrdered
export def "catalog-system-pub-products-search list-filteredand-ordered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --ft: string # Filter by full text. The form is`ft={searchWord}` (e.g. television)
  --fq: string # General filter. It can be by category (`fq=C:/{a}/{b}`), by specification (`fq=specificationFilter_{a}:{b}`), by price range (`fq=P:[{a} TO {b}]`), by collection (`fq=productClusterIds:{{productClusterId}}`), by product ID (`fq=productId:{{productId}}`), by SKU ID (`fq=skuId:{{skuId}}`), by Reference ID (`fq=alternateIds_RefId:{{referenceId}}`), by EAN13 (`fq=alternateIds_Ean:{{ean13}}`), by availability at a specific sales channel (`fq=isAvailablePerSalesChannel_{{sc}}:{{bool}}`), by available at a specific seller (`fq=sellerId:{{sellerId}}`) (e.g. C:/1000041/1000049/)
  --o: string # Sorting method. It can be by Price (`O=OrderByPriceDESC` or `O=OrderByPriceASC`), by Top Selling Products (`O=OrderByTopSaleDESC`), by Best Reviews (`O=OrderByReviewRateDESC`), by Name (`O=OrderByNameASC` or `O=OrderByNameDESC`), by Release Date (`O=OrderByReleaseDateDESC`), by Best Discounts (`O=OrderByBestDiscountDESC`), by Score (`O=OrderByScoreDESC`) (e.g. OrderByNameASC)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "ft" $ft "scalar") (serialize-qp "fq" $fq "scalar") (serialize-qp "O" $o "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pub/products/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"_from": $qp_from, "_to": $qp_to, "ft": $ft, "fq": $fq, "O": $o} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search Product by Product URL
#
# GET /api/catalog_system/pub/products/search/{product-text-link}/p
# operationId: Searchbyproducturl
export def "catalog-system-pub-products-search-p get-searchbyproducturl" [
  product_text_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_text_link | is-empty) { error make --unspanned { msg: "path parameter 'product-text-link' must be non-empty" } }
  let full_url = (build-url $base ({product_text_link: (encode-path-segment $product_text_link)} | format pattern "/api/catalog_system/pub/products/search/{product_text_link}/p") $auth.query)
  let accept_val = "application/json"
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

# Search for Products
#
# GET /api/catalog_system/pub/products/search/{search}
# operationId: ProductSearch
export def "catalog-system-pub-products-search list" [
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($search | is-empty) { error make --unspanned { msg: "path parameter 'search' must be non-empty" } }
  let full_url = (build-url $base ({search: (encode-path-segment $search)} | format pattern "/api/catalog_system/pub/products/search/{search}") $auth.query)
  let accept_val = "application/json"
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

# Product Search Autocomplete
#
# GET /buscaautocomplete
# operationId: AutoComplete
export def "buscaautocomplete complete-auto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-name-contains: string # Part of the string that will be searched. (e.g. jeans)
  --content-type: string # Type of the content being sent (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand (e.g. application/json)
]: nothing -> record<itemsReturned: table<criteria: string, href: string, items: list, name: string, thumb: string, thumbUrl: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LEGACY_SEARCH_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LEGACY_SEARCH_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  let qp = [(serialize-qp "productNameContains" $product_name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buscaautocomplete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"productNameContains": $product_name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
