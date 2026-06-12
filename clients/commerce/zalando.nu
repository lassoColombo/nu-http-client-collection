# Auto-generated client for Zalando Shop vv1.0
# Source: https://api.apis.guru/v2/specs/zalando.com/v1.0/swagger.json
# Auth: --token flag or $env.ZALANDO_SHOP_TOKEN

const BASE_URL = "https://api.zalando.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ZALANDO_SHOP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.zalando.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["best" "most_helpful" "newest" "worst"] }
def Accept-Language-completer [] { ["da-DK" "de-AT" "de-CH" "de-DE" "en-GB" "es-ES" "fi-FI" "fr-BE" "fr-CH" "fr-FR" "it-IT" "nl-BE" "nl-NL" "no-NO" "pl-PL" "sv-SE"] }
def sort-completer-1 [] { ["activationdate" "popularity" "priceasc" "pricedesc" "sale"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --articleId: list # Article IDs. A list of config SKUs for which the article reviews will be returned. Required if articleModelId is empty.
  --articleModelId: list # Article model IDs. A list of model SKUs for which the article reviews will be returned. Required if articleId is empty.
  --minStarRating: string # To get reviews with minimum star rating.
  --maxStarRating: string # To get reviews with maximum star rating.
  --qp-sort: string@sort-completer # articles are sorted on reviews provided by customers (eg: best) (default: newest)
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleId" $articleId "multi") (serialize-qp "articleModelId" $articleModelId "multi") (serialize-qp "minStarRating" $minStarRating "scalar") (serialize-qp "maxStarRating" $maxStarRating "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/article-reviews" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --articleModelId: list # Article model IDs. A list of model SKUs for which the article review summaries will be returned.
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleModelId" $articleModelId "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/article-reviews-summaries" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article Reviews Summaries by articleModelId
#
# GET /article-reviews-summaries/{articleModelId}
export def "article-reviews-summaries get" [
  articleModelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: float, CHEST: float, CHEST_GIRTH: float, COLLAR_SIZE: float, CUP_SIZE: float, HIPS_OR_REAR: float, LEG_FIT: float, LENGTH: float, OVERALL: float, SHOE_WIDTH: float, SHOULDERS: float, SLEEVES: float>, averageStarRating: float, numberOfUserPositiveRecommendations: int, numberOfUserRecommendations: int, numberOfUserReviews: int, starRatingDistribution: record<1: int, 2: int, 3: int, 4: int, 5: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/article-reviews-summaries/($articleModelId)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article Reviews by reviewId
#
# GET /article-reviews/{reviewId}
export def "article-reviews get" [
  reviewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleId: string, articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: int, CHEST: int, CHEST_GIRTH: int, COLLAR_SIZE: int, CUP_SIZE: int, HIPS_OR_REAR: int, LEG_FIT: int, LENGTH: int, OVERALL: int, SHOE_WIDTH: int, SHOULDERS: int, SLEEVES: int>, created: string, customerCity: string, customerCountry: string, customerNickname: string, description: string, helpfulCount: int, language: string, rating: int, recommend: bool, reviewId: string, title: string, unhelpfulCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/article-reviews/($reviewId)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --articleId: list # The `articleIds` to use use for filtering.  One or more `articleIds` might be used as a filter criteria. Submit multiple `articleId` request parameters for more than one to be used. They will be treated as `OR` criteria.
  --articleModelId: list # filters by article ModelId
  --articleUnitId: list # filters by article's unit id
  --activationDate: list # period or time the articles are activated for selling in the shop
  --ageGroup: list # filters by age group (eg: kids)
  --assortmentArea: list # filters by classification of articles (eg: maternity) 
  --brand: list # filters by brand key given by user (eg: SA5)
  --brandfamily: list # filters by brand family key (eg: nike) 
  --category: list # filters by category (eg: Socks, Rain Coats)
  --color: list # filters by color (eg: red, blue)
  --den: list # filters by den 
  --filling: list # filters by different kinds of garment filling materials (eg: satin, wolle)
  --fullText: string # filters by text (eg: search by 'as' gives result with articles of brand Sass)
  --gender: list # filters by gender
  --heelForm: list # filters by heel form (eg: flat)
  --heelHeight: list # filters by height of the heel size or length (eg: xs)
  --length: string # filters by garments length (eg: 3/4 length, knee-length)
  --occasion: list # filters by type of occasion (eg: party, business)
  --pattern: list # filters by pattern on the garments (eg: animal print, plain)
  --price: string # filters all articles in price range (eg: 9-90)
  --sale: list # filters discounted articles marked as sale
  --season: list # filters by season (Autumn/Winter or Spring/Summer)
  --shaftHeight: list # filters by shaft height (eg: s, xs)
  --shaftWidth: list # filters by shaft width (eg: s, l)
  --shirtCollar: list # filters by shirt collar styles (eg: low V neck, lined collar)
  --shoeFastener: list # filters by shoe fastener types (eg: buckle, lacing)
  --shoeToecap: list # filters by shoe toe cap variants (eg: pointed, square)
  --shopArea: list # filters by classification of articles
  --size: string # filters by size
  --sports: list # filters by different sport activities (eg: football)
  --technology: list # filters by technology used to produce the articles
  --trouserRise: list # filters by trouser rise
  --upperMaterial: list # filters by different type of upper material used on garments (eg: lace)
  --volume: list # filters by volume
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-sort: string@sort-completer-1 # sorting order (eg: popularity)
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleId" $articleId "multi") (serialize-qp "articleModelId" $articleModelId "multi") (serialize-qp "articleUnitId" $articleUnitId "multi") (serialize-qp "activationDate" $activationDate "multi") (serialize-qp "ageGroup" $ageGroup "multi") (serialize-qp "assortmentArea" $assortmentArea "multi") (serialize-qp "brand" $brand "multi") (serialize-qp "brandfamily" $brandfamily "multi") (serialize-qp "category" $category "multi") (serialize-qp "color" $color "multi") (serialize-qp "den" $den "multi") (serialize-qp "filling" $filling "multi") (serialize-qp "fullText" $fullText "scalar") (serialize-qp "gender" $gender "multi") (serialize-qp "heelForm" $heelForm "multi") (serialize-qp "heelHeight" $heelHeight "multi") (serialize-qp "length" $length "scalar") (serialize-qp "occasion" $occasion "multi") (serialize-qp "pattern" $pattern "multi") (serialize-qp "price" $price "scalar") (serialize-qp "sale" $sale "csv") (serialize-qp "season" $season "multi") (serialize-qp "shaftHeight" $shaftHeight "multi") (serialize-qp "shaftWidth" $shaftWidth "multi") (serialize-qp "shirtCollar" $shirtCollar "multi") (serialize-qp "shoeFastener" $shoeFastener "multi") (serialize-qp "shoeToecap" $shoeToecap "multi") (serialize-qp "shopArea" $shopArea "multi") (serialize-qp "size" $size "scalar") (serialize-qp "sports" $sports "multi") (serialize-qp "technology" $technology "multi") (serialize-qp "trouserRise" $trouserRise "multi") (serialize-qp "upperMaterial" $upperMaterial "multi") (serialize-qp "volume" $volume "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/articles" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article by articleId
#
# GET /articles/{articleId}
export def "articles get" [
  articleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<activationDate: string, additionalInfos: list<string>, ageGroups: list<string>, attributes: table<name: string, values: list>, available: bool, brand: record<brandFamily: record<key: string, name: string, shopUrl: string>, key: string, logoLargeUrl: string, logoUrl: string, name: string, shopUrl: string>, categoryKeys: list<string>, color: string, genders: list<string>, id: string, media: record<images: list<record>>, modelId: string, name: string, season: string, seasonYear: string, shopUrl: string, tags: list<string>, units: table<available: bool, id: string, originalPrice: record, partnerId: string, price: record, size: string, stock: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article media by articleId
#
# GET /articles/{articleId}/media
export def "articles-media get" [
  articleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<images: table<largeHdUrl: string, largeUrl: string, mediumHdUrl: string, mediumUrl: string, orderNumber: int, smallHdUrl: string, smallUrl: string, thumbnailHdUrl: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)/media" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article reviews by articleId
#
# GET /articles/{articleId}/reviews
export def "articles-reviews get" [
  articleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --minStarRating: string # To get reviews with minimum star rating.
  --maxStarRating: string # To get reviews with maximum star rating.
  --qp-sort: string@sort-completer # articles are sorted on reviews provided by customers (eg: best) (default: newest)
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minStarRating" $minStarRating "scalar") (serialize-qp "maxStarRating" $maxStarRating "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)/reviews" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article reviews summary by articleId
#
# GET /articles/{articleId}/reviews-summary
export def "articles-reviews-summary get" [
  articleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<articleModelId: string, articleSizeRatings: record<BOOTLEG_WIDTH: float, CHEST: float, CHEST_GIRTH: float, COLLAR_SIZE: float, CUP_SIZE: float, HIPS_OR_REAR: float, LEG_FIT: float, LENGTH: float, OVERALL: float, SHOE_WIDTH: float, SHOULDERS: float, SLEEVES: float>, averageStarRating: float, numberOfUserPositiveRecommendations: int, numberOfUserRecommendations: int, numberOfUserReviews: int, starRatingDistribution: record<1: int, 2: int, 3: int, 4: int, 5: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)/reviews-summary" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article units by articleId
#
# GET /articles/{articleId}/units
export def "articles-units list" [
  articleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<available: bool, id: string, originalPrice: record<currency: string, formatted: string, value: float>, partnerId: string, price: record<currency: string, formatted: string, value: float>, size: string, stock: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)/units" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Article units by articleId snd unitId
#
# GET /articles/{articleId}/units/{unitId}
export def "articles-units get" [
  articleId: string
  unitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<available: bool, id: string, originalPrice: record<currency: string, formatted: string, value: float>, partnerId: string, price: record<currency: string, formatted: string, value: float>, size: string, stock: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/articles/($articleId)/units/($unitId)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: list # Request Brand by key
  --name: list # Request Brand by name
  --brandFamilyName: list # Request Brand by brandFamilyName
  --brandFamilyKey: list # Request Brand by brandFamilyKey
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "multi") (serialize-qp "name" $name "multi") (serialize-qp "brandFamilyName" $brandFamilyName "multi") (serialize-qp "brandFamilyKey" $brandFamilyKey "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/brands" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<brandFamily: record<key: string, name: string, shopUrl: string>, key: string, logoLargeUrl: string, logoUrl: string, name: string, shopUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/brands/($key)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list # Request Categories by names
  --type: string # Request Categories by type
  --outlet: string # Request Categories by outlet
  --hidden: string # Request Categories by hidden
  --targetGroup: string # Request Categories by target group
  --key: list # Request Categories by keys
  --parentKey: list # Request Categories by parent keys
  --childKey: list # Request Categories by child keys
  --suggestedFilter: list # Request Categories by suggested filters
  --page: string # to request with required page number or pagination
  --pageSize: string # to request with required page size in a page
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "type" $type "scalar") (serialize-qp "outlet" $outlet "scalar") (serialize-qp "hidden" $hidden "scalar") (serialize-qp "targetGroup" $targetGroup "scalar") (serialize-qp "key" $key "multi") (serialize-qp "parentKey" $parentKey "multi") (serialize-qp "childKey" $childKey "multi") (serialize-qp "suggestedFilter" $suggestedFilter "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<childKeys: list<string>, cid: int, hidden: bool, key: string, name: string, outlet: bool, parentKey: string, suggestedFilters: list<string>, targetGroup: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($key)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<countryCode: string, currencyCode: string, languageCode: string, rootCategoryKey: string, shopUrl: string, taxRate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --ageGroup: list # filters by age group (eg: kids)
  --articleId: list # The `articleIds` to use use for filtering.  One or more `articleIds` might be used as a filter criteria. Submit multiple `articleId` request parameters for more than one to be used. They will be treated as `OR` criteria.
  --activationDate: list # period or time the articles are activated for selling in the shop
  --articleModelId: list # filters by article ModelId
  --assortmentArea: list # filters by classification of articles (eg: maternity) 
  --brand: list # filters by brand key given by user (eg: SA5)
  --brandfamily: list # filters by brand family key (eg: nike) 
  --category: list # filters by category (eg: Socks, Rain Coats)
  --color: list # filters by color (eg: red, blue)
  --den: list # filters by den 
  --filling: list # filters by different kinds of garment filling materials (eg: satin, wolle)
  --gender: list # filters by gender
  --heelForm: list # filters by heel form (eg: flat)
  --heelHeight: list # filters by height of the heel size or length (eg: xs)
  --length: string # filters by garments length (eg: 3/4 length, knee-length)
  --occasion: list # filters by type of occasion (eg: party, business)
  --pattern: list # filters by pattern on the garments (eg: animal print, plain)
  --price: string # filters all articles in price range (eg: 9-90)
  --sale: list # filters discounted articles marked as sale
  --season: list # filters by season (Autumn/Winter or Spring/Summer)
  --shaftHeight: list # filters by shaft height (eg: s, xs)
  --shaftWidth: list # filters by shaft width (eg: s, l)
  --shirtCollar: list # filters by shirt collar styles (eg: low V neck, lined collar)
  --shoeFastener: list # filters by shoe fastener types (eg: buckle, lacing)
  --shoeToecap: list # filters by shoe toe cap variants (eg: pointed, square)
  --shopArea: list # filters by classification of articles
  --size: string # filters by size
  --sports: list # filters by different sport activities (eg: football)
  --technology: list # filters by technology used to produce the articles
  --trouserRise: list # filters by trouser rise
  --upperMaterial: list # filters by different type of upper material used on garments (eg: lace)
  --volume: list # filters by volume
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<facets: list<record>, filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ageGroup" $ageGroup "multi") (serialize-qp "articleId" $articleId "multi") (serialize-qp "activationDate" $activationDate "multi") (serialize-qp "articleModelId" $articleModelId "multi") (serialize-qp "assortmentArea" $assortmentArea "multi") (serialize-qp "brand" $brand "multi") (serialize-qp "brandfamily" $brandfamily "multi") (serialize-qp "category" $category "multi") (serialize-qp "color" $color "multi") (serialize-qp "den" $den "multi") (serialize-qp "filling" $filling "multi") (serialize-qp "gender" $gender "multi") (serialize-qp "heelForm" $heelForm "multi") (serialize-qp "heelHeight" $heelHeight "multi") (serialize-qp "length" $length "scalar") (serialize-qp "occasion" $occasion "multi") (serialize-qp "pattern" $pattern "multi") (serialize-qp "price" $price "scalar") (serialize-qp "sale" $sale "csv") (serialize-qp "season" $season "multi") (serialize-qp "shaftHeight" $shaftHeight "multi") (serialize-qp "shaftWidth" $shaftWidth "multi") (serialize-qp "shirtCollar" $shirtCollar "multi") (serialize-qp "shoeFastener" $shoeFastener "multi") (serialize-qp "shoeToecap" $shoeToecap "multi") (serialize-qp "shopArea" $shopArea "multi") (serialize-qp "size" $size "scalar") (serialize-qp "sports" $sports "multi") (serialize-qp "technology" $technology "multi") (serialize-qp "trouserRise" $trouserRise "multi") (serialize-qp "upperMaterial" $upperMaterial "multi") (serialize-qp "volume" $volume "multi") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/facets" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<multiValue: bool, name: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/filters" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Single Filter by filterName
#
# GET /filters/{filterName}
export def "filters get" [
  filterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> record<multiValue: bool, name: string, type: string, values: table<displayName: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/filters/($filterName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Recommendations by articleId
#
# GET /recommendations/{articleIds}
export def "recommendations get" [
  articleIds: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # To get maximum results of Recommendations by articleId.
  --qp-fields: list # Comma separated list of fields that should be returned. Fields of subobjects are specified with dots as separator. Fields of objects within lists are specified in the same way.  Example: id,name,brand.key,brand.name, units.id,units.size,units.price.formatted
  --Accept-Language: string@Accept-Language-completer # Specify which Shop to use.  A standard `Accept-Language` header which specifies the shop that should be used. E.g. `de-DE` will use the German shop (as does [https://www.zalando.de](https://www/zalando.de) and `de-AT` will use the Austrian one.  The shop choosen will e.g. define the currency used for prices as well as the language for product names and descriptions. Furthermore it will impact which articles are available as they might differ between countries.
]: nothing -> table<id: string, media: record<images: list>, modelId: string, name: string, shopUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/recommendations/($articleIds)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
