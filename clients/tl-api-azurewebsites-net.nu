# Auto-generated client for API v2020-08-10_6-22
# Source: https://api.apis.guru/v2/specs/tl-api.azurewebsites.net/2020-08-10_6-22/openapi.json
# Auth: --token flag or $env.API_TOKEN

const BASE_URL = "https://tl-api.azurewebsites.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://tl-api.azurewebsites.net" "https://triviallife.azure-api.net/v1"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "article delete" } } | get name | first)
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
export def "article delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: int # indentity number(primary key) for article object (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ArticleId" $article_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ArticleId": $article_id} | compact), body: null}
}

# Add new article
#
# POST /api/Article
# operationId: Article_Post
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
# --gymArticles item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
export def "article create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-status: oneof<nothing, bool> # Active Status
  --apply-for-all-gyms: oneof<nothing, bool>
  --article-id: int # format: int32
  available_gyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --available-qty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --created-date: string # format: date-time
  --created-user: string # nullable
  --cron-expression: string # Access Schedule CRON Expression (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employee-discount: float # Default EmployeeDiscount (format: decimal)
  --employee-price: float # Default EmployeePrice (format: decimal)
  --gym-articles: list # Gym Customizations (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --is-add-on: oneof<nothing, bool>
  --is-inventory-item: oneof<nothing, bool> # Default IsInventoryItem of the Article
  --is-obsolete: oneof<nothing, bool> # Default IsObsolete of the Article
  measure_unit: string
  --modified-date: string # format: date-time
  --modified-user: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorder-level: float # Deafault ReorderLevel (format: decimal)
  --revenue-account-id: int # Default Revenue account (format: int32)
  --selling-price: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vat-applicable: oneof<nothing, bool> # VAT Applicable
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article")
  let req_body = {"activeStatus": $active_status, "applyForAllGyms": $apply_for_all_gyms, "articleId": $article_id, "availableGyms": $available_gyms, "availableQty": $available_qty, "barcode": $barcode, "createdDate": $created_date, "createdUser": $created_user, "cronExpression": $cron_expression, "description": $description, "discount": $discount, "employeeDiscount": $employee_discount, "employeePrice": $employee_price, "gymArticles": $gym_articles, "isAddOn": $is_add_on, "isInventoryItem": $is_inventory_item, "isObsolete": $is_obsolete, "measureUnit": $measure_unit, "modifiedDate": $modified_date, "modifiedUser": $modified_user, "name": $name, "number": $number, "price": $price, "reorderLevel": $reorder_level, "revenueAccountId": $revenue_account_id, "sellingPrice": $selling_price, "tags": $tags, "type": $type, "vat": $vat, "vatApplicable": $vat_applicable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# update existing article
#
# PUT /api/Article
# operationId: Article_Put
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
# --gymArticles item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
export def "article update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-status: oneof<nothing, bool> # Active Status
  --apply-for-all-gyms: oneof<nothing, bool>
  --article-id: int # format: int32
  available_gyms: list # item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --available-qty: float # Default AvailableQty (format: decimal)
  --barcode: string # nullable
  --created-date: string # format: date-time
  --created-user: string # nullable
  --cron-expression: string # Access Schedule CRON Expression (nullable)
  --description: string # nullable
  --discount: float # format: decimal
  --employee-discount: float # Default EmployeeDiscount (format: decimal)
  --employee-price: float # Default EmployeePrice (format: decimal)
  --gym-articles: list # Gym Customizations (nullable) — item shape: {articleId?: int, availableQty?: float, createdUser?: string, employeeDiscount?: float, employeePrice?: float, gymId?: int, gymIdList?: string, gymName?: string, id?: int, isDefault?: bool, isInventoryItem?: bool, isObsolete?: bool, modifiedUser?: string, reorderLevel?: float, revenueAccountId?: int, sellingPrice?: float}
  --is-add-on: oneof<nothing, bool>
  --is-inventory-item: oneof<nothing, bool> # Default IsInventoryItem of the Article
  --is-obsolete: oneof<nothing, bool> # Default IsObsolete of the Article
  measure_unit: string
  --modified-date: string # format: date-time
  --modified-user: string # nullable
  name: string
  --number: int # format: int32
  price: float # format: decimal
  --reorder-level: float # Deafault ReorderLevel (format: decimal)
  --revenue-account-id: int # Default Revenue account (format: int32)
  --selling-price: float # Default SellingPrice (format: decimal)
  --tags: string # nullable
  type: string
  --vat: float # format: decimal
  --vat-applicable: oneof<nothing, bool> # VAT Applicable
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article")
  let req_body = {"activeStatus": $active_status, "applyForAllGyms": $apply_for_all_gyms, "articleId": $article_id, "availableGyms": $available_gyms, "availableQty": $available_qty, "barcode": $barcode, "createdDate": $created_date, "createdUser": $created_user, "cronExpression": $cron_expression, "description": $description, "discount": $discount, "employeeDiscount": $employee_discount, "employeePrice": $employee_price, "gymArticles": $gym_articles, "isAddOn": $is_add_on, "isInventoryItem": $is_inventory_item, "isObsolete": $is_obsolete, "measureUnit": $measure_unit, "modifiedDate": $modified_date, "modifiedUser": $modified_user, "name": $name, "number": $number, "price": $price, "reorderLevel": $reorder_level, "revenueAccountId": $revenue_account_id, "sellingPrice": $selling_price, "tags": $tags, "type": $type, "vat": $vat, "vatApplicable": $vat_applicable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add article details that associate with a Gym
#
# PUT /api/Article/ArticleGymDetails
# operationId: Article_UpdateArticleGymDetails
export def "article-article-gym-details update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/ArticleGymDetails")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/Article/GetAddons
#
# operationId: Article_GetAddons
export def "article-get-addons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # Search text - will be search by the name (nullable)
  --gym-ids: string # Comma separated gymIds deafult "-1" for all gyms (nullable, default: -1)
  --type: string # nullable, default: all
  --limit: int # format: int32, default: 100
  --offset: int # format: int32, default: 0
]: nothing -> record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $search_text "scalar") (serialize-qp "gymIds" $gym_ids "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/GetAddons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"searchText": $search_text, "gymIds": $gym_ids, "type": $type, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Get Gym specific properties for article
#
# GET /api/Article/GymArticle/{articleId}/{gymId}
# operationId: Article_GymArticleDetails
export def "article-gym-article get-details" [
  article_id: int
  gym_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<articleId: int, availableQty: float, createdUser: string, employeeDiscount: float, employeePrice: float, gymId: int, gymIdList: string, gymName: string, id: int, isDefault: bool, isInventoryItem: bool, isObsolete: bool, modifiedUser: string, reorderLevel: float, revenueAccountId: int, sellingPrice: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleId' must be non-empty" } }
  if ($gym_id | is-empty) { error make --unspanned { msg: "path parameter 'gymId' must be non-empty" } }
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id), gym_id: (encode-path-segment $gym_id)} | format pattern "/api/Article/GymArticle/{article_id}/{gym_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add measure unit
#
# POST /api/Article/MeasureUnit
# operationId: Article_AddMeasureUnit
export def "article-measure-unit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/MeasureUnit")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get mesure units
#
# GET /api/Article/MeasureUnits
# operationId: Article_GetMeasureUnits
export def "article-measure-units get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # type of the measure unit (all, item, service) (nullable)
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/MeasureUnits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type} | compact), body: null}
}

# Get Revenue Accounts
#
# GET /api/Article/RevenueAccounts
# operationId: Article_GetRevenueAccounts
export def "article-revenue-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Article/RevenueAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search articles It will only return basic information of article
#
# GET /api/Article/Search
# operationId: Article_Search
export def "article-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # part of article name (nullable)
  --gym-id: int # -1 for all gyms (format: int32, default: -1)
  --type: string # filter article type. default is 'all' (nullable, default: all)
  --order-by: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --active-status: int # Active Status 1 : Active, 2: Inactive, 3: All, Default : 1 (format: int32, default: 1)
]: nothing -> record<isError: bool, message: string, responseException: any, result: table<activeStatus: bool, applyForAllGyms: bool, articleId: int, createdDate: string, createdUser: string, description: string, measureUnit: string, modifiedDate: string, modifiedUser: string, name: string, number: int, price: float, sellingPrice: float, tags: string, totalCount: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $search_text "scalar") (serialize-qp "gymId" $gym_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "activeStatus" $active_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/Search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"searchText": $search_text, "gymId": $gym_id, "type": $type, "orderBy": $order_by, "limit": $limit, "offset": $offset, "activeStatus": $active_status} | compact), body: null}
}

# Deactivate existing article
#
# PUT /api/Article/UpdateStatus
# operationId: Article_UpdateStatus
export def "article-update-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article-id: int # format: int32
  --status: int # 1 : activate , 2 deactivate (format: int32)
  --user-name: string # Updating user (nullable)
]: nothing -> record<isError: bool, message: string, responseException: any, result: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ArticleId" $article_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Article/UpdateStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ArticleId": $article_id, "status": $status, "userName": $user_name} | compact), body: null}
}

# Get article details This will return all properties related to article entity
#
# GET /api/Article/{articleID}
# operationId: Article_get
export def "article get" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($article_id | is-empty) { error make --unspanned { msg: "path parameter 'articleID' must be non-empty" } }
  let full_url = (build-url $base ({article_id: (encode-path-segment $article_id)} | format pattern "/api/Article/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Authenticate and provide token for autherizations.
#
# POST /api/Auth/login
# operationId: Auth_Login
export def "auth-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # nullable
  --remember: oneof<nothing, bool>
  --username: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Auth/login")
  let req_body = {"password": $password, "remember": $remember, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get gym details This will return all properties related to gym entity
#
# GET /api/Gym/{gymID}
# operationId: Gym_get
export def "gym get" [
  gym_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gym_id | is-empty) { error make --unspanned { msg: "path parameter 'gymID' must be non-empty" } }
  let full_url = (build-url $base ({gym_id: (encode-path-segment $gym_id)} | format pattern "/api/Gym/{gym_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all of the members details This will return all properties related to member entity
#
# GET /api/Membership
# operationId: Membership_Get
export def "membership get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Membership")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add new Member
#
# POST /api/Membership
# operationId: Membership_Post
export def "membership create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Membership")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete existing package
#
# DELETE /api/Package
# operationId: Package_Delete
export def "package delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # primary key of package entity (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PackageId" $package_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PackageId": $package_id} | compact), body: null}
}

# Get package details by packageId
#
# GET /api/Package
# operationId: Package_Get
export def "package get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # primary key of package entity (format: int32)
]: nothing -> record<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packageId" $package_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"packageId": $package_id} | compact), body: null}
}

# Insert new package into the system
#
# POST /api/Package
# operationId: Package_Post
# --addOns item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
export def "package create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-ons: list # Extra articles list added to the given package. (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addon-fee: float # sum of addon fees. incoming values for this filed will ignore. (format: decimal)
  --apply-for-all-gyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.
  --available-gyms: list # Gyms list where this package is available. (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --binding-period: int # Range of period a member is bound to the contract if he/she choose this package. (format: int32)
  --created-date: string # Package created DateTime. (format: date-time)
  --created-user: string # Package created user. (nullable)
  --description: string # Common descriptions about package.If there are more instructions can be stored as comma separated values. (nullable)
  --end-date: string # End date of the package.After that package is not valid for use. (format: date-time)
  --expire-in-months: int # No of months the fixed package is valid for sale (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values. (nullable)
  --free-months: int # No of months gym member can come without payments. (format: int32)
  --instructions-to-gym-users: string # Instruction to the gym members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --instructions-to-web-users: string # Instruction to the MRM members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --is-active: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.
  --is-atg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.
  --is-auto-renew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration if this package would be chosen.
  --is-first-month-free: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.
  --is-registration-fee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.
  --is-rest-amount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.
  --is-shown-in-mobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.
  --is-sponsor-package: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.
  --maximum-give-away-rest-amount: float # If a member join the gym middle of a month via this package, what is the maximum amount of price can be neglected from payment from the member. (format: decimal)
  --member-can-add-add-ons: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.
  --member-can-leave-within-free-period: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within free period if he/she choose this package.
  --member-can-remove-add-ons: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.
  --modified-date: string # Package last modified DateTime. (format: date-time)
  --modified-user: string # Package last modified user. (nullable)
  --monthly-fee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period. read only (format: decimal)
  --next-package-number: int # Next Package the contract continue after the binding period of this package. (format: int32)
  --number-of-installments: int # Maximum Number of installment a member can divide the package price/cost to pay. (format: int32)
  --number-of-visits: int # If package is fixed visit type, then how many visits are available for this package. (format: int32)
  --package-id: int # format: int32
  package_name: string
  --package-number: string # nullable
  package_type: string # Package type can be either fixed visit or unlimited.
  --per-visit-price: float # Cost/Price of the single visit to gym. (format: decimal)
  registration_fee: float # Registartion fee for the package at a gym. read only (format: decimal)
  service_fee: float # total Service charge of the package for entire period. (format: decimal)
  --shown-in-web: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.
  --start-date: string # Start date of the package. (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of stuff relevant to the package. (nullable)
  --total-price: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore. (format: decimal)
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Package")
  let req_body = {"addOns": $add_ons, "addonFee": $addon_fee, "applyForAllGyms": $apply_for_all_gyms, "availableGyms": $available_gyms, "bindingPeriod": $binding_period, "createdDate": $created_date, "createdUser": $created_user, "description": $description, "endDate": $end_date, "expireInMonths": $expire_in_months, "features": $features, "freeMonths": $free_months, "instructionsToGymUsers": $instructions_to_gym_users, "instructionsToWebUsers": $instructions_to_web_users, "isActive": $is_active, "isAtg": $is_atg, "isAutoRenew": $is_auto_renew, "isFirstMonthFree": $is_first_month_free, "isRegistrationFee": $is_registration_fee, "isRestAmount": $is_rest_amount, "isShownInMobile": $is_shown_in_mobile, "isSponsorPackage": $is_sponsor_package, "maximumGiveAwayRestAmount": $maximum_give_away_rest_amount, "memberCanAddAddOns": $member_can_add_add_ons, "memberCanLeaveWithinFreePeriod": $member_can_leave_within_free_period, "memberCanRemoveAddOns": $member_can_remove_add_ons, "modifiedDate": $modified_date, "modifiedUser": $modified_user, "monthlyFee": $monthly_fee, "nextPackageNumber": $next_package_number, "numberOfInstallments": $number_of_installments, "numberOfVisits": $number_of_visits, "packageId": $package_id, "packageName": $package_name, "packageNumber": $package_number, "packageType": $package_type, "perVisitPrice": $per_visit_price, "registrationFee": $registration_fee, "serviceFee": $service_fee, "shownInWeb": $shown_in_web, "startDate": $start_date, "tags": $tags, "totalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update existing package by its ID
#
# PUT /api/Package
# operationId: Package_Put
# --addOns item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
# --availableGyms item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
export def "package update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-ons: list # Extra articles list added to the given package. (nullable) — item shape: {articleId: int, articleName?: string, articleNumber?: int, articlePrice?: float, endOrder?: int, isIncludeServiceInCharge?: bool, measureUnit?: string, numberOfItems?: float, startOrder?: int}
  --addon-fee: float # sum of addon fees. incoming values for this filed will ignore. (format: decimal)
  --apply-for-all-gyms: oneof<nothing, bool> # Boolean value to indicate wheather package is available in all the gyms.
  --available-gyms: list # Gyms list where this package is available. (nullable) — item shape: {externalGymNumber?: int, gymId?: int, gymName?: string, location?: string}
  --binding-period: int # Range of period a member is bound to the contract if he/she choose this package. (format: int32)
  --created-date: string # Package created DateTime. (format: date-time)
  --created-user: string # Package created user. (nullable)
  --description: string # Common descriptions about package.If there are more instructions can be stored as comma separated values. (nullable)
  --end-date: string # End date of the package.After that package is not valid for use. (format: date-time)
  --expire-in-months: int # No of months the fixed package is valid for sale (format: int32)
  --features: string # What are the facilities, features available for package.ex:- wifi, ACm etc.Can be stored as comma seperated values. (nullable)
  --free-months: int # No of months gym member can come without payments. (format: int32)
  --instructions-to-gym-users: string # Instruction to the gym members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --instructions-to-web-users: string # Instruction to the MRM members relevant to the package. If there are more instructions can be stored as comma seperated values. (nullable)
  --is-active: oneof<nothing, bool> # Boolean value to indicate this package is still active or not.
  --is-atg: oneof<nothing, bool> # Boolean value to indicate ATG transaction from bank is applicable or not.
  --is-auto-renew: oneof<nothing, bool> # Boolean value to indicate the contract will auto renew after expiration if this package would be chosen.
  --is-first-month-free: oneof<nothing, bool> # Boolean value to indicate if the first month charges is free.
  --is-registration-fee: oneof<nothing, bool> # Boolean value to indicate this package has registration fee or not.
  --is-rest-amount: oneof<nothing, bool> # Boolean value to indicate rest amount is applicable or not.
  --is-shown-in-mobile: oneof<nothing, bool> # Boolean value to indicate package is visible in Mobile App or not.
  --is-sponsor-package: oneof<nothing, bool> # Boolean value to indicate package can be sponsored or not by other party.
  --maximum-give-away-rest-amount: float # If a member join the gym middle of a month via this package, what is the maximum amount of price can be neglected from payment from the member. (format: decimal)
  --member-can-add-add-ons: oneof<nothing, bool> # Boolean value to indicate member can add extra addons he wish if he choose this package.
  --member-can-leave-within-free-period: oneof<nothing, bool> # Boolean value to indicate if member can leave from contract within free period if he/she choose this package.
  --member-can-remove-add-ons: oneof<nothing, bool> # Boolean value to indicate member can remove already added addons if he choose this package.
  --modified-date: string # Package last modified DateTime. (format: date-time)
  --modified-user: string # Package last modified user. (nullable)
  --monthly-fee: float # Monthly installment fee if package is not fixed visit. addition of the servicefee and addon fees divided by binding period. read only (format: decimal)
  --next-package-number: int # Next Package the contract continue after the binding period of this package. (format: int32)
  --number-of-installments: int # Maximum Number of installment a member can divide the package price/cost to pay. (format: int32)
  --number-of-visits: int # If package is fixed visit type, then how many visits are available for this package. (format: int32)
  --package-id: int # format: int32
  package_name: string
  --package-number: string # nullable
  package_type: string # Package type can be either fixed visit or unlimited.
  --per-visit-price: float # Cost/Price of the single visit to gym. (format: decimal)
  registration_fee: float # Registartion fee for the package at a gym. read only (format: decimal)
  service_fee: float # total Service charge of the package for entire period. (format: decimal)
  --shown-in-web: oneof<nothing, bool> # Boolean value to show this package in MRM system or not.
  --start-date: string # Start date of the package. (format: date-time)
  --tags: string # Comma separated string values in case of need of maintain some labels kind of stuff relevant to the package. (nullable)
  --total-price: float # total price for the package including Addon fees, service fee and registration fee. incoming values for this field will ignore. (format: decimal)
]: any -> record<isError: bool, message: string, responseException: any, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Package")
  let req_body = {"addOns": $add_ons, "addonFee": $addon_fee, "applyForAllGyms": $apply_for_all_gyms, "availableGyms": $available_gyms, "bindingPeriod": $binding_period, "createdDate": $created_date, "createdUser": $created_user, "description": $description, "endDate": $end_date, "expireInMonths": $expire_in_months, "features": $features, "freeMonths": $free_months, "instructionsToGymUsers": $instructions_to_gym_users, "instructionsToWebUsers": $instructions_to_web_users, "isActive": $is_active, "isAtg": $is_atg, "isAutoRenew": $is_auto_renew, "isFirstMonthFree": $is_first_month_free, "isRegistrationFee": $is_registration_fee, "isRestAmount": $is_rest_amount, "isShownInMobile": $is_shown_in_mobile, "isSponsorPackage": $is_sponsor_package, "maximumGiveAwayRestAmount": $maximum_give_away_rest_amount, "memberCanAddAddOns": $member_can_add_add_ons, "memberCanLeaveWithinFreePeriod": $member_can_leave_within_free_period, "memberCanRemoveAddOns": $member_can_remove_add_ons, "modifiedDate": $modified_date, "modifiedUser": $modified_user, "monthlyFee": $monthly_fee, "nextPackageNumber": $next_package_number, "numberOfInstallments": $number_of_installments, "numberOfVisits": $number_of_visits, "packageId": $package_id, "packageName": $package_name, "packageNumber": $package_number, "packageType": $package_type, "perVisitPrice": $per_visit_price, "registrationFee": $registration_fee, "serviceFee": $service_fee, "shownInWeb": $shown_in_web, "startDate": $start_date, "tags": $tags, "totalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search packages
#
# GET /api/Package/Search
# operationId: Package_Search
export def "package-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # part of package name (nullable)
  --gym-id: int # primary key of TL gym entity (format: int32, default: -1)
  --type: string # filter package type.!-- default is 'all' (nullable, default: all)
  --order-by: string # order by column.!-- invalid column will give internal server error (nullable, default: 1)
  --limit: int # number of recode in result and default is 100. use negative numbers to order by desc (format: int32, default: 100)
  --offset: int # number of recodes to skip (format: int32, default: 0)
  --active-status: int # active status active : 1, inactive : 2, all 3, deafult : 1 (format: int32, default: 1)
  --category-id: int # Packge Category Id (format: int32, default: -1)
  --startp-price: float # Start price of the price Range (format: decimal, default: 0)
  --end-price: float # End Price of the price Range (format: decimal, default: 9999999)
  --request-source: int # 1 : MRM, 2 : Mobile (format: int32, default: 1)
]: nothing -> table<isError: bool, message: string, responseException: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $search_text "scalar") (serialize-qp "gymId" $gym_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "activeStatus" $active_status "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "startpPrice" $startp_price "scalar") (serialize-qp "endPrice" $end_price "scalar") (serialize-qp "requestSource" $request_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package/Search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"searchText": $search_text, "gymId": $gym_id, "type": $type, "orderBy": $order_by, "limit": $limit, "offset": $offset, "activeStatus": $active_status, "categoryId": $category_id, "startpPrice": $startp_price, "endPrice": $end_price, "requestSource": $request_source} | compact), body: null}
}

# Status update of existing package
#
# PUT /api/Package/UpdateStatus
# operationId: Package_UpdateStatus
export def "package-update-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: int # package Id (format: int32)
  --status: int # status : 1 activate, 2 : deactivate (format: int32, default: 1)
  --user-name: string # Status updated User (nullable, default: system)
]: nothing -> record<isError: bool, message: string, responseException: any, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packageId" $package_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Package/UpdateStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"packageId": $package_id, "status": $status, "userName": $user_name} | compact), body: null}
}

# Get the current status of message
#
# GET /api/Status
# operationId: Status_Get
export def "status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # respose of POST request (nullable)
]: nothing -> record<messageId: string, referenceId: int, source: any, statusId: int, statusText: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "messageId" $message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"messageId": $message_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all Users detail This will return all properties related to User entity
#
# GET /api/User
# operationId: User_Get
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountNumber: string, externalEntityNumber: string, guardian: int, gymNumber: string, introduceBy: int, name: string, number: string, typeId: int, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a new User
#
# POST /api/User/registerUser
# operationId: User_registerUser
export def "user-register-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record. (format: int32)
  --account-number: string # Account number of the user.It can be any stakeholder of the application.even can be a gym. (nullable)
  --gym-number: string # If this user is a gym, then the gym number. (nullable)
  --external-entity-number: string # Entity number that make a relationship with BOX API DB. (nullable)
  --name: string # Name of the user. (nullable)
  --number: string # Unique number maintain by application to idenify user. (nullable)
  --introduce-by: int # If Someone introduced this user to the system, then that user's UserId. (format: int32)
  --guardian: int # Gaurdian of the this user if he/she is under 18 years old. (format: int32)
  --type-id: int # Type of the user. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $user_id "scalar") (serialize-qp "AccountNumber" $account_number "scalar") (serialize-qp "GymNumber" $gym_number "scalar") (serialize-qp "ExternalEntityNumber" $external_entity_number "scalar") (serialize-qp "Name" $name "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "IntroduceBy" $introduce_by "scalar") (serialize-qp "Guardian" $guardian "scalar") (serialize-qp "TypeId" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/User/registerUser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"UserId": $user_id, "AccountNumber": $account_number, "GymNumber": $gym_number, "ExternalEntityNumber": $external_entity_number, "Name": $name, "Number": $number, "IntroduceBy": $introduce_by, "Guardian": $guardian, "TypeId": $type_id} | compact), body: null}
}

# Update an exsisting User
#
# PUT /api/User/updateuser
# operationId: User_updateUser
export def "user-updateuser update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Indentity number(primary key) for user object. Generated in DB table when inserting a record. (format: int32)
  --account-number: string # Account number of the user.It can be any stakeholder of the application.even can be a gym. (nullable)
  --gym-number: string # If this user is a gym, then the gym number. (nullable)
  --external-entity-number: string # Entity number that make a relationship with BOX API DB. (nullable)
  --name: string # Name of the user. (nullable)
  --number: string # Unique number maintain by application to idenify user. (nullable)
  --introduce-by: int # If Someone introduced this user to the system, then that user's UserId. (format: int32)
  --guardian: int # Gaurdian of the this user if he/she is under 18 years old. (format: int32)
  --type-id: int # Type of the user. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $user_id "scalar") (serialize-qp "AccountNumber" $account_number "scalar") (serialize-qp "GymNumber" $gym_number "scalar") (serialize-qp "ExternalEntityNumber" $external_entity_number "scalar") (serialize-qp "Name" $name "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "IntroduceBy" $introduce_by "scalar") (serialize-qp "Guardian" $guardian "scalar") (serialize-qp "TypeId" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/User/updateuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"UserId": $user_id, "AccountNumber": $account_number, "GymNumber": $gym_number, "ExternalEntityNumber": $external_entity_number, "Name": $name, "Number": $number, "IntroduceBy": $introduce_by, "Guardian": $guardian, "TypeId": $type_id} | compact), body: null}
}
