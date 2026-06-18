# Auto-generated client for 1,000,000+ Recipe and Grocery List API (v2) vpartner
# Source: https://api.apis.guru/v2/specs/bigoven.com/partner/openapi.json
# Auth: --token flag or $env.1_000_000_RECIPE_AND_GROCERY_LIST_API__V2_TOKEN

const BASE_URL = "https://api2.bigoven.com"
const DEFAULT_AUTH = "x-bigoven-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o 1_000_000_RECIPE_AND_GROCERY_LIST_API__V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-bigoven-api-key" => { {headers: {X-BigOven-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api2.bigoven.com"] }
def auth-scheme-completer [] { ["x-bigoven-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "collection get" } } | get name | first)
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

# Gets a recipe collection. A recipe collection is a curated set of recipes.
#
# GET /collection/{id}
# operationId: Collection_GetCollection
export def "collection get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rpp: int # results per page (format: int32)
  --pg: int # page number (starting with 1) (format: int32)
  --test: oneof<nothing, bool>
  --session-for-logging: string
]: nothing -> record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rpp" $rpp "scalar") (serialize-qp "pg" $pg "scalar") (serialize-qp "test" $test "scalar") (serialize-qp "sessionForLogging" $session_for_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/collection/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a recipe collection metadata. A recipe collection is a curated set of recipes.
#
# GET /collection/{id}/meta
# operationId: Collection_GetCollectionMeta
export def "collection-meta get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Title: string, Token: string, WebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/collection/{id}/meta"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the list of current, seasonal recipe collections. From here, you can use the /collection/{id} endpoint to retrieve the recipes in those collections.
#
# GET /collections
# operationId: Collection_Collections
export def "collections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --test: string
]: nothing -> table<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: list<record>, Title: string, Token: string, WebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete all the items on a grocery list; faster operation than a sync with deleted items.
#
# DELETE /grocerylist
# operationId: GroceryList_Delete
export def "grocerylist list-grocery-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the user's grocery list. User is determined by Basic Authentication.
#
# GET /grocerylist
# operationId: GroceryList_Get
export def "grocerylist list-grocery-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Clears the checked lines.
#
# POST /grocerylist/clearcheckedlines
# operationId: GroceryList_GroceryListRemoveMarkedItems
export def "grocerylist-clearcheckedlines list-grocery-grocery-list-delete-marked-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/clearcheckedlines")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Departmentalize a list of strings -- used for ad-hoc grocery list item addition
#
# POST /grocerylist/department
# operationId: GroceryList_Department
export def "grocerylist-department list-grocery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --items: string # Gets or sets the items.
]: any -> table<dept: string, item: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/department")
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add a single line item to the grocery list
#
# POST /grocerylist/item
export def "grocerylist-item create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department: string # Gets or sets the department.
  --name: string # Gets or sets the name.
  --notes: string # Gets or sets the notes.
  --quantity: string # Gets or sets the quantity.
  --unit: string # Gets or sets the unit.
]: any -> record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/item")
  let req_body = {"department": $department, "name": $name, "notes": $notes, "quantity": $quantity, "unit": $unit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# /grocerylist/item/{guid} DELETE will delete this item assuming you own it.
#
# DELETE /grocerylist/item/{guid}
# operationId: GroceryList_DeleteItemByGuid
export def "grocerylist-item list-grocery-delete" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/grocerylist/item/{guid}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a grocery item by GUID
#
# PUT /grocerylist/item/{guid}
# operationId: GroceryList_GroceryListItemGuid
export def "grocerylist-item list-grocery-grocery-list" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department: string # Gets or sets the department.
  --body-guid: string # Gets or sets the unique identifier.
  --ischecked: oneof<nothing, bool> # Gets or sets the ischecked.
  --name: string # Gets or sets the name.
  --notes: string # Gets or sets the notes.
  --quantity: string # Gets or sets the quantity.
  --unit: string # Gets or sets the unit.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/grocerylist/item/{guid}"))
  let req_body = {"department": $department, "guid": $body_guid, "ischecked": $ischecked, "name": $name, "notes": $notes, "quantity": $quantity, "unit": $unit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add a single line item to the grocery list
#
# POST /grocerylist/line
# operationId: GroceryList_Post
export def "grocerylist-line list-grocery-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string # Gets or sets the text.
]: any -> record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/line")
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add a Recipe to the grocery list. In the request data, pass in recipeId, scale (scale=1.0 says to keep the recipe the same size as originally posted), markAsPending (true/false) to indicate that the lines in the recipe should be marked in a "pending" (unconfirmed by user) state.
#
# POST /grocerylist/recipe
# operationId: GroceryList_AddRecipe
export def "grocerylist-recipe list-grocery-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --mark-as-pending: oneof<nothing, bool> # Gets or sets the mark as pending.
  --recipe-id: int # Gets or sets the recipe identifier. (format: int32)
  --scale: float # Gets or sets the scale. (format: double)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/recipe")
  let req_body = {"markAsPending": $mark_as_pending, "recipeId": $recipe_id, "scale": $scale} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Synchronize the grocery list. Call this with a POST to /grocerylist/sync
#
# POST /grocerylist/sync
# operationId: GroceryList_PostGroceryListSync
# --list shape: {Items?: list, LastModified?: string, Recipes?: list, VersionGuid?: string}
export def "grocerylist-sync list-grocery-create-grocery-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --list: record # shape: {Items?: list, LastModified?: string, Recipes?: list, VersionGuid?: string}
  --since: string # Gets or sets the since.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grocerylist/sync")
  let req_body = {"list": $list, "since": $since} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST: /image/avatar Testing with Postman (validated 11/20/2015): 1) Remove the Content-Type header; add authentication information 2) On the request, click Body and choose "form-data", then add a line item with "key" column set to "file" and on the right, change the type of the input from Text to File. Browse and choose a JPG.
#
# POST /image/avatar
# operationId: Images_UploadUserAvatar
export def "image-avatar upload-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/image/avatar")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Indexes this instance.
#
# GET /me
# operationId: Me_Index
export def "me get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Puts me.
#
# PUT /me
# operationId: Me_PutMe
# --Accounting shape: {CreditBalance?: int, MemberSince?: string, PremiumExpiryDate?: string, UserLevel?: string}
# --Personal shape: {Email?: string, Location?: record}
# --Preferences shape: {EatingStyle?: string}
# --Profile shape: {AboutMe?: string, BackgroundUrl?: string, Counts?: record, FirstName?: string, FullName?: string, HomeUrl?: string, LastName?: string, PhotoUrl?: string, UserID?: int, UserName?: string}
export def "me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accounting: record # shape: {CreditBalance?: int, MemberSince?: string, PremiumExpiryDate?: string, UserLevel?: string}
  --bo-auth-token: string # The user-specific authentication token
  --last-change-log-id: string # Last change log
  --personal: record # Personal level info -- email, location, etc. — shape: {Email?: string, Location?: record}
  --preferences: record # shape: {EatingStyle?: string}
  --profile: record # shape: {AboutMe?: string, BackgroundUrl?: string, Counts?: record, FirstName?: string, FullName?: string, HomeUrl?: string, LastName?: string, PhotoUrl?: string, UserID?: int, UserName?: string}
]: any -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let req_body = {"Accounting": $accounting, "BOAuthToken": $bo_auth_token, "LastChangeLogID": $last_change_log_id, "Personal": $personal, "Preferences": $preferences, "Profile": $profile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Puts me personal.
#
# PUT /me/personal
# operationId: Me_PutMePersonal
# --Location shape: {City?: string, Country?: string, DMA?: int}
export def "me-personal update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string
  --location: record # shape: {City?: string, Country?: string, DMA?: int}
]: any -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/personal")
  let req_body = {"Email": $email, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Puts me preferences.
#
# PUT /me/preferences
# operationId: Me_PutMePreferences
export def "me-preferences update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --eating-style: string
]: any -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/preferences")
  let req_body = {"EatingStyle": $eating_style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the options.
#
# GET /me/preferences/options
# operationId: Me_GetOptions
export def "me-preferences-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<EatingStyle: record<Options: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/preferences/options")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Puts me.
#
# PUT /me/profile
# --Counts shape: {AddedCount?: int, FollowersCount?: int, FollowingCount?: int, PrivateRecipeCount?: int, PublicRecipeCount?: int, TotalRecipes?: int}
export def "me-profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --about-me: string
  --background-url: string
  --counts: record # shape: {AddedCount?: int, FollowersCount?: int, FollowingCount?: int, PrivateRecipeCount?: int, PublicRecipeCount?: int, TotalRecipes?: int}
  --first-name: string
  --full-name: string
  --home-url: string
  --last-name: string
  --photo-url: string
  --user-id: int # format: int64
  --user-name: string
]: any -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/profile")
  let req_body = {"AboutMe": $about_me, "BackgroundUrl": $background_url, "Counts": $counts, "FirstName": $first_name, "FullName": $full_name, "HomeUrl": $home_url, "LastName": $last_name, "PhotoUrl": $photo_url, "UserID": $user_id, "UserName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Skinnies this instance.
#
# GET /me/skinny
# operationId: Me_Skinny
export def "me-skinny get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/skinny")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add a new recipe
#
# POST /recipe
# operationId: Recipe_Post
# --Ingredients item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
# --NutritionInfo shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
# --Poster shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
export def "recipe create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --ad-tags: string
  --admin-boost: int # format: int32
  --all-categories-text: string
  --bookmark-image-url: string
  --bookmark-site-logo: string
  --bookmark-url: string
  --category: string
  --collection: string
  --collection-id: int # format: int32
  --creation-date: string # format: date-time
  --cuisine: string
  --description: string
  --favorite-count: int # format: int32
  --hero-photo-url: string
  --image-squares: list<int>
  --image-url: string
  --ingredients: list # item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
  --ingredients-text-block: string
  --instructions: string
  --is-bookmark: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --is-recipe-scan: oneof<nothing, bool>
  --is-sponsored: oneof<nothing, bool>
  --last-modified: string # format: date-time
  --max-image-square: int # format: int32
  --medal-count: int # format: int32
  --menu-count: int # format: int32
  --microcategory: string
  --notes-count: int # format: int32
  --nutrition-info: record # shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
  --poster: record # shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
  --primary-ingredient: string
  --recipe-id: int # format: int32
  --review-count: int # format: int32
  --star-rating: float # format: double
  --subcategory: string
  --title: string
  --total-minutes: int # format: int32
  --variant-of-recipe-id: int # format: int32
  --verified-by-class: string
  --verified-date-time: string # format: date-time
  --web-url: string
  --yield-number: float # format: double
  --yield-unit: string
]: any -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipe")
  let req_body = {"ActiveMinutes": $active_minutes, "AdTags": $ad_tags, "AdminBoost": $admin_boost, "AllCategoriesText": $all_categories_text, "BookmarkImageURL": $bookmark_image_url, "BookmarkSiteLogo": $bookmark_site_logo, "BookmarkURL": $bookmark_url, "Category": $category, "Collection": $collection, "CollectionID": $collection_id, "CreationDate": $creation_date, "Cuisine": $cuisine, "Description": $description, "FavoriteCount": $favorite_count, "HeroPhotoUrl": $hero_photo_url, "ImageSquares": $image_squares, "ImageURL": $image_url, "Ingredients": $ingredients, "IngredientsTextBlock": $ingredients_text_block, "Instructions": $instructions, "IsBookmark": $is_bookmark, "IsPrivate": $is_private, "IsRecipeScan": $is_recipe_scan, "IsSponsored": $is_sponsored, "LastModified": $last_modified, "MaxImageSquare": $max_image_square, "MedalCount": $medal_count, "MenuCount": $menu_count, "Microcategory": $microcategory, "NotesCount": $notes_count, "NutritionInfo": $nutrition_info, "Poster": $poster, "PrimaryIngredient": $primary_ingredient, "RecipeID": $recipe_id, "ReviewCount": $review_count, "StarRating": $star_rating, "Subcategory": $subcategory, "Title": $title, "TotalMinutes": $total_minutes, "VariantOfRecipeID": $variant_of_recipe_id, "VerifiedByClass": $verified_by_class, "VerifiedDateTime": $verified_date_time, "WebURL": $web_url, "YieldNumber": $yield_number, "YieldUnit": $yield_unit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update a recipe
#
# PUT /recipe
# operationId: Recipe_Put
# --Ingredients item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
# --NutritionInfo shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
# --Poster shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
export def "recipe update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --ad-tags: string
  --admin-boost: int # format: int32
  --all-categories-text: string
  --bookmark-image-url: string
  --bookmark-site-logo: string
  --bookmark-url: string
  --category: string
  --collection: string
  --collection-id: int # format: int32
  --creation-date: string # format: date-time
  --cuisine: string
  --description: string
  --favorite-count: int # format: int32
  --hero-photo-url: string
  --image-squares: list<int>
  --image-url: string
  --ingredients: list # item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
  --ingredients-text-block: string
  --instructions: string
  --is-bookmark: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --is-recipe-scan: oneof<nothing, bool>
  --is-sponsored: oneof<nothing, bool>
  --last-modified: string # format: date-time
  --max-image-square: int # format: int32
  --medal-count: int # format: int32
  --menu-count: int # format: int32
  --microcategory: string
  --notes-count: int # format: int32
  --nutrition-info: record # shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
  --poster: record # shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
  --primary-ingredient: string
  --recipe-id: int # format: int32
  --review-count: int # format: int32
  --star-rating: float # format: double
  --subcategory: string
  --title: string
  --total-minutes: int # format: int32
  --variant-of-recipe-id: int # format: int32
  --verified-by-class: string
  --verified-date-time: string # format: date-time
  --web-url: string
  --yield-number: float # format: double
  --yield-unit: string
]: any -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipe")
  let req_body = {"ActiveMinutes": $active_minutes, "AdTags": $ad_tags, "AdminBoost": $admin_boost, "AllCategoriesText": $all_categories_text, "BookmarkImageURL": $bookmark_image_url, "BookmarkSiteLogo": $bookmark_site_logo, "BookmarkURL": $bookmark_url, "Category": $category, "Collection": $collection, "CollectionID": $collection_id, "CreationDate": $creation_date, "Cuisine": $cuisine, "Description": $description, "FavoriteCount": $favorite_count, "HeroPhotoUrl": $hero_photo_url, "ImageSquares": $image_squares, "ImageURL": $image_url, "Ingredients": $ingredients, "IngredientsTextBlock": $ingredients_text_block, "Instructions": $instructions, "IsBookmark": $is_bookmark, "IsPrivate": $is_private, "IsRecipeScan": $is_recipe_scan, "IsSponsored": $is_sponsored, "LastModified": $last_modified, "MaxImageSquare": $max_image_square, "MedalCount": $medal_count, "MenuCount": $menu_count, "Microcategory": $microcategory, "NotesCount": $notes_count, "NutritionInfo": $nutrition_info, "Poster": $poster, "PrimaryIngredient": $primary_ingredient, "RecipeID": $recipe_id, "ReviewCount": $review_count, "StarRating": $star_rating, "Subcategory": $subcategory, "Title": $title, "TotalMinutes": $total_minutes, "VariantOfRecipeID": $variant_of_recipe_id, "VerifiedByClass": $verified_by_class, "VerifiedDateTime": $verified_date_time, "WebURL": $web_url, "YieldNumber": $yield_number, "YieldUnit": $yield_unit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Given a query, return recipe titles starting with query. Query must be at least 3 chars in length.
#
# GET /recipe/autocomplete
# operationId: Recipe_AutoComplete
export def "recipe-autocomplete complete-auto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string
  --limit: int # format: int32
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/autocomplete" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Automatics the complete all recipes.
#
# GET /recipe/autocomplete/all
# operationId: Recipe_AutoCompleteAllRecipes
export def "recipe-autocomplete-all complete-auto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query.
  --limit: int # The limit. (format: int32)
]: nothing -> table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/autocomplete/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Automatics the complete my recipes.
#
# GET /recipe/autocomplete/mine
# operationId: Recipe_AutoCompleteMyRecipes
export def "recipe-autocomplete-mine complete-auto-my" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query.
  --limit: int # The limit. (format: int32)
]: nothing -> table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/autocomplete/mine" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of recipe categories (the ID field can be used for include_cat in search parameters)
#
# GET /recipe/categories
# operationId: Recipe_Categories
export def "recipe-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Category: string, DefaultActiveMinutes: int, DefaultTotalMinutes: int, ID: int, ParentID: int, PrimaryImage: string, ShortDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipe/categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns last active recipe for the user
#
# GET /recipe/get/active/recipe
# operationId: Recipe_GetActiveRecipe
export def "recipe-get-active-recipe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string
]: nothing -> record<Data: record, Message: string, StatusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/get/active/recipe" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets recipe single step as text
#
# POST /recipe/get/saved/step
# operationId: Recipe_GetStep
export def "recipe-get-saved-step get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string
  --recipe-id: int # format: int32
  --step-id: int # format: int32
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "recipeId" $recipe_id "scalar") (serialize-qp "stepId" $step_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/get/saved/step" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns stored step number and number of steps in recipe
#
# POST /recipe/get/step/number
# operationId: Recipe_GetStepNumber
export def "recipe-get-step-number get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string
  --recipe-id: int # format: int32
]: nothing -> record<Data: record, Message: string, StatusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "recipeId" $recipe_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/get/step/number" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the pending by user.
#
# GET /recipe/photos/pending
# operationId: Images_GetPendingByUser
export def "recipe-photos-pending get-images-by-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipe/photos/pending")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Stores recipe step number and returns saved step data
#
# POST /recipe/post/step
# operationId: Recipe_GetSteps
export def "recipe-post-step get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string
  --recipe-id: int # format: int32
  --step-id: int # format: int32
]: nothing -> record<Data: record, Message: string, StatusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "recipeId" $recipe_id "scalar") (serialize-qp "stepId" $step_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/post/step" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DELETE a reply to a given review. Authenticated user must be the one who originally posted the reply.
#
# DELETE /recipe/review/replies/{replyId}
# operationId: Review_DeleteReply
export def "recipe-review-replies delete-reply" [
  reply_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reply_id: (encode-path-segment $reply_id)} | format pattern "/recipe/review/replies/{reply_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update (PUT) a reply to a given review. Authenticated user must be the original one that posted the reply.
#
# PUT /recipe/review/replies/{replyId}
# operationId: Review_PutReply
export def "recipe-review-replies update-reply" [
  reply_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # The comment. If mentioning any user(s) (optional), include them as @username in the text body. Do not use @ symbol for anything but mentioning @usernames.
]: any -> record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reply_id: (encode-path-segment $reply_id)} | format pattern "/recipe/review/replies/{reply_id}"))
  let req_body = {"Comment": $comment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a given review by string-style ID. This will return a payload with FeaturedReply, ReplyCount. Recommended display is to list top-level reviews with one featured reply underneath. Currently, the FeaturedReply is the most recent one for that rating.
#
# GET /recipe/review/{reviewId}
export def "recipe-review get-by-reviewId" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/recipe/review/{review_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a given top-level review.
#
# PUT /recipe/review/{reviewId}
# operationId: Review_Put
export def "recipe-review update" [
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
  --accept: string@accept-completer # Response content type
  --active-minutes: int # How many minutes of ACTIVE time (i.e., actively working on the recipe, not waiting for rising, baking, etc.) did it demand of the cook? Optional. (format: int32)
  --comment: string # The notes
  --make-again: string # "yes" or "no"
  --star-rating: int # 1, 2, 3, 4, or 5 (format: int32)
  --total-minutes: int # How long, start to finish, in minutes (integer) did it take? Optional. (format: int32)
]: any -> record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/recipe/review/{review_id}"))
  let req_body = {"ActiveMinutes": $active_minutes, "Comment": $comment, "MakeAgain": $make_again, "StarRating": $star_rating, "TotalMinutes": $total_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a paged list of replies for a given review.
#
# GET /recipe/review/{reviewId}/replies
# operationId: Review_GetReplies
export def "recipe-review-replies get" [
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
  --accept: string@accept-completer # Response content type
  --pg: int # the page (int), starting with 1 (format: int32)
  --rpp: int # results per page (int) (format: int32)
]: nothing -> table<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/recipe/review/{review_id}/replies") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST a reply to a given review. The date will be set by server. Note that replies no longer have star ratings, only top-level reviews do.
#
# POST /recipe/review/{reviewId}/replies
# operationId: Review_PostReply
export def "recipe-review-replies create-reply" [
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
  --accept: string@accept-completer # Response content type
  --comment: string # The comment. If mentioning any user(s) (optional), include them as @username in the text body. Do not use @ symbol for anything but mentioning @usernames.
]: any -> record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/recipe/review/{review_id}/replies"))
  let req_body = {"Comment": $comment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST an image as a new RecipeScan request 1) Fetch the filename -- DONE 2) Copy it to the pics/scan folder - ENSURE NO NAMING COLLISIONS -- DONE 3) Create 120 thumbnail size in pics/scan/120 -- DONE 4) Insert the CloudTasks record 5) Create the HIT 6) Update the CloudTasks record with the HIT ID 7) Email the requesing user 8) Call out to www.bigoven.com to fetch the image and re-create the thumbnail
#
# POST /recipe/scan
# operationId: Recipe_Scan
export def "recipe-scan create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test: oneof<nothing, bool>
  --devicetype: string
  --lat: float # format: double
  --lng: float # format: double
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test" $test "scalar") (serialize-qp "devicetype" $devicetype "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipe/scan" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return full Recipe detail with steps. Returns 403 if the recipe is owned by someone else.
#
# GET /recipe/steps/{id}
# operationId: Recipe_GetRecipeWithSteps
export def "recipe-steps get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool>
]: nothing -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefetch" $prefetch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recipe/steps/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete a Recipe (you must be authenticated as an owner of the recipe)
#
# DELETE /recipe/{id}
# operationId: Recipe_Delete
export def "recipe delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recipe/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return full Recipe detail. Returns 403 if the recipe is owned by someone else.
#
# GET /recipe/{id}
# operationId: Recipe_Get
export def "recipe get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool> # The prefetch.
]: nothing -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefetch" $prefetch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recipe/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Zaps the recipe.
#
# GET /recipe/{id}/zap
# operationId: Recipe_ZapRecipe
export def "recipe-zap get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recipe/{id}/zap"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Feedback on a Recipe -- for internal BigOven editors
#
# POST /recipe/{recipeId}/feedback
# operationId: Recipe_Feedback
export def "recipe-feedback create" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feedback: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/feedback"))
  let req_body = {"feedback": $feedback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST: /recipe/{recipeId}/image?lat=42&lng=21&caption=this%20is%20my%20caption Note that caption, lng and lat are all optional, but must go on the request URI as params because this endpoint needs a multipart/mime content header and will not parse JSON in the body along with it. Testing with Postman (validated 11/20/2015): 1) Remove the Content-Type header; add authentication information 2) On the request, click Body and choose "form-data", then add a line item with "key" column set to "file" and on the right, change the type of the input from Text to File. Browse and choose a JPG.
#
# POST /recipe/{recipeId}/image
# operationId: Images_UploadRecipeImage
export def "recipe-image upload" [
  recipe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --caption: string
  --lat: float # format: double
  --lng: float # format: double
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "caption" $caption "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/image") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all the images for a recipe. DEPRECATED. Please use /recipe/{recipeId}/photos.
#
# GET /recipe/{recipeId}/images
# operationId: Images_Get
export def "recipe-images get" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/images"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# HTTP POST a new note into the system.
#
# POST /recipe/{recipeId}/note
# operationId: Note_Post
export def "recipe-note create" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # Gets or sets the creation date. (format: date-time)
  --date: string # Gets or sets the date. (format: date-time)
  --date-dt: string # Gets or sets the date dt.
  --guid: string # Gets or sets the unique identifier.
  --id: int # Gets or sets the identifier. (format: int32)
  --notes: string # Gets or sets the notes.
  --people: string # Gets or sets the people.
  --body-recipe-id: int # Gets or sets the recipe identifier. (format: int32)
  --user-id: int # Gets or sets the user identifier. (format: int32)
  --variations: string # Gets or sets the variations.
]: any -> record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/note"))
  let req_body = {"CreationDate": $creation_date, "Date": $date, "DateDT": $date_dt, "GUID": $guid, "ID": $id, "Notes": $notes, "People": $people, "RecipeID": $body_recipe_id, "UserID": $user_id, "Variations": $variations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a review do a DELETE Http request of /note/{ID}
#
# DELETE /recipe/{recipeId}/note/{noteId}
# operationId: Note_Delete
export def "recipe-note delete" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), note_id: (encode-path-segment $note_id)} | format pattern "/recipe/{recipe_id}/note/{note_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a given note. Make sure you're passing authentication information in the header for the user who owns the note.
#
# GET /recipe/{recipeId}/note/{noteId}
# operationId: Note_Get
export def "recipe-note get" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), note_id: (encode-path-segment $note_id)} | format pattern "/recipe/{recipe_id}/note/{note_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# HTTP PUT (update) a Recipe note (RecipeNote).
#
# PUT /recipe/{recipeId}/note/{noteId}
# operationId: Note_Put
export def "recipe-note update" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # Gets or sets the creation date. (format: date-time)
  --date: string # Gets or sets the date. (format: date-time)
  --date-dt: string # Gets or sets the date dt.
  --guid: string # Gets or sets the unique identifier.
  --id: int # Gets or sets the identifier. (format: int32)
  --notes: string # Gets or sets the notes.
  --people: string # Gets or sets the people.
  --body-recipe-id: int # Gets or sets the recipe identifier. (format: int32)
  --user-id: int # Gets or sets the user identifier. (format: int32)
  --variations: string # Gets or sets the variations.
]: any -> record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), note_id: (encode-path-segment $note_id)} | format pattern "/recipe/{recipe_id}/note/{note_id}"))
  let req_body = {"CreationDate": $creation_date, "Date": $date, "DateDT": $date_dt, "GUID": $guid, "ID": $id, "Notes": $notes, "People": $people, "RecipeID": $body_recipe_id, "UserID": $user_id, "Variations": $variations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# recipe/100/notes
#
# GET /recipe/{recipeId}/notes
# operationId: Note_GetNotes
export def "recipe-notes get" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # page (int, starting from 1) (format: int32)
  --rpp: int # recipeId (format: int32)
]: nothing -> record<ResultCount: int, Results: table<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/notes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all the photos for a recipe
#
# GET /recipe/{recipeId}/photos
# operationId: Images_GetRecipePhotos
export def "recipe-photos get-images" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # format: int32
  --rpp: int # format: int32
]: nothing -> record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/photos") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get recipes related to the given recipeId
#
# GET /recipe/{recipeId}/related
# operationId: Recipe_Related
export def "recipe-related get" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # The page (format: int32)
  --rpp: int # The results per page (format: int32)
]: nothing -> record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/related") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get *my* review for the recipe {recipeId}, where "me" is determined by standard authentication headers
#
# GET /recipe/{recipeId}/review
export def "recipe-review get-by-recipeId" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/review"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add a new review. Only one review can be provided per {userId, recipeId} pair. Otherwise your review will be updated.
#
# POST /recipe/{recipeId}/review
# operationId: Review_Post
export def "recipe-review create" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # How many minutes of ACTIVE time (i.e., actively working on the recipe, not waiting for rising, baking, etc.) did it demand of the cook? Optional. (format: int32)
  --comment: string # The notes
  --make-again: string # "yes" or "no"
  --star-rating: int # 1, 2, 3, 4, or 5 (format: int32)
  --total-minutes: int # How long, start to finish, in minutes (integer) did it take? Optional. (format: int32)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/review"))
  let req_body = {"ActiveMinutes": $active_minutes, "Comment": $comment, "MakeAgain": $make_again, "StarRating": $star_rating, "TotalMinutes": $total_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DEPRECATED! - Deletes a review by recipeId and reviewId. Please use recipe/review/{reviewId} instead.
#
# DELETE /recipe/{recipeId}/review/{reviewId}
# operationId: Review_Delete
export def "recipe-review delete" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), review_id: (encode-path-segment $review_id)} | format pattern "/recipe/{recipe_id}/review/{review_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a given review - DEPRECATED. See recipe/review/{reviewId} for the current usage. Beginning in January 2017, BigOven moded from an integer-based ID system to a GUID-style string-based ID system for reviews and replies. We are also supporting more of a "Google Play" style model for Reviews and Replies. That is, there are top-level Reviews and then an unlimited list of replies (which do not carry star ratings) underneath existing reviews. Also, a given user can only have one review per recipe. Existing legacy endpoints will continue to work, but we strongly recommend you migrate to using the newer endpoints listed which do NOT carry the "DEPRECATED" flag.
#
# GET /recipe/{recipeId}/review/{reviewId}
# operationId: Review_Get
export def "recipe-review get-by-recipeId-reviewId" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), review_id: (encode-path-segment $review_id)} | format pattern "/recipe/{recipe_id}/review/{review_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# HTTP PUT (update) a recipe review. DEPRECATED. Please see recipe/review/{reviewId} PUT for the new endpoint. We are moving to a string-based primary key system, no longer integers, for reviews and replies.
#
# PUT /recipe/{recipeId}/review/{reviewId}
# operationId: Review_PutLegacy
export def "recipe-review update-legacy" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --comment: string
  --guid: string
  --make-again: string
  --parent-id: int # format: int32
  --star-rating: int # format: int32
  --total-minutes: int # format: int32
]: any -> record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id), review_id: (encode-path-segment $review_id)} | format pattern "/recipe/{recipe_id}/review/{review_id}"))
  let req_body = {"ActiveMinutes": $active_minutes, "Comment": $comment, "GUID": $guid, "MakeAgain": $make_again, "ParentID": $parent_id, "StarRating": $star_rating, "TotalMinutes": $total_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get paged list of reviews for a recipe. Each review will have at most one FeaturedReply, as well as a ReplyCount.
#
# GET /recipe/{recipeId}/reviews
# operationId: Review_GetReviews
export def "recipe-reviews get" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # the page (int), starting with 1 (format: int32)
  --rpp: int # results per page (int) (format: int32)
]: nothing -> table<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/reviews") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of RecipeScan images for the recipe. There will be at most 3 per recipe.
#
# GET /recipe/{recipeId}/scans
# operationId: Images_GetScanImages
export def "recipe-scans get-images-images" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({recipe_id: (encode-path-segment $recipe_id)} | format pattern "/recipe/{recipe_id}/scans"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search for recipes. There are many parameters that you can apply. Starting with the most common, use title_kw to search within a title. Use any_kw to search across the entire recipe. If you'd like to limit by course, set the parameter "include_primarycat" to one of (appetizers,bread,breakfast,dessert,drinks,maindish,salad,sidedish,soup,marinades,other). If you'd like to exclude a category, set exclude_cat to one or more (comma-separated) list of those categories to exclude. If you'd like to include a category, set include_cat to one or more (comma-separated) of those categories to include. To explicitly include an ingredient in your search, set the parameter "include_ing" to a CSV of up to three ingredients, e.g.:include_ing=mustard,chicken,beef%20tips To explicitly exclude an ingredient in your search, set the parameter "exclude_ing" to a CSV of up to three ingredients. All searches must contain the paging parameters pg and rpp, which are integers, and represent the page number (1-based) and results per page (rpp). So, to get the third page of a result set paged with 25 recipes per page, you'd pass pg=3&rpp=25 If you'd like to target searches to just a single target user's recipes, set userId=the target userId (number). Or, you can set username=theirusername vtn;vgn;chs;glf;ntf;dyf;sff;slf;tnf;wmf;rmf;cps cuisine photos filter=added,try,favorites,myrecipes\r\n\r\n folder=FolderNameCaseSensitive coll=ID of Collection
#
# GET /recipes
# operationId: Recipe_RecipeSearch
export def "recipes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --any-kw: string # Search anywhere in the recipe for the keyword
  --folder: string # Search in a specific folder name for the authenticated user
  --coll: int # Limit to a collection ID number (format: int32)
  --filter: string # optionally set to either "myrecipes", "try", "favorites","added" to filter to just the authenticated user's recipe set
  --title-kw: string # Search just in the recipe title for the keyword
  --user-id: int # Set the target userid to search their public recipes (format: int32)
  --username: string # Set the target username to search their public recipes
  --qp-token: string
  --photos: oneof<nothing, bool> # if set to true, limit search results to photos only
  --boostmine: oneof<nothing, bool> # if set to true, boost my own recipes in my folders so they show up high in the list (at the expense of other sort orders)
  --include-cat: string # integer of the subcategory you'd like to limit searches to (see the /recipe/categories endpoint for available id numbers). For instance, 58 is "Main Dish > Casseroles".
  --exclude-cat: string # like include_cat, set this to an integer to exclude a specific category
  --include-primarycat: string # csv indicating up to three top-level categories -- valid values are [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --exclude-primarycat: string # csv indicating integer values for up to 3 top-level categories -- valid values are 1...11 [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --include-ing: string # A CSV representing up to 3 ingredients to include, e.g., tomatoes,corn%20%starch,chicken
  --exclude-ing: string # A CSV representing up to 3 ingredients to exclude (Powersearch-capable plan required)
  --cuisine: string # Limit to a specific cuisine. Cooks can enter anything free-form, but the few dozen preconfigured values are Afghan,African,American,American-South,Asian,Australian,Brazilian,Cajun,Canadian,Caribbean,Chinese,Croatian,Cuban,Dessert,Eastern European,English,French,German,Greek,Hawaiian,Hungarian,India,Indian,Irish,Italian,Japanese,Jewish,Korean,Latin,Mediterranean,Mexican,Middle Eastern,Moroccan,Polish,Russian,Scandanavian,Seafood,Southern,Southwestern,Spanish,Tex-Mex,Thai,Vegan,Vegetarian,Vietnamese
  --db: string
  --userset: string # If set to a given username, it'll force the search to filter to just that username
  --servings-min: float # Limit to yield of a given number size or greater. Note that cooks usually enter recipes by Servings, but sometimes they are posted by "dozen", etc. This parameter simply specifies the minimum number for that value entered in "yield." (format: double)
  --total-mins: int # Optional. If supplied, will restrict results to recipes that can be made in {totalMins} or less. (Convert "1 hour, 15 minutes" to 75 before passing in.) (format: int32)
  --max-ingredients: int # Optional. If supplied, will restrict results to recipes that can be made with {maxIngredients} ingredients or less (format: int32)
  --min-ingredients: int # Optional. If supplied, will restrict results to recipes that have at least {minIngredients} (format: int32)
  --rpp: int # integer; results per page (format: int32)
  --pg: int # integer: the page number (format: int32)
  --vtn: int # when set to 1, limit to vegetarian (Powersearch-capable plan required) (format: int32)
  --vgn: int # when set to 1, limit to vegan (Powersearch-capable plan required) (format: int32)
  --chs: int # when set to 1, limit to contains-cheese (Powersearch-capable plan required) (format: int32)
  --glf: int # when set to 1, limit to gluten-free (Powersearch-capable plan required) (format: int32)
  --ntf: int # when set to 1, limit to nut-free (Powersearch-capable plan required) (format: int32)
  --dyf: int # when set to 1, limit to dairy-free (Powersearch-capable plan required) (format: int32)
  --sff: int # when set to 1, limit to seafood-free (Powersearch-capable plan required) (format: int32)
  --slf: int # when set to 1, limit to shellfish-free (Powersearch-capable plan required) (format: int32)
  --tnf: int # when set to 1, limit to tree-nut free (Powersearch-capable plan required) (format: int32)
  --wmf: int # when set to 1, limit to white-meat free (Powersearch-capable plan required) (format: int32)
  --rmf: int # when set to 1, limit to red-meat free (Powersearch-capable plan required) (format: int32)
  --cps: int # when set to 1, recipe contains pasta, set to 0 means contains no pasta (Powersearch-capable plan required) (format: int32)
  --champion: int # optional. When set to 1, this will limit search results to "best of" recipes as determined by various internal editorial and programmatic algorithms. For the most comprehensive results, don't include this parameter. (format: int32)
  --synonyms: oneof<nothing, bool> # optional, default is false. When set to true, BigOven will attempt to apply synonyms in search (e.g., excluding pork will also exclude bacon)
]: nothing -> record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "any_kw" $any_kw "scalar") (serialize-qp "folder" $folder "scalar") (serialize-qp "coll" $coll "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "title_kw" $title_kw "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "boostmine" $boostmine "scalar") (serialize-qp "include_cat" $include_cat "scalar") (serialize-qp "exclude_cat" $exclude_cat "scalar") (serialize-qp "include_primarycat" $include_primarycat "scalar") (serialize-qp "exclude_primarycat" $exclude_primarycat "scalar") (serialize-qp "include_ing" $include_ing "scalar") (serialize-qp "exclude_ing" $exclude_ing "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "db" $db "scalar") (serialize-qp "userset" $userset "scalar") (serialize-qp "servingsMin" $servings_min "scalar") (serialize-qp "totalMins" $total_mins "scalar") (serialize-qp "maxIngredients" $max_ingredients "scalar") (serialize-qp "minIngredients" $min_ingredients "scalar") (serialize-qp "rpp" $rpp "scalar") (serialize-qp "pg" $pg "scalar") (serialize-qp "vtn" $vtn "scalar") (serialize-qp "vgn" $vgn "scalar") (serialize-qp "chs" $chs "scalar") (serialize-qp "glf" $glf "scalar") (serialize-qp "ntf" $ntf "scalar") (serialize-qp "dyf" $dyf "scalar") (serialize-qp "sff" $sff "scalar") (serialize-qp "slf" $slf "scalar") (serialize-qp "tnf" $tnf "scalar") (serialize-qp "wmf" $wmf "scalar") (serialize-qp "rmf" $rmf "scalar") (serialize-qp "cps" $cps "scalar") (serialize-qp "champion" $champion "scalar") (serialize-qp "synonyms" $synonyms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a random, home-page-quality Recipe.
#
# GET /recipes/random
# operationId: Recipe_GetRandomRecipe
export def "recipes-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recipes/random")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the recipe/comment tuples for those recipes with 4 or 5 star ratings
#
# GET /recipes/raves
# operationId: Recipe_Raves
export def "recipes-raves get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # page, starting with 1 (format: int32)
  --rpp: int # results per page (format: int32)
]: nothing -> table<RecipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Review: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record, Replies: list, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/raves" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of recipes that the authenticated user has most recently viewed
#
# GET /recipes/recentviews
# operationId: Recipe_RecentViews
export def "recipes-recentviews get-recent-views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # Page number starting with 1 (format: int32)
  --rpp: int # results per page (format: int32)
]: nothing -> table<date: string, recipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg" $pg "scalar") (serialize-qp "rpp" $rpp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/recentviews" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search for recipes. There are many parameters that you can apply. Starting with the most common, use title_kw to search within a title. Use any_kw to search across the entire recipe. If you'd like to limit by course, set the parameter "include_primarycat" to one of (appetizers,bread,breakfast,dessert,drinks,maindish,salad,sidedish,soup,marinades,other). If you'd like to exclude a category, set exclude_cat to one or more (comma-separated) list of those categories to exclude. If you'd like to include a category, set include_cat to one or more (comma-separated) of those categories to include. To explicitly include an ingredient in your search, set the parameter "include_ing" to a CSV of up to three ingredients, e.g.:include_ing=mustard,chicken,beef%20tips To explicitly exclude an ingredient in your search, set the parameter "exclude_ing" to a CSV of up to three ingredients. All searches must contain the paging parameters pg and rpp, which are integers, and represent the page number (1-based) and results per page (rpp). So, to get the third page of a result set paged with 25 recipes per page, you'd pass pg=3&rpp=25 If you'd like to target searches to just a single target user's recipes, set userId=the target userId (number). Or, you can set username=theirusername vtn;vgn;chs;glf;ntf;dyf;sff;slf;tnf;wmf;rmf;cps cuisine photos filter=added,try,favorites,myrecipes\r\n\r\n folder=FolderNameCaseSensitive coll=ID of Collection
#
# GET /recipes/top25random
# operationId: Recipe_RecipeSearchRandom
export def "recipes-top25random list-random" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --any-kw: string # Search anywhere in the recipe for the keyword
  --folder: string # Search in a specific folder name for the authenticated user
  --coll: int # Limit to a collection ID number (format: int32)
  --filter: string # optionally set to either "myrecipes", "try", "favorites","added" to filter to just the authenticated user's recipe set
  --title-kw: string # Search just in the recipe title for the keyword
  --user-id: int # Set the target userid to search their public recipes (format: int32)
  --username: string # Set the target username to search their public recipes
  --qp-token: string
  --photos: oneof<nothing, bool> # if set to true, limit search results to photos only
  --boostmine: oneof<nothing, bool> # if set to true, boost my own recipes in my folders so they show up high in the list (at the expense of other sort orders)
  --include-cat: string # integer of the subcategory you'd like to limit searches to (see the /recipe/categories endpoint for available id numbers). For instance, 58 is "Main Dish > Casseroles".
  --exclude-cat: string # like include_cat, set this to an integer to exclude a specific category
  --include-primarycat: string # csv indicating up to three top-level categories -- valid values are [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --exclude-primarycat: string # csv indicating integer values for up to 3 top-level categories -- valid values are 1...11 [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --include-ing: string # A CSV representing up to 3 ingredients to include, e.g., tomatoes,corn%20%starch,chicken
  --exclude-ing: string # A CSV representing up to 3 ingredients to exclude (Powersearch-capable plan required)
  --cuisine: string # Limit to a specific cuisine. Cooks can enter anything free-form, but the few dozen preconfigured values are Afghan,African,American,American-South,Asian,Australian,Brazilian,Cajun,Canadian,Caribbean,Chinese,Croatian,Cuban,Dessert,Eastern European,English,French,German,Greek,Hawaiian,Hungarian,India,Indian,Irish,Italian,Japanese,Jewish,Korean,Latin,Mediterranean,Mexican,Middle Eastern,Moroccan,Polish,Russian,Scandanavian,Seafood,Southern,Southwestern,Spanish,Tex-Mex,Thai,Vegan,Vegetarian,Vietnamese
  --db: string
  --userset: string # If set to a given username, it'll force the search to filter to just that username
  --servings-min: float # Limit to yield of a given number size or greater. Note that cooks usually enter recipes by Servings, but sometimes they are posted by "dozen", etc. This parameter simply specifies the minimum number for that value entered in "yield." (format: double)
  --total-mins: int # Optional. If supplied, will restrict results to recipes that can be made in {totalMins} or less. (Convert "1 hour, 15 minutes" to 75 before passing in.) (format: int32)
  --max-ingredients: int # Optional. If supplied, will restrict results to recipes that can be made with {maxIngredients} ingredients or less (format: int32)
  --min-ingredients: int # Optional. If supplied, will restrict results to recipes that have at least {minIngredients} (format: int32)
  --vtn: int # when set to 1, limit to vegetarian (Powersearch-capable plan required) (format: int32)
  --vgn: int # when set to 1, limit to vegan (Powersearch-capable plan required) (format: int32)
  --chs: int # when set to 1, limit to contains-cheese (Powersearch-capable plan required) (format: int32)
  --glf: int # when set to 1, limit to gluten-free (Powersearch-capable plan required) (format: int32)
  --ntf: int # when set to 1, limit to nut-free (Powersearch-capable plan required) (format: int32)
  --dyf: int # when set to 1, limit to dairy-free (Powersearch-capable plan required) (format: int32)
  --sff: int # when set to 1, limit to seafood-free (Powersearch-capable plan required) (format: int32)
  --slf: int # when set to 1, limit to shellfish-free (Powersearch-capable plan required) (format: int32)
  --tnf: int # when set to 1, limit to tree-nut free (Powersearch-capable plan required) (format: int32)
  --wmf: int # when set to 1, limit to white-meat free (Powersearch-capable plan required) (format: int32)
  --rmf: int # when set to 1, limit to red-meat free (Powersearch-capable plan required) (format: int32)
  --cps: int # when set to 1, recipe contains pasta, set to 0 means contains no pasta (Powersearch-capable plan required) (format: int32)
  --champion: int # optional. When set to 1, this will limit search results to "best of" recipes as determined by various internal editorial and programmatic algorithms. For the most comprehensive results, don't include this parameter. (format: int32)
  --synonyms: oneof<nothing, bool> # optional, default is false. When set to true, BigOven will attempt to apply synonyms in search (e.g., excluding pork will also exclude bacon)
]: nothing -> record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "any_kw" $any_kw "scalar") (serialize-qp "folder" $folder "scalar") (serialize-qp "coll" $coll "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "title_kw" $title_kw "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "boostmine" $boostmine "scalar") (serialize-qp "include_cat" $include_cat "scalar") (serialize-qp "exclude_cat" $exclude_cat "scalar") (serialize-qp "include_primarycat" $include_primarycat "scalar") (serialize-qp "exclude_primarycat" $exclude_primarycat "scalar") (serialize-qp "include_ing" $include_ing "scalar") (serialize-qp "exclude_ing" $exclude_ing "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "db" $db "scalar") (serialize-qp "userset" $userset "scalar") (serialize-qp "servingsMin" $servings_min "scalar") (serialize-qp "totalMins" $total_mins "scalar") (serialize-qp "maxIngredients" $max_ingredients "scalar") (serialize-qp "minIngredients" $min_ingredients "scalar") (serialize-qp "vtn" $vtn "scalar") (serialize-qp "vgn" $vgn "scalar") (serialize-qp "chs" $chs "scalar") (serialize-qp "glf" $glf "scalar") (serialize-qp "ntf" $ntf "scalar") (serialize-qp "dyf" $dyf "scalar") (serialize-qp "sff" $sff "scalar") (serialize-qp "slf" $slf "scalar") (serialize-qp "tnf" $tnf "scalar") (serialize-qp "wmf" $wmf "scalar") (serialize-qp "rmf" $rmf "scalar") (serialize-qp "cps" $cps "scalar") (serialize-qp "champion" $champion "scalar") (serialize-qp "synonyms" $synonyms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipes/top25random" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Same as GET recipe but also includes the recipe videos (if any)
#
# GET /recipes/{id}
# operationId: Recipe_GetV2
export def "recipes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool> # The prefetch.
]: nothing -> record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, Videos: table<InsertedOn: string, IsPrimaryVideo: bool, MediaId: string, VidId: int>, WebURL: string, YieldNumber: float, YieldUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bigoven-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefetch" $prefetch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recipes/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
