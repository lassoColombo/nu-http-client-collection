# Auto-generated client for spoonacular API v1.1
# Source: https://api.apis.guru/v2/specs/spoonacular.com/1.1/openapi.json
# Auth: --token flag or $env.SPOONACULAR_API_TOKEN

const BASE_URL = "https://api.spoonacular.com"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPOONACULAR_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.spoonacular.com"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def content-type-completer [] { ["application/json" "application/x-www-form-urlencoded" "multipart/form-data"] }
def language-completer [] { ["de" "en"] }
def add-menu-item-information-completer [] { ["false" "true"] }
def accept-completer [] { ["application/json" "media/*" "text/html"] }
def locale-completer [] { ["en_GB" "en_US"] }
def add-product-information-completer [] { ["false" "true"] }
def measure-completer [] { ["metric" "us"] }
def normalize-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "food-converse talkToChatbot" } } | get name | first)
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

# Talk to Chatbot
#
# GET /food/converse
# Docs: https://spoonacular.com/food-api/docs#Talk-to-Chatbot — Read entire docs
# operationId: talkToChatbot
export def "food-converse talkToChatbot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The request / question / answer from the user to the chatbot. (e.g. donut recipes)
  --context-id: string # An arbitrary globally unique id for your conversation. The conversation can contain states so you should pass your context id if you want the bot to be able to remember the conversation. (e.g. 342938)
]: nothing -> record<answerText: string, media: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "contextId" $context_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/converse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Conversation Suggests
#
# GET /food/converse/suggest
# Docs: https://spoonacular.com/food-api/docs#Conversation-Suggests — Read entire docs
# operationId: getConversationSuggests
export def "food-converse-suggest get-conversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A (partial) query from the user. The endpoint will return if it matches topics it can talk about. (e.g. tell)
  --number: float # The number of suggestions to return (between 1 and 25). (e.g. 5)
]: nothing -> record<suggests: record<_: list<record>>, words: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/converse/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Custom Foods
#
# GET /food/customFoods/search
# Docs: https://spoonacular.com/food-api/docs#Search-Custom-Foods — Read entire docs
# operationId: searchCustomFoods
export def "food-custom-foods-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --username: string # The username. (e.g. dsky)
  --hash: string # The private hash for the username. (e.g. 4b5v4398573406)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<customFoods: table<id: int, imageUrl: string, price: float, servings: float, title: string>, number: int, offset: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "hash" $hash "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/customFoods/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detect Food in Text
#
# POST /food/detect
# Docs: https://spoonacular.com/food-api/docs#Detect-Food-in-Text — Read entire docs
# operationId: detectFoodInText
export def "food-detect detectFoodInText" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: record
]: any -> record<annotations: table<annotation: string, image: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/food/detect")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Image Analysis by URL
#
# GET /food/images/analyze
# Docs: https://spoonacular.com/food-api/docs#Image-Analysis-by-URL — Read entire docs
# operationId: imageAnalysisByURL
export def "food-images-analyze imageAnalysisByURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # The URL of the image to be analyzed. (e.g. https://spoonacular.com/recipeImages/635350-240x150.jpg)
]: nothing -> record<category: record<name: string, probability: float>, nutrition: record<calories: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, recipesUsed: int>, recipes: table<id: int, imageType: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageUrl" $image_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/images/analyze" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Image Classification by URL
#
# GET /food/images/classify
# Docs: https://spoonacular.com/food-api/docs#Image-Classification-by-URL — Read entire docs
# operationId: imageClassificationByURL
export def "food-images-classify imageClassificationByURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # The URL of the image to be classified. (e.g. https://spoonacular.com/recipeImages/635350-240x150.jpg)
]: nothing -> record<category: string, probability: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageUrl" $image_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/images/classify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Autocomplete Ingredient Search
#
# GET /food/ingredients/autocomplete
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Ingredient-Search — Read entire docs
# operationId: autocompleteIngredientSearch
export def "food-ingredients-autocomplete autocompleteIngredientSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --meta-information: oneof<nothing, bool> # Whether to return more meta information about the ingredients. (e.g. false)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. egg)
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
]: nothing -> table<aisle: string, id: int, image: string, name: string, possibleUnits: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "metaInformation" $meta_information "scalar") (serialize-qp "intolerances" $intolerances "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/ingredients/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compute Glycemic Load
#
# POST /food/ingredients/glycemicLoad
# Docs: https://spoonacular.com/food-api/docs#Compute-Glycemic-Load — Read entire docs
# operationId: computeGlycemicLoad
export def "food-ingredients-glycemic-load computeGlycemicLoad" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  ingredients: list
]: any -> record<ingredients: table<glycemicIndex: float, glycemicLoad: float, id: int, original: string>, totalGlycemicLoad: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/ingredients/glycemicLoad" $qp)
  let body = {"ingredients": $ingredients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Map Ingredients to Grocery Products
#
# POST /food/ingredients/map
# Docs: https://spoonacular.com/food-api/docs#Map-Ingredients-to-Grocery-Products — Read entire docs
# operationId: mapIngredientsToGroceryProducts
export def "food-ingredients-map mapIngredientsToGroceryProducts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ingredients: list
  servings: float
]: any -> table<ingredientImage: string, meta: list<string>, original: string, originalName: string, products: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/food/ingredients/map")
  let body = {"ingredients": $ingredients, "servings": $servings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ingredient Search
#
# GET /food/ingredients/search
# Docs: https://spoonacular.com/food-api/docs#Ingredient-Search — Read entire docs
# operationId: ingredientSearch
export def "food-ingredients-search ingredientSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --add-children: oneof<nothing, bool> # Whether to add children of found foods. (e.g. true)
  --min-protein-percent: float # The minimum percentage of protein the food must have (between 0 and 100). (e.g. 10)
  --max-protein-percent: float # The maximum percentage of protein the food can have (between 0 and 100). (e.g. 90)
  --min-fat-percent: float # The minimum percentage of fat the food must have (between 0 and 100). (e.g. 10)
  --max-fat-percent: float # The maximum percentage of fat the food can have (between 0 and 100). (e.g. 90)
  --min-carbs-percent: float # The minimum percentage of carbs the food must have (between 0 and 100). (e.g. 10)
  --max-carbs-percent: float # The maximum percentage of carbs the food can have (between 0 and 100). (e.g. 90)
  --meta-information: oneof<nothing, bool> # Whether to return more meta information about the ingredients. (e.g. false)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. egg)
  --qp-sort: string # The strategy to sort recipes by. See a full list of supported sorting options. (e.g. calories)
  --sort-direction: string # The direction in which to sort. Must be either 'asc' (ascending) or 'desc' (descending). (e.g. asc)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
]: nothing -> record<number: int, offset: int, results: table<id: int, image: string, name: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "addChildren" $add_children "scalar") (serialize-qp "minProteinPercent" $min_protein_percent "scalar") (serialize-qp "maxProteinPercent" $max_protein_percent "scalar") (serialize-qp "minFatPercent" $min_fat_percent "scalar") (serialize-qp "maxFatPercent" $max_fat_percent "scalar") (serialize-qp "minCarbsPercent" $min_carbs_percent "scalar") (serialize-qp "maxCarbsPercent" $max_carbs_percent "scalar") (serialize-qp "metaInformation" $meta_information "scalar") (serialize-qp "intolerances" $intolerances "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/ingredients/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Ingredient Substitutes
#
# GET /food/ingredients/substitutes
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Substitutes — Read entire docs
# operationId: getIngredientSubstitutes
export def "food-ingredients-substitutes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredient-name: string # The name of the ingredient you want to replace. (e.g. butter)
]: nothing -> record<ingredient: string, message: string, substitutes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ingredientName" $ingredient_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/ingredients/substitutes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compute Ingredient Amount
#
# GET /food/ingredients/{id}/amount
# Docs: https://spoonacular.com/food-api/docs#Compute-Ingredient-Amount — Read entire docs
# operationId: computeIngredientAmount
export def "food-ingredients-amount computeIngredientAmount" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nutrient: string # The target nutrient. See a list of supported nutrients. (e.g. protein)
  --target: float # The target number of the given nutrient. (e.g. 2)
  --unit: string # The target unit. (e.g. oz)
]: nothing -> record<amount: float, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nutrient" $nutrient "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "unit" $unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/ingredients/{id}/amount") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Ingredient Information
#
# GET /food/ingredients/{id}/information
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Information — Read entire docs
# operationId: getIngredientInformation
export def "food-ingredients-information get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # The amount of this ingredient. (e.g. 150)
  --unit: string # The unit for the given amount. (e.g. grams)
]: nothing -> record<aisle: string, amount: float, categoryPath: list<string>, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<record>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>, properties: list<record>, weightPerServing: record<amount: float, unit: string>>, original: string, originalName: string, possibleUnits: list<string>, shoppingListUnits: list<string>, unit: string, unitLong: string, unitShort: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "unit" $unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/food/ingredients/{id}/information") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Ingredient Substitutes by ID
#
# GET /food/ingredients/{id}/substitutes
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Substitutes-by-ID — Read entire docs
# operationId: getIngredientSubstitutesByID
export def "food-ingredients-substitutes get-by-id-id" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ingredient: string, message: string, substitutes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/food/ingredients/{id}/substitutes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Random Food Joke
#
# GET /food/jokes/random
# Docs: https://spoonacular.com/food-api/docs#Random-Food-Joke — Read entire docs
# operationId: getARandomFoodJoke
export def "food-jokes-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/food/jokes/random")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Menu Items
#
# GET /food/menuItems/search
# Docs: https://spoonacular.com/food-api/docs#Search-Menu-Items — Read entire docs
# operationId: searchMenuItems
export def "food-menu-items-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --min-calories: float # The minimum amount of calories the menu item must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the menu item can have. (e.g. 800)
  --min-carbs: float # The minimum amount of carbohydrates in grams the menu item must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the menu item can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the menu item must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the menu item can have. (e.g. 100)
  --min-fat: float # The minimum amount of fat in grams the menu item must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the menu item can have. (e.g. 100)
  --add-menu-item-information: oneof<nothing, bool> # If set to true, you get more information about the menu items returned. (e.g. true)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<menuItems: table<id: int, image: string, imageType: string, restaurantChain: string, servings: record, title: string>, number: int, offset: int, totalMenuItems: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "minCalories" $min_calories "scalar") (serialize-qp "maxCalories" $max_calories "scalar") (serialize-qp "minCarbs" $min_carbs "scalar") (serialize-qp "maxCarbs" $max_carbs "scalar") (serialize-qp "minProtein" $min_protein "scalar") (serialize-qp "maxProtein" $max_protein "scalar") (serialize-qp "minFat" $min_fat "scalar") (serialize-qp "maxFat" $max_fat "scalar") (serialize-qp "addMenuItemInformation" $add_menu_item_information "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/menuItems/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Autocomplete Menu Item Search
#
# GET /food/menuItems/suggest
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Menu-Item-Search — Read entire docs
# operationId: autocompleteMenuItemSearch
export def "food-menu-items-suggest autocompleteMenuItemSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (partial) search query. (e.g. chicke)
  --number: float # The number of results to return (between 1 and 25). (e.g. 10)
]: nothing -> record<results: table<id: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/menuItems/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Menu Item Information
#
# GET /food/menuItems/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Menu-Item-Information — Read entire docs
# operationId: getMenuItemInformation
export def "food-menu-items get-menu-item-information" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, restaurantChain: string, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/food/menuItems/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Menu Item Nutrition Label Widget
#
# GET /food/menuItems/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-Label-Widget — Read entire docs
# operationId: menuItemNutritionLabelWidget
export def "food-menu-items-nutrition-label menuItemNutritionLabelWidget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar") (serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/menuItems/{id}/nutritionLabel") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Menu Item Nutrition Label Image
#
# GET /food/menuItems/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-Label-Image — Read entire docs
# operationId: menuItemNutritionLabelImage
export def "food-menu-items-nutrition-labelpng menuItemNutritionLabelImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/menuItems/{id}/nutritionLabel.png") $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Menu Item Nutrition by ID Widget
#
# GET /food/menuItems/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-by-ID-Widget — Read entire docs
# operationId: visualizeMenuItemNutritionByID
export def "food-menu-items-nutrition-widget visualizeMenuItemNutritionByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/menuItems/{id}/nutritionWidget") $qp)
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Menu Item Nutrition by ID Image
#
# GET /food/menuItems/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-by-ID-Image — Read entire docs
# operationId: menuItemNutritionByIDImage
export def "food-menu-items-nutrition-widgetpng menuItemNutritionByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/food/menuItems/{id}/nutritionWidget.png"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Classify Grocery Product
#
# POST /food/products/classify
# Docs: https://spoonacular.com/food-api/docs#Classify-Grocery-Product — Read entire docs
# operationId: classifyGroceryProduct
export def "food-products-classify classifyGroceryProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string@locale-completer # The display name of the returned category, supported is en_US (for American English) and en_GB (for British English). (e.g. en_US)
  plu_code: string
  title: string
  upc: string
]: any -> record<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/products/classify" $qp)
  let body = {"plu_code": $plu_code, "title": $title, "upc": $upc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Classify Grocery Product Bulk
#
# POST /food/products/classifyBatch
# Docs: https://spoonacular.com/food-api/docs#Classify-Grocery-Product-Bulk — Read entire docs
# operationId: classifyGroceryProductBulk
export def "food-products-classify-batch classifyGroceryProductBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The display name of the returned category, supported is en_US (for American English) and en_GB (for British English). (e.g. en_US)
  --body: record
]: any -> table<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/products/classifyBatch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Grocery Products
#
# GET /food/products/search
# Docs: https://spoonacular.com/food-api/docs#Search-Grocery-Products — Read entire docs
# operationId: searchGroceryProducts
export def "food-products-search list-grocery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --min-calories: float # The minimum amount of calories the product must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the product can have. (e.g. 800)
  --min-carbs: float # The minimum amount of carbohydrates in grams the product must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the product can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the product must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the product can have. (e.g. 100)
  --min-fat: float # The minimum amount of fat in grams the product must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the product can have. (e.g. 100)
  --add-product-information: oneof<nothing, bool> # If set to true, you get more information about the products returned. (e.g. true)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<number: int, offset: int, products: table<id: int, imageType: string, title: string>, totalProducts: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "minCalories" $min_calories "scalar") (serialize-qp "maxCalories" $max_calories "scalar") (serialize-qp "minCarbs" $min_carbs "scalar") (serialize-qp "maxCarbs" $max_carbs "scalar") (serialize-qp "minProtein" $min_protein "scalar") (serialize-qp "maxProtein" $max_protein "scalar") (serialize-qp "minFat" $min_fat "scalar") (serialize-qp "maxFat" $max_fat "scalar") (serialize-qp "addProductInformation" $add_product_information "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/products/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Autocomplete Product Search
#
# GET /food/products/suggest
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Product-Search — Read entire docs
# operationId: autocompleteProductSearch
export def "food-products-suggest autocompleteProductSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (partial) search query. (e.g. chicke)
  --number: int # The number of results to return (between 1 and 25). (e.g. 10)
]: nothing -> record<results: table<id: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/products/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Grocery Products by UPC
#
# GET /food/products/upc/{upc}
# Docs: https://spoonacular.com/food-api/docs#Search-Grocery-Products-by-UPC — Read entire docs
# operationId: searchGroceryProductsByUPC
export def "food-products-upc list-grocery" [
  upc: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upc: $upc} | format pattern "/food/products/upc/{upc}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Comparable Products
#
# GET /food/products/upc/{upc}/comparable
# Docs: https://spoonacular.com/food-api/docs#Get-Comparable-Products — Read entire docs
# operationId: getComparableProducts
export def "food-products-upc-comparable get" [
  upc: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comparableProducts: record<calories: list<record>, likes: list<record>, price: list<record>, protein: list<record>, spoonacularScore: list<record>, sugar: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upc: $upc} | format pattern "/food/products/upc/{upc}/comparable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Information
#
# GET /food/products/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Product-Information — Read entire docs
# operationId: getProductInformation
export def "food-products get-product-information" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aisle: string, badges: list<string>, breadcrumbs: list<string>, generatedText: any, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/food/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Product Nutrition Label Widget
#
# GET /food/products/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-Label-Widget — Read entire docs
# operationId: productNutritionLabelWidget
export def "food-products-nutrition-label productNutritionLabelWidget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar") (serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/products/{id}/nutritionLabel") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Product Nutrition Label Image
#
# GET /food/products/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-Label-Image — Read entire docs
# operationId: productNutritionLabelImage
export def "food-products-nutrition-labelpng productNutritionLabelImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/products/{id}/nutritionLabel.png") $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Product Nutrition by ID Widget
#
# GET /food/products/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-by-ID-Widget — Read entire docs
# operationId: visualizeProductNutritionByID
export def "food-products-nutrition-widget visualizeProductNutritionByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/food/products/{id}/nutritionWidget") $qp)
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Product Nutrition by ID Image
#
# GET /food/products/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-by-ID-Image — Read entire docs
# operationId: productNutritionByIDImage
export def "food-products-nutrition-widgetpng productNutritionByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/food/products/{id}/nutritionWidget.png"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Restaurants
#
# GET /food/restaurants/search
# Docs: https://spoonacular.com/food-api/docs#Search-Restaurants — Read entire docs
# operationId: searchRestaurants
export def "food-restaurants-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query. (e.g. beach cafe)
  --lat: float # The latitude of the user's location. (e.g. 37.7786357)
  --lng: float # The longitude of the user's location.". (e.g. -122.3918135)
  --distance: float # The distance around the location in miles. (e.g. 2)
  --budget: float # The user's budget for a meal in USD. (e.g. 20)
  --cuisine: string # The cuisine of the restaurant. (e.g. italian)
  --min-rating: float # The minimum rating of the restaurant between 0 and 5. (e.g. 4.4)
  --is-open: oneof<nothing, bool> # Whether the restaurant must be open at the time of search. (e.g. true)
  --qp-sort: string # How to sort the results, one of the following 'cheapest', 'fastest', 'rating', 'distance' or the default 'relevance'. (e.g. distance)
  --page: float # The page number of results. (e.g. 0)
]: nothing -> record<restaurants: table<_id: string, address: record, aggregated_rating_count: int, cuisines: list, delivery_enabled: bool, description: string, dollar_signs: int, food_photos: list, is_open: bool, local_hours: record, logo_photos: list, miles: float, name: string, offers_first_party_delivery: bool, offers_third_party_delivery: bool, phone_number: int, pickup_enabled: bool, store_photos: list, type: string, weighted_rating_value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "budget" $budget "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "min-rating" $min_rating "scalar") (serialize-qp "is-open" $is_open "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/restaurants/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search All Food
#
# GET /food/search
# Docs: https://spoonacular.com/food-api/docs#Search-All-Food — Read entire docs
# operationId: searchAllFood
export def "food-search list-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query. (e.g. apple)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<limit: int, offset: int, query: string, searchResults: table<name: string, results: list, totalResults: int>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Site Content
#
# GET /food/site/search
# Docs: https://spoonacular.com/food-api/docs#Search-Site-Content — Read entire docs
# operationId: searchSiteContent
export def "food-site-search list-site-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The query to search for. You can also use partial queries such as "spagh" to already find spaghetti recipes, articles, grocery products, and other content. (e.g. past)
]: nothing -> record<Articles: table<dataPoints: list, image: string, link: string, name: string>, Grocery_Products: table<dataPoints: list, image: string, link: string, name: string>, Menu_Items: table<dataPoints: list, image: string, link: string, name: string>, Recipes: table<dataPoints: list, image: string, link: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/site/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Random Food Trivia
#
# GET /food/trivia/random
# Docs: https://spoonacular.com/food-api/docs#Random-Food-Trivia — Read entire docs
# operationId: getRandomFoodTrivia
export def "food-trivia-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/food/trivia/random")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Food Videos
#
# GET /food/videos/search
# Docs: https://spoonacular.com/food-api/docs#Search-Food-Videos — Read entire docs
# operationId: searchFoodVideos
export def "food-videos-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --type: string # The type of the recipes. See a full list of supported meal types. (e.g. main course)
  --cuisine: string # The cuisine(s) of the recipes. One or more, comma separated. See a full list of supported cuisines. (e.g. italian)
  --diet: string # The diet for which the recipes must be suitable. See a full list of supported diets. (e.g. vegetarian)
  --include-ingredients: string # A comma-separated list of ingredients that the recipes should contain. (e.g. tomato,cheese)
  --exclude-ingredients: string # A comma-separated list of ingredients or ingredient types that the recipes must not contain. (e.g. eggs)
  --min-length: float # Minimum video length in seconds. (e.g. 0)
  --max-length: float # Maximum video length in seconds. (e.g. 999)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<totalResults: int, videos: table<length: int, rating: float, shortTitle: string, thumbnail: string, title: string, views: int, youTubeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "diet" $diet "scalar") (serialize-qp "includeIngredients" $include_ingredients "scalar") (serialize-qp "excludeIngredients" $exclude_ingredients "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/videos/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wine Description
#
# GET /food/wine/description
# Docs: https://spoonacular.com/food-api/docs#Wine-Description — Read entire docs
# operationId: getWineDescription
export def "food-wine-description get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The name of the wine that should be paired, e.g. "merlot", "riesling", or "malbec". (e.g. merlot)
]: nothing -> record<wineDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wine" $wine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/wine/description" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dish Pairing for Wine
#
# GET /food/wine/dishes
# Docs: https://spoonacular.com/food-api/docs#Dish-Pairing-for-Wine — Read entire docs
# operationId: getDishPairingForWine
export def "food-wine-dishes get-dish-pairing-for" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The type of wine that should be paired, e.g. "merlot", "riesling", or "malbec". (e.g. malbec)
]: nothing -> record<pairings: list<string>, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wine" $wine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/wine/dishes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wine Pairing
#
# GET /food/wine/pairing
# Docs: https://spoonacular.com/food-api/docs#Wine-Pairing — Read entire docs
# operationId: getWinePairing
export def "food-wine-pairing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --food: string # The food to get a pairing for. This can be a dish ("steak"), an ingredient ("salmon"), or a cuisine ("italian"). (e.g. steak)
  --max-price: float # The maximum price for the specific wine recommendation in USD. (e.g. 50)
]: nothing -> record<pairedWines: list<string>, pairingText: string, productMatches: table<averageRating: float, description: any, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "food" $food "scalar") (serialize-qp "maxPrice" $max_price "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/wine/pairing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wine Recommendation
#
# GET /food/wine/recommendation
# Docs: https://spoonacular.com/food-api/docs#Wine-Recommendation — Read entire docs
# operationId: getWineRecommendation
export def "food-wine-recommendation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The type of wine to get a specific product recommendation for. (e.g. merlot)
  --max-price: float # The maximum price for the specific wine recommendation in USD. (e.g. 50)
  --min-rating: float # The minimum rating of the recommended wine between 0 and 1. For example, 0.8 equals 4 out of 5 stars. (e.g. 0.7)
  --number: float # The number of wine recommendations expected (between 1 and 100). (default: 10, e.g. 3)
]: nothing -> record<recommendedWines: table<averageRating: float, description: string, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>, totalFound: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wine" $wine "scalar") (serialize-qp "maxPrice" $max_price "scalar") (serialize-qp "minRating" $min_rating "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/food/wine/recommendation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate Meal Plan
#
# GET /mealplanner/generate
# Docs: https://spoonacular.com/food-api/docs#Generate-Meal-Plan — Read entire docs
# operationId: generateMealPlan
export def "mealplanner-generate generateMealPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-frame: string # Either for one "day" or an entire "week". (e.g. day)
  --target-calories: float # What is the caloric target for one day? The meal plan generator will try to get as close as possible to that goal. (e.g. 2000)
  --diet: string # Enter a diet that the meal plan has to adhere to. See a full list of supported diets. (e.g. vegetarian)
  --exclude: string # A comma-separated list of allergens or ingredients that must be excluded. (e.g. shellfish, olives)
]: nothing -> record<meals: table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string>, nutrients: record<calories: float, carbohydrates: float, fat: float, protein: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "targetCalories" $target_calories "scalar") (serialize-qp "diet" $diet "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mealplanner/generate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear Meal Plan Day
#
# DELETE /mealplanner/{username}/day/{date}
# Docs: https://spoonacular.com/food-api/docs#Clear-Meal-Plan-Day — Read entire docs
# operationId: clearMealPlanDay
export def "mealplanner-day clearMealPlanDay" [
  username: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, date: $date} | format pattern "/mealplanner/{username}/day/{date}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Add to Meal Plan
#
# POST /mealplanner/{username}/items
# Docs: https://spoonacular.com/food-api/docs#Add-to-Meal-Plan — Read entire docs
# operationId: addToMealPlan
# --value shape: {ingredients: list}
export def "mealplanner-items create-to-meal-plan" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  date: float
  position: int
  slot: int
  type: string
  value: record # shape: {ingredients: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/mealplanner/{username}/items") $qp)
  let body = {"date": $date, "position": $position, "slot": $slot, "type": $type, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete from Meal Plan
#
# DELETE /mealplanner/{username}/items/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-from-Meal-Plan — Read entire docs
# operationId: deleteFromMealPlan
export def "mealplanner-items delete-from-meal-plan" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/mealplanner/{username}/items/{id}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Get Shopping List
#
# GET /mealplanner/{username}/shopping-list
# Docs: https://spoonacular.com/food-api/docs#Get-Shopping-List — Read entire docs
# operationId: getShoppingList
export def "mealplanner-shopping-list get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
]: nothing -> record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/mealplanner/{username}/shopping-list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to Shopping List
#
# POST /mealplanner/{username}/shopping-list/items
# Docs: https://spoonacular.com/food-api/docs#Add-to-Shopping-List — Read entire docs
# operationId: addToShoppingList
export def "mealplanner-shopping-list-items create-to" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  aisle: string
  item: string
  --parse: oneof<nothing, bool>
]: any -> record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/mealplanner/{username}/shopping-list/items") $qp)
  let body = {"aisle": $aisle, "item": $item, "parse": $parse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete from Shopping List
#
# DELETE /mealplanner/{username}/shopping-list/items/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-from-Shopping-List — Read entire docs
# operationId: deleteFromShoppingList
export def "mealplanner-shopping-list-items delete-from" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/mealplanner/{username}/shopping-list/items/{id}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Generate Shopping List
#
# POST /mealplanner/{username}/shopping-list/{start-date}/{end-date}
# Docs: https://spoonacular.com/food-api/docs#Generate-Shopping-List — Read entire docs
# operationId: generateShoppingList
export def "mealplanner-shopping-list generateShoppingList" [
  username: string
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
  --body: record
]: any -> record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, start_date: $start_date, end_date: $end_date} | format pattern "/mealplanner/{username}/shopping-list/{start_date}/{end_date}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Get Meal Plan Templates
#
# GET /mealplanner/{username}/templates
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Templates — Read entire docs
# operationId: getMealPlanTemplates
export def "mealplanner-templates list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
]: nothing -> record<templates: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/mealplanner/{username}/templates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Meal Plan Template
#
# POST /mealplanner/{username}/templates
# Docs: https://spoonacular.com/food-api/docs#Add-Meal-Plan-Template — Read entire docs
# operationId: addMealPlanTemplate
export def "mealplanner-templates create-meal-plan" [
  username: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (e.g. 4b5v4398573406)
  --body: record
]: any -> record<items: table<day: int, position: int, slot: int, type: string, value: record>, name: string, publishAsPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, username: $username} | format pattern "/mealplanner/{username}/templates") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Delete Meal Plan Template
#
# DELETE /mealplanner/{username}/templates/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-Meal-Plan-Template — Read entire docs
# operationId: deleteMealPlanTemplate
export def "mealplanner-templates delete-meal-plan" [
  username: string
  username: string
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (e.g. 4b5v4398573406)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, username: $username, id: $id, id: $id} | format pattern "/mealplanner/{username}/templates/{id}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "" $body
}

# Get Meal Plan Template
#
# GET /mealplanner/{username}/templates/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Template — Read entire docs
# operationId: getMealPlanTemplate
export def "mealplanner-templates get-meal-plan" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
]: nothing -> record<days: table<day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/mealplanner/{username}/templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Meal Plan Week
#
# GET /mealplanner/{username}/week/{start-date}
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Week — Read entire docs
# operationId: getMealPlanWeek
export def "mealplanner-week get-meal-plan" [
  username: string
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username.
]: nothing -> record<days: table<date: float, day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, start_date: $start_date} | format pattern "/mealplanner/{username}/week/{start_date}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Analyze Recipe
#
# POST /recipes/analyze
# Docs: https://spoonacular.com/food-api/docs#Analyze-Recipe — Read entire docs
# operationId: analyzeRecipe
export def "recipes-analyze analyzeRecipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The input language, either "en" or "de". (e.g. en)
  --include-nutrition: oneof<nothing, bool> # Whether nutrition data should be added to correctly parsed ingredients. (e.g. false)
  --include-taste: oneof<nothing, bool> # Whether taste data should be added to correctly parsed ingredients. (e.g. false)
  --ingredients: list
  --instructions: string
  --servings: int
  --title: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "includeNutrition" $include_nutrition "scalar") (serialize-qp "includeTaste" $include_taste "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/analyze" $qp)
  let body = {"ingredients": $ingredients, "instructions": $instructions, "servings": $servings, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyze Recipe Instructions
#
# POST /recipes/analyzeInstructions
# Docs: https://spoonacular.com/food-api/docs#Analyze-Recipe-Instructions — Read entire docs
# operationId: analyzeRecipeInstructions
export def "recipes-analyze-instructions analyzeRecipeInstructions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: record
]: any -> record<equipment: table<id: float, name: string>, ingredients: table<id: float, name: string>, parsedInstructions: table<name: string, steps: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipes/analyzeInstructions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Autocomplete Recipe Search
#
# GET /recipes/autocomplete
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Recipe-Search — Read entire docs
# operationId: autocompleteRecipeSearch
export def "recipes-autocomplete autocompleteRecipeSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> table<id: int, imageType: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Recipes
#
# GET /recipes/complexSearch
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes — Read entire docs
# operationId: searchRecipes
export def "recipes-complex-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --cuisine: string # The cuisine(s) of the recipes. One or more, comma separated (will be interpreted as 'OR'). See a full list of supported cuisines. (e.g. italian)
  --exclude-cuisine: string # The cuisine(s) the recipes must not match. One or more, comma separated (will be interpreted as 'AND'). See a full list of supported cuisines. (e.g. greek)
  --diet: string # The diet for which the recipes must be suitable. See a full list of supported diets. (e.g. vegetarian)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. gluten)
  --equipment: string # The equipment required. Multiple values will be interpreted as 'or'. For example, value could be "blender, frying pan, bowl". (e.g. pan)
  --include-ingredients: string # A comma-separated list of ingredients that should/must be used in the recipes. (e.g. tomato,cheese)
  --exclude-ingredients: string # A comma-separated list of ingredients or ingredient types that the recipes must not contain. (e.g. eggs)
  --type: string # The type of recipe. See a full list of supported meal types. (e.g. main course)
  --instructions-required: oneof<nothing, bool> # Whether the recipes must have instructions. (e.g. true)
  --fill-ingredients: oneof<nothing, bool> # Add information about the ingredients and whether they are used or missing in relation to the query. (e.g. false)
  --add-recipe-information: oneof<nothing, bool> # If set to true, you get more information about the recipes returned. (e.g. false)
  --add-recipe-nutrition: oneof<nothing, bool> # If set to true, you get nutritional information about each recipes returned. (e.g. false)
  --author: string # The username of the recipe author. (e.g. coffeebean)
  --tags: string # The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must have.
  --recipe-box-id: float # The id of the recipe box to which the search should be limited to. (e.g. 2468)
  --title-match: string # Enter text that must be found in the title of the recipes. (e.g. Crock Pot)
  --max-ready-time: float # The maximum time in minutes it should take to prepare and cook the recipe. (e.g. 20)
  --ignore-pantry: oneof<nothing, bool> # Whether to ignore typical pantry items, such as water, salt, flour, etc. (default: false, e.g. false)
  --qp-sort: string # The strategy to sort recipes by. See a full list of supported sorting options. (e.g. calories)
  --sort-direction: string # The direction in which to sort. Must be either 'asc' (ascending) or 'desc' (descending). (e.g. asc)
  --min-carbs: float # The minimum amount of carbohydrates in grams the recipe must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the recipe can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the recipe must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the recipe can have. (e.g. 100)
  --min-calories: float # The minimum amount of calories the recipe must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the recipe can have. (e.g. 800)
  --min-fat: float # The minimum amount of fat in grams the recipe must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the recipe can have. (e.g. 100)
  --min-alcohol: float # The minimum amount of alcohol in grams the recipe must have. (e.g. 0)
  --max-alcohol: float # The maximum amount of alcohol in grams the recipe can have. (e.g. 100)
  --min-caffeine: float # The minimum amount of caffeine in milligrams the recipe must have. (e.g. 0)
  --max-caffeine: float # The maximum amount of caffeine in milligrams the recipe can have. (e.g. 100)
  --min-copper: float # The minimum amount of copper in milligrams the recipe must have. (e.g. 0)
  --max-copper: float # The maximum amount of copper in milligrams the recipe can have. (e.g. 100)
  --min-calcium: float # The minimum amount of calcium in milligrams the recipe must have. (e.g. 0)
  --max-calcium: float # The maximum amount of calcium in milligrams the recipe can have. (e.g. 100)
  --min-choline: float # The minimum amount of choline in milligrams the recipe must have. (e.g. 0)
  --max-choline: float # The maximum amount of choline in milligrams the recipe can have. (e.g. 100)
  --min-cholesterol: float # The minimum amount of cholesterol in milligrams the recipe must have. (e.g. 0)
  --max-cholesterol: float # The maximum amount of cholesterol in milligrams the recipe can have. (e.g. 100)
  --min-fluoride: float # The minimum amount of fluoride in milligrams the recipe must have. (e.g. 0)
  --max-fluoride: float # The maximum amount of fluoride in milligrams the recipe can have. (e.g. 100)
  --min-saturated-fat: float # The minimum amount of saturated fat in grams the recipe must have. (e.g. 0)
  --max-saturated-fat: float # The maximum amount of saturated fat in grams the recipe can have. (e.g. 100)
  --min-vitamin-a: float # The minimum amount of Vitamin A in IU the recipe must have. (e.g. 0)
  --max-vitamin-a: float # The maximum amount of Vitamin A in IU the recipe can have. (e.g. 100)
  --min-vitamin-c: float # The minimum amount of Vitamin C milligrams the recipe must have. (e.g. 0)
  --max-vitamin-c: float # The maximum amount of Vitamin C in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-d: float # The minimum amount of Vitamin D in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-d: float # The maximum amount of Vitamin D in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-e: float # The minimum amount of Vitamin E in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-e: float # The maximum amount of Vitamin E in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-k: float # The minimum amount of Vitamin K in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-k: float # The maximum amount of Vitamin K in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-b1: float # The minimum amount of Vitamin B1 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b1: float # The maximum amount of Vitamin B1 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b2: float # The minimum amount of Vitamin B2 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b2: float # The maximum amount of Vitamin B2 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b5: float # The minimum amount of Vitamin B5 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b5: float # The maximum amount of Vitamin B5 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b3: float # The minimum amount of Vitamin B3 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b3: float # The maximum amount of Vitamin B3 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b6: float # The minimum amount of Vitamin B6 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b6: float # The maximum amount of Vitamin B6 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b12: float # The minimum amount of Vitamin B12 in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-b12: float # The maximum amount of Vitamin B12 in micrograms the recipe can have. (e.g. 100)
  --min-fiber: float # The minimum amount of fiber in grams the recipe must have. (e.g. 0)
  --max-fiber: float # The maximum amount of fiber in grams the recipe can have. (e.g. 100)
  --min-folate: float # The minimum amount of folate in micrograms the recipe must have. (e.g. 0)
  --max-folate: float # The maximum amount of folate in micrograms the recipe can have. (e.g. 100)
  --min-folic-acid: float # The minimum amount of folic acid in micrograms the recipe must have. (e.g. 0)
  --max-folic-acid: float # The maximum amount of folic acid in micrograms the recipe can have. (e.g. 100)
  --min-iodine: float # The minimum amount of iodine in micrograms the recipe must have. (e.g. 0)
  --max-iodine: float # The maximum amount of iodine in micrograms the recipe can have. (e.g. 100)
  --min-iron: float # The minimum amount of iron in milligrams the recipe must have. (e.g. 0)
  --max-iron: float # The maximum amount of iron in milligrams the recipe can have. (e.g. 100)
  --min-magnesium: float # The minimum amount of magnesium in milligrams the recipe must have. (e.g. 0)
  --max-magnesium: float # The maximum amount of magnesium in milligrams the recipe can have. (e.g. 100)
  --min-manganese: float # The minimum amount of manganese in milligrams the recipe must have. (e.g. 0)
  --max-manganese: float # The maximum amount of manganese in milligrams the recipe can have. (e.g. 100)
  --min-phosphorus: float # The minimum amount of phosphorus in milligrams the recipe must have. (e.g. 0)
  --max-phosphorus: float # The maximum amount of phosphorus in milligrams the recipe can have. (e.g. 100)
  --min-potassium: float # The minimum amount of potassium in milligrams the recipe must have. (e.g. 0)
  --max-potassium: float # The maximum amount of potassium in milligrams the recipe can have. (e.g. 100)
  --min-selenium: float # The minimum amount of selenium in micrograms the recipe must have. (e.g. 0)
  --max-selenium: float # The maximum amount of selenium in micrograms the recipe can have. (e.g. 100)
  --min-sodium: float # The minimum amount of sodium in milligrams the recipe must have. (e.g. 0)
  --max-sodium: float # The maximum amount of sodium in milligrams the recipe can have. (e.g. 100)
  --min-sugar: float # The minimum amount of sugar in grams the recipe must have. (e.g. 0)
  --max-sugar: float # The maximum amount of sugar in grams the recipe can have. (e.g. 100)
  --min-zinc: float # The minimum amount of zinc in milligrams the recipe must have. (e.g. 0)
  --max-zinc: float # The maximum amount of zinc in milligrams the recipe can have. (e.g. 100)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> record<number: int, offset: int, results: table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "excludeCuisine" $exclude_cuisine "scalar") (serialize-qp "diet" $diet "scalar") (serialize-qp "intolerances" $intolerances "scalar") (serialize-qp "equipment" $equipment "scalar") (serialize-qp "includeIngredients" $include_ingredients "scalar") (serialize-qp "excludeIngredients" $exclude_ingredients "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "instructionsRequired" $instructions_required "scalar") (serialize-qp "fillIngredients" $fill_ingredients "scalar") (serialize-qp "addRecipeInformation" $add_recipe_information "scalar") (serialize-qp "addRecipeNutrition" $add_recipe_nutrition "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "recipeBoxId" $recipe_box_id "scalar") (serialize-qp "titleMatch" $title_match "scalar") (serialize-qp "maxReadyTime" $max_ready_time "scalar") (serialize-qp "ignorePantry" $ignore_pantry "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "minCarbs" $min_carbs "scalar") (serialize-qp "maxCarbs" $max_carbs "scalar") (serialize-qp "minProtein" $min_protein "scalar") (serialize-qp "maxProtein" $max_protein "scalar") (serialize-qp "minCalories" $min_calories "scalar") (serialize-qp "maxCalories" $max_calories "scalar") (serialize-qp "minFat" $min_fat "scalar") (serialize-qp "maxFat" $max_fat "scalar") (serialize-qp "minAlcohol" $min_alcohol "scalar") (serialize-qp "maxAlcohol" $max_alcohol "scalar") (serialize-qp "minCaffeine" $min_caffeine "scalar") (serialize-qp "maxCaffeine" $max_caffeine "scalar") (serialize-qp "minCopper" $min_copper "scalar") (serialize-qp "maxCopper" $max_copper "scalar") (serialize-qp "minCalcium" $min_calcium "scalar") (serialize-qp "maxCalcium" $max_calcium "scalar") (serialize-qp "minCholine" $min_choline "scalar") (serialize-qp "maxCholine" $max_choline "scalar") (serialize-qp "minCholesterol" $min_cholesterol "scalar") (serialize-qp "maxCholesterol" $max_cholesterol "scalar") (serialize-qp "minFluoride" $min_fluoride "scalar") (serialize-qp "maxFluoride" $max_fluoride "scalar") (serialize-qp "minSaturatedFat" $min_saturated_fat "scalar") (serialize-qp "maxSaturatedFat" $max_saturated_fat "scalar") (serialize-qp "minVitaminA" $min_vitamin_a "scalar") (serialize-qp "maxVitaminA" $max_vitamin_a "scalar") (serialize-qp "minVitaminC" $min_vitamin_c "scalar") (serialize-qp "maxVitaminC" $max_vitamin_c "scalar") (serialize-qp "minVitaminD" $min_vitamin_d "scalar") (serialize-qp "maxVitaminD" $max_vitamin_d "scalar") (serialize-qp "minVitaminE" $min_vitamin_e "scalar") (serialize-qp "maxVitaminE" $max_vitamin_e "scalar") (serialize-qp "minVitaminK" $min_vitamin_k "scalar") (serialize-qp "maxVitaminK" $max_vitamin_k "scalar") (serialize-qp "minVitaminB1" $min_vitamin_b1 "scalar") (serialize-qp "maxVitaminB1" $max_vitamin_b1 "scalar") (serialize-qp "minVitaminB2" $min_vitamin_b2 "scalar") (serialize-qp "maxVitaminB2" $max_vitamin_b2 "scalar") (serialize-qp "minVitaminB5" $min_vitamin_b5 "scalar") (serialize-qp "maxVitaminB5" $max_vitamin_b5 "scalar") (serialize-qp "minVitaminB3" $min_vitamin_b3 "scalar") (serialize-qp "maxVitaminB3" $max_vitamin_b3 "scalar") (serialize-qp "minVitaminB6" $min_vitamin_b6 "scalar") (serialize-qp "maxVitaminB6" $max_vitamin_b6 "scalar") (serialize-qp "minVitaminB12" $min_vitamin_b12 "scalar") (serialize-qp "maxVitaminB12" $max_vitamin_b12 "scalar") (serialize-qp "minFiber" $min_fiber "scalar") (serialize-qp "maxFiber" $max_fiber "scalar") (serialize-qp "minFolate" $min_folate "scalar") (serialize-qp "maxFolate" $max_folate "scalar") (serialize-qp "minFolicAcid" $min_folic_acid "scalar") (serialize-qp "maxFolicAcid" $max_folic_acid "scalar") (serialize-qp "minIodine" $min_iodine "scalar") (serialize-qp "maxIodine" $max_iodine "scalar") (serialize-qp "minIron" $min_iron "scalar") (serialize-qp "maxIron" $max_iron "scalar") (serialize-qp "minMagnesium" $min_magnesium "scalar") (serialize-qp "maxMagnesium" $max_magnesium "scalar") (serialize-qp "minManganese" $min_manganese "scalar") (serialize-qp "maxManganese" $max_manganese "scalar") (serialize-qp "minPhosphorus" $min_phosphorus "scalar") (serialize-qp "maxPhosphorus" $max_phosphorus "scalar") (serialize-qp "minPotassium" $min_potassium "scalar") (serialize-qp "maxPotassium" $max_potassium "scalar") (serialize-qp "minSelenium" $min_selenium "scalar") (serialize-qp "maxSelenium" $max_selenium "scalar") (serialize-qp "minSodium" $min_sodium "scalar") (serialize-qp "maxSodium" $max_sodium "scalar") (serialize-qp "minSugar" $min_sugar "scalar") (serialize-qp "maxSugar" $max_sugar "scalar") (serialize-qp "minZinc" $min_zinc "scalar") (serialize-qp "maxZinc" $max_zinc "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "limitLicense" $limit_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/complexSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Convert Amounts
#
# GET /recipes/convert
# Docs: https://spoonacular.com/food-api/docs#Convert-Amounts — Read entire docs
# operationId: convertAmounts
export def "recipes-convert convertAmounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredient-name: string # The ingredient which you want to convert. (e.g. flour)
  --source-amount: float # The amount from which you want to convert, e.g. the 2.5 in "2.5 cups of flour to grams". (e.g. 2.5)
  --source-unit: string # The unit from which you want to convert, e.g. the grams in "2.5 cups of flour to grams". You can also use "piece", e.g. "3.4 oz tomatoes to piece" (e.g. cups)
  --target-unit: string # The unit to which you want to convert, e.g. the grams in "2.5 cups of flour to grams". You can also use "piece", e.g. "3.4 oz tomatoes to piece" (e.g. grams)
]: nothing -> record<answer: string, sourceAmount: float, sourceUnit: string, targetAmount: float, targetUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ingredientName" $ingredient_name "scalar") (serialize-qp "sourceAmount" $source_amount "scalar") (serialize-qp "sourceUnit" $source_unit "scalar") (serialize-qp "targetUnit" $target_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/convert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Classify Cuisine
#
# POST /recipes/cuisine
# Docs: https://spoonacular.com/food-api/docs#Classify-Cuisine — Read entire docs
# operationId: classifyCuisine
export def "recipes-cuisine classifyCuisine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: record
]: any -> record<confidence: float, cuisine: string, cuisines: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipes/cuisine")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Extract Recipe from Website
#
# GET /recipes/extract
# Docs: https://spoonacular.com/food-api/docs#Extract-Recipe-from-Website — Read entire docs
# operationId: extractRecipeFromWebsite
export def "recipes-extract extractRecipeFromWebsite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # The URL of the recipe page. (e.g. https://foodista.com/recipe/ZHK4KPB6/chocolate-crinkle-cookies)
  --force-extraction: oneof<nothing, bool> # If true, the extraction will be triggered whether we already know the recipe or not. Use this only if information is missing as this operation is slower. (e.g. true)
  --analyze: oneof<nothing, bool> # If true, the recipe will be analyzed and classified resolving in more data such as cuisines, dish types, and more. (e.g. false)
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
  --include-taste: oneof<nothing, bool> # Whether taste data should be added to correctly parsed ingredients. (default: false, e.g. false)
]: nothing -> record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "forceExtraction" $force_extraction "scalar") (serialize-qp "analyze" $analyze "scalar") (serialize-qp "includeNutrition" $include_nutrition "scalar") (serialize-qp "includeTaste" $include_taste "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/extract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Recipes by Ingredients
#
# GET /recipes/findByIngredients
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes-by-Ingredients — Read entire docs
# operationId: searchRecipesByIngredients
export def "recipes-find-by-ingredients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredients: string # A comma-separated list of ingredients that the recipes should contain. (e.g. carrots,tomatoes)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
  --ranking: float # Whether to maximize used ingredients (1) or minimize missing ingredients (2) first. (e.g. 1)
  --ignore-pantry: oneof<nothing, bool> # Whether to ignore typical pantry items, such as water, salt, flour, etc. (default: false, e.g. false)
]: nothing -> table<id: int, image: string, imageType: string, likes: int, missedIngredientCount: int, missedIngredients: list<record>, title: string, unusedIngredients: list<record>, usedIngredientCount: float, usedIngredients: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ingredients" $ingredients "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "limitLicense" $limit_license "scalar") (serialize-qp "ranking" $ranking "scalar") (serialize-qp "ignorePantry" $ignore_pantry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/findByIngredients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Recipes by Nutrients
#
# GET /recipes/findByNutrients
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes-by-Nutrients — Read entire docs
# operationId: searchRecipesByNutrients
export def "recipes-find-by-nutrients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-carbs: float # The minimum amount of carbohydrates in grams the recipe must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the recipe can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the recipe must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the recipe can have. (e.g. 100)
  --min-calories: float # The minimum amount of calories the recipe must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the recipe can have. (e.g. 800)
  --min-fat: float # The minimum amount of fat in grams the recipe must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the recipe can have. (e.g. 100)
  --min-alcohol: float # The minimum amount of alcohol in grams the recipe must have. (e.g. 0)
  --max-alcohol: float # The maximum amount of alcohol in grams the recipe can have. (e.g. 100)
  --min-caffeine: float # The minimum amount of caffeine in milligrams the recipe must have. (e.g. 0)
  --max-caffeine: float # The maximum amount of caffeine in milligrams the recipe can have. (e.g. 100)
  --min-copper: float # The minimum amount of copper in milligrams the recipe must have. (e.g. 0)
  --max-copper: float # The maximum amount of copper in milligrams the recipe can have. (e.g. 100)
  --min-calcium: float # The minimum amount of calcium in milligrams the recipe must have. (e.g. 0)
  --max-calcium: float # The maximum amount of calcium in milligrams the recipe can have. (e.g. 100)
  --min-choline: float # The minimum amount of choline in milligrams the recipe must have. (e.g. 0)
  --max-choline: float # The maximum amount of choline in milligrams the recipe can have. (e.g. 100)
  --min-cholesterol: float # The minimum amount of cholesterol in milligrams the recipe must have. (e.g. 0)
  --max-cholesterol: float # The maximum amount of cholesterol in milligrams the recipe can have. (e.g. 100)
  --min-fluoride: float # The minimum amount of fluoride in milligrams the recipe must have. (e.g. 0)
  --max-fluoride: float # The maximum amount of fluoride in milligrams the recipe can have. (e.g. 100)
  --min-saturated-fat: float # The minimum amount of saturated fat in grams the recipe must have. (e.g. 0)
  --max-saturated-fat: float # The maximum amount of saturated fat in grams the recipe can have. (e.g. 100)
  --min-vitamin-a: float # The minimum amount of Vitamin A in IU the recipe must have. (e.g. 0)
  --max-vitamin-a: float # The maximum amount of Vitamin A in IU the recipe can have. (e.g. 100)
  --min-vitamin-c: float # The minimum amount of Vitamin C in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-c: float # The maximum amount of Vitamin C in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-d: float # The minimum amount of Vitamin D in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-d: float # The maximum amount of Vitamin D in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-e: float # The minimum amount of Vitamin E in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-e: float # The maximum amount of Vitamin E in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-k: float # The minimum amount of Vitamin K in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-k: float # The maximum amount of Vitamin K in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-b1: float # The minimum amount of Vitamin B1 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b1: float # The maximum amount of Vitamin B1 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b2: float # The minimum amount of Vitamin B2 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b2: float # The maximum amount of Vitamin B2 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b5: float # The minimum amount of Vitamin B5 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b5: float # The maximum amount of Vitamin B5 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b3: float # The minimum amount of Vitamin B3 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b3: float # The maximum amount of Vitamin B3 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b6: float # The minimum amount of Vitamin B6 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b6: float # The maximum amount of Vitamin B6 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b12: float # The minimum amount of Vitamin B12 in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-b12: float # The maximum amount of Vitamin B12 in micrograms the recipe can have. (e.g. 100)
  --min-fiber: float # The minimum amount of fiber in grams the recipe must have. (e.g. 0)
  --max-fiber: float # The maximum amount of fiber in grams the recipe can have. (e.g. 100)
  --min-folate: float # The minimum amount of folate in micrograms the recipe must have. (e.g. 0)
  --max-folate: float # The maximum amount of folate in micrograms the recipe can have. (e.g. 100)
  --min-folic-acid: float # The minimum amount of folic acid in micrograms the recipe must have. (e.g. 0)
  --max-folic-acid: float # The maximum amount of folic acid in micrograms the recipe can have. (e.g. 100)
  --min-iodine: float # The minimum amount of iodine in micrograms the recipe must have. (e.g. 0)
  --max-iodine: float # The maximum amount of iodine in micrograms the recipe can have. (e.g. 100)
  --min-iron: float # The minimum amount of iron in milligrams the recipe must have. (e.g. 0)
  --max-iron: float # The maximum amount of iron in milligrams the recipe can have. (e.g. 100)
  --min-magnesium: float # The minimum amount of magnesium in milligrams the recipe must have. (e.g. 0)
  --max-magnesium: float # The maximum amount of magnesium in milligrams the recipe can have. (e.g. 100)
  --min-manganese: float # The minimum amount of manganese in milligrams the recipe must have. (e.g. 0)
  --max-manganese: float # The maximum amount of manganese in milligrams the recipe can have. (e.g. 100)
  --min-phosphorus: float # The minimum amount of phosphorus in milligrams the recipe must have. (e.g. 0)
  --max-phosphorus: float # The maximum amount of phosphorus in milligrams the recipe can have. (e.g. 100)
  --min-potassium: float # The minimum amount of potassium in milligrams the recipe must have. (e.g. 0)
  --max-potassium: float # The maximum amount of potassium in milligrams the recipe can have. (e.g. 100)
  --min-selenium: float # The minimum amount of selenium in micrograms the recipe must have. (e.g. 0)
  --max-selenium: float # The maximum amount of selenium in micrograms the recipe can have. (e.g. 100)
  --min-sodium: float # The minimum amount of sodium in milligrams the recipe must have. (e.g. 0)
  --max-sodium: float # The maximum amount of sodium in milligrams the recipe can have. (e.g. 100)
  --min-sugar: float # The minimum amount of sugar in grams the recipe must have. (e.g. 0)
  --max-sugar: float # The maximum amount of sugar in grams the recipe can have. (e.g. 100)
  --min-zinc: float # The minimum amount of zinc in milligrams the recipe must have. (e.g. 0)
  --max-zinc: float # The maximum amount of zinc in milligrams the recipe can have. (e.g. 100)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --random: oneof<nothing, bool> # If true, every request will give you a random set of recipes within the requested limits. (e.g. false)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minCarbs" $min_carbs "scalar") (serialize-qp "maxCarbs" $max_carbs "scalar") (serialize-qp "minProtein" $min_protein "scalar") (serialize-qp "maxProtein" $max_protein "scalar") (serialize-qp "minCalories" $min_calories "scalar") (serialize-qp "maxCalories" $max_calories "scalar") (serialize-qp "minFat" $min_fat "scalar") (serialize-qp "maxFat" $max_fat "scalar") (serialize-qp "minAlcohol" $min_alcohol "scalar") (serialize-qp "maxAlcohol" $max_alcohol "scalar") (serialize-qp "minCaffeine" $min_caffeine "scalar") (serialize-qp "maxCaffeine" $max_caffeine "scalar") (serialize-qp "minCopper" $min_copper "scalar") (serialize-qp "maxCopper" $max_copper "scalar") (serialize-qp "minCalcium" $min_calcium "scalar") (serialize-qp "maxCalcium" $max_calcium "scalar") (serialize-qp "minCholine" $min_choline "scalar") (serialize-qp "maxCholine" $max_choline "scalar") (serialize-qp "minCholesterol" $min_cholesterol "scalar") (serialize-qp "maxCholesterol" $max_cholesterol "scalar") (serialize-qp "minFluoride" $min_fluoride "scalar") (serialize-qp "maxFluoride" $max_fluoride "scalar") (serialize-qp "minSaturatedFat" $min_saturated_fat "scalar") (serialize-qp "maxSaturatedFat" $max_saturated_fat "scalar") (serialize-qp "minVitaminA" $min_vitamin_a "scalar") (serialize-qp "maxVitaminA" $max_vitamin_a "scalar") (serialize-qp "minVitaminC" $min_vitamin_c "scalar") (serialize-qp "maxVitaminC" $max_vitamin_c "scalar") (serialize-qp "minVitaminD" $min_vitamin_d "scalar") (serialize-qp "maxVitaminD" $max_vitamin_d "scalar") (serialize-qp "minVitaminE" $min_vitamin_e "scalar") (serialize-qp "maxVitaminE" $max_vitamin_e "scalar") (serialize-qp "minVitaminK" $min_vitamin_k "scalar") (serialize-qp "maxVitaminK" $max_vitamin_k "scalar") (serialize-qp "minVitaminB1" $min_vitamin_b1 "scalar") (serialize-qp "maxVitaminB1" $max_vitamin_b1 "scalar") (serialize-qp "minVitaminB2" $min_vitamin_b2 "scalar") (serialize-qp "maxVitaminB2" $max_vitamin_b2 "scalar") (serialize-qp "minVitaminB5" $min_vitamin_b5 "scalar") (serialize-qp "maxVitaminB5" $max_vitamin_b5 "scalar") (serialize-qp "minVitaminB3" $min_vitamin_b3 "scalar") (serialize-qp "maxVitaminB3" $max_vitamin_b3 "scalar") (serialize-qp "minVitaminB6" $min_vitamin_b6 "scalar") (serialize-qp "maxVitaminB6" $max_vitamin_b6 "scalar") (serialize-qp "minVitaminB12" $min_vitamin_b12 "scalar") (serialize-qp "maxVitaminB12" $max_vitamin_b12 "scalar") (serialize-qp "minFiber" $min_fiber "scalar") (serialize-qp "maxFiber" $max_fiber "scalar") (serialize-qp "minFolate" $min_folate "scalar") (serialize-qp "maxFolate" $max_folate "scalar") (serialize-qp "minFolicAcid" $min_folic_acid "scalar") (serialize-qp "maxFolicAcid" $max_folic_acid "scalar") (serialize-qp "minIodine" $min_iodine "scalar") (serialize-qp "maxIodine" $max_iodine "scalar") (serialize-qp "minIron" $min_iron "scalar") (serialize-qp "maxIron" $max_iron "scalar") (serialize-qp "minMagnesium" $min_magnesium "scalar") (serialize-qp "maxMagnesium" $max_magnesium "scalar") (serialize-qp "minManganese" $min_manganese "scalar") (serialize-qp "maxManganese" $max_manganese "scalar") (serialize-qp "minPhosphorus" $min_phosphorus "scalar") (serialize-qp "maxPhosphorus" $max_phosphorus "scalar") (serialize-qp "minPotassium" $min_potassium "scalar") (serialize-qp "maxPotassium" $max_potassium "scalar") (serialize-qp "minSelenium" $min_selenium "scalar") (serialize-qp "maxSelenium" $max_selenium "scalar") (serialize-qp "minSodium" $min_sodium "scalar") (serialize-qp "maxSodium" $max_sodium "scalar") (serialize-qp "minSugar" $min_sugar "scalar") (serialize-qp "maxSugar" $max_sugar "scalar") (serialize-qp "minZinc" $min_zinc "scalar") (serialize-qp "maxZinc" $max_zinc "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "random" $random "scalar") (serialize-qp "limitLicense" $limit_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/findByNutrients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Guess Nutrition by Dish Name
#
# GET /recipes/guessNutrition
# Docs: https://spoonacular.com/food-api/docs#Guess-Nutrition-by-Dish-Name — Read entire docs
# operationId: guessNutritionByDishName
export def "recipes-guess-nutrition guessNutritionByDishName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the dish. (e.g. Spaghetti Aglio et Olio)
]: nothing -> record<calories: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, recipesUsed: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/guessNutrition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Recipe Information Bulk
#
# GET /recipes/informationBulk
# Docs: https://spoonacular.com/food-api/docs#Get-Recipe-Information-Bulk — Read entire docs
# operationId: getRecipeInformationBulk
export def "recipes-information-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # A comma-separated list of recipe ids. (e.g. 715538,716429)
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
]: nothing -> table<aggregateLikes: int, analyzedInstructions: list<string>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: list<record>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list, pairingText: string, productMatches: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "includeNutrition" $include_nutrition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/informationBulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parse Ingredients
#
# POST /recipes/parseIngredients
# Docs: https://spoonacular.com/food-api/docs#Parse-Ingredients — Read entire docs
# operationId: parseIngredients
export def "recipes-parse-ingredients parseIngredients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: record
]: any -> table<aisle: string, amount: float, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<string>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record, flavonoids: list, nutrients: list, properties: list, weightPerServing: record>, original: string, originalName: string, possibleUnits: list<string>, unit: string, unitLong: string, unitShort: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/parseIngredients" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Analyze a Recipe Search Query
#
# GET /recipes/queries/analyze
# Docs: https://spoonacular.com/food-api/docs#Analyze-a-Recipe-Search-Query — Read entire docs
# operationId: analyzeARecipeSearchQuery
export def "recipes-queries-analyze analyzeARecipeSearchQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The recipe search query. (e.g. salmon with fusilli and no nuts)
]: nothing -> record<cuisines: list<string>, dishes: table<image: string, name: string>, ingredients: table<image: string, include: bool, name: string>, modifiers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/queries/analyze" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Quick Answer
#
# GET /recipes/quickAnswer
# Docs: https://spoonacular.com/food-api/docs#Quick-Answer — Read entire docs
# operationId: quickAnswer
export def "recipes-quick-answer quickAnswer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The nutrition related question. (e.g. How much vitamin c is in 2 apples?)
]: nothing -> record<answer: string, image: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/quickAnswer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Random Recipes
#
# GET /recipes/random
# Docs: https://spoonacular.com/food-api/docs#Get-Random-Recipes — Read entire docs
# operationId: getRandomRecipes
export def "recipes-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
  --tags: string # The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must have.
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> record<recipes: table<aggregateLikes: float, analyzedInstructions: list, cheap: bool, creditsText: string, cuisines: list, dairyFree: bool, diets: list, dishTypes: list, extendedIngredients: list, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitLicense" $limit_license "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/random" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Equipment Widget
#
# POST /recipes/visualizeEquipment
# Docs: https://spoonacular.com/food-api/docs#Equipment-Widget — Read entire docs
# operationId: visualizeEquipment
export def "recipes-visualize-equipment visualizeEquipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipes/visualizeEquipment")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Ingredients Widget
#
# POST /recipes/visualizeIngredients
# Docs: https://spoonacular.com/food-api/docs#Ingredients-Widget — Read entire docs
# operationId: visualizeIngredients
export def "recipes-visualize-ingredients visualizeIngredients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/visualizeIngredients" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Recipe Nutrition Widget
#
# POST /recipes/visualizeNutrition
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Widget — Read entire docs
# operationId: visualizeRecipeNutrition
export def "recipes-visualize-nutrition visualizeRecipeNutrition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/visualizeNutrition" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Price Breakdown Widget
#
# POST /recipes/visualizePriceEstimator
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-Widget — Read entire docs
# operationId: visualizePriceBreakdown
export def "recipes-visualize-price-estimator visualizePriceBreakdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/visualizePriceEstimator" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Recipe Card
#
# POST /recipes/visualizeRecipe
# Docs: https://spoonacular.com/food-api/docs#Create-Recipe-Card — Read entire docs
# operationId: createRecipeCard
export def "recipes-visualize-recipe create-recipe-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: record
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipes/visualizeRecipe")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Recipe Taste Widget
#
# POST /recipes/visualizeTaste
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-Widget — Read entire docs
# operationId: visualizeRecipeTaste
export def "recipes-visualize-taste visualizeRecipeTaste" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --normalize: oneof<nothing, bool> # Whether to normalize to the strongest taste.
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "normalize" $normalize "scalar") (serialize-qp "rgb" $rgb "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/visualizeTaste" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Analyzed Recipe Instructions
#
# GET /recipes/{id}/analyzedInstructions
# Docs: https://spoonacular.com/food-api/docs#Get-Analyzed-Recipe-Instructions — Read entire docs
# operationId: getAnalyzedRecipeInstructions
export def "recipes-analyzed-instructions get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-breakdown: oneof<nothing, bool> # Whether to break down the recipe steps even more. (e.g. true)
]: nothing -> record<equipment: table<id: int, name: string>, ingredients: table<id: int, name: string>, parsedInstructions: table<name: string, steps: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stepBreakdown" $step_breakdown "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/analyzedInstructions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Recipe Card
#
# GET /recipes/{id}/card
# Docs: https://spoonacular.com/food-api/docs#Create-Recipe-Card — Read entire docs
# operationId: createRecipeCardGet
export def "recipes-card create-recipe-card-get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: string # The mask to put over the recipe image ("ellipseMask", "diamondMask", "starMask", "heartMask", "potMask", "fishMask"). (e.g. ellipseMask)
  --background-image: string # The background image ("none","background1", or "background2"). (e.g. background1)
  --background-color: string # The background color for the recipe card as a hex-string. (e.g. ffffff)
  --font-color: string # The font color for the recipe card as a hex-string. (e.g. 333333)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mask" $mask "scalar") (serialize-qp "backgroundImage" $background_image "scalar") (serialize-qp "backgroundColor" $background_color "scalar") (serialize-qp "fontColor" $font_color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/card") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Equipment by ID Widget
#
# GET /recipes/{id}/equipmentWidget
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID-Widget — Read entire docs
# operationId: visualizeRecipeEquipmentByID
export def "recipes-equipment-widget visualizeRecipeEquipmentByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/equipmentWidget") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Equipment by ID
#
# GET /recipes/{id}/equipmentWidget.json
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID — Read entire docs
# operationId: getRecipeEquipmentByID
export def "recipes-equipment-widgetjson get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<equipment: table<image: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/equipmentWidget.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Equipment by ID Image
#
# GET /recipes/{id}/equipmentWidget.png
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID-Image — Read entire docs
# operationId: equipmentByIDImage
export def "recipes-equipment-widgetpng equipmentByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/equipmentWidget.png"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Recipe Information
#
# GET /recipes/{id}/information
# Docs: https://spoonacular.com/food-api/docs#Get-Recipe-Information — Read entire docs
# operationId: getRecipeInformation
export def "recipes-information get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
]: nothing -> record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeNutrition" $include_nutrition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/information") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ingredients by ID Widget
#
# GET /recipes/{id}/ingredientWidget
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID-Widget — Read entire docs
# operationId: visualizeRecipeIngredientsByID
export def "recipes-ingredient-widget visualizeRecipeIngredientsByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --measure: string@measure-completer # Whether the the measures should be 'us' or 'metric'. (e.g. metric)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar") (serialize-qp "measure" $measure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/ingredientWidget") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ingredients by ID
#
# GET /recipes/{id}/ingredientWidget.json
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID — Read entire docs
# operationId: getRecipeIngredientsByID
export def "recipes-ingredient-widgetjson get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ingredients: table<amount: record, image: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/ingredientWidget.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ingredients by ID Image
#
# GET /recipes/{id}/ingredientWidget.png
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID-Image — Read entire docs
# operationId: ingredientsByIDImage
export def "recipes-ingredient-widgetpng ingredientsByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --measure: string@measure-completer # Whether the the measures should be 'us' or 'metric'. (e.g. metric)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "measure" $measure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/ingredientWidget.png") $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Nutrition Label Widget
#
# GET /recipes/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Label-Widget — Read entire docs
# operationId: recipeNutritionLabelWidget
export def "recipes-nutrition-label recipeNutritionLabelWidget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar") (serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/nutritionLabel") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Nutrition Label Image
#
# GET /recipes/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Label-Image — Read entire docs
# operationId: recipeNutritionLabelImage
export def "recipes-nutrition-labelpng recipeNutritionLabelImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showOptionalNutrients" $show_optional_nutrients "scalar") (serialize-qp "showZeroValues" $show_zero_values "scalar") (serialize-qp "showIngredients" $show_ingredients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/nutritionLabel.png") $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Nutrition by ID Widget
#
# GET /recipes/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-by-ID-Widget — Read entire docs
# operationId: visualizeRecipeNutritionByID
export def "recipes-nutrition-widget visualizeRecipeNutritionByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/nutritionWidget") $qp)
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Nutrition by ID
#
# GET /recipes/{id}/nutritionWidget.json
# Docs: https://spoonacular.com/food-api/docs#Nutrition-by-ID — Read entire docs
# operationId: getRecipeNutritionWidgetByID
export def "recipes-nutrition-widgetjson get-recipe-nutrition-widget" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bad: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, calories: string, carbs: string, fat: string, good: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, protein: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/nutritionWidget.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Nutrition by ID Image
#
# GET /recipes/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-by-ID-Image — Read entire docs
# operationId: recipeNutritionByIDImage
export def "recipes-nutrition-widgetpng recipeNutritionByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/nutritionWidget.png"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Price Breakdown by ID Widget
#
# GET /recipes/{id}/priceBreakdownWidget
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID-Widget — Read entire docs
# operationId: visualizeRecipePriceBreakdownByID
export def "recipes-price-breakdown-widget visualizeRecipePriceBreakdownByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "defaultCss" $default_css "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/priceBreakdownWidget") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Price Breakdown by ID
#
# GET /recipes/{id}/priceBreakdownWidget.json
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID — Read entire docs
# operationId: getRecipePriceBreakdownByID
export def "recipes-price-breakdown-widgetjson get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ingredients: table<amount: record, image: string, name: string, price: float>, totalCost: float, totalCostPerServing: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/priceBreakdownWidget.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Price Breakdown by ID Image
#
# GET /recipes/{id}/priceBreakdownWidget.png
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID-Image — Read entire docs
# operationId: priceBreakdownByIDImage
export def "recipes-price-breakdown-widgetpng priceBreakdownByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/priceBreakdownWidget.png"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Similar Recipes
#
# GET /recipes/{id}/similar
# Docs: https://spoonacular.com/food-api/docs#Get-Similar-Recipes — Read entire docs
# operationId: getSimilarRecipes
export def "recipes-similar get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "limitLicense" $limit_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/similar") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Summarize Recipe
#
# GET /recipes/{id}/summary
# Docs: https://spoonacular.com/food-api/docs#Summarize-Recipe — Read entire docs
# operationId: summarizeRecipe
export def "recipes-summary summarizeRecipe" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, summary: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/summary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Taste by ID Widget
#
# GET /recipes/{id}/tasteWidget
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-by-ID-Widget — Read entire docs
# operationId: visualizeRecipeTasteByID
export def "recipes-taste-widget visualizeRecipeTasteByID" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Whether to normalize to the strongest taste. (default: true, e.g. true)
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "normalize" $normalize "scalar") (serialize-qp "rgb" $rgb "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/tasteWidget") $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Taste by ID
#
# GET /recipes/{id}/tasteWidget.json
# Docs: https://spoonacular.com/food-api/docs#Taste-by-ID — Read entire docs
# operationId: getRecipeTasteByID
export def "recipes-taste-widgetjson get" [
  id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Normalize to the strongest taste. (default: true, e.g. true)
]: nothing -> record<bitterness: float, fattiness: float, saltiness: float, savoriness: float, sourness: float, spiciness: float, sweetness: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "normalize" $normalize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, id: $id} | format pattern "/recipes/{id}/tasteWidget.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recipe Taste by ID Image
#
# GET /recipes/{id}/tasteWidget.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-by-ID-Image — Read entire docs
# operationId: recipeTasteByIDImage
export def "recipes-taste-widgetpng recipeTasteByIDImage" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Normalize to the strongest taste. (e.g. false)
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "normalize" $normalize "scalar") (serialize-qp "rgb" $rgb "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/recipes/{id}/tasteWidget.png") $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect User
#
# POST /users/connect
# Docs: https://spoonacular.com/food-api/docs#Connect-User — Read entire docs
# operationId: connectUser
export def "users-connect connectUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  first_name: string
  last_name: string
  username: string
]: any -> record<hash: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/connect")
  let body = {"email": $email, "firstName": $first_name, "lastName": $last_name, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
