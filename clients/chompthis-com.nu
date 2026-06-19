# Auto-generated client for Chomp Food Database API Documentation v1.0.0-oas3
# Source: https://api.apis.guru/v2/specs/chompthis.com/1.0.0-oas3/openapi.json
# Auth: --token flag or $env.CHOMP_FOOD_DATABASE_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://chompthis.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHOMP_FOOD_DATABASE_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://chompthis.com/api/v2"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def limit-completer [] { ["1" "10" "2" "3" "4" "5" "6" "7" "8" "9"] }
def diet-completer [] { ["Gluten Free" "Vegan" "Vegetarian"] }
def limit-completer-1 [] { ["1" "2" "3"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "food-branded-barcode-php get" } } | get name | first)
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

# Get a branded food item using a barcode
#
# GET /food/branded/barcode.php
export def "food-branded-barcode-php get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # #### UPC/EAN barcode **Example** > ```&code=0842234000988```
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/branded/barcode.php" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"code": $code} | compact), body: null}
}

# Get a branded food item by name
#
# GET /food/branded/name.php
export def "food-branded-name-php get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # #### Search for branded food items using a general food name keyword. This does not have to exactly match the "official" name for the food. **Example** > ```&name=Starburst```
  --limit: int@limit-completer # #### Set maximum number of records you want the API to return. The default value is "**10**." **Example** > ```&limit=10```
  --page: int # #### This is how you paginate the search result. By default, you will see the first 10 records. You must increment the page number to access the next 10 records, and so on. The default value is "**1**." **Example** > ```&page=1```
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/branded/name.php" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "limit": $limit, "page": $page} | compact), body: null}
}

# Get data for branded food items using various search parameters
#
# GET /food/branded/search.php
export def "food-branded-search-php get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allergen: string # #### Filter the search to only include branded foods that contain a specific allergen. **Example** > ```&allergen=Peanuts``` **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --brand: string # #### Filter the search to only include branded foods that are owned by a specific brand. **Example** > ```&brand=Starbucks```
  --category: string # #### Filter the search to only include branded foods from a specific category. **Example** > ```&category=Plant Based Foods```
  --country: string # #### Filter the search to only include branded foods that are sold in a specific country. **Example** > ```&country=United States``` **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --diet: string@diet-completer # #### Filter the search to only include branded foods that are considered compatible with a specific diet. **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --ingredient: string # #### Filter the search to only include branded foods that contain a specific ingredient. **Example** > ```&ingredient=Salt```
  --keyword: string # #### Filter the search to only include branded foods that are associated with a specific keyword. **Example** > ```&keyword=Organic``` **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --mineral: string # #### Filter the search to only include branded foods that contain a specific mineral. **Example** > ```&mineral=Potassium```
  --nutrient: string # #### Filter the search to only include branded foods that contain a specific nutrient. **Example** > ```&nutrient=Caffeine``` **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --palm-oil: string # #### Filter the search to only include branded foods that contain a specific ingredient made using palm oil. **Example** > ```&palm_oil=E160a Beta Carotene```
  --trace: string # ### Filter the search to only include branded foods that contain a specific trace ingredient. **Example** > ```&trace=Tree Nuts``` **Important Note**: This parameter cannot be used alone. It must be paired with at least 1 additional parameter.
  --vitamin: string # #### Filter the search to only include branded foods that contain a specific vitamin. **Example** > ```&vitamin=Biotin```
  --limit: int@limit-completer # #### Set maximum number of records you want the API to return. The default value is "**10**." **Example** > ```&limit=10```
  --page: int # #### This is how you paginate the search result. By default, you will see the first 10 records. You must increment the page number to access the next 10 records, and so on. The default value is "**1**." **Example** > ```&page=1```
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allergen" $allergen "scalar") (serialize-qp "brand" $brand "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "diet" $diet "scalar") (serialize-qp "ingredient" $ingredient "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "mineral" $mineral "scalar") (serialize-qp "nutrient" $nutrient "scalar") (serialize-qp "palm_oil" $palm_oil "scalar") (serialize-qp "trace" $trace "scalar") (serialize-qp "vitamin" $vitamin "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/branded/search.php" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"allergen": $allergen, "brand": $brand, "category": $category, "country": $country, "diet": $diet, "ingredient": $ingredient, "keyword": $keyword, "mineral": $mineral, "nutrient": $nutrient, "palm_oil": $palm_oil, "trace": $trace, "vitamin": $vitamin, "limit": $limit, "page": $page} | compact), body: null}
}

# Get raw/generic food ingredient item(s)
#
# GET /food/ingredient/search.php
export def "food-ingredient-search-php get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find: string # Search our database for a single ingredient or a specific set of ingredients. **Example #1: Single Ingredient** > ```&find=raw broccoli``` **Example #2: Set of Ingredients** > ```&find=raw broccoli,buttermilk waffle,mashed potatoes``` **Important Notes** * Comma-separated lists cannot contain more than **10 ingredients**. You must perform additional API calls if you are looking up more than 10 ingredients.
  --limit: int@limit-completer-1 # #### Set maximum number of records you want the API to return, per search term. The default value is "**1**." **Example** > ```&limit=3```
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "find" $find "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/ingredient/search.php" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"find": $find, "limit": $limit} | compact), body: null}
}
