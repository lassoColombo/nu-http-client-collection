# Auto-generated client for API v2020-08-10_6-22
# Source: https://api.apis.guru/v2/specs/tl-api.azurewebsites.net/2020-08-10_6-22/openapi.json
# Auth: --token flag or $env.API_TOKEN

const BASE_URL = "https://tl-api.azurewebsites.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://tl-api.azurewebsites.net" "https://triviallife.azure-api.net/v1"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "article Delete" } } | get name | first)
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

# Delete article from the system             
#
# DELETE /api/Article
# operationId: Article_Delete
export def "article Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ArticleId: int # indentity number(primary key) for article object (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ArticleId" $ArticleId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new article             
#
# POST /api/Article
# operationId: Article_Post
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
# --gymArticles item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
export def "article Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activeStatus: oneof<nothing, bool> # Active Status 
  --applyForAllGyms: oneof<nothing, bool>
  --articleId: int # format: int32
  availableGyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --availableQty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --createdDate: string # format: date-time
  --createdUser: string # nullable
  --cronExpression: string # Access Schedule CRON Expression  (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employeeDiscount: float # Default EmployeeDiscount (format: decimal)
  --employeePrice: float # Default EmployeePrice (format: decimal)
  --gymArticles: list # Gym Customizations  (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --isAddOn: oneof<nothing, bool>
  --isInventoryItem: oneof<nothing, bool> # Default IsInventoryItem of the Article 
  --isObsolete: oneof<nothing, bool> # Default IsObsolete of the Article 
  measureUnit: string
  --modifiedDate: string # format: date-time
  --modifiedUser: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorderLevel: float # Deafault ReorderLevel (format: decimal)
  --revenueAccountId: int # Default Revenue account (format: int32)
  --sellingPrice: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vatApplicable: oneof<nothing, bool> # VAT Applicable 
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article")
  let body = {activeStatus: $activeStatus, applyForAllGyms: $applyForAllGyms, articleId: $articleId, availableGyms: $availableGyms, availableQty: $availableQty, barcode: $barcode, createdDate: $createdDate, createdUser: $createdUser, cronExpression: $cronExpression, description: $description, discount: $discount, employeeDiscount: $employeeDiscount, employeePrice: $employeePrice, gymArticles: $gymArticles, isAddOn: $isAddOn, isInventoryItem: $isInventoryItem, isObsolete: $isObsolete, measureUnit: $measureUnit, modifiedDate: $modifiedDate, modifiedUser: $modifiedUser, name: $name, number: $number, price: $price, reorderLevel: $reorderLevel, revenueAccountId: $revenueAccountId, sellingPrice: $sellingPrice, tags: $tags, type: $type, vat: $vat, vatApplicable: $vatApplicable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# update existing article             
#
# PUT /api/Article
# operationId: Article_Put
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
# --gymArticles item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
export def "article Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activeStatus: oneof<nothing, bool> # Active Status 
  --applyForAllGyms: oneof<nothing, bool>
  --articleId: int # format: int32
  availableGyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --availableQty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --createdDate: string # format: date-time
  --createdUser: string # nullable
  --cronExpression: string # Access Schedule CRON Expression  (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employeeDiscount: float # Default EmployeeDiscount (format: decimal)
  --employeePrice: float # Default EmployeePrice (format: decimal)
  --gymArticles: list # Gym Customizations  (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --isAddOn: oneof<nothing, bool>
  --isInventoryItem: oneof<nothing, bool> # Default IsInventoryItem of the Article 
  --isObsolete: oneof<nothing, bool> # Default IsObsolete of the Article 
  measureUnit: string
  --modifiedDate: string # format: date-time
  --modifiedUser: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorderLevel: float # Deafault ReorderLevel (format: decimal)
  --revenueAccountId: int # Default Revenue account (format: int32)
  --sellingPrice: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vatApplicable: oneof<nothing, bool> # VAT Applicable 
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article")
  let body = {activeStatus: $activeStatus, applyForAllGyms: $applyForAllGyms, articleId: $articleId, availableGyms: $availableGyms, availableQty: $availableQty, barcode: $barcode, createdDate: $createdDate, createdUser: $createdUser, cronExpression: $cronExpression, description: $description, discount: $discount, employeeDiscount: $employeeDiscount, employeePrice: $employeePrice, gymArticles: $gymArticles, isAddOn: $isAddOn, isInventoryItem: $isInventoryItem, isObsolete: $isObsolete, measureUnit: $measureUnit, modifiedDate: $modifiedDate, modifiedUser: $modifiedUser, name: $name, number: $number, price: $price, reorderLevel: $reorderLevel, revenueAccountId: $revenueAccountId, sellingPrice: $sellingPrice, tags: $tags, type: $type, vat: $vat, vatApplicable: $vatApplicable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add article details that associate with a Gym             
#
# PUT /api/Article/ArticleGymDetails
# operationId: Article_UpdateArticleGymDetails
export def "article-article-gym-details UpdateArticleGymDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/ArticleGymDetails")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/Article/GetAddons
#
# operationId: Article_GetAddons
export def "article-get-addons GetAddons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchText: string # Search text - will be search by the name (nullable)
  --gymIds: string # Comma separated gymIds deafult "-1" for all gyms (nullable, default: -1)
  --type: string # nullable, default: all
  --limit: int # format: int32, default: 100
  --offset: int # format: int32, default: 0
]: nothing -> record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $searchText "scalar") (serialize-qp "gymIds" $gymIds "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/GetAddons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gym specific properties for article             
#
# GET /api/Article/GymArticle/{articleId}/{gymId}
# operationId: Article_GymArticleDetails
export def "article-gym-article GymArticleDetails" [
  articleId: int
  gymId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<articleId: int, availableQty: float, createdUser: string, employeeDiscount: float, employeePrice: float, gymId: int, gymIdList: string, gymName: string, id: int, isDefault: bool, isInventoryItem: bool, isObsolete: bool, modifiedUser: string, reorderLevel: float, revenueAccountId: int, sellingPrice: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Article/GymArticle/($articleId)/($gymId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add measure unit
#
# POST /api/Article/MeasureUnit
# operationId: Article_AddMeasureUnit
export def "article-measure-unit AddMeasureUnit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/MeasureUnit")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mesure units
#
# GET /api/Article/MeasureUnits
# operationId: Article_GetMeasureUnits
export def "article-measure-units GetMeasureUnits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # type of the measure unit (all, item, service) (nullable)
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/MeasureUnits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Revenue Accounts 
#
# GET /api/Article/RevenueAccounts
# operationId: Article_GetRevenueAccounts
export def "article-revenue-accounts GetRevenueAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/RevenueAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search articles It will only return basic information of article             
#
# GET /api/Article/Search
# operationId: Article_Search
export def "article-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchText: string # part of article name (nullable)
  --gymId: int # -1 for all gyms  (format: int32, default: -1)
  --type: string # filter article type. default is 'all' (nullable, default: all)
  --orderBy: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --activeStatus: int # Active Status 1 : Active, 2: Inactive, 3: All, Default : 1 (format: int32, default: 1)
]: nothing -> record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $searchText "scalar") (serialize-qp "gymId" $gymId "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "activeStatus" $activeStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/Search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivate existing article 
#
# PUT /api/Article/UpdateStatus
# operationId: Article_UpdateStatus
export def "article-update-status UpdateStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ArticleId: int # format: int32
  --status: int # 1 : activate , 2 deactivate (format: int32)
  --userName: string # Updating user (nullable)
]: nothing -> record<isError: bool, message: string, responseException: any, result: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ArticleId" $ArticleId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/UpdateStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get article details This will return all properties related to article entity             
#
# GET /api/Article/{articleID}
# operationId: Article_get
export def "article get" [
  articleID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Article/($articleID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authenticate and provide token for autherizations.             
#
# POST /api/Auth/login
# operationId: Auth_Login
export def "auth-login Login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # nullable
  --remember: oneof<nothing, bool>
  --username: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Auth/login")
  let body = {password: $password, remember: $remember, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get gym details This will return all properties related to gym entity             
#
# GET /api/Gym/{gymID}
# operationId: Gym_get
export def "gym get" [
  gymID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Gym/($gymID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all of the members details This will return all properties related to member entity             
#
# GET /api/Membership
# operationId: Membership_Get
export def "membership Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Membership")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new Member             
#
# POST /api/Membership
# operationId: Membership_Post
export def "membership Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Membership")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete existing package             
#
# DELETE /api/Package
# operationId: Package_Delete
export def "package Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PackageId: int # primary key of package entity (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PackageId" $PackageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get package details by packageId             
#
# GET /api/Package
# operationId: Package_Get
export def "package Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --packageId: int # primary key of package entity (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packageId" $packageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert new package into the system             
#
# POST /api/Package
# operationId: Package_Post
# --addOns item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
export def "package Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addOns: list # Extra articles list added to the given package.              (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addonFee: float # sum of addon fees. incoming values for this filed will ignore.              (format: decimal)
  --applyForAllGyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.             
  --availableGyms: list # Gyms list where this package is available.              (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --bindingPeriod: int # Range of period a member is bound to the contract if he/she choose this package.              (format: int32)
  --createdDate: string # Package created DateTime.              (format: date-time)
  --createdUser: string # Package created user.              (nullable)
  --description: string # Common descriptions about package.If there are more instructions               can be stored as comma separated values.              (nullable)
  --endDate: string # End date of the package.After that package is not valid for use.              (format: date-time)
  --expireInMonths: int # No of months the fixed package is valid for sale              (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values.              (nullable)
  --freeMonths: int # No of months gym member can come without payments.              (format: int32)
  --instructionsToGymUsers: string # Instruction to the gym members relevant to the package.              If there are more instructions can be stored as comma seperated values.              (nullable)
  --instructionsToWebUsers: string # Instruction to the MRM members relevant to the package.              If there are more instructions can be stored as comma seperated values.              (nullable)
  --isActive: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.             
  --isAtg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.             
  --isAutoRenew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration               if this package would be chosen.             
  --isFirstMonthFree: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.             
  --isRegistrationFee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.             
  --isRestAmount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.             
  --isShownInMobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.             
  --isSponsorPackage: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.             
  --maximumGiveAwayRestAmount: float # If a member join the gym middle of a month via this package,               what is the maximum amount of price can be neglected from payment from the member.              (format: decimal)
  --memberCanAddAddOns: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.             
  --memberCanLeaveWithinFreePeriod: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within               free period if he/she choose this package.             
  --memberCanRemoveAddOns: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.             
  --modifiedDate: string # Package last modified DateTime.              (format: date-time)
  --modifiedUser: string # Package last modified user.              (nullable)
  --monthlyFee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period.              read only              (format: decimal)
  --nextPackageNumber: int # Next Package the contract continue after the binding period of this package.              (format: int32)
  --numberOfInstallments: int # Maximum Number of installment a member can divide the package price/cost to pay.              (format: int32)
  --numberOfVisits: int # If package is fixed visit type, then how many visits are available for this package.              (format: int32)
  --packageId: int # format: int32
  packageName: string
  --packageNumber: string # nullable
  packageType: string # Package type can be either fixed visit or unlimited.             
  --perVisitPrice: float # Cost/Price of the single visit to gym.              (format: decimal)
  registrationFee: float # Registartion fee for the package at a gym.              read only              (format: decimal)
  serviceFee: float # total Service charge of the package for entire period.              (format: decimal)
  --shownInWeb: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.             
  --startDate: string # Start date of the package.              (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of               stuff relevant to the package.              (nullable)
  --totalPrice: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore.              (format: decimal)
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Package")
  let body = {addOns: $addOns, addonFee: $addonFee, applyForAllGyms: $applyForAllGyms, availableGyms: $availableGyms, bindingPeriod: $bindingPeriod, createdDate: $createdDate, createdUser: $createdUser, description: $description, endDate: $endDate, expireInMonths: $expireInMonths, features: $features, freeMonths: $freeMonths, instructionsToGymUsers: $instructionsToGymUsers, instructionsToWebUsers: $instructionsToWebUsers, isActive: $isActive, isAtg: $isAtg, isAutoRenew: $isAutoRenew, isFirstMonthFree: $isFirstMonthFree, isRegistrationFee: $isRegistrationFee, isRestAmount: $isRestAmount, isShownInMobile: $isShownInMobile, isSponsorPackage: $isSponsorPackage, maximumGiveAwayRestAmount: $maximumGiveAwayRestAmount, memberCanAddAddOns: $memberCanAddAddOns, memberCanLeaveWithinFreePeriod: $memberCanLeaveWithinFreePeriod, memberCanRemoveAddOns: $memberCanRemoveAddOns, modifiedDate: $modifiedDate, modifiedUser: $modifiedUser, monthlyFee: $monthlyFee, nextPackageNumber: $nextPackageNumber, numberOfInstallments: $numberOfInstallments, numberOfVisits: $numberOfVisits, packageId: $packageId, packageName: $packageName, packageNumber: $packageNumber, packageType: $packageType, perVisitPrice: $perVisitPrice, registrationFee: $registrationFee, serviceFee: $serviceFee, shownInWeb: $shownInWeb, startDate: $startDate, tags: $tags, totalPrice: $totalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update existing package by its ID             
#
# PUT /api/Package
# operationId: Package_Put
# --addOns item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
export def "package Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addOns: list # Extra articles list added to the given package.              (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addonFee: float # sum of addon fees. incoming values for this filed will ignore.              (format: decimal)
  --applyForAllGyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.             
  --availableGyms: list # Gyms list where this package is available.              (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --bindingPeriod: int # Range of period a member is bound to the contract if he/she choose this package.              (format: int32)
  --createdDate: string # Package created DateTime.              (format: date-time)
  --createdUser: string # Package created user.              (nullable)
  --description: string # Common descriptions about package.If there are more instructions               can be stored as comma separated values.              (nullable)
  --endDate: string # End date of the package.After that package is not valid for use.              (format: date-time)
  --expireInMonths: int # No of months the fixed package is valid for sale              (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values.              (nullable)
  --freeMonths: int # No of months gym member can come without payments.              (format: int32)
  --instructionsToGymUsers: string # Instruction to the gym members relevant to the package.              If there are more instructions can be stored as comma seperated values.              (nullable)
  --instructionsToWebUsers: string # Instruction to the MRM members relevant to the package.              If there are more instructions can be stored as comma seperated values.              (nullable)
  --isActive: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.             
  --isAtg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.             
  --isAutoRenew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration               if this package would be chosen.             
  --isFirstMonthFree: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.             
  --isRegistrationFee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.             
  --isRestAmount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.             
  --isShownInMobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.             
  --isSponsorPackage: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.             
  --maximumGiveAwayRestAmount: float # If a member join the gym middle of a month via this package,               what is the maximum amount of price can be neglected from payment from the member.              (format: decimal)
  --memberCanAddAddOns: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.             
  --memberCanLeaveWithinFreePeriod: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within               free period if he/she choose this package.             
  --memberCanRemoveAddOns: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.             
  --modifiedDate: string # Package last modified DateTime.              (format: date-time)
  --modifiedUser: string # Package last modified user.              (nullable)
  --monthlyFee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period.              read only              (format: decimal)
  --nextPackageNumber: int # Next Package the contract continue after the binding period of this package.              (format: int32)
  --numberOfInstallments: int # Maximum Number of installment a member can divide the package price/cost to pay.              (format: int32)
  --numberOfVisits: int # If package is fixed visit type, then how many visits are available for this package.              (format: int32)
  --packageId: int # format: int32
  packageName: string
  --packageNumber: string # nullable
  packageType: string # Package type can be either fixed visit or unlimited.             
  --perVisitPrice: float # Cost/Price of the single visit to gym.              (format: decimal)
  registrationFee: float # Registartion fee for the package at a gym.              read only              (format: decimal)
  serviceFee: float # total Service charge of the package for entire period.              (format: decimal)
  --shownInWeb: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.             
  --startDate: string # Start date of the package.              (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of               stuff relevant to the package.              (nullable)
  --totalPrice: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore.              (format: decimal)
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Package")
  let body = {addOns: $addOns, addonFee: $addonFee, applyForAllGyms: $applyForAllGyms, availableGyms: $availableGyms, bindingPeriod: $bindingPeriod, createdDate: $createdDate, createdUser: $createdUser, description: $description, endDate: $endDate, expireInMonths: $expireInMonths, features: $features, freeMonths: $freeMonths, instructionsToGymUsers: $instructionsToGymUsers, instructionsToWebUsers: $instructionsToWebUsers, isActive: $isActive, isAtg: $isAtg, isAutoRenew: $isAutoRenew, isFirstMonthFree: $isFirstMonthFree, isRegistrationFee: $isRegistrationFee, isRestAmount: $isRestAmount, isShownInMobile: $isShownInMobile, isSponsorPackage: $isSponsorPackage, maximumGiveAwayRestAmount: $maximumGiveAwayRestAmount, memberCanAddAddOns: $memberCanAddAddOns, memberCanLeaveWithinFreePeriod: $memberCanLeaveWithinFreePeriod, memberCanRemoveAddOns: $memberCanRemoveAddOns, modifiedDate: $modifiedDate, modifiedUser: $modifiedUser, monthlyFee: $monthlyFee, nextPackageNumber: $nextPackageNumber, numberOfInstallments: $numberOfInstallments, numberOfVisits: $numberOfVisits, packageId: $packageId, packageName: $packageName, packageNumber: $packageNumber, packageType: $packageType, perVisitPrice: $perVisitPrice, registrationFee: $registrationFee, serviceFee: $serviceFee, shownInWeb: $shownInWeb, startDate: $startDate, tags: $tags, totalPrice: $totalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search packages             
#
# GET /api/Package/Search
# operationId: Package_Search
export def "package-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchText: string # part of package name (nullable)
  --gymId: int # primary key of TL gym entity (format: int32, default: -1)
  --type: string # filter package type.!-- default is 'all' (nullable, default: all)
  --orderBy: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --activeStatus: int # active status active : 1, inactive : 2, all 3, deafult : 1 (format: int32, default: 1)
  --categoryId: int # Packge Category Id (format: int32, default: -1)
  --startpPrice: float # Start price of the price Range (format: decimal, default: 0)
  --endPrice: float # End Price of the price Range (format: decimal, default: 9999999)
  --requestSource: int # 1 : MRM, 2 : Mobile  (format: int32, default: 1)
]: nothing -> table<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $searchText "scalar") (serialize-qp "gymId" $gymId "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "activeStatus" $activeStatus "scalar") (serialize-qp "categoryId" $categoryId "scalar") (serialize-qp "startpPrice" $startpPrice "scalar") (serialize-qp "endPrice" $endPrice "scalar") (serialize-qp "requestSource" $requestSource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package/Search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Status update of existing package 
#
# PUT /api/Package/UpdateStatus
# operationId: Package_UpdateStatus
export def "package-update-status UpdateStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --packageId: int # package Id (format: int32)
  --status: int # status : 1 activate, 2 : deactivate (format: int32, default: 1)
  --userName: string # Status updated User (nullable, default: system)
]: nothing -> record<isError: bool, message: string, responseException: any, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packageId" $packageId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package/UpdateStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the current status of message
#
# GET /api/Status
# operationId: Status_Get
export def "status Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --messageId: string # respose of POST request (nullable)
]: nothing -> record<messageId: string, referenceId: int, source: any, statusId: int, statusText: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "messageId" $messageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the all Test objects.             
#
# GET /api/Test
# operationId: Test_get
export def "test get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Users detail This will return all properties related to User entity             
#
# GET /api/User
# operationId: User_Get
export def "user Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountNumber: string, externalEntityNumber: string, guardian: int, gymNumber: string, introduceBy: int, name: string, number: string, typeId: int, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a new User             
#
# POST /api/User/registerUser
# operationId: User_registerUser
export def "user-register-user registerUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UserId: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record.              (format: int32)
  --AccountNumber: string # Account number of the user.It can be any stakeholder of the application.even can be a gym.              (nullable)
  --GymNumber: string # If this user is a gym, then the gym number.              (nullable)
  --ExternalEntityNumber: string # Entity number that make a relationship with BOX API DB.              (nullable)
  --Name: string # Name of the user.              (nullable)
  --Number: string # Unique number maintain by application to idenify user.              (nullable)
  --IntroduceBy: int # If Someone introduced this user to the system, then that user's UserId.              (format: int32)
  --Guardian: int # Gaurdian of the this user if he/she is under 18 years old.              (format: int32)
  --TypeId: int # Type of the user.              (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $UserId "scalar") (serialize-qp "AccountNumber" $AccountNumber "scalar") (serialize-qp "GymNumber" $GymNumber "scalar") (serialize-qp "ExternalEntityNumber" $ExternalEntityNumber "scalar") (serialize-qp "Name" $Name "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "IntroduceBy" $IntroduceBy "scalar") (serialize-qp "Guardian" $Guardian "scalar") (serialize-qp "TypeId" $TypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/User/registerUser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an exsisting User             
#
# PUT /api/User/updateuser
# operationId: User_updateUser
export def "user-updateuser updateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UserId: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record.              (format: int32)
  --AccountNumber: string # Account number of the user.It can be any stakeholder of the application.even can be a gym.              (nullable)
  --GymNumber: string # If this user is a gym, then the gym number.              (nullable)
  --ExternalEntityNumber: string # Entity number that make a relationship with BOX API DB.              (nullable)
  --Name: string # Name of the user.              (nullable)
  --Number: string # Unique number maintain by application to idenify user.              (nullable)
  --IntroduceBy: int # If Someone introduced this user to the system, then that user's UserId.              (format: int32)
  --Guardian: int # Gaurdian of the this user if he/she is under 18 years old.              (format: int32)
  --TypeId: int # Type of the user.              (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $UserId "scalar") (serialize-qp "AccountNumber" $AccountNumber "scalar") (serialize-qp "GymNumber" $GymNumber "scalar") (serialize-qp "ExternalEntityNumber" $ExternalEntityNumber "scalar") (serialize-qp "Name" $Name "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "IntroduceBy" $IntroduceBy "scalar") (serialize-qp "Guardian" $Guardian "scalar") (serialize-qp "TypeId" $TypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/User/updateuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
