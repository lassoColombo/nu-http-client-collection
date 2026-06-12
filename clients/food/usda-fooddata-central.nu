# Auto-generated client for Food Data Central API v1.0.1
# Source: https://api.swaggerhub.com/apis/fdcnal/food-data_central_api/1.0.1/swagger.json
# Auth: --token flag or $env.FOOD_DATA_CENTRAL_API_TOKEN

const BASE_URL = "https://api.nal.usda.gov/fdc"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FOOD_DATA_CENTRAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://api.nal.usda.gov/fdc"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def format-completer [] { ["abridged" "full"] }
def sortBy-completer [] { ["dataType.keyword" "fdcId" "lowercaseDescription.keyword" "publishedDate"] }
def sortOrder-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "food get" } } | get name | first)
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

# Fetches details for one food item by FDC ID
#
# GET /v1/food/{fdcId}
# operationId: getFood
export def "food get" [
  fdcId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Optional. 'abridged' for an abridged set of elements, 'full' for all elements (default).
  --nutrients: list # Optional. List of up to 25 nutrient numbers. Only the nutrient information for the specified nutrients will be returned. Should be comma separated list (e.g. nutrients=203,204) or repeating parameters (e.g. nutrients=203&nutrients=204). If a food does not have any matching nutrients, the food will be returned with an empty foodNutrients element. (e.g. [203, 204, 205])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "nutrients" $nutrients "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/food/($fdcId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches details for multiple food items using input FDC IDs
#
# GET /v1/foods
# operationId: getFoods
export def "foods get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fdcIds: list # List of multiple FDC ID's. Should be comma separated list (e.g. fdcIds=534358,373052) or repeating parameters (e.g. fdcIds=534358&fdcIds=373052). (e.g. [534358, 373052, 616350])
  --format: string@format-completer # Optional. 'abridged' for an abridged set of elements, 'full' for all elements (default).
  --nutrients: list # Optional. List of up to 25 nutrient numbers. Only the nutrient information for the specified nutrients will be returned. Should be comma separated list (e.g. nutrients=203,204) or repeating parameters (e.g. nutrients=203&nutrients=204). If a food does not have any matching nutrients, the food will be returned with an empty foodNutrients element. (e.g. [203, 204, 205])
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fdcIds" $fdcIds "multi") (serialize-qp "format" $format "scalar") (serialize-qp "nutrients" $nutrients "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/foods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches details for multiple food items using input FDC IDs
#
# POST /v1/foods
# operationId: postFoods
export def "foods post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fdcIds: list # List of multiple FDC ID's (e.g. [534358, 373052, 616350])
  --format: string@format-completer # Optional. 'abridged' for an abridged set of elements, 'full' for all elements (default).
  --nutrients: list # Optional. List of up to 25 nutrient numbers. Only the nutrient information for the specified nutrients will be returned.  If a food does not have any matching nutrients, the food will be returned with an empty foodNutrients element. (e.g. [203, 204, 205])
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/foods")
  let body = {fdcIds: $fdcIds, format: $format, nutrients: $nutrients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a paged list of foods, in the 'abridged' format
#
# GET /v1/foods/list
# operationId: getFoodsList
export def "foods-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataType: list # Optional. Filter on a specific data type; specify one or more values in an array. (e.g. [Foundation, SR Legacy])
  --pageSize: int # Optional. Maximum number of results to return for the current page. Default is 50. (e.g. 25)
  --pageNumber: int # Optional. Page number to retrieve. The offset into the overall result set is expressed as (pageNumber * pageSize) (e.g. 2)
  --sortBy: string@sortBy-completer # Optional. Specify one of the possible values to sort by that field. Note, dataType.keyword will be dataType and lowercaseDescription.keyword will be description in future releases.
  --sortOrder: string@sortOrder-completer # Optional. The sort direction for the results. Only applicable if sortBy is specified.
]: nothing -> table<dataType: string, description: string, fdcId: int, foodNutrients: list<record>, publicationDate: string, brandOwner: string, gtinUpc: string, ndbNumber: int, foodCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataType" $dataType "csv") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/foods/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paged list of foods, in the 'abridged' format
#
# POST /v1/foods/list
# operationId: postFoodsList
export def "foods-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataType: list # Optional. Filter on a specific data type; specify one or more values in an array. (e.g. [Foundation, SR Legacy])
  --pageSize: int # Optional. Maximum number of results to return for the current page. Default is 50. (e.g. 25)
  --pageNumber: int # Optional. Page number to retrieve. The offset into the overall result set is expressed as (pageNumber * pageSize) (e.g. 2)
  --sortBy: string@sortBy-completer # Optional. Specify one of the possible values to sort by that field. Note, dataType.keyword will be dataType and lowercaseDescription.keyword will be description in future releases.
  --sortOrder: string@sortOrder-completer # Optional. The sort direction for the results. Only applicable if sortBy is specified.
]: any -> table<dataType: string, description: string, fdcId: int, foodNutrients: list<record>, publicationDate: string, brandOwner: string, gtinUpc: string, ndbNumber: int, foodCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/foods/list")
  let body = {dataType: $dataType, pageSize: $pageSize, pageNumber: $pageNumber, sortBy: $sortBy, sortOrder: $sortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of foods that matched search (query) keywords
#
# GET /v1/foods/search
# operationId: getFoodsSearch
export def "foods-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # One or more search terms.  The string may include [search operators](https://fdc.nal.usda.gov/help.html#bkmk-2) (e.g. cheddar cheese)
  --dataType: list # Optional. Filter on a specific data type; specify one or more values in an array. (e.g. [Foundation, SR Legacy])
  --pageSize: int # Optional. Maximum number of results to return for the current page. Default is 50. (e.g. 25)
  --pageNumber: int # Optional. Page number to retrieve. The offset into the overall result set is expressed as (pageNumber * pageSize) (e.g. 2)
  --sortBy: string@sortBy-completer # Optional. Specify one of the possible values to sort by that field. Note, dataType.keyword will be dataType and lowercaseDescription.keyword will be description in future releases. (e.g. dataType.keyword)
  --sortOrder: string@sortOrder-completer # Optional. The sort direction for the results. Only applicable if sortBy is specified. (e.g. asc)
  --brandOwner: string # Optional. Filter results based on the brand owner of the food. Only applies to Branded Foods (e.g. Kar Nut Products Company)
]: nothing -> record<foodSearchCriteria: record<query: string, dataType: list<string>, pageSize: int, pageNumber: int, sortBy: string, sortOrder: string, brandOwner: string, tradeChannel: list<string>, startDate: string, endDate: string>, totalHits: int, currentPage: int, totalPages: int, foods: table<fdcId: int, dataType: string, description: string, foodCode: string, foodNutrients: list, publicationDate: string, scientificName: string, brandOwner: string, gtinUpc: string, ingredients: string, ndbNumber: int, additionalDescriptions: string, allHighlightFields: string, score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "dataType" $dataType "csv") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "brandOwner" $brandOwner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/foods/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of foods that matched search (query) keywords
#
# POST /v1/foods/search
# operationId: postFoodsSearch
export def "foods-search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # Search terms to use in the search. The string may also include standard [search operators](https://fdc.nal.usda.gov/help.html#bkmk-2) (e.g. Cheddar cheese)
  --dataType: list # Optional. Filter on a specific data type; specify one or more values in an array. (e.g. [Foundation, SR Legacy])
  --pageSize: int # Optional. Maximum number of results to return for the current page. Default is 50. (e.g. 25)
  --pageNumber: int # Optional. Page number to retrieve. The offset into the overall result set is expressed as (pageNumber * pageSize) (e.g. 2)
  --sortBy: string@sortBy-completer # Optional. Specify one of the possible values to sort by that field. Note, dataType.keyword will be dataType and description.keyword will be description in future releases.
  --sortOrder: string@sortOrder-completer # Optional. The sort direction for the results. Only applicable if sortBy is specified.
  --brandOwner: string # Optional. Filter results based on the brand owner of the food. Only applies to Branded Foods. (e.g. Kar Nut Products Company)
  --tradeChannel: list # Optional. Filter foods containing any of the specified trade channels. (e.g. [“CHILD_NUTRITION_FOOD_PROGRAMS”, “GROCERY”])
  --startDate: string # Filter foods published on or after this date. Format: YYYY-MM-DD (e.g. 2021-01-01)
  --endDate: string # Filter foods published on or before this date. Format: YYYY-MM-DD (e.g. 2021-12-30)
]: any -> record<foodSearchCriteria: record<query: string, dataType: list<string>, pageSize: int, pageNumber: int, sortBy: string, sortOrder: string, brandOwner: string, tradeChannel: list<string>, startDate: string, endDate: string>, totalHits: int, currentPage: int, totalPages: int, foods: table<fdcId: int, dataType: string, description: string, foodCode: string, foodNutrients: list, publicationDate: string, scientificName: string, brandOwner: string, gtinUpc: string, ingredients: string, ndbNumber: int, additionalDescriptions: string, allHighlightFields: string, score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/foods/search")
  let body = {query: $body_query, dataType: $dataType, pageSize: $pageSize, pageNumber: $pageNumber, sortBy: $sortBy, sortOrder: $sortOrder, brandOwner: $brandOwner, tradeChannel: $tradeChannel, startDate: $startDate, endDate: $endDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns this documentation in JSON format
#
# GET /v1/json-spec
# operationId: getJsonSpec
export def "json-spec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/json-spec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns this documentation in JSON format
#
# GET /v1/yaml-spec
# operationId: getYamlSpec
export def "yaml-spec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/yaml-spec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
