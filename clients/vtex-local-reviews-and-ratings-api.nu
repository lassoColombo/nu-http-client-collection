# Auto-generated client for Reviews and Ratings API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Reviews-and-Ratings-API/1.0/openapi.json
# Auth: --token flag or $env.REVIEWS_AND_RATINGS_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o REVIEWS_AND_RATINGS_API_TOKEN | default "" }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.myvtex.com/reviews-and-ratings/api"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rating get-product" } } | get name | first)
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

# Get Product Rating
#
# GET /rating/{productId}
# operationId: GetProductRating
export def "rating get-product" [
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
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<average: float, totalCount: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/rating/{product_id}") $auth.query)
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

# Create a Review
#
# POST /review
# operationId: SaveReview
export def "review create-save" [
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
  product_id: string # Product ID.
  rating: int # Customer rating. (format: int32)
  reviewer_name: string # Reviewer name.
  text: string # Review's text.
  title: string # Review's title.
]: any -> record<approved: bool, id: string, locale: string, location: string, pastReviews: string, productId: string, rating: float, reviewDateTime: string, reviewerName: string, searchDate: string, shopperId: string, sku: string, text: string, title: string, verifiedPurchaser: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/review" $auth.query)
  let req_body = {"productId": $product_id, "rating": $rating, "reviewerName": $reviewer_name, "text": $text, "title": $title} | compact
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

# Delete Review
#
# DELETE /review/{reviewId}
# operationId: DeleteReview
export def "review delete" [
  review_id: string
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
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/review/{review_id}") $auth.query)
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

# Get Review by Review ID
#
# GET /review/{reviewId}
# operationId: GetReviewbyReviewId
export def "review get-reviewby" [
  review_id: string
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
]: nothing -> record<approved: bool, id: string, locale: string, location: string, pastReviews: string, productId: string, rating: float, reviewDateTime: string, reviewerName: string, searchDate: string, shopperId: string, sku: string, text: string, title: string, verifiedPurchaser: bool> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/review/{review_id}") $auth.query)
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

# Update a Review
#
# PATCH /review/{reviewId}
# operationId: EditReview
export def "review update-edit" [
  review_id: string
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
  --locale: string # Review's locale. (nullable)
  product_id: string # Product ID.
  rating: float # Customer rating.
  reviewer_name: string # Reviewer name.
  --shopper-id: string # Shopper email.
  text: string # Review's text.
  title: string # Review's title.
  --verified-purchaser: oneof<nothing, bool> # If the reviewer is a verified purchaser (`true`) or not (`false`).
]: any -> record<approved: bool, id: string, locale: string, location: string, pastReviews: string, productId: string, rating: float, reviewDateTime: string, reviewerName: string, searchDate: string, shopperId: string, sku: string, text: string, title: string, verifiedPurchaser: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/review/{review_id}") $auth.query)
  let req_body = {"locale": $locale, "productId": $product_id, "rating": $rating, "reviewerName": $reviewer_name, "shopperId": $shopper_id, "text": $text, "title": $title, "verifiedPurchaser": $verified_purchaser} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete Multiple Reviews
#
# DELETE /reviews
# operationId: DeleteMultipleReviews
export def "reviews delete-multiple" [
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
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reviews" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get a list of Reviews
#
# GET /reviews
# operationId: GetalistofReviews
export def "reviews get-alistof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # Returns Reviews that contain the search term in `productId`, `sku`, `shopperId`, or `reviewerName`. (e.g. search_term)
  --qp-from: string # Zero base starting record number, `0` is the default value. (e.g. 0)
  --qp-to: string # Zero base ending record number, `3` is the default value. (e.g. 3)
  --order-by: string # Case-sensitive fieldName to order records (optionally add `:asc` or `:desc`). (e.g. :asc)
  --status: oneof<nothing, bool> # Status of the review, approved (`true`) or not (`false`). (e.g. true)
  --product-id: string # Filter the reviews by product ID. (e.g. 1)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<data: table<approved: bool, id: string, locale: string, location: string, pastReviews: string, productId: string, rating: float, reviewDateTime: string, reviewerName: string, searchDate: string, shopperId: string, sku: string, text: string, title: string, verifiedPurchaser: bool>, range: record<from: float, to: float, total: float>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_term" $search_term "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "product_id" $product_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reviews" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search_term": $search_term, "from": $qp_from, "to": $qp_to, "order_by": $order_by, "status": $status, "product_id": $product_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Multiple Reviews
#
# POST /reviews
# operationId: SaveMultipleReviews
export def "reviews create-save-multiple" [
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
]: any -> list<string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o REVIEWS_AND_RATINGS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o REVIEWS_AND_RATINGS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reviews" $auth.query)
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
