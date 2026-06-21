# Auto-generated client for Zalando Shop vv1.0
# Source: https://api.apis.guru/v2/specs/zalando.com/v1.0/swagger.json
# Auth: --token flag or $env.ZALANDO_SHOP_TOKEN

const BASE_URL = "https://api.zalando.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ZALANDO_SHOP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://api.zalando.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["best" "most_helpful" "newest" "worst"] }
def accept-language-completer [] { ["da-DK" "de-AT" "de-CH" "de-DE" "en-GB" "es-ES" "fi-FI" "fr-BE" "fr-CH" "fr-FR" "it-IT" "nl-BE" "nl-NL" "no-NO" "pl-PL" "sv-SE"] }
def sort-completer-1 [] { ["activationdate" "popularity" "priceasc" "pricedesc" "sale"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "article-reviews list" } } | get name | first)
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

# Get Article Reviews
#
# GET /article-reviews
export def "article-reviews list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: list<string> # Article IDs. A list of config SKUs for which the article reviews will be returned. Required if articleModelId is empty.
  --article-model-id: list<string> # Article model IDs. A list of model SKUs for which the article reviews will be returned. Required if articleId is empty.
  --min-star-rating: string # To get reviews with minimum star rating.
  --max-star-rating: string # To get reviews with maximum star rating.
  --qp-sort: string@sort-completer # articles are sorted on reviews provided by customers (eg: best) (default: newest)
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleId" $article_id "multi") (serialize-qp "articleModelId" $article_model_id "multi") (serialize-qp "minStarRating" $min_star_rating "scalar") (serialize-qp "maxStarRating" $max_star_rating "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/article-reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"articleId": $article_id, "articleModelId": $article_model_id, "minStarRating": $min_star_rating, "maxStarRating": $max_star_rating, "sort": $qp_sort, "page": $page, "pageSize": $page_size, "fields": $fields} | compact), body: null}
}

# Get Article Reviews Summaries
#
# GET /article-reviews-summaries
export def "article-reviews-summaries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-model-id: list<string> # Article model IDs. A list of model SKUs for which the article review summaries will be returned.
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleModelId" $article_model_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/article-reviews-summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"articleModelId": $article_model_id, "page": $page, "pageSize": $page_size, "fields": $fields} | compact), body: null}
}

# Get Article Reviews Summaries by articleModelId
#
# GET /article-reviews-summaries/{articleModelId}
export def "article-reviews-summaries get" [
  article_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: float, CHEST: float, CHEST_GIRTH: float, COLLAR_SIZE: float, CUP_SIZE: float, HIPS_OR_REAR: float, LEG_FIT: float, LENGTH: float, OVERALL: float, SHOE_WIDTH: float, SHOULDERS: float, SLEEVES: float>, averageStarRating: float, numberOfUserPositiveRecommendations: int, numberOfUserRecommendations: int, numberOfUserReviews: int, starRatingDistribution: record<1: int, 2: int, 3: int, 4: int, 5: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_model_id | is-empty) { error make --unspanned { msg: "path parameter 'articleModelId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_model_id: (encode-path-segment $article_model_id)} | format pattern "/article-reviews-summaries/{article_model_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Article Reviews by reviewId
#
# GET /article-reviews/{reviewId}
export def "article-reviews get" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleId: string, articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: int, CHEST: int, CHEST_GIRTH: int, COLLAR_SIZE: int, CUP_SIZE: int, HIPS_OR_REAR: int, LEG_FIT: int, LENGTH: int, OVERALL: int, SHOE_WIDTH: int, SHOULDERS: int, SLEEVES: int>, created: string, customerCity: string, customerCountry: string, customerNickname: string, description: string, helpfulCount: int, language: string, rating: int, recommend: bool, reviewId: string, title: string, unhelpfulCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/article-reviews/{review_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Search for Articles
#
# GET /articles
export def "articles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: list<string> # The `articleIds` to use use for filtering. One or more `articleIds` might be used as a filter criteria. Submit multiple `articleId` request parameters for more than one to be used. They will be treated as `OR` criteria.
  --article-model-id: list<string> # filters by article ModelId
  --article-unit-id: list<string> # filters by article's unit id
  --activation-date: list<string> # period or time the articles are activated for selling in the shop
  --age-group: list<string> # filters by age group (eg: kids)
  --assortment-area: list<string> # filters by classification of articles (eg: maternity)
  --brand: list<string> # filters by brand key given by user (eg: SA5)
  --brandfamily: list<string> # filters by brand family key (eg: nike)
  --category: list<string> # filters by category (eg: Socks, Rain Coats)
  --color: list<string> # filters by color (eg: red, blue)
  --den: list<string> # filters by den
  --filling: list<string> # filters by different kinds of garment filling materials (eg: satin, wolle)
  --full-text: string # filters by text (eg: search by 'as' gives result with articles of brand Sass)
  --gender: list<string> # filters by gender
  --heel-form: list<string> # filters by heel form (eg: flat)
  --heel-height: list<string> # filters by height of the heel size or length (eg: xs)
  --length: string # filters by garments length (eg: 3/4 length, knee-length)
  --occasion: list<string> # filters by type of occasion (eg: party, business)
  --pattern: list<string> # filters by pattern on the garments (eg: animal print, plain)
  --price: string # filters all articles in price range (eg: 9-90)
  --sale: list<string> # filters discounted articles marked as sale
  --season: list<string> # filters by season (Autumn/Winter or Spring/Summer)
  --shaft-height: list<string> # filters by shaft height (eg: s, xs)
  --shaft-width: list<string> # filters by shaft width (eg: s, l)
  --shirt-collar: list<string> # filters by shirt collar styles (eg: low V neck, lined collar)
  --shoe-fastener: list<string> # filters by shoe fastener types (eg: buckle, lacing)
  --shoe-toecap: list<string> # filters by shoe toe cap variants (eg: pointed, square)
  --shop-area: list<string> # filters by classification of articles
  --size: string # filters by size
  --sports: list<string> # filters by different sport activities (eg: football)
  --technology: list<string> # filters by technology used to produce the articles
  --trouser-rise: list<string> # filters by trouser rise
  --upper-material: list<string> # filters by different type of upper material used on garments (eg: lace)
  --volume: list<string> # filters by volume
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --qp-sort: string@sort-completer-1 # sorting order (eg: popularity)
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleId" $article_id "multi") (serialize-qp "articleModelId" $article_model_id "multi") (serialize-qp "articleUnitId" $article_unit_id "multi") (serialize-qp "activationDate" $activation_date "multi") (serialize-qp "ageGroup" $age_group "multi") (serialize-qp "assortmentArea" $assortment_area "multi") (serialize-qp "brand" $brand "multi") (serialize-qp "brandfamily" $brandfamily "multi") (serialize-qp "category" $category "multi") (serialize-qp "color" $color "multi") (serialize-qp "den" $den "multi") (serialize-qp "filling" $filling "multi") (serialize-qp "fullText" $full_text "scalar") (serialize-qp "gender" $gender "multi") (serialize-qp "heelForm" $heel_form "multi") (serialize-qp "heelHeight" $heel_height "multi") (serialize-qp "length" $length "scalar") (serialize-qp "occasion" $occasion "multi") (serialize-qp "pattern" $pattern "multi") (serialize-qp "price" $price "scalar") (serialize-qp "sale" $sale "csv") (serialize-qp "season" $season "multi") (serialize-qp "shaftHeight" $shaft_height "multi") (serialize-qp "shaftWidth" $shaft_width "multi") (serialize-qp "shirtCollar" $shirt_collar "multi") (serialize-qp "shoeFastener" $shoe_fastener "multi") (serialize-qp "shoeToecap" $shoe_toecap "multi") (serialize-qp "shopArea" $shop_area "multi") (serialize-qp "size" $size "scalar") (serialize-qp "sports" $sports "multi") (serialize-qp "technology" $technology "multi") (serialize-qp "trouserRise" $trouser_rise "multi") (serialize-qp "upperMaterial" $upper_material "multi") (serialize-qp "volume" $volume "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"articleId": $article_id, "articleModelId": $article_model_id, "articleUnitId": $article_unit_id, "activationDate": $activation_date, "ageGroup": $age_group, "assortmentArea": $assortment_area, "brand": $brand, "brandfamily": $brandfamily, "category": $category, "color": $color, "den": $den, "filling": $filling, "fullText": $full_text, "gender": $gender, "heelForm": $heel_form, "heelHeight": $heel_height, "length": $length, "occasion": $occasion, "pattern": $pattern, "price": $price, "sale": $sale, "season": $season, "shaftHeight": $shaft_height, "shaftWidth": $shaft_width, "shirtCollar": $shirt_collar, "shoeFastener": $shoe_fastener, "shoeToecap": $shoe_toecap, "shopArea": $shop_area, "size": $size, "sports": $sports, "technology": $technology, "trouserRise": $trouser_rise, "upperMaterial": $upper_material, "volume": $volume, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "fields": $fields} | compact), body: null}
}

# Get Article by articleId
#
# GET /articles/{articleId}
export def "articles get" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<activationDate: string, additionalInfos: list<string>, ageGroups: list<string>, attributes: table<name: string, values: list>, available: bool, brand: record<brandFamily: record<key: string, name: string, shopUrl: string>, key: string, logoLargeUrl: string, logoUrl: string, name: string, shopUrl: string>, categoryKeys: list<string>, color: string, genders: list<string>, id: string, media: record<images: list<record>>, modelId: string, name: string, season: string, seasonYear: string, shopUrl: string, tags: list<string>, units: table<available: bool, id: string, originalPrice: record, partnerId: string, price: record, size: string, stock: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/articles/{article_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Article media by articleId
#
# GET /articles/{articleId}/media
export def "articles-media get" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<images: table<largeHdUrl: string, largeUrl: string, mediumHdUrl: string, mediumUrl: string, orderNumber: int, smallHdUrl: string, smallUrl: string, thumbnailHdUrl: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/articles/{article_id}/media") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Article reviews by articleId
#
# GET /articles/{articleId}/reviews
export def "articles-reviews get" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-star-rating: string # To get reviews with minimum star rating.
  --max-star-rating: string # To get reviews with maximum star rating.
  --qp-sort: string@sort-completer # articles are sorted on reviews provided by customers (eg: best) (default: newest)
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  let qp = [(serialize-qp "minStarRating" $min_star_rating "scalar") (serialize-qp "maxStarRating" $max_star_rating "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/articles/{article_id}/reviews") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minStarRating": $min_star_rating, "maxStarRating": $max_star_rating, "sort": $qp_sort, "page": $page, "pageSize": $page_size, "fields": $fields} | compact), body: null}
}

# Get Article reviews summary by articleId
#
# GET /articles/{articleId}/reviews-summary
export def "articles-reviews-summary get" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: float, CHEST: float, CHEST_GIRTH: float, COLLAR_SIZE: float, CUP_SIZE: float, HIPS_OR_REAR: float, LEG_FIT: float, LENGTH: float, OVERALL: float, SHOE_WIDTH: float, SHOULDERS: float, SLEEVES: float>, averageStarRating: float, numberOfUserPositiveRecommendations: int, numberOfUserRecommendations: int, numberOfUserReviews: int, starRatingDistribution: record<1: int, 2: int, 3: int, 4: int, 5: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/articles/{article_id}/reviews-summary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Article units by articleId
#
# GET /articles/{articleId}/units
export def "articles-units list" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<available: bool, id: string, originalPrice: record<currency: string, formatted: string, value: float>, partnerId: string, price: record<currency: string, formatted: string, value: float>, size: string, stock: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/articles/{article_id}/units") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Article units by articleId snd unitId
#
# GET /articles/{articleId}/units/{unitId}
export def "articles-units get" [
  article_id: string
  unit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<available: bool, id: string, originalPrice: record<currency: string, formatted: string, value: float>, partnerId: string, price: record<currency: string, formatted: string, value: float>, size: string, stock: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  if ($unit_id | is-empty) { error make --unspanned { msg: "path parameter 'unitId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id), unit_id: (encode-path-segment $unit_id)} | format pattern "/articles/{article_id}/units/{unit_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Shop Brands
#
# GET /brands
export def "brands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: list<string> # Request Brand by key
  --name: list<string> # Request Brand by name
  --brand-family-name: list<string> # Request Brand by brandFamilyName
  --brand-family-key: list<string> # Request Brand by brandFamilyKey
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "multi") (serialize-qp "name" $name "multi") (serialize-qp "brandFamilyName" $brand_family_name "multi") (serialize-qp "brandFamilyKey" $brand_family_key "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/brands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key, "name": $name, "brandFamilyName": $brand_family_name, "brandFamilyKey": $brand_family_key, "page": $page, "pageSize": $page_size, "fields": $fields} | compact), body: null}
}

# Get Single Brand by Key
#
# GET /brands/{key}
export def "brands get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<brandFamily: record<key: string, name: string, shopUrl: string>, key: string, logoLargeUrl: string, logoUrl: string, name: string, shopUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/brands/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Shop Categories
#
# GET /categories
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list<string> # Request Categories by names
  --type: string # Request Categories by type
  --outlet: string # Request Categories by outlet
  --hidden: string # Request Categories by hidden
  --target-group: string # Request Categories by target group
  --key: list<string> # Request Categories by keys
  --parent-key: list<string> # Request Categories by parent keys
  --child-key: list<string> # Request Categories by child keys
  --suggested-filter: list<string> # Request Categories by suggested filters
  --page: string # to request with required page number or pagination
  --page-size: string # to request with required page size in a page
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "type" $type "scalar") (serialize-qp "outlet" $outlet "scalar") (serialize-qp "hidden" $hidden "scalar") (serialize-qp "targetGroup" $target_group "scalar") (serialize-qp "key" $key "multi") (serialize-qp "parentKey" $parent_key "multi") (serialize-qp "childKey" $child_key "multi") (serialize-qp "suggestedFilter" $suggested_filter "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "type": $type, "outlet": $outlet, "hidden": $hidden, "targetGroup": $target_group, "key": $key, "parentKey": $parent_key, "childKey": $child_key, "suggestedFilter": $suggested_filter, "page": $page, "pageSize": $page_size, "fields": $fields} | compact), body: null}
}

# Get Single Category by Key
#
# GET /categories/{key}
export def "categories get" [
  key: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<childKeys: list<string>, cid: int, hidden: bool, key: string, name: string, outlet: bool, parentKey: string, suggestedFilters: list<string>, targetGroup: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-array $key)} | format pattern "/categories/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Shop Domains
#
# GET /domains
export def "domains get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<countryCode: string, currencyCode: string, languageCode: string, rootCategoryKey: string, shopUrl: string, taxRate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Shop Facets
#
# GET /facets
export def "facets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-group: list<string> # filters by age group (eg: kids)
  --article-id: list<string> # The `articleIds` to use use for filtering. One or more `articleIds` might be used as a filter criteria. Submit multiple `articleId` request parameters for more than one to be used. They will be treated as `OR` criteria.
  --activation-date: list<string> # period or time the articles are activated for selling in the shop
  --article-model-id: list<string> # filters by article ModelId
  --assortment-area: list<string> # filters by classification of articles (eg: maternity)
  --brand: list<string> # filters by brand key given by user (eg: SA5)
  --brandfamily: list<string> # filters by brand family key (eg: nike)
  --category: list<string> # filters by category (eg: Socks, Rain Coats)
  --color: list<string> # filters by color (eg: red, blue)
  --den: list<string> # filters by den
  --filling: list<string> # filters by different kinds of garment filling materials (eg: satin, wolle)
  --gender: list<string> # filters by gender
  --heel-form: list<string> # filters by heel form (eg: flat)
  --heel-height: list<string> # filters by height of the heel size or length (eg: xs)
  --length: string # filters by garments length (eg: 3/4 length, knee-length)
  --occasion: list<string> # filters by type of occasion (eg: party, business)
  --pattern: list<string> # filters by pattern on the garments (eg: animal print, plain)
  --price: string # filters all articles in price range (eg: 9-90)
  --sale: list<string> # filters discounted articles marked as sale
  --season: list<string> # filters by season (Autumn/Winter or Spring/Summer)
  --shaft-height: list<string> # filters by shaft height (eg: s, xs)
  --shaft-width: list<string> # filters by shaft width (eg: s, l)
  --shirt-collar: list<string> # filters by shirt collar styles (eg: low V neck, lined collar)
  --shoe-fastener: list<string> # filters by shoe fastener types (eg: buckle, lacing)
  --shoe-toecap: list<string> # filters by shoe toe cap variants (eg: pointed, square)
  --shop-area: list<string> # filters by classification of articles
  --size: string # filters by size
  --sports: list<string> # filters by different sport activities (eg: football)
  --technology: list<string> # filters by technology used to produce the articles
  --trouser-rise: list<string> # filters by trouser rise
  --upper-material: list<string> # filters by different type of upper material used on garments (eg: lace)
  --volume: list<string> # filters by volume
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<facets: list<record>, filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ageGroup" $age_group "multi") (serialize-qp "articleId" $article_id "multi") (serialize-qp "activationDate" $activation_date "multi") (serialize-qp "articleModelId" $article_model_id "multi") (serialize-qp "assortmentArea" $assortment_area "multi") (serialize-qp "brand" $brand "multi") (serialize-qp "brandfamily" $brandfamily "multi") (serialize-qp "category" $category "multi") (serialize-qp "color" $color "multi") (serialize-qp "den" $den "multi") (serialize-qp "filling" $filling "multi") (serialize-qp "gender" $gender "multi") (serialize-qp "heelForm" $heel_form "multi") (serialize-qp "heelHeight" $heel_height "multi") (serialize-qp "length" $length "scalar") (serialize-qp "occasion" $occasion "multi") (serialize-qp "pattern" $pattern "multi") (serialize-qp "price" $price "scalar") (serialize-qp "sale" $sale "csv") (serialize-qp "season" $season "multi") (serialize-qp "shaftHeight" $shaft_height "multi") (serialize-qp "shaftWidth" $shaft_width "multi") (serialize-qp "shirtCollar" $shirt_collar "multi") (serialize-qp "shoeFastener" $shoe_fastener "multi") (serialize-qp "shoeToecap" $shoe_toecap "multi") (serialize-qp "shopArea" $shop_area "multi") (serialize-qp "size" $size "scalar") (serialize-qp "sports" $sports "multi") (serialize-qp "technology" $technology "multi") (serialize-qp "trouserRise" $trouser_rise "multi") (serialize-qp "upperMaterial" $upper_material "multi") (serialize-qp "volume" $volume "multi") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/facets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ageGroup": $age_group, "articleId": $article_id, "activationDate": $activation_date, "articleModelId": $article_model_id, "assortmentArea": $assortment_area, "brand": $brand, "brandfamily": $brandfamily, "category": $category, "color": $color, "den": $den, "filling": $filling, "gender": $gender, "heelForm": $heel_form, "heelHeight": $heel_height, "length": $length, "occasion": $occasion, "pattern": $pattern, "price": $price, "sale": $sale, "season": $season, "shaftHeight": $shaft_height, "shaftWidth": $shaft_width, "shirtCollar": $shirt_collar, "shoeFastener": $shoe_fastener, "shoeToecap": $shoe_toecap, "shopArea": $shop_area, "size": $size, "sports": $sports, "technology": $technology, "trouserRise": $trouser_rise, "upperMaterial": $upper_material, "volume": $volume, "fields": $fields} | compact), body: null}
}

# Shop Filters
#
# GET /filters
export def "filters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<multiValue: bool, name: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Single Filter by filterName
#
# GET /filters/{filterName}
export def "filters get" [
  filter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<multiValue: bool, name: string, type: string, values: table<displayName: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filter_name | is-empty) { error make --unspanned { msg: "path parameter 'filterName' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({filter_name: (encode-path-segment $filter_name)} | format pattern "/filters/{filter_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get Recommendations by articleId
#
# GET /recommendations/{articleIds}
export def "recommendations get" [
  article_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # To get maximum results of Recommendations by articleId.
  --fields: list<string> # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way. Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --accept-language: string@accept-language-completer # Specify which Shop to use. A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one. The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<id: string, media: record<images: list>, modelId: string, name: string, shopUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_ids | is-empty) { error make --unspanned { msg: "path parameter 'articleIds' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "fields" $fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({article_ids: (encode-path-array $article_ids)} | format pattern "/recommendations/{article_ids}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "fields": $fields} | compact), body: null}
}
