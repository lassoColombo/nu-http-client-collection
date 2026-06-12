# Auto-generated client for BTCPay Greenfield API vv1
# Source: https://docs.btcpayserver.org/API/Greenfield/v1/swagger.json
# Auth: --token flag or $env.BTCPAY_GREENFIELD_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BTCPAY_GREENFIELD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def status-completer [] { ["Expired" "Invalid" "New" "Processing" "Settled"] }
def refundVariant-completer [] { ["CurrentRate" "Custom" "Fiat" "OverpaidAmount" "RateThen"] }
def onExisting-completer [] { ["KeepVersion" "UpdateVersion"] }
def state-completer [] { ["AwaitingApproval" "AwaitingPayment" "Cancelled" "Completed" "InProgress"] }
def wordList-completer [] { ["ChineseSimplified" "ChineseTraditional" "Czech" "English" "French" "Japanese" "PortugueseBrazil" "Spanish"] }
def wordCount-completer [] { ["12" "15" "18" "21" "24"] }
def scriptPubKeyType-completer [] { ["Legacy" "Segwit" "SegwitP2SH" "TaprootBIP86"] }
def speedPolicy-completer [] { ["HighSpeed" "LowMediumSpeed" "LowSpeed" "MediumSpeed"] }
def networkFeeMode-completer [] { ["Always" "MultiplePaymentsOnly" "Never"] }
def recurringType-completer [] { ["Lifetime" "Monthly" "Quarterly" "Yearly"] }
def onPayBehavior-completer [] { ["HardMigration" "SoftMigration"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-keys DeleteApiKey" } } | get name | first)
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

# Revoke an API Key
#
# DELETE /api/v1/api-keys/{apikey}
# operationId: ApiKeys_DeleteApiKey
export def "api-keys DeleteApiKey" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api-keys/($apikey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke an API Key of target user
#
# DELETE /api/v1/users/{idOrEmail}/api-keys/{apikey}
# operationId: ApiKeys_DeleteUserApiKey
export def "users-api-keys DeleteUserApiKey" [
  idOrEmail: string
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)/api-keys/($apikey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the current API Key information
#
# GET /api/v1/api-keys/current
# operationId: ApiKeys_GetCurrentApiKey
export def "api-keys-current GetCurrentApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string, label: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api-keys/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke the current API Key
#
# DELETE /api/v1/api-keys/current
# operationId: ApiKeys_DeleteCurrentApiKey
export def "api-keys-current DeleteCurrentApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string, label: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api-keys/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new API Key
#
# POST /api/v1/api-keys
# operationId: ApiKeys_CreateApiKey
export def "api-keys CreateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The label of the new API Key (nullable)
  --permissions: list # The permissions granted to this API Key (See API Key Authentication) (nullable)
]: any -> record<apiKey: string, label: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api-keys")
  let body = {label: $label, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new API Key for a user
#
# POST /api/v1/users/{idOrEmail}/api-keys
# operationId: ApiKeys_CreateUserApiKey
export def "users-api-keys CreateUserApiKey" [
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The label of the new API Key (nullable)
  --permissions: list # The permissions granted to this API Key (See API Key Authentication) (nullable)
]: any -> record<apiKey: string, label: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)/api-keys")
  let body = {label: $label, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new Point of Sale app
#
# POST /api/v1/stores/{storeId}/apps/pos
# operationId: Apps_CreatePointOfSaleApp
export def "stores-apps-pos CreatePointOfSaleApp" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string # JSON of item available in the app
]: any -> record<items: table<id: string, title: string, description: string, image: string, price: string, priceType: string, buyButtonText: string, inventory: int, disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/apps/pos")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Point of Sale app
#
# PUT /api/v1/apps/pos/{appId}
# operationId: Apps_PutPointOfSaleApp
export def "apps-pos PutPointOfSaleApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string # JSON of item available in the app
]: any -> record<items: table<id: string, title: string, description: string, image: string, price: string, priceType: string, buyButtonText: string, inventory: int, disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/pos/($appId)")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Point of Sale app data
#
# GET /api/v1/apps/pos/{appId}
# operationId: Apps_GetPointOfSaleApp
export def "apps-pos GetPointOfSaleApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<id: string, title: string, description: string, image: string, price: string, priceType: string, buyButtonText: string, inventory: int, disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/pos/($appId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Crowdfund app
#
# PUT /api/v1/apps/crowdfund/{appId}
# operationId: Apps_PutCrowdfundApp
export def "apps-crowdfund PutCrowdfundApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perksTemplate: string # JSON of perks available in the app
]: any -> record<perks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/crowdfund/($appId)")
  let body = {perksTemplate: $perksTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get crowdfund app data
#
# GET /api/v1/apps/crowdfund/{appId}
# operationId: Apps_GetCrowdfundApp
export def "apps-crowdfund GetCrowdfundApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<perks: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/crowdfund/($appId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Crowdfund app
#
# POST /api/v1/stores/{storeId}/apps/crowdfund
# operationId: Apps_CreateCrowdfundApp
export def "stores-apps-crowdfund CreateCrowdfundApp" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perksTemplate: string # JSON of perks available in the app
]: any -> record<perks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/apps/crowdfund")
  let body = {perksTemplate: $perksTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get basic app data
#
# GET /api/v1/apps/{appId}
# operationId: Apps_GetApp
export def "apps GetApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, appName: string, storeId: record, created: int, appType: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($appId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete app
#
# DELETE /api/v1/apps/{appId}
# operationId: Apps_DeleteApp
export def "apps DeleteApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($appId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads an image for an app item
#
# POST /api/v1/apps/{appId}/image
# operationId: Apps_UploadAppItemImage
export def "apps-image UploadAppItemImage" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The image (format: binary)
]: any -> record<id: string, userId: string, uri: string, url: string, originalName: string, storageName: string, created: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($appId)/image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Deletes the app item image
#
# DELETE /api/v1/apps/{appId}/image/{fileId}
# operationId: App_DeleteAppItemImage
export def "apps-image DeleteAppItemImage" [
  appId: string
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($appId)/image/($fileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get app sales statistics
#
# GET /api/v1/apps/{appId}/sales
# operationId: Apps_GetAppSales
export def "apps-sales GetAppSales" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --numberOfDays: float # How many of the last days (nullable, default: 7)
]: nothing -> record<salesCount: int, series: table<date: int, label: string, salesCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "numberOfDays" $numberOfDays "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/apps/($appId)/sales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get app top items statistics
#
# GET /api/v1/apps/{appId}/top-items
# operationId: Apps_GetAppTopItems
export def "apps-top-items GetAppTopItems" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # How many of the items (nullable, default: 5)
  --offset: float # Offset for paging (nullable, default: 0)
]: nothing -> table<itemCode: string, title: string, salesCount: int, total: string, totalFormatted: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/apps/($appId)/top-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get basic app data for all apps for a store
#
# GET /api/v1/stores/{storeId}/apps
# operationId: Apps_GetAllAppsForStore
export def "stores-apps GetAllAppsForStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, appName: string, storeId: record, created: int, appType: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get basic app data for all apps for all stores for a user
#
# GET /api/v1/apps
# operationId: Apps_GetAllApps
export def "apps GetAllApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, appName: string, storeId: record, created: int, appType: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorize User
#
# GET /api-keys/authorize
# operationId: ApiKeys_Authorize
export def "api-keys-authorize Authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list # The permissions to request. (See API Key authentication) (nullable)
  --strict: oneof<nothing, bool> # If permissions are specified, and strict is set to false, it will allow the user to reject some of permissions the application is requesting. (nullable, default: true)
  --applicationIdentifier: string # If specified, BTCPay Server will check if there is an existing API key associated with the user that also has this application identifier, redirect host AND the permissions required match(takes selectiveStores and strict into account). `applicationIdentifier` is ignored if redirect is not specified. (nullable)
  --selectiveStores: oneof<nothing, bool> # If the application is requesting the CanModifyStoreSettings permission and selectiveStores is set to true, this allows the user to only grant permissions to selected stores under the user's control. (nullable, default: false)
  --applicationName: string # The name of your application (nullable)
  --redirect: string # The url to redirect to after the user consents, with the query parameters appended to it: permissions, user-id, api-key. If not specified, user is redirected to their API Key list. (nullable, format: url)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permissions" $permissions "multi") (serialize-qp "strict" $strict "scalar") (serialize-qp "applicationIdentifier" $applicationIdentifier "scalar") (serialize-qp "selectiveStores" $selectiveStores "scalar") (serialize-qp "applicationName" $applicationName "scalar") (serialize-qp "redirect" $redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-keys/authorize" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all files
#
# GET /api/v1/files
# operationId: Files_GetFiles
export def "files GetFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, userId: string, uri: string, url: string, originalName: string, storageName: string, created: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a file
#
# POST /api/v1/files
# operationId: Files_UploadFile
export def "files UploadFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The profile picture (format: binary)
]: any -> record<id: string, userId: string, uri: string, url: string, originalName: string, storageName: string, created: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/files")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get file
#
# GET /api/v1/files/{fileId}
# operationId: Files_GetFile
export def "files GetFile" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, userId: string, uri: string, url: string, originalName: string, storageName: string, created: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/files/($fileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete file
#
# DELETE /api/v1/files/{fileId}
# operationId: Files_DeleteFile
export def "files DeleteFile" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/files/($fileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get health status
#
# GET /api/v1/health
# operationId: Health_GetHealth
export def "health GetHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<synchronized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoices
#
# GET /api/v1/stores/{storeId}/invoices
# operationId: Invoices_GetInvoices
export def "stores-invoices GetInvoices" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderId: list # Array of OrderIds to fetch the invoices for (e.g. 1000&orderId=1001&orderId=1002)
  --textSearch: string # A term that can help locating specific invoices.
  --status: string@status-completer # Array of statuses of invoices to be fetched
  --endDate: float # End date of the period to retrieve invoices (format: int32, e.g. 1592312018)
  --includePaymentMethods: oneof<nothing, bool> # Includes payment methods available to the response (default: false)
  --take: float # Number of records returned in response (nullable)
  --skip: float # Number of records to skip (nullable)
  --startDate: float # Start date of the period to retrieve invoices (format: int32, e.g. 1592312018)
]: nothing -> table<paymentMethods: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "multi") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "includePaymentMethods" $includePaymentMethods "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "startDate" $startDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new invoice
#
# POST /api/v1/stores/{storeId}/invoices
# operationId: Invoices_CreateInvoice
# --metadata shape: {buyerName?: string, buyerEmail?: string, buyerCountry?: string, buyerZip?: string, buyerState?: string, buyerCity?: string, buyerAddress1?: string, buyerAddress2?: string, buyerPhone?: string, itemDesc?: string, itemCode?: string, orderId?: string, orderUrl?: string, taxIncluded?: float, physical?: string, paymentRequestId?: string, posData?: record, receiptData?: record}
# --checkout shape: {speedPolicy?: string, paymentMethods?: list, defaultPaymentMethod?: string, lazyPaymentMethods?: bool, expirationMinutes?: float, monitoringMinutes?: float, paymentTolerance?: float, redirectURL?: string, redirectAutomatically?: bool, defaultLanguage?: string}
# --receipt shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
export def "stores-invoices CreateInvoice" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # Additional information around the invoice that can be supplied. The mentioned properties are all optional and you can introduce any json format you wish. See [our documentation](https://docs.btcpayserver.org/Development/InvoiceMetadata/) for more information. (e.g. {orderId: pos-app_346KRC5BjXXXo8cRFKwTBmdR6ZJ4, orderUrl: https://localhost:14142/apps/346KRC5BjXXXo8cRFKwTBmdR6ZJ4/pos, itemDesc: Tea shop, posData: {tip: 0.48, cart: [{id: pu erh, count: 1, image: ~/img/pos-sample/pu-erh.jpg, price: {type: 2, value: 2, formatted: $2.00}, title: Pu Erh, inventory: }, {id: rooibos, count: 1, image: ~/img/pos-sample/rooibos.jpg, price: {type: 2, value: 1.2, formatted: $1.20}, title: Rooibos, inventory: }], total: 3.68, subTotal: 3.2, customAmount: 0, discountAmount: 0, discountPercentage: 0}, receiptData: {Tip: $0.48, Cart: {Pu Erh: $2.00 x 1 = $2.00, Rooibos: $1.20 x 1 = $1.20}}}) — shape: {buyerName?: string, buyerEmail?: string, buyerCountry?: string, buyerZip?: string, buyerState?: string, buyerCity?: string, buyerAddress1?: string, buyerAddress2?: string, buyerPhone?: string, itemDesc?: string, itemCode?: string, orderId?: string, orderUrl?: string, taxIncluded?: float, physical?: string, paymentRequestId?: string, posData?: record, receiptData?: record}
  --checkout: record # Additional settings to customize the checkout flow (nullable) — shape: {speedPolicy?: string, paymentMethods?: list, defaultPaymentMethod?: string, lazyPaymentMethods?: bool, expirationMinutes?: float, monitoringMinutes?: float, paymentTolerance?: float, redirectURL?: string, redirectAutomatically?: bool, defaultLanguage?: string}
  --receipt: record # Additional settings to customize the public receipt (nullable) — shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
  --amount: string # The amount of the invoice. If null or unspecified, the invoice will be a top-up invoice. (ie. The invoice will consider any payment as a full payment) (nullable, format: decimal, e.g. 5.00)
  --currency: string # The currency of the invoice (if null, empty or unspecified, the currency will be the store's settings default)' (nullable, e.g. USD)
  --additionalSearchTerms: list # Additional search term to help you find this invoice via text search (nullable)
]: any -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices")
  let body = {metadata: $metadata, checkout: $checkout, receipt: $receipt, amount: $amount, currency: $currency, additionalSearchTerms: $additionalSearchTerms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get invoice
#
# GET /api/v1/stores/{storeId}/invoices/{invoiceId}
# operationId: Invoices_GetInvoice
export def "stores-invoices GetInvoice" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive invoice
#
# DELETE /api/v1/stores/{storeId}/invoices/{invoiceId}
# operationId: Invoices_ArchiveInvoice
export def "stores-invoices ArchiveInvoice" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update invoice
#
# PUT /api/v1/stores/{storeId}/invoices/{invoiceId}
# operationId: Invoices_UpdateInvoice
# --metadata shape: {buyerName?: string, buyerEmail?: string, buyerCountry?: string, buyerZip?: string, buyerState?: string, buyerCity?: string, buyerAddress1?: string, buyerAddress2?: string, buyerPhone?: string, itemDesc?: string, itemCode?: string, orderId?: string, orderUrl?: string, taxIncluded?: float, physical?: string, paymentRequestId?: string, posData?: record, receiptData?: record}
export def "stores-invoices UpdateInvoice" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # Additional information around the invoice that can be supplied. The mentioned properties are all optional and you can introduce any json format you wish. See [our documentation](https://docs.btcpayserver.org/Development/InvoiceMetadata/) for more information. (e.g. {orderId: pos-app_346KRC5BjXXXo8cRFKwTBmdR6ZJ4, orderUrl: https://localhost:14142/apps/346KRC5BjXXXo8cRFKwTBmdR6ZJ4/pos, itemDesc: Tea shop, posData: {tip: 0.48, cart: [{id: pu erh, count: 1, image: ~/img/pos-sample/pu-erh.jpg, price: {type: 2, value: 2, formatted: $2.00}, title: Pu Erh, inventory: }, {id: rooibos, count: 1, image: ~/img/pos-sample/rooibos.jpg, price: {type: 2, value: 1.2, formatted: $1.20}, title: Rooibos, inventory: }], total: 3.68, subTotal: 3.2, customAmount: 0, discountAmount: 0, discountPercentage: 0}, receiptData: {Tip: $0.48, Cart: {Pu Erh: $2.00 x 1 = $2.00, Rooibos: $1.20 x 1 = $1.20}}}) — shape: {buyerName?: string, buyerEmail?: string, buyerCountry?: string, buyerZip?: string, buyerState?: string, buyerCity?: string, buyerAddress1?: string, buyerAddress2?: string, buyerPhone?: string, itemDesc?: string, itemCode?: string, orderId?: string, orderUrl?: string, taxIncluded?: float, physical?: string, paymentRequestId?: string, posData?: record, receiptData?: record}
]: any -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get invoice payment methods
#
# GET /api/v1/stores/{storeId}/invoices/{invoiceId}/payment-methods
# operationId: Invoices_GetInvoicePaymentMethods
export def "stores-invoices-payment-methods GetInvoicePaymentMethods" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeSensitive: oneof<nothing, bool> # If `true`, `additionalData` might include sensitive data (such as xpub). Requires the permission `btcpay.store.canmodifystoresettings`. (default: false)
  --onlyAccountedPayments: oneof<nothing, bool> # If default or true, only returns payments which are accounted (in Bitcoin, this mean not returning RBF'd or double spent payments) (default: true)
]: nothing -> table<paymentMethodId: string, currency: string, destination: string, paymentLink: string, rate: string, paymentMethodPaid: string, totalPaid: string, due: string, amount: string, paymentMethodFee: string, payments: list<record>, activated: bool, additionalData: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeSensitive" $includeSensitive "scalar") (serialize-qp "onlyAccountedPayments" $onlyAccountedPayments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/payment-methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice refund trigger data
#
# GET /api/v1/stores/{storeId}/invoices/{invoiceId}/refund/{paymentMethodId}
# operationId: Invoices_GetInvoiceRefundTriggerData
export def "stores-invoices-refund GetInvoiceRefundTriggerData" [
  invoiceId: string
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<paymentAmountThen: string, paymentAmountNow: string, invoiceAmount: string, paymentCurrency: string, paymentCurrencyDivisibility: float, invoiceCurrencyDivisibility: float, invoiceCurrency: string, overpaidPaymentAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/refund/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark invoice status
#
# POST /api/v1/stores/{storeId}/invoices/{invoiceId}/status
# operationId: Invoices_MarkInvoiceStatus
export def "stores-invoices-status MarkInvoiceStatus" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Mark an invoice as completed or invalid.
]: any -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unarchive invoice
#
# POST /api/v1/stores/{storeId}/invoices/{invoiceId}/unarchive
# operationId: Invoices_UnarchiveInvoice
export def "stores-invoices-unarchive UnarchiveInvoice" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate Payment Method
#
# POST /api/v1/stores/{storeId}/invoices/{invoiceId}/payment-methods/{paymentMethodId}/activate
# operationId: Invoices_ActivatePaymentMethod
export def "stores-invoices-payment-methods-activate ActivatePaymentMethod" [
  invoiceId: string
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/payment-methods/($paymentMethodId)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refund invoice
#
# POST /api/v1/stores/{storeId}/invoices/{invoiceId}/refund
# operationId: Invoices_Refund
export def "stores-invoices-refund Refund" [
  invoiceId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the pull payment (Default: 'Refund' followed by the invoice id) (nullable)
  --description: string # Description of the pull payment
  --payoutMethodId: string # Payout method IDs. Available payment method IDs for Bitcoin are:   - `"BTC-CHAIN"`: Onchain    -`"BTC-LN"`: Lightning (e.g. BTC-LN)
  --refundVariant: string@refundVariant-completer # * `RateThen`: Refund the crypto currency price, at the rate the invoice got paid. * `CurrentRate`: Refund the crypto currency price, at the current rate. *`Fiat`: Refund the invoice currency, at the rate when the refund will be sent. *`OverpaidAmount`: Refund the crypto currency amount that was overpaid. *`Custom`: Specify the amount, currency, and rate of the refund. (see `customAmount` and `customCurrency`)
  --subtractPercentage: string # Optional percentage by which to reduce the refund, e.g. as processing charge or to compensate for the mining fee. (format: decimal, e.g. 2.1)
  --customAmount: string # The amount to refund if the `refundVariant` is `Custom`. (format: decimal, e.g. 5.00)
  --customCurrency: string # The currency to refund if the `refundVariant` is `Custom` (e.g. USD)
]: any -> record<id: string, name: string, description: string, currency: string, amount: string, BOLT11Expiration: string, autoApproveClaims: bool, archived: bool, viewLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/invoices/($invoiceId)/refund")
  let body = {name: $name, description: $description, payoutMethodId: $payoutMethodId, refundVariant: $refundVariant, subtractPercentage: $subtractPercentage, customAmount: $customAmount, customCurrency: $customCurrency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get node information
#
# GET /api/v1/server/lightning/{cryptoCode}/info
# operationId: InternalLightningNodeApi_GetInfo
export def "server-lightning-info GetInfo" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nodeURIs: list<string>, blockHeight: int, alias: string, color: string, version: string, peersCount: int, activeChannelsCount: int, inactiveChannelsCount: int, pendingChannelsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get node balance
#
# GET /api/v1/server/lightning/{cryptoCode}/balance
# operationId: InternalLightningNodeApi_GetBalance
export def "server-lightning-balance GetBalance" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<onchain: record, offchain: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get node balance histogram
#
# GET /api/v1/server/lightning/{cryptoCode}/histogram
# operationId: InternalLightningNodeApi_GetHistogram
export def "server-lightning-histogram GetHistogram" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, balance: string, series: list<string>, labels: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/histogram")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect to lightning node
#
# POST /api/v1/server/lightning/{cryptoCode}/connect
# operationId: InternalLightningNodeApi_ConnectToNode
export def "server-lightning-connect ConnectToNode" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodeURI: string # Node URI in the form `pubkey@endpoint[:port]` (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/connect")
  let body = {nodeURI: $nodeURI} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channels
#
# GET /api/v1/server/lightning/{cryptoCode}/channels
# operationId: InternalLightningNodeApi_GetChannels
export def "server-lightning-channels GetChannels" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<remoteNode: string, isPublic: bool, isActive: bool, capacity: string, localBalance: string, channelPoint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open channel
#
# POST /api/v1/server/lightning/{cryptoCode}/channels
# operationId: InternalLightningNodeApi_OpenChannel
export def "server-lightning-channels OpenChannel" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodeURI: string # Node URI in the form `pubkey@endpoint[:port]`
  --channelAmount: string # The amount to fund (in satoshi)
  --feeRate: float # The amount to fund (in satoshi per byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/channels")
  let body = {nodeURI: $nodeURI, channelAmount: $channelAmount, feeRate: $feeRate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get deposit address
#
# POST /api/v1/server/lightning/{cryptoCode}/address
# operationId: InternalLightningNodeApi_GetDepositAddress
export def "server-lightning-address GetDepositAddress" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/address")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment
#
# GET /api/v1/server/lightning/{cryptoCode}/payments/{paymentHash}
# operationId: InternalLightningNodeApi_GetPayment
export def "server-lightning-payments GetPayment" [
  cryptoCode: string
  paymentHash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/payments/($paymentHash)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice
#
# GET /api/v1/server/lightning/{cryptoCode}/invoices/{id}
# operationId: InternalLightningNodeApi_GetInvoice
export def "server-lightning-invoices GetInvoice" [
  cryptoCode: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/invoices/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pay Lightning Invoice
#
# POST /api/v1/server/lightning/{cryptoCode}/invoices/pay
# operationId: InternalLightningNodeApi_PayInvoice
export def "server-lightning-invoices-pay PayInvoice" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BOLT11: string # The BOLT11 of the invoice to pay
  --amount: string # Optional explicit payment amount in millisatoshi (if specified, it overrides the BOLT11 amount) (nullable)
  --maxFeePercent: string # The fee limit expressed as a percentage of the payment amount (nullable, format: float, e.g. 6.15)
  --maxFeeFlat: string # The fee limit expressed as a fixed amount in satoshi (nullable, e.g. 21)
  --sendTimeout: float # The number of seconds after which the payment times out (nullable, default: 30, e.g. 30)
]: any -> record<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/invoices/pay")
  let body = {BOLT11: $BOLT11, amount: $amount, maxFeePercent: $maxFeePercent, maxFeeFlat: $maxFeeFlat, sendTimeout: $sendTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get invoices
#
# GET /api/v1/server/lightning/{cryptoCode}/invoices
# operationId: InternalLightningNodeApi_GetInvoices
export def "server-lightning-invoices GetInvoices" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pendingOnly: oneof<nothing, bool> # Limit to pending invoices only (nullable, default: false)
  --offsetIndex: float # The index of an invoice that will be used as the start of the list (nullable, default: 0)
]: nothing -> table<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pendingOnly" $pendingOnly "scalar") (serialize-qp "offsetIndex" $offsetIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lightning invoice
#
# POST /api/v1/server/lightning/{cryptoCode}/invoices
# operationId: InternalLightningNodeApi_CreateInvoice
export def "server-lightning-invoices CreateInvoice" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # Amount wrapped in a string, represented in a millisatoshi string. (1000 millisatoshi = 1 satoshi)
  --description: string # Description of the invoice in the BOLT11 (nullable)
  --descriptionHashOnly: oneof<nothing, bool> # If `descriptionHashOnly` is `true` (default is `false`), then the BOLT11 returned contains a hash of the `description`, rather than the `description`, itself. This allows for much longer descriptions, but they must be communicated via some other mechanism. (nullable, default: false)
  --expiry: any # Expiration time in seconds
  --privateRouteHints: oneof<nothing, bool> # True if the invoice should include private route hints (nullable, default: false)
]: any -> record<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/invoices")
  let body = {amount: $amount, description: $description, descriptionHashOnly: $descriptionHashOnly, expiry: $expiry, privateRouteHints: $privateRouteHints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payments
#
# GET /api/v1/server/lightning/{cryptoCode}/payments
# operationId: InternalLightningNodeApi_GetPayments
export def "server-lightning-payments GetPayments" [
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePending: oneof<nothing, bool> # Also include pending payments (nullable, default: false)
  --offsetIndex: float # The index of a payment that will be used as the start of the list (nullable, default: 0)
]: nothing -> table<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePending" $includePending "scalar") (serialize-qp "offsetIndex" $offsetIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/server/lightning/($cryptoCode)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get node information
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/info
# operationId: StoreLightningNodeApi_GetInfo
export def "stores-lightning-info GetInfo" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nodeURIs: list<string>, blockHeight: int, alias: string, color: string, version: string, peersCount: int, activeChannelsCount: int, inactiveChannelsCount: int, pendingChannelsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get node balance
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/balance
# operationId: StoreLightningNodeApi_GetBalance
export def "stores-lightning-balance GetBalance" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<onchain: record, offchain: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get node balance histogram
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/histogram
# operationId: StoreLightningNodeApi_GetHistogram
export def "stores-lightning-histogram GetHistogram" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, balance: string, series: list<string>, labels: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/histogram")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect to lightning node
#
# POST /api/v1/stores/{storeId}/lightning/{cryptoCode}/connect
# operationId: StoreLightningNodeApi_ConnectToNode
export def "stores-lightning-connect ConnectToNode" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodeURI: string # Node URI in the form `pubkey@endpoint[:port]` (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/connect")
  let body = {nodeURI: $nodeURI} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channels
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/channels
# operationId: StoreLightningNodeApi_GetChannels
export def "stores-lightning-channels GetChannels" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<remoteNode: string, isPublic: bool, isActive: bool, capacity: string, localBalance: string, channelPoint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open channel
#
# POST /api/v1/stores/{storeId}/lightning/{cryptoCode}/channels
# operationId: StoreLightningNodeApi_OpenChannel
export def "stores-lightning-channels OpenChannel" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodeURI: string # Node URI in the form `pubkey@endpoint[:port]`
  --channelAmount: string # The amount to fund (in satoshi)
  --feeRate: float # The amount to fund (in satoshi per byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/channels")
  let body = {nodeURI: $nodeURI, channelAmount: $channelAmount, feeRate: $feeRate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get deposit address
#
# POST /api/v1/stores/{storeId}/lightning/{cryptoCode}/address
# operationId: StoreLightningNodeApi_GetDepositAddress
export def "stores-lightning-address GetDepositAddress" [
  storeId: string
  cryptoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/address")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/payments/{paymentHash}
# operationId: StoreLightningNodeApi_GetPayment
export def "stores-lightning-payments GetPayment" [
  cryptoCode: string
  storeId: string
  paymentHash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/payments/($paymentHash)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/invoices/{id}
# operationId: StoreLightningNodeApi_GetInvoice
export def "stores-lightning-invoices GetInvoice" [
  cryptoCode: string
  storeId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/invoices/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pay Lightning Invoice
#
# POST /api/v1/stores/{storeId}/lightning/{cryptoCode}/invoices/pay
# operationId: StoreLightningNodeApi_PayInvoice
export def "stores-lightning-invoices-pay PayInvoice" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BOLT11: string # The BOLT11 of the invoice to pay
  --amount: string # Optional explicit payment amount in millisatoshi (if specified, it overrides the BOLT11 amount) (nullable)
  --maxFeePercent: string # The fee limit expressed as a percentage of the payment amount (nullable, format: float, e.g. 6.15)
  --maxFeeFlat: string # The fee limit expressed as a fixed amount in satoshi (nullable, e.g. 21)
  --sendTimeout: float # The number of seconds after which the payment times out (nullable, default: 30, e.g. 30)
]: any -> record<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/invoices/pay")
  let body = {BOLT11: $BOLT11, amount: $amount, maxFeePercent: $maxFeePercent, maxFeeFlat: $maxFeeFlat, sendTimeout: $sendTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get invoices
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/invoices
# operationId: StoreLightningNodeApi_GetInvoices
export def "stores-lightning-invoices GetInvoices" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pendingOnly: oneof<nothing, bool> # Limit to pending invoices only (nullable, default: false)
  --offsetIndex: float # The index of an invoice that will be used as the start of the list (nullable, default: 0)
]: nothing -> table<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pendingOnly" $pendingOnly "scalar") (serialize-qp "offsetIndex" $offsetIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lightning invoice
#
# POST /api/v1/stores/{storeId}/lightning/{cryptoCode}/invoices
# operationId: StoreLightningNodeApi_CreateInvoice
export def "stores-lightning-invoices CreateInvoice" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # Amount wrapped in a string, represented in a millisatoshi string. (1000 millisatoshi = 1 satoshi)
  --description: string # Description of the invoice in the BOLT11 (nullable)
  --descriptionHashOnly: oneof<nothing, bool> # If `descriptionHashOnly` is `true` (default is `false`), then the BOLT11 returned contains a hash of the `description`, rather than the `description`, itself. This allows for much longer descriptions, but they must be communicated via some other mechanism. (nullable, default: false)
  --expiry: any # Expiration time in seconds
  --privateRouteHints: oneof<nothing, bool> # True if the invoice should include private route hints (nullable, default: false)
]: any -> record<id: string, status: string, BOLT11: string, paidAt: float, expiresAt: record, amount: string, amountReceived: string, paymentHash: string, preimage: string, customRecords: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/invoices")
  let body = {amount: $amount, description: $description, descriptionHashOnly: $descriptionHashOnly, expiry: $expiry, privateRouteHints: $privateRouteHints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payments
#
# GET /api/v1/stores/{storeId}/lightning/{cryptoCode}/payments
# operationId: StoreLightningNodeApi_GetPayments
export def "stores-lightning-payments GetPayments" [
  cryptoCode: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePending: oneof<nothing, bool> # Also include pending payments (nullable, default: false)
  --offsetIndex: float # The index of an invoice that will be used as the start of the list (nullable, default: 0)
]: nothing -> table<id: string, status: string, BOLT11: string, paymentHash: string, preimage: string, createdAt: float, totalAmount: string, feeAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePending" $includePending "scalar") (serialize-qp "offsetIndex" $offsetIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning/($cryptoCode)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get available rate sources
#
# GET /misc/rate-sources
# operationId: GetRateSources
export def "misc-rate-sources GetRateSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/misc/rate-sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permissions metadata
#
# GET /misc/permissions
# operationId: permissionsMetadata
export def "misc-permissions permissionsMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, included: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/misc/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Language codes
#
# GET /misc/lang
# operationId: langCodes
export def "misc-lang langCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, currentLanguage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/misc/lang")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoice checkout
#
# GET /i/{invoiceId}
# operationId: Invoice_Checkout
export def "i Checkout" [
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # The preferred language of the checkout page. You can use "auto" to use the language of the customer's browser or see the list of language codes with [this operation](#operation/langCodes).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/i/($invoiceId)" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notifications
#
# GET /api/v1/users/me/notifications
# operationId: Notifications_GetNotifications
export def "users-me-notifications GetNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: list # Array of store ids to fetch the notifications for (e.g. &storeId=ABCDE&storeId=FGHIJ)
  --take: float # Number of records returned in response (nullable)
  --skip: float # Number of records to skip (nullable)
  --seen: string # filter by seen notifications (nullable)
]: nothing -> record<id: string, identifier: string, type: string, body: string, storeId: string, link: string, createdTime: record, seen: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "multi") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "seen" $seen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification
#
# GET /api/v1/users/me/notifications/{id}
# operationId: Notifications_GetNotification
export def "users-me-notifications GetNotification" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, identifier: string, type: string, body: string, storeId: string, link: string, createdTime: record, seen: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/notifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update notification
#
# PUT /api/v1/users/me/notifications/{id}
# operationId: Notifications_UpdateNotification
export def "users-me-notifications UpdateNotification" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --seen: oneof<nothing, bool> # Sets the notification as seen/unseen. If left null, sets it to the opposite value (nullable)
]: any -> record<id: string, identifier: string, type: string, body: string, storeId: string, link: string, createdTime: record, seen: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/notifications/($id)")
  let body = {seen: $seen} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Notification
#
# DELETE /api/v1/users/me/notifications/{id}
# operationId: Notifications_DeleteNotification
export def "users-me-notifications DeleteNotification" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/notifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification settings
#
# GET /api/v1/users/me/notification-settings
# operationId: Notifications_GetNotificationSettings
export def "users-me-notification-settings GetNotificationSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notifications: table<identifier: string, name: string, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notification-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update notification settings
#
# PUT /api/v1/users/me/notification-settings
# operationId: Notifications_UpdateNotificationSettings
export def "users-me-notification-settings UpdateNotificationSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disabled: list # List of the notification type identifiers, which should be disabled. Can also be a single item 'all'. (e.g. [newversion, pluginupdate])
]: any -> record<notifications: table<identifier: string, name: string, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notification-settings")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment requests
#
# GET /api/v1/stores/{storeId}/payment-requests
# operationId: PaymentRequests_GetPaymentRequests
export def "stores-payment-requests GetPaymentRequests" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<amount: string, title: string, currency: string, email: string, description: string, expiryDate: float, referenceId: string, allowCustomPaymentAmounts: bool, formId: string, formResponse: record, id: string, storeId: string, status: string, createdTime: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new payment request
#
# POST /api/v1/stores/{storeId}/payment-requests
# operationId: PaymentRequests_CreatePaymentRequest
export def "stores-payment-requests CreatePaymentRequest" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the payment request (format: decimal)
  --title: string # The title of the payment request
  --currency: string # The currency of the payment request. If empty, the store's default currency code will be used. (nullable, format: ISO 4217 Currency code(BTC, EUR, USD, etc))
  --email: string # The email used in invoices generated by the payment request (nullable, format: email)
  --description: string # The description of the payment request (nullable, format: html)
  --expiryDate: float # The expiry date of the payment request (nullable)
  --referenceId: string # An optional user-defined identifier for this payment request. (nullable, e.g. INV-123493)
  --allowCustomPaymentAmounts: oneof<nothing, bool> # Whether to allow users to create invoices that partially pay the payment request  (nullable)
  --formId: string # Form ID to request customer data (nullable)
  --formResponse: record # Form data response (nullable)
]: any -> record<amount: string, title: string, currency: string, email: string, description: string, expiryDate: float, referenceId: string, allowCustomPaymentAmounts: bool, formId: string, formResponse: record, id: string, storeId: string, status: string, createdTime: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests")
  let body = {amount: $amount, title: $title, currency: $currency, email: $email, description: $description, expiryDate: $expiryDate, referenceId: $referenceId, allowCustomPaymentAmounts: $allowCustomPaymentAmounts, formId: $formId, formResponse: $formResponse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment request
#
# GET /api/v1/stores/{storeId}/payment-requests/{paymentRequestId}
# operationId: PaymentRequests_GetPaymentRequest
export def "stores-payment-requests GetPaymentRequest" [
  storeId: string
  paymentRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: string, title: string, currency: string, email: string, description: string, expiryDate: float, referenceId: string, allowCustomPaymentAmounts: bool, formId: string, formResponse: record, id: string, storeId: string, status: string, createdTime: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests/($paymentRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive payment request
#
# DELETE /api/v1/stores/{storeId}/payment-requests/{paymentRequestId}
# operationId: PaymentRequests_ArchivePaymentRequest
export def "stores-payment-requests ArchivePaymentRequest" [
  storeId: string
  paymentRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests/($paymentRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update payment request
#
# PUT /api/v1/stores/{storeId}/payment-requests/{paymentRequestId}
# operationId: PaymentRequests_UpdatePaymentRequest
export def "stores-payment-requests UpdatePaymentRequest" [
  storeId: string
  paymentRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the payment request (format: decimal)
  --title: string # The title of the payment request
  --currency: string # The currency of the payment request. If empty, the store's default currency code will be used. (nullable, format: ISO 4217 Currency code(BTC, EUR, USD, etc))
  --email: string # The email used in invoices generated by the payment request (nullable, format: email)
  --description: string # The description of the payment request (nullable, format: html)
  --expiryDate: float # The expiry date of the payment request (nullable)
  --referenceId: string # An optional user-defined identifier for this payment request. (nullable, e.g. INV-123493)
  --allowCustomPaymentAmounts: oneof<nothing, bool> # Whether to allow users to create invoices that partially pay the payment request  (nullable)
  --formId: string # Form ID to request customer data (nullable)
  --formResponse: record # Form data response (nullable)
]: any -> record<amount: string, title: string, currency: string, email: string, description: string, expiryDate: float, referenceId: string, allowCustomPaymentAmounts: bool, formId: string, formResponse: record, id: string, storeId: string, status: string, createdTime: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests/($paymentRequestId)")
  let body = {amount: $amount, title: $title, currency: $currency, email: $email, description: $description, expiryDate: $expiryDate, referenceId: $referenceId, allowCustomPaymentAmounts: $allowCustomPaymentAmounts, formId: $formId, formResponse: $formResponse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new invoice for the payment request
#
# POST /api/v1/stores/{storeId}/payment-requests/{paymentRequestId}/pay
# operationId: PaymentRequests_Pay
export def "stores-payment-requests-pay Pay" [
  storeId: string
  paymentRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the invoice. If `null` or `unspecified`, it will be set to the payment request's due amount. Note that the payment's request `allowCustomPaymentAmounts` must be `true`, or a 422 error will be sent back.' (nullable, format: decimal, e.g. 0.1)
  --allowPendingInvoiceReuse: oneof<nothing, bool> # If `true`, this endpoint will not necessarily create a new invoice, and instead attempt to give back a pending one for this payment request. (nullable, default: false)
]: any -> record<metadata: record, checkout: record, receipt: record, id: string, storeId: record, amount: string, paidAmount: string, currency: string, type: string, checkoutLink: string, createdTime: record, expirationTime: record, monitoringExpiration: record, status: string, additionalStatus: string, availableStatusesForManualMarking: list<string>, archived: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-requests/($paymentRequestId)/pay")
  let body = {amount: $amount, allowPendingInvoiceReuse: $allowPendingInvoiceReuse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store configured payout processors
#
# GET /api/v1/stores/{storeId}/payout-processors
# operationId: StorePayoutProcessors_GetStorePayoutProcessors
export def "stores-payout-processors GetStorePayoutProcessors" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, friendlyName: string, payoutMethods: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove store configured payout processor
#
# DELETE /api/v1/stores/{storeId}/payout-processors/{processor}/{paymentMethodId}
# operationId: StorePayoutProcessors_RemoveStorePayoutProcessor
export def "stores-payout-processors RemoveStorePayoutProcessor" [
  paymentMethodId: string
  storeId: string
  processor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/($processor)/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payout processors
#
# GET /api/v1/payout-processors
# operationId: PayoutProcessors_GetPayoutProcessors
export def "payout-processors GetPayoutProcessors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, friendlyName: string, payoutMethods: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/payout-processors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configured store onchain automated payout processors
#
# GET /api/v1/stores/{storeId}/payout-processors/OnChainAutomatedPayoutSenderFactory/{paymentMethodId}
# operationId: GreenfieldStoreAutomatedOnChainPayoutProcessorsController_GetStoreOnChainAutomatedPayoutProcessorsForPaymentMethod
export def "stores-payout-processors-on-chain-automated-payout-sender-factory GetStoreOnChainAutomatedPayoutProcessorsForPaymentMethod" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<payoutMethodId: string, feeTargetBlock: float, intervalSeconds: record, threshold: string, processNewPayoutsInstantly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/OnChainAutomatedPayoutSenderFactory/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update configured store onchain automated payout processors
#
# PUT /api/v1/stores/{storeId}/payout-processors/OnChainAutomatedPayoutSenderFactory/{paymentMethodId}
# operationId: GreenfieldStoreAutomatedOnChainPayoutProcessorsController_UpdateStoreOnChainAutomatedPayoutProcessorForPaymentMethod
export def "stores-payout-processors-on-chain-automated-payout-sender-factory UpdateStoreOnChainAutomatedPayoutProcessorForPaymentMethod" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feeTargetBlock: float # How many blocks should the fee rate calculation target to confirm in. Set to 1 if not provided (nullable)
  --intervalSeconds: any # How often should the processor run
  --threshold: string # Only process payouts when this payout sum is reached. (format: decimal, e.g. 0.1)
  --processNewPayoutsInstantly: oneof<nothing, bool> # Skip the interval when ane eligible payout has been approved (or created with pre-approval) (default: false)
]: any -> record<payoutMethodId: string, feeTargetBlock: float, intervalSeconds: record, threshold: string, processNewPayoutsInstantly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/OnChainAutomatedPayoutSenderFactory/($paymentMethodId)")
  let body = {feeTargetBlock: $feeTargetBlock, intervalSeconds: $intervalSeconds, threshold: $threshold, processNewPayoutsInstantly: $processNewPayoutsInstantly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get configured store Lightning automated payout processors
#
# GET /api/v1/stores/{storeId}/payout-processors/LightningAutomatedPayoutSenderFactory/{payoutMethodId}
# operationId: GreenfieldStoreAutomatedLightningPayoutProcessorsController_GetStoreLightningAutomatedPayoutProcessorsForPaymentMethod
export def "stores-payout-processors-lightning-automated-payout-sender-factory GetStoreLightningAutomatedPayoutProcessorsForPaymentMethod" [
  payoutMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<payoutMethodId: string, intervalSeconds: record, cancelPayoutAfterFailures: float, processNewPayoutsInstantly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/LightningAutomatedPayoutSenderFactory/($payoutMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update configured store Lightning automated payout processors
#
# PUT /api/v1/stores/{storeId}/payout-processors/LightningAutomatedPayoutSenderFactory/{payoutMethodId}
# operationId: GreenfieldStoreAutomatedLightningPayoutProcessorsController_UpdateStoreLightningAutomatedPayoutProcessor
export def "stores-payout-processors-lightning-automated-payout-sender-factory UpdateStoreLightningAutomatedPayoutProcessor" [
  payoutMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --intervalSeconds: any # How often should the processor run
  --cancelPayoutAfterFailures: float # How many failures should the processor tolerate before cancelling the payout (nullable)
  --processNewPayoutsInstantly: oneof<nothing, bool> # Skip the interval when ane eligible payout has been approved (or created with pre-approval) (default: false)
]: any -> record<payoutMethodId: string, intervalSeconds: record, cancelPayoutAfterFailures: float, processNewPayoutsInstantly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/LightningAutomatedPayoutSenderFactory/($payoutMethodId)")
  let body = {intervalSeconds: $intervalSeconds, cancelPayoutAfterFailures: $cancelPayoutAfterFailures, processNewPayoutsInstantly: $processNewPayoutsInstantly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get configured store onchain automated payout processors
#
# GET /api/v1/stores/{storeId}/payout-processors/OnChainAutomatedTransferSenderFactory
# operationId: GreenfieldStoreAutomatedOnChainPayoutProcessorsController_GetStoreOnChainAutomatedTransferSenderFactory
export def "stores-payout-processors-on-chain-automated-transfer-sender-factory GetStoreOnChainAutomatedTransferSenderFactory" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<payoutMethodId: string, feeTargetBlock: float, intervalSeconds: record, threshold: string, processNewPayoutsInstantly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/OnChainAutomatedTransferSenderFactory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update configured store onchain automated payout processors
#
# PUT /api/v1/stores/{storeId}/payout-processors/OnChainAutomatedTransferSenderFactory
# operationId: GreenfieldStoreAutomatedOnChainPayoutProcessorsController_UpdateStoreOnChainAutomatedTransferSenderFactory
export def "stores-payout-processors-on-chain-automated-transfer-sender-factory UpdateStoreOnChainAutomatedTransferSenderFactory" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feeTargetBlock: float # How many blocks should the fee rate calculation target to confirm in. Set to 1 if not provided (nullable)
  --intervalSeconds: any # How often should the processor run
  --threshold: string # Only process payouts when this payout sum is reached. (format: decimal, e.g. 0.1)
  --processNewPayoutsInstantly: oneof<nothing, bool> # Skip the interval when ane eligible payout has been approved (or created with pre-approval) (default: false)
]: any -> record<payoutMethodId: string, feeTargetBlock: float, intervalSeconds: record, threshold: string, processNewPayoutsInstantly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/OnChainAutomatedTransferSenderFactory")
  let body = {feeTargetBlock: $feeTargetBlock, intervalSeconds: $intervalSeconds, threshold: $threshold, processNewPayoutsInstantly: $processNewPayoutsInstantly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get configured store Lightning automated payout processors
#
# GET /api/v1/stores/{storeId}/payout-processors/LightningAutomatedPayoutSenderFactory
# operationId: GreenfieldStoreAutomatedLightningPayoutProcessorsController_GetStoreLightningAutomatedPayoutSenderFactory
export def "stores-payout-processors-lightning-automated-payout-sender-factory GetStoreLightningAutomatedPayoutSenderFactory" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<payoutMethodId: string, intervalSeconds: record, cancelPayoutAfterFailures: float, processNewPayoutsInstantly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payout-processors/LightningAutomatedPayoutSenderFactory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Link a boltcard to a pull payment
#
# POST /api/v1/pull-payments/{pullPaymentId}/boltcards
# operationId: PullPayments_LinkBoltcard
export def "pull-payments-boltcards LinkBoltcard" [
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  UID: string # The `UID` of the NTag424 (e.g. 46ab87ff36a3b7)
  --onExisting: string@onExisting-completer # What to do if the boltcard is already linked.  * `KeepVersion` will return the keys (K0-K4) that are already registered.  * `UpdateVersion` will increment the version of the key, and thus return different keys (K0-K4). (See [Deterministic Boltcard Key Generation](https://github.com/boltcard/boltcard/blob/main/docs/DETERMINISTIC.md)) (default: UpdateVersion)
]: any -> record<LNURLW: string, version: float, K0: string, K1: string, K2: string, K3: string, K4: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)/boltcards")
  let body = {UID: $UID, onExisting: $onExisting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store's pull payments
#
# GET /api/v1/stores/{storeId}/pull-payments
# operationId: PullPayments_GetPullPayments
export def "stores-pull-payments GetPullPayments" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeArchived: oneof<nothing, bool> # Whether this should list archived pull payments (default: false)
]: nothing -> table<id: string, name: string, description: string, currency: string, amount: string, BOLT11Expiration: string, autoApproveClaims: bool, archived: bool, viewLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/pull-payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new pull payment
#
# POST /api/v1/stores/{storeId}/pull-payments
# operationId: PullPayments_CreatePullPayment
export def "stores-pull-payments CreatePullPayment" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the pull payment (nullable)
  --description: string # The description of the pull payment (nullable)
  --amount: string # The amount in `currency` of this pull payment as a decimal string (format: decimal, e.g. 0.1)
  --currency: string # The currency of the amount. (e.g. BTC)
  --BOLT11Expiration: string # If lightning is activated, do not accept BOLT11 invoices with expiration less than … days (nullable, default: 30, e.g. 30)
  --autoApproveClaims: oneof<nothing, bool> # Any payouts created for this pull payment will skip the approval phase upon creation (nullable, default: false, e.g. false)
  --startsAt: int # When this pull payment is effective. Already started if null or unspecified. (nullable, format: unix timestamp in seconds, e.g. 1592312018)
  --expiresAt: int # When this pull payment expires. Never expires if null or unspecified. (nullable, format: unix timestamp in seconds, e.g. 1593129600)
  --payoutMethods: list # The list of supported payout methods supported by this pull payment. Available options can be queried from the `StorePaymentMethods_GetStorePaymentMethods` endpoint. If `null`, all available payout methods will be supported. (nullable)
]: any -> record<id: string, name: string, description: string, currency: string, amount: string, BOLT11Expiration: string, autoApproveClaims: bool, archived: bool, viewLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/pull-payments")
  let body = {name: $name, description: $description, amount: $amount, currency: $currency, BOLT11Expiration: $BOLT11Expiration, autoApproveClaims: $autoApproveClaims, startsAt: $startsAt, expiresAt: $expiresAt, payoutMethods: $payoutMethods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Pull Payment
#
# GET /api/v1/pull-payments/{pullPaymentId}
# operationId: PullPayments_GetPullPayment
export def "pull-payments GetPullPayment" [
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, currency: string, amount: string, BOLT11Expiration: string, autoApproveClaims: bool, archived: bool, viewLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a pull payment
#
# DELETE /api/v1/stores/{storeId}/pull-payments/{pullPaymentId}
# operationId: PullPayments_ArchivePullPayment
export def "stores-pull-payments ArchivePullPayment" [
  storeId: string
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/pull-payments/($pullPaymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payouts
#
# GET /api/v1/pull-payments/{pullPaymentId}/payouts
# operationId: PullPayments_GetPayouts
export def "pull-payments-payouts GetPayouts" [
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeCancelled: oneof<nothing, bool> # Whether this should list cancelled payouts (default: false)
]: nothing -> table<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCancelled" $includeCancelled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)/payouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Payout
#
# POST /api/v1/pull-payments/{pullPaymentId}/payouts
# operationId: PullPayments_CreatePayout
export def "pull-payments-payouts CreatePayout" [
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination: string # The destination of the payout (can be an address or a BIP21 url) (e.g. 1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2)
  --amount: string # The amount of the payout in the currency of the pull payment (eg. USD). (format: decimal, e.g. 10399.18)
  --payoutMethodId: string # Payout method IDs. Available payment method IDs for Bitcoin are:   - `"BTC-CHAIN"`: Onchain    -`"BTC-LN"`: Lightning (e.g. BTC-LN)
]: any -> record<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)/payouts")
  let body = {destination: $destination, amount: $amount, payoutMethodId: $payoutMethodId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Payout
#
# GET /api/v1/pull-payments/{pullPaymentId}/payouts/{payoutId}
# operationId: PullPayments_GetPayout
export def "pull-payments-payouts GetPayout" [
  pullPaymentId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)/payouts/($payoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Pull Payment LNURL details
#
# GET /api/v1/pull-payments/{pullPaymentId}/lnurl
# operationId: PullPayments_GetPullPaymentLNURL
export def "pull-payments-lnurl GetPullPaymentLNURL" [
  pullPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<lnurlBech32: string, lnurlUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pull-payments/($pullPaymentId)/lnurl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Payout
#
# POST /api/v1/stores/{storeId}/payouts
# operationId: Payouts_CreatePayoutThroughStore
export def "stores-payouts CreatePayoutThroughStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination: string # The destination of the payout (can be an address or a BIP21 url) (e.g. 1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2)
  --amount: string # The amount of the payout in the currency of the pull payment (eg. USD). (format: decimal, e.g. 10399.18)
  --payoutMethodId: string # Payout method IDs. Available payment method IDs for Bitcoin are:   - `"BTC-CHAIN"`: Onchain    -`"BTC-LN"`: Lightning (e.g. BTC-LN)
  --pullPaymentId: string # The pull payment to create this for. Optional.
  --approved: oneof<nothing, bool> # Whether to approve this payout automatically upon creation
  --metadata: record # Additional metadata to store with the payout
]: any -> record<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts")
  let body = {destination: $destination, amount: $amount, payoutMethodId: $payoutMethodId, pullPaymentId: $pullPaymentId, approved: $approved, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Store Payouts
#
# GET /api/v1/stores/{storeId}/payouts
# operationId: PullPayments_GetStorePayouts
export def "stores-payouts GetStorePayouts" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeCancelled: oneof<nothing, bool> # Whether this should list cancelled payouts (default: false)
]: nothing -> table<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCancelled" $includeCancelled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payout
#
# GET /api/v1/stores/{storeId}/payouts/{payoutId}
# operationId: GetStorePayout
export def "stores-payouts GetStorePayout" [
  storeId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts/($payoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve Payout
#
# POST /api/v1/stores/{storeId}/payouts/{payoutId}
# operationId: PullPayments_ApprovePayout
export def "stores-payouts ApprovePayout" [
  storeId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: int # The revision number of the payout being modified
  --rateRule: string # The rate rule to calculate the rate of the payout. This can also be a fixed decimal. (if null or unspecified, will use the same rate setting as the store's settings) (nullable, e.g. kraken(BTC_USD))
]: any -> record<id: string, revision: int, pullPaymentId: string, date: string, destination: string, originalCurrency: string, originalAmount: string, payoutCurrency: string, payoutAmount: string, payoutMethodId: string, state: string, paymentProof: record<proofType: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts/($payoutId)")
  let body = {revision: $revision, rateRule: $rateRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel Payout
#
# DELETE /api/v1/stores/{storeId}/payouts/{payoutId}
# operationId: PullPayments_CancelPayout
export def "stores-payouts CancelPayout" [
  storeId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts/($payoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark Payout as Paid
#
# POST /api/v1/stores/{storeId}/payouts/{payoutId}/mark-paid
# operationId: PullPayments_MarkPayoutPaid
export def "stores-payouts-mark-paid MarkPayoutPaid" [
  storeId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts/($payoutId)/mark-paid")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark Payout
#
# POST /api/v1/stores/{storeId}/payouts/{payoutId}/mark
# operationId: PullPayments_MarkPayout
# --paymentProof shape: {proofType?: string, id?: string, link?: string}
export def "stores-payouts-mark MarkPayout" [
  storeId: string
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # The state of the payout (`AwaitingApproval`, `AwaitingPayment`, `InProgress`, `Completed`, `Cancelled`) (e.g. AwaitingPayment)
  --paymentProof: record # Additional information around how the payout is being or has been paid out. The mentioned properties are all optional (except `proofType`) and you can introduce any json format you wish. — shape: {proofType?: string, id?: string, link?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payouts/($payoutId)/mark")
  let body = {state: $state, paymentProof: $paymentProof} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get server email settings
#
# GET /api/v1/server/email
# operationId: ServerEmail_GetSettings
export def "server-email GetSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enableStoresToUseServerEmailSettings: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update server email settings
#
# PUT /api/v1/server/email
# operationId: ServerEmail_UpdateSettings
export def "server-email UpdateSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enableStoresToUseServerEmailSettings: oneof<nothing, bool> # Indicates if stores can use server email settings
]: any -> record<enableStoresToUseServerEmailSettings: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/email")
  let body = {enableStoresToUseServerEmailSettings: $enableStoresToUseServerEmailSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get server info
#
# GET /api/v1/server/info
# operationId: ServerInfo_GetServerInfo
export def "server-info GetServerInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: string, onion: string, supportedPaymentMethods: list<string>, fullySynched: bool, syncStatus: table<paymentMethodId: string, nodeInformation: record, chainHeight: int, syncHeight: float, available: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store's roles
#
# GET /api/v1/server/roles
# operationId: Server_GetStoreRoles
export def "server-roles GetStoreRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, role: string, permissions: list<string>, isServerRole: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store email settings
#
# GET /api/v1/stores/{storeId}/email
# operationId: Stores_GetStoreEmailSettings
export def "stores-email GetStoreEmailSettings" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<from: string, server: string, port: int, login: string, disableCertificateCheck: bool, passwordSet: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update store email settings
#
# PUT /api/v1/stores/{storeId}/email
# operationId: Stores_UpdateStoreEmailSettings
export def "stores-email UpdateStoreEmailSettings" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-from: string # The sender email address (e.g. sender@gmail.com)
  --server: string # SMTP server host (e.g. smtp.gmail.com)
  --port: int # SMTP server port (e.g. 587)
  --login: string # SMTP username (e.g. John.Smith)
  --disableCertificateCheck: oneof<nothing, bool> # Disable TLS certificate security checks (e.g. false)
  --password: string # SMTP password. Keep null or empty to not update it. (nullable, e.g. MyS3cr3t)
]: any -> record<from: string, server: string, port: int, login: string, disableCertificateCheck: bool, passwordSet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/email")
  let body = {from: $body_from, server: $server, port: $port, login: $login, disableCertificateCheck: $disableCertificateCheck, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send an email for a store
#
# POST /api/v1/stores/{storeId}/email/send
# operationId: Stores_SendStoreEmail
export def "stores-email-send SendStoreEmail" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email of the recipient
  --subject: string # Subject of the email
  --body-body: string # Body of the email to send as plain text.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/email/send")
  let body = {email: $email, subject: $subject, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store configured lightning addresses
#
# GET /api/v1/stores/{storeId}/lightning-addresses
# operationId: StoreLightningAddresses_GetStoreLightningAddresses
export def "stores-lightning-addresses GetStoreLightningAddresses" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<username: string, currencyCode: string, min: string, max: string, invoiceMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning-addresses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store configured lightning address
#
# GET /api/v1/stores/{storeId}/lightning-addresses/{username}
# operationId: StoreLightningAddresses_GetStoreLightningAddress
export def "stores-lightning-addresses GetStoreLightningAddress" [
  storeId: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<username: string, currencyCode: string, min: string, max: string, invoiceMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning-addresses/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or update store configured lightning address
#
# POST /api/v1/stores/{storeId}/lightning-addresses/{username}
# operationId: StoreLightningAddresses_AddOrUpdateStoreLightningAddress
export def "stores-lightning-addresses AddOrUpdateStoreLightningAddress" [
  storeId: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-username: string # The username of the lightning address
  --currencyCode: string # The currency to generate the invoices for this lightning address in. Leave null lto use the store default. (nullable)
  --min: string # The minimum amount in sats this ln address allows (nullable)
  --max: string # The maximum amount in sats this ln address allows (nullable)
  --invoiceMetadata: record # The invoice metadata as JSON. (nullable)
]: any -> record<username: string, currencyCode: string, min: string, max: string, invoiceMetadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning-addresses/($username)")
  let body = {username: $body_username, currencyCode: $currencyCode, min: $min, max: $max, invoiceMetadata: $invoiceMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove configured lightning address
#
# DELETE /api/v1/stores/{storeId}/lightning-addresses/{username}
# operationId: StoreLightningAddresses_RemoveStoreLightningAddress
export def "stores-lightning-addresses RemoveStoreLightningAddress" [
  storeId: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/lightning-addresses/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store payment methods
#
# GET /api/v1/stores/{storeId}/payment-methods
# operationId: StorePaymentMethods_GetStorePaymentMethods
export def "stores-payment-methods GetStorePaymentMethods" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --onlyEnabled: oneof<nothing, bool> # Fetch payment methods that are enabled/disabled only
  --includeConfig: oneof<nothing, bool> # Fetch the config of the payment methods, if `true`, the permission `btcpay.store.canmodifystoresettings` is required.
]: nothing -> table<enabled: bool, paymentMethodId: string, config: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyEnabled" $onlyEnabled "scalar") (serialize-qp "includeConfig" $includeConfig "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store payment method
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}
# operationId: StorePaymentMethods_GetStorePaymentMethod
export def "stores-payment-methods GetStorePaymentMethod" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeConfig: oneof<nothing, bool> # Fetch the config of the payment methods, if `true`, the permission `btcpay.store.canmodifystoresettings` is required.
]: nothing -> record<enabled: bool, paymentMethodId: string, config: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeConfig" $includeConfig "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update store's payment method
#
# PUT /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}
# operationId: StorePaymentMethods_UpdateStorePaymentMethod
# --config shape: {useBech32Scheme?: bool, lud12Enabled?: bool, lud21Enabled?: bool, connectionString?: string, derivationScheme?: string, label?: string, accountKeyPath?: string}
export def "stores-payment-methods UpdateStorePaymentMethod" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the payment method is enabled, leave null or unspecified to not change current setting (nullable, e.g. true)
  --config: record # The new payment method config, leave null or unspecified to not change current setting (nullable) — shape: {useBech32Scheme?: bool, lud12Enabled?: bool, lud21Enabled?: bool, connectionString?: string, derivationScheme?: string, label?: string, accountKeyPath?: string}
]: any -> record<enabled: bool, paymentMethodId: string, config: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)")
  let body = {enabled: $enabled, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete store's payment method
#
# DELETE /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}
# operationId: StorePaymentMethods_DeleteStorePaymentMethod
export def "stores-payment-methods DeleteStorePaymentMethod" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rates
#
# GET /api/v1/stores/{storeId}/rates
# operationId: Stores_GetStoreRates
export def "stores-rates GetStoreRates" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currencyPair: list # The currency pairs to fetch rates for (nullable, e.g. [BTC_USD, BTC_EUR])
]: nothing -> table<currencyPair: string, errors: list<string>, rate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currencyPair" $currencyPair "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store rate settings for the specified rate source
#
# GET /api/v1/stores/{storeId}/rates/configuration/{rateSource}
# operationId: Stores_GetStoreRateConfiguration
export def "stores-rates-configuration GetStoreRateConfiguration" [
  rateSource: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<spread: string, preferredSource: string, isCustomScript: bool, effectiveScript: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/rates/configuration/($rateSource)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store rate settings for the specified rate source
#
# PUT /api/v1/stores/{storeId}/rates/configuration/{rateSource}
# operationId: Stores_UpdateStoreRateConfiguration
export def "stores-rates-configuration UpdateStoreRateConfiguration" [
  rateSource: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spread: string # A spread applies to the rate fetched in `%`. Must be `>= 0` or `<= 100`
  --preferredSource: string # When `isCustomScript` is `false`, uses this source in the default `effectiveScript`. When `isCustomScript` is `true`, this field is ignored (set to `null`). See `/misc/rate-sources` for available sources.
  --isCustomScript: oneof<nothing, bool> # Whether to use `preferredSource` with default script or a custom `effectiveScript`.
  --effectiveScript: string # When `isCustomScript` is `true`, this represent the custom script used to calculate a currency pair's exchange rate. Else, it represent the script generated by the default rules and `preferredSource`.
]: any -> record<spread: string, preferredSource: string, isCustomScript: bool, effectiveScript: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/rates/configuration/($rateSource)")
  let body = {spread: $spread, preferredSource: $preferredSource, isCustomScript: $isCustomScript, effectiveScript: $effectiveScript} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview rate configuration results
#
# POST /api/v1/stores/{storeId}/rates/configuration/preview
# operationId: Stores_PreviewStoreRateConfiguration
export def "stores-rates-configuration-preview PreviewStoreRateConfiguration" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currencyPair: list # The currency pairs to preview (nullable)
  --spread: string # A spread applies to the rate fetched in `%`. Must be `>= 0` or `<= 100`
  --preferredSource: string # When `isCustomScript` is `false`, uses this source in the default `effectiveScript`. When `isCustomScript` is `true`, this field is ignored (set to `null`). See `/misc/rate-sources` for available sources.
  --isCustomScript: oneof<nothing, bool> # Whether to use `preferredSource` with default script or a custom `effectiveScript`.
  --effectiveScript: string # When `isCustomScript` is `true`, this represent the custom script used to calculate a currency pair's exchange rate. Else, it represent the script generated by the default rules and `preferredSource`.
]: any -> table<currencyPair: string, errors: list<string>, rate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currencyPair" $currencyPair "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/rates/configuration/preview" $qp)
  let body = {spread: $spread, preferredSource: $preferredSource, isCustomScript: $isCustomScript, effectiveScript: $effectiveScript} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store users
#
# GET /api/v1/stores/{storeId}/users
# operationId: Stores_GetStoreUsers
export def "stores-users GetStoreUsers" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>, userId: string, role: string, storeRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a store user
#
# POST /api/v1/stores/{storeId}/users
# operationId: Stores_AddStoreUser
@deprecated --flag userId
@deprecated --flag role
export def "stores-users AddStoreUser" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The id of the user
  --email: string # The email of the user
  --name: string # The name of the user (nullable)
  --imageUrl: string # The profile picture URL of the user (nullable)
  --invitationUrl: string # The pending invitation URL of the user (nullable)
  --emailConfirmed: oneof<nothing, bool> # True if the email has been confirmed by the user
  --requiresEmailConfirmation: oneof<nothing, bool> # True if the email requires confirmation to log in
  --approved: oneof<nothing, bool> # True if an admin has approved the user
  --requiresApproval: oneof<nothing, bool> # True if the instance requires approval to log in
  --created: float # The creation date of the user as a unix timestamp. Null if created before v1.0.5.6 (nullable)
  --disabled: oneof<nothing, bool> # True if an admin has disabled the user
  --roles: list # The roles of the user
  --userId: string # The id of the user (Deprecated, use `id` instead) (DEPRECATED)
  --role: string # The role of the user. Default roles are `Owner`, `Manager`, `Employee` and `Guest` (Deprecated, use `storeRole` instead) (DEPRECATED)
  --storeRole: string # The role of the user. Default roles are `Owner`, `Manager`, `Employee` and `Guest`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/users")
  let body = {id: $id, email: $email, name: $name, imageUrl: $imageUrl, invitationUrl: $invitationUrl, emailConfirmed: $emailConfirmed, requiresEmailConfirmation: $requiresEmailConfirmation, approved: $approved, requiresApproval: $requiresApproval, created: $created, disabled: $disabled, roles: $roles, userId: $userId, role: $role, storeRole: $storeRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a store user
#
# PUT /api/v1/stores/{storeId}/users/{idOrEmail}
# operationId: Stores_UpdateStoreUser
@deprecated --flag userId
@deprecated --flag role
export def "stores-users UpdateStoreUser" [
  storeId: string
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The id of the user
  --email: string # The email of the user
  --name: string # The name of the user (nullable)
  --imageUrl: string # The profile picture URL of the user (nullable)
  --invitationUrl: string # The pending invitation URL of the user (nullable)
  --emailConfirmed: oneof<nothing, bool> # True if the email has been confirmed by the user
  --requiresEmailConfirmation: oneof<nothing, bool> # True if the email requires confirmation to log in
  --approved: oneof<nothing, bool> # True if an admin has approved the user
  --requiresApproval: oneof<nothing, bool> # True if the instance requires approval to log in
  --created: float # The creation date of the user as a unix timestamp. Null if created before v1.0.5.6 (nullable)
  --disabled: oneof<nothing, bool> # True if an admin has disabled the user
  --roles: list # The roles of the user
  --userId: string # The id of the user (Deprecated, use `id` instead) (DEPRECATED)
  --role: string # The role of the user. Default roles are `Owner`, `Manager`, `Employee` and `Guest` (Deprecated, use `storeRole` instead) (DEPRECATED)
  --storeRole: string # The role of the user. Default roles are `Owner`, `Manager`, `Employee` and `Guest`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/users/($idOrEmail)")
  let body = {id: $id, email: $email, name: $name, imageUrl: $imageUrl, invitationUrl: $invitationUrl, emailConfirmed: $emailConfirmed, requiresEmailConfirmation: $requiresEmailConfirmation, approved: $approved, requiresApproval: $requiresApproval, created: $created, disabled: $disabled, roles: $roles, userId: $userId, role: $role, storeRole: $storeRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Store User
#
# DELETE /api/v1/stores/{storeId}/users/{idOrEmail}
# operationId: Stores_RemoveStoreUser
export def "stores-users RemoveStoreUser" [
  storeId: string
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/users/($idOrEmail)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store on-chain wallet overview
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet
# operationId: StoreOnChainWallets_ShowOnChainWalletOverview
export def "stores-payment-methods-wallet ShowOnChainWalletOverview" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: string, unconfirmedBalance: string, confirmedBalance: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store on-chain wallet balance histogram
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/histogram
# operationId: StoreOnChainWallets_ShowOnChainWalletHistogram
export def "stores-payment-methods-wallet-histogram ShowOnChainWalletHistogram" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, balance: string, series: list<string>, labels: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/histogram")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store on-chain wallet fee rate
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/feerate
# operationId: StoreOnChainWallets_GetOnChainFeeRate
export def "stores-payment-methods-wallet-feerate GetOnChainFeeRate" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --blockTarget: float # The number of blocks away you are willing to target for confirmation. Defaults to the wallet's configured `RecommendedFeeBlockTarget`
]: nothing -> record<feeRate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blockTarget" $blockTarget "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/feerate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store on-chain wallet address
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/address
# operationId: StoreOnChainWallets_GetOnChainWalletReceiveAddress
export def "stores-payment-methods-wallet-address GetOnChainWalletReceiveAddress" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceGenerate: oneof<nothing, bool> # Whether to generate a new address for this request even if the previous one was not used (default: false)
]: nothing -> record<address: string, keyPath: string, paymentLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceGenerate" $forceGenerate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UnReserve last store on-chain wallet address
#
# DELETE /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/address
# operationId: StoreOnChainWallets_UnReserveOnChainWalletReceiveAddress
export def "stores-payment-methods-wallet-address UnReserveOnChainWalletReceiveAddress" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/address")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store on-chain wallet transactions
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/transactions
# operationId: StoreOnChainWallets_ShowOnChainWalletTransactions
export def "stores-payment-methods-wallet-transactions ShowOnChainWalletTransactions" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --labelFilter: string # Transaction label to filter by (e.g. invoice)
  --limit: int # Maximum number of transactions to return
  --skip: int # Number of transactions to skip from the start
  --statusFilter: list # Statuses to filter the transactions with
]: nothing -> table<transactionHash: string, comment: string, amount: string, blockHash: string, blockHeight: string, confirmations: string, timestamp: record, status: record, labels: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labelFilter" $labelFilter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "statusFilter" $statusFilter "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create store on-chain wallet transaction
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/transactions
# operationId: StoreOnChainWallets_CreateOnChainTransaction
# --destinations item shape: {destination?: string, amount?: string, subtractFromAmount?: bool}
export def "stores-payment-methods-wallet-transactions CreateOnChainTransaction" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinations: list # What and where to send money — item shape: {destination?: string, amount?: string, subtractFromAmount?: bool}
  --feerate: float # Transaction fee. (format: decimal or long (sats/byte))
  --proceedWithPayjoin: oneof<nothing, bool> # Whether to attempt to do a BIP78 payjoin if one of the destinations is a BIP21 with payjoin enabled (nullable, default: true)
  --proceedWithBroadcast: oneof<nothing, bool> # Whether to broadcast the transaction after creating it or to simply return the transaction in hex format. (nullable, default: true)
  --signWithSeed: oneof<nothing, bool> # If false, build an unsigned PSBT and skip server-side signing (use the CreateOnChainTransactionPSBT client helper). (nullable, default: true)
  --noChange: oneof<nothing, bool> # Whether to send all the spent coins to the destinations (THIS CAN COST YOU SIGNIFICANT AMOUNTS OF MONEY, LEAVE FALSE UNLESS YOU KNOW WHAT YOU ARE DOING). (nullable, default: false)
  --rbf: oneof<nothing, bool> # Whether to enable RBF for the transaction. Leave blank to have it random (beneficial to privacy) (nullable)
  --excludeUnconfirmed: oneof<nothing, bool> # Whether to exclude unconfirmed UTXOs from the transaction. (nullable, default: false)
  --selectedInputs: list # Restrict the creation of the transactions from the outpoints provided ONLY (coin selection) (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/transactions")
  let body = {destinations: $destinations, feerate: $feerate, proceedWithPayjoin: $proceedWithPayjoin, proceedWithBroadcast: $proceedWithBroadcast, signWithSeed: $signWithSeed, noChange: $noChange, rbf: $rbf, excludeUnconfirmed: $excludeUnconfirmed, selectedInputs: $selectedInputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Broadcast an on-chain transaction or finalized PSBT
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/transactions/broadcast
# operationId: StoreOnChainWallets_BroadcastOnChainTransaction
export def "stores-payment-methods-wallet-transactions-broadcast BroadcastOnChainTransaction" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: string # A finalized PSBT (base64) or raw transaction hex string
]: any -> record<transactionHash: string, comment: string, amount: string, blockHash: string, blockHeight: string, confirmations: string, timestamp: record, status: record, labels: table<type: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/transactions/broadcast")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store on-chain wallet transaction
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/transactions/{transactionId}
# operationId: StoreOnChainWallets_GetOnChainWalletTransaction
export def "stores-payment-methods-wallet-transactions GetOnChainWalletTransaction" [
  paymentMethodId: string
  storeId: string
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transactionHash: string, comment: string, amount: string, blockHash: string, blockHeight: string, confirmations: string, timestamp: record, status: record, labels: table<type: string, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/transactions/($transactionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch store on-chain wallet transaction info
#
# PATCH /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/transactions/{transactionId}
# operationId: StoreOnChainWallets_PatchOnChainWalletTransaction
@deprecated --flag labels
export def "stores-payment-methods-wallet-transactions PatchOnChainWalletTransaction" [
  paymentMethodId: string
  storeId: string
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: string # Whether to update the label/comments even if the transaction does not yet exist
  --comment: string # Transaction comment (nullable)
  --labels: list # Transaction labels (DEPRECATED, nullable)
]: any -> record<transactionHash: string, comment: string, amount: string, blockHash: string, blockHeight: string, confirmations: string, timestamp: record, status: record, labels: table<type: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/transactions/($transactionId)" $qp)
  let body = {comment: $comment, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store on-chain wallet UTXOS
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/utxos
# operationId: StoreOnChainWallets_GetOnChainWalletUTXOs
export def "stores-payment-methods-wallet-utxos GetOnChainWalletUTXOs" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<comment: string, amount: string, link: string, outpoint: string, timestamp: record, keyPath: string, address: string, confirmations: float, labels: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/utxos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate store on-chain wallet
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/generate
# operationId: StoreOnChainPaymentMethods_GenerateOnChainWallet
export def "stores-payment-methods-wallet-generate GenerateOnChainWallet" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # A label that will be shown in the UI
  --existingMnemonic: string # A BIP39 mnemonic (e.g. quality warfare scatter zone report forest potato local swing solve upon candy garment boost lab)
  --passphrase: string # A passphrase for the BIP39 mnemonic seed
  --accountNumber: float # The account to derive from the BIP39 mnemonic seed (default: 0)
  --savePrivateKeys: oneof<nothing, bool> # Whether to store the seed inside BTCPay Server to enable some additional services. IF `false` AND `existingMnemonic` IS NOT SPECIFIED, BE SURE TO SECURELY STORE THE SEED IN THE RESPONSE! (default: false)
  --wordList: string@wordList-completer # If `existingMnemonic` is not set, a mnemonic is generated using the specified wordList. (default: English)
  --wordCount: float@wordCount-completer # If `existingMnemonic` is not set, a mnemonic is generated using the specified wordCount. (default: 12)
  --scriptPubKeyType: string@scriptPubKeyType-completer # the type of wallet to generate (default: Segwit)
]: any -> record<enabled: bool, paymentMethodId: string, config: record<derivationScheme: string, label: string, accountKeyPath: string>, mnemonic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/generate")
  let body = {label: $label, existingMnemonic: $existingMnemonic, passphrase: $passphrase, accountNumber: $accountNumber, savePrivateKeys: $savePrivateKeys, wordList: $wordList, wordCount: $wordCount, scriptPubKeyType: $scriptPubKeyType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview store on-chain payment method addresses
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/preview
# operationId: StoreOnChainPaymentMethods_GetOnChainPaymentMethodPreview
export def "stores-payment-methods-wallet-preview GetOnChainPaymentMethodPreview" [
  storeId: string
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # From which index to fetch the addresses
  --count: float # Number of addresses to preview
]: nothing -> record<addresses: table<keyPath: string, address: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview proposed store on-chain payment method addresses
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/preview
# operationId: StoreOnChainPaymentMethods_POSTOnChainPaymentMethodPreview
export def "stores-payment-methods-wallet-preview POSTOnChainPaymentMethodPreview" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # From which index to fetch the addresses
  --count: float # Number of addresses to preview
  --derivationScheme: string # The derivation scheme (e.g. xpub...)
]: any -> record<addresses: table<keyPath: string, address: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/preview" $qp)
  let body = {derivationScheme: $derivationScheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store on-chain wallet objects
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects
# operationId: StoreOnChainWallets_GetOnChainWalletObjects
export def "stores-payment-methods-wallet-objects GetOnChainWalletObjects" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # The ids of objects to fetch, if used, type should be specified (e.g. 03abcde...)
  --type: string # The type of object to fetch (e.g. tx)
  --includeNeighbourData: oneof<nothing, bool> # Whether or not you should include neighbour's node data in the result (ie, `links.objectData`) (default: true)
]: nothing -> table<data: record, links: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "type" $type "scalar") (serialize-qp "includeNeighbourData" $includeNeighbourData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/Update store on-chain wallet objects
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects
# operationId: StoreOnChainWallets_AddOrUpdateOnChainWalletObjects
# --links item shape: {type?: string, id?: string, linkData?: record, objectData?: record}
export def "stores-payment-methods-wallet-objects AddOrUpdateOnChainWalletObjects" [
  paymentMethodId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --links: list # Links of this object (nullable) — item shape: {type?: string, id?: string, linkData?: record, objectData?: record}
  --type: string # The type of wallet object
  --id: string # The identifier of the wallet object (unique per type, per wallet)
]: any -> record<data: record, links: table<type: string, id: string, linkData: record, objectData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects")
  let body = {data: $data, links: $links, type: $type, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store on-chain wallet object
#
# GET /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects/{objectType}/{objectId}
# operationId: StoreOnChainWallets_GetOnChainWalletObject
export def "stores-payment-methods-wallet-objects GetOnChainWalletObject" [
  paymentMethodId: string
  storeId: string
  objectId: string
  objectType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeNeighbourData: oneof<nothing, bool> # Whether or not you should include neighbour's node data in the result (ie, `links.objectData`) (default: true)
]: nothing -> record<data: record, links: table<type: string, id: string, linkData: record, objectData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeNeighbourData" $includeNeighbourData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects/($objectType)/($objectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove store on-chain wallet objects
#
# DELETE /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects/{objectType}/{objectId}
# operationId: StoreOnChainWallets_RemoveOnChainWalletObject
export def "stores-payment-methods-wallet-objects RemoveOnChainWalletObject" [
  paymentMethodId: string
  storeId: string
  objectId: string
  objectType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects/($objectType)/($objectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/Update store on-chain wallet object link
#
# POST /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects/{objectType}/{objectId}/links
# operationId: StoreOnChainWallets_AddOrUpdateOnChainWalletLink
export def "stores-payment-methods-wallet-objects-links AddOrUpdateOnChainWalletLink" [
  paymentMethodId: string
  storeId: string
  objectId: string
  objectType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # The data of the link
  --type: string # The type of wallet object
  --id: string # The identifier of the wallet object (unique per type, per wallet)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects/($objectType)/($objectId)/links")
  let body = {data: $data, type: $type, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove store on-chain wallet object links
#
# DELETE /api/v1/stores/{storeId}/payment-methods/{paymentMethodId}/wallet/objects/{objectType}/{objectId}/links/{linkType}/{linkId}
# operationId: StoreOnChainWallets_RemoveOnChainWalletLink
export def "stores-payment-methods-wallet-objects-links RemoveOnChainWalletLink" [
  paymentMethodId: string
  storeId: string
  linkId: string
  objectId: string
  linkType: string
  objectType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/payment-methods/($paymentMethodId)/wallet/objects/($objectType)/($objectId)/links/($linkType)/($linkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stores
#
# GET /api/v1/stores
# operationId: Stores_GetStores
export def "stores GetStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, website: string, supportUrl: string, logoUrl: string, cssUrl: string, paymentSoundUrl: string, brandColor: string, applyBrandColorToBackend: bool, defaultCurrency: string, additionalTrackedRates: list<string>, invoiceExpiration: record, refundBOLT11Expiration: record, displayExpirationTimer: record, monitoringExpiration: record, speedPolicy: string, lightningDescriptionTemplate: string, paymentTolerance: float, archived: bool, anyoneCanCreateInvoice: bool, receipt: record, lightningAmountInSatoshi: bool, lightningPrivateRouteHints: bool, onChainWithLnInvoiceFallback: bool, redirectAutomatically: bool, showRecommendedFee: bool, recommendedFeeBlockTarget: int, defaultLang: string, htmlTitle: string, networkFeeMode: string, payJoinEnabled: bool, autoDetectLanguage: bool, showPayInWalletButton: bool, showStoreHeader: bool, celebratePayment: bool, playSoundOnPayment: bool, lazyPaymentMethods: bool, defaultPaymentMethod: string, paymentMethodCriteria: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new store
#
# POST /api/v1/stores
# operationId: Stores_CreateStore
# --receipt shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
export def "stores CreateStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the store
  --website: string # The absolute url of the store (nullable, format: url)
  --supportUrl: string # The support URI of the store, can contain the placeholders `{OrderId}` and `{InvoiceId}`. Can be any valid URI, such as a website, email, and nostr. (nullable, format: uri)
  --logoUrl: string # Absolute URL to a logo file or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --cssUrl: string # Absolute URL to CSS file to customize the public/customer-facing pages of the store. (Invoice, Payment Request, Pull Payment, etc.) or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --paymentSoundUrl: string # Absolute URL to a sound file or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --brandColor: string # The brand color of the store in HEX format (nullable, e.g. #F7931A)
  --applyBrandColorToBackend: oneof<nothing, bool> # Apply the brand color to the store's backend as well (default: false)
  --defaultCurrency: string # The default currency of the store (default: USD, e.g. USD)
  --additionalTrackedRates: list # Additional rates to track. The rates of those currencies, in addition to the default currency, will be recorded when a new invoice is created. The rates will then be accessible through reports. (default: [], e.g. [EUR, JPY])
  --invoiceExpiration: any # The time after which an invoice is considered expired if not paid. The value will be rounded down to a minute. (default: 900)
  --refundBOLT11Expiration: any # The minimum expiry of BOLT11 invoices accepted for refunds by default. (in days) (default: 30)
  --displayExpirationTimer: any # The time left that will trigger the countdown timer on the checkout page to be shown. The value will be rounded down to a minute. (default: 300)
  --monitoringExpiration: any # The time after which an invoice which has been paid but not confirmed will be considered invalid. The value will be rounded down to a minute. (default: 86400)
  --speedPolicy: string@speedPolicy-completer # This is a risk mitigation parameter for the merchant to configure how they want to fulfill orders depending on the number of block confirmations for the transaction made by the consumer on the selected cryptocurrency. `"HighSpeed"`: 0 confirmations (1 confirmation if RBF enabled in transaction)    `"MediumSpeed"`: 1 confirmation    `"LowMediumSpeed"`: 2 confirmations    `"LowSpeed"`: 6 confirmations
  --lightningDescriptionTemplate: string # The BOLT11 description of the lightning invoice in the checkout. You can use placeholders '{StoreName}', '{ItemDescription}' and '{OrderId}'. (nullable)
  --paymentTolerance: float # Consider an invoice fully paid, even if the payment is missing 'x' % of the full amount. (format: double, default: 0.0)
  --archived: oneof<nothing, bool> # If true, the store does not appear in the stores list by default. (default: false)
  --anyoneCanCreateInvoice: oneof<nothing, bool> # If true, then no authentication is needed to create invoices on this store. (default: false)
  --receipt: record # Additional settings to customize the public receipt (nullable) — shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
  --lightningAmountInSatoshi: oneof<nothing, bool> # If true, lightning payment methods show amount in satoshi in the checkout page. (default: false)
  --lightningPrivateRouteHints: oneof<nothing, bool> # Should private route hints be included in the lightning payment of the checkout page. (default: false)
  --onChainWithLnInvoiceFallback: oneof<nothing, bool> # Unify on-chain and lightning payment URL. (default: false)
  --redirectAutomatically: oneof<nothing, bool> # After successful payment, should the checkout page redirect the user automatically to the redirect URL of the invoice? (default: false)
  --showRecommendedFee: oneof<nothing, bool> # default: true
  --recommendedFeeBlockTarget: int # The fee rate recommendation in the checkout page for the on-chain payment to be confirmed after 'x' blocks. (format: int32, default: 1)
  --defaultLang: string # The default language to use in the checkout page. (The different translations available are listed [here](https://github.com/btcpayserver/btcpayserver/tree/master/BTCPayServer/wwwroot/locales) (default: en)
  --htmlTitle: string # The HTML title of the checkout page (when you over the tab in your browser) (nullable)
  --networkFeeMode: string@networkFeeMode-completer # Check whether network fee should be added to the invoice if on-chain payment is used. ([More information](https://docs.btcpayserver.org/FAQ/Stores/#add-network-fee-to-invoice-vary-with-mining-fees))
  --payJoinEnabled: oneof<nothing, bool> # If true, payjoin will be proposed in the checkout page if possible. ([More information](https://docs.btcpayserver.org/Payjoin/)) (default: false)
  --autoDetectLanguage: oneof<nothing, bool> # If true, the language on the checkout page will adapt to the language defined by the user's browser settings (default: false)
  --showPayInWalletButton: oneof<nothing, bool> # If true, the "Pay in wallet" button will be shown on the checkout page (Checkout V2) (default: true)
  --showStoreHeader: oneof<nothing, bool> # If true, the store header will be shown on the checkout page (Checkout V2) (default: true)
  --celebratePayment: oneof<nothing, bool> # If true, payments on the checkout page will be celebrated with confetti (Checkout V2) (default: true)
  --playSoundOnPayment: oneof<nothing, bool> # If true, sounds on the checkout page will be enabled (Checkout V2) (default: false)
  --lazyPaymentMethods: oneof<nothing, bool> # If true, payment methods are enabled individually upon user interaction in the invoice (default: false)
  --defaultPaymentMethod: string # Payment method IDs. Available payment method IDs for Bitcoin are:   - `"BTC-CHAIN"`: Onchain    -`"BTC-LN"`: Lightning    - `"BTC-LNURL"`: LNURL (e.g. BTC-CHAIN)
  --paymentMethodCriteria: record # The criteria required to activate specific payment methods. (nullable)
]: any -> record<name: string, website: string, supportUrl: string, logoUrl: string, cssUrl: string, paymentSoundUrl: string, brandColor: string, applyBrandColorToBackend: bool, defaultCurrency: string, additionalTrackedRates: list<string>, invoiceExpiration: record, refundBOLT11Expiration: record, displayExpirationTimer: record, monitoringExpiration: record, speedPolicy: string, lightningDescriptionTemplate: string, paymentTolerance: float, archived: bool, anyoneCanCreateInvoice: bool, receipt: record, lightningAmountInSatoshi: bool, lightningPrivateRouteHints: bool, onChainWithLnInvoiceFallback: bool, redirectAutomatically: bool, showRecommendedFee: bool, recommendedFeeBlockTarget: int, defaultLang: string, htmlTitle: string, networkFeeMode: string, payJoinEnabled: bool, autoDetectLanguage: bool, showPayInWalletButton: bool, showStoreHeader: bool, celebratePayment: bool, playSoundOnPayment: bool, lazyPaymentMethods: bool, defaultPaymentMethod: string, paymentMethodCriteria: record, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stores")
  let body = {name: $name, website: $website, supportUrl: $supportUrl, logoUrl: $logoUrl, cssUrl: $cssUrl, paymentSoundUrl: $paymentSoundUrl, brandColor: $brandColor, applyBrandColorToBackend: $applyBrandColorToBackend, defaultCurrency: $defaultCurrency, additionalTrackedRates: $additionalTrackedRates, invoiceExpiration: $invoiceExpiration, refundBOLT11Expiration: $refundBOLT11Expiration, displayExpirationTimer: $displayExpirationTimer, monitoringExpiration: $monitoringExpiration, speedPolicy: $speedPolicy, lightningDescriptionTemplate: $lightningDescriptionTemplate, paymentTolerance: $paymentTolerance, archived: $archived, anyoneCanCreateInvoice: $anyoneCanCreateInvoice, receipt: $receipt, lightningAmountInSatoshi: $lightningAmountInSatoshi, lightningPrivateRouteHints: $lightningPrivateRouteHints, onChainWithLnInvoiceFallback: $onChainWithLnInvoiceFallback, redirectAutomatically: $redirectAutomatically, showRecommendedFee: $showRecommendedFee, recommendedFeeBlockTarget: $recommendedFeeBlockTarget, defaultLang: $defaultLang, htmlTitle: $htmlTitle, networkFeeMode: $networkFeeMode, payJoinEnabled: $payJoinEnabled, autoDetectLanguage: $autoDetectLanguage, showPayInWalletButton: $showPayInWalletButton, showStoreHeader: $showStoreHeader, celebratePayment: $celebratePayment, playSoundOnPayment: $playSoundOnPayment, lazyPaymentMethods: $lazyPaymentMethods, defaultPaymentMethod: $defaultPaymentMethod, paymentMethodCriteria: $paymentMethodCriteria} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store
#
# GET /api/v1/stores/{storeId}
# operationId: Stores_GetStore
export def "stores GetStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, website: string, supportUrl: string, logoUrl: string, cssUrl: string, paymentSoundUrl: string, brandColor: string, applyBrandColorToBackend: bool, defaultCurrency: string, additionalTrackedRates: list<string>, invoiceExpiration: record, refundBOLT11Expiration: record, displayExpirationTimer: record, monitoringExpiration: record, speedPolicy: string, lightningDescriptionTemplate: string, paymentTolerance: float, archived: bool, anyoneCanCreateInvoice: bool, receipt: record, lightningAmountInSatoshi: bool, lightningPrivateRouteHints: bool, onChainWithLnInvoiceFallback: bool, redirectAutomatically: bool, showRecommendedFee: bool, recommendedFeeBlockTarget: int, defaultLang: string, htmlTitle: string, networkFeeMode: string, payJoinEnabled: bool, autoDetectLanguage: bool, showPayInWalletButton: bool, showStoreHeader: bool, celebratePayment: bool, playSoundOnPayment: bool, lazyPaymentMethods: bool, defaultPaymentMethod: string, paymentMethodCriteria: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update store
#
# PUT /api/v1/stores/{storeId}
# operationId: Stores_UpdateStore
# --receipt shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
export def "stores UpdateStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the store
  --website: string # The absolute url of the store (nullable, format: url)
  --supportUrl: string # The support URI of the store, can contain the placeholders `{OrderId}` and `{InvoiceId}`. Can be any valid URI, such as a website, email, and nostr. (nullable, format: uri)
  --logoUrl: string # Absolute URL to a logo file or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --cssUrl: string # Absolute URL to CSS file to customize the public/customer-facing pages of the store. (Invoice, Payment Request, Pull Payment, etc.) or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --paymentSoundUrl: string # Absolute URL to a sound file or a reference to an uploaded file id with `fileid:ID` (nullable, format: uri)
  --brandColor: string # The brand color of the store in HEX format (nullable, e.g. #F7931A)
  --applyBrandColorToBackend: oneof<nothing, bool> # Apply the brand color to the store's backend as well (default: false)
  --defaultCurrency: string # The default currency of the store (default: USD, e.g. USD)
  --additionalTrackedRates: list # Additional rates to track. The rates of those currencies, in addition to the default currency, will be recorded when a new invoice is created. The rates will then be accessible through reports. (default: [], e.g. [EUR, JPY])
  --invoiceExpiration: any # The time after which an invoice is considered expired if not paid. The value will be rounded down to a minute. (default: 900)
  --refundBOLT11Expiration: any # The minimum expiry of BOLT11 invoices accepted for refunds by default. (in days) (default: 30)
  --displayExpirationTimer: any # The time left that will trigger the countdown timer on the checkout page to be shown. The value will be rounded down to a minute. (default: 300)
  --monitoringExpiration: any # The time after which an invoice which has been paid but not confirmed will be considered invalid. The value will be rounded down to a minute. (default: 86400)
  --speedPolicy: string@speedPolicy-completer # This is a risk mitigation parameter for the merchant to configure how they want to fulfill orders depending on the number of block confirmations for the transaction made by the consumer on the selected cryptocurrency. `"HighSpeed"`: 0 confirmations (1 confirmation if RBF enabled in transaction)    `"MediumSpeed"`: 1 confirmation    `"LowMediumSpeed"`: 2 confirmations    `"LowSpeed"`: 6 confirmations
  --lightningDescriptionTemplate: string # The BOLT11 description of the lightning invoice in the checkout. You can use placeholders '{StoreName}', '{ItemDescription}' and '{OrderId}'. (nullable)
  --paymentTolerance: float # Consider an invoice fully paid, even if the payment is missing 'x' % of the full amount. (format: double, default: 0.0)
  --archived: oneof<nothing, bool> # If true, the store does not appear in the stores list by default. (default: false)
  --anyoneCanCreateInvoice: oneof<nothing, bool> # If true, then no authentication is needed to create invoices on this store. (default: false)
  --receipt: record # Additional settings to customize the public receipt (nullable) — shape: {enabled?: bool, showQR?: bool, showPayments?: bool}
  --lightningAmountInSatoshi: oneof<nothing, bool> # If true, lightning payment methods show amount in satoshi in the checkout page. (default: false)
  --lightningPrivateRouteHints: oneof<nothing, bool> # Should private route hints be included in the lightning payment of the checkout page. (default: false)
  --onChainWithLnInvoiceFallback: oneof<nothing, bool> # Unify on-chain and lightning payment URL. (default: false)
  --redirectAutomatically: oneof<nothing, bool> # After successful payment, should the checkout page redirect the user automatically to the redirect URL of the invoice? (default: false)
  --showRecommendedFee: oneof<nothing, bool> # default: true
  --recommendedFeeBlockTarget: int # The fee rate recommendation in the checkout page for the on-chain payment to be confirmed after 'x' blocks. (format: int32, default: 1)
  --defaultLang: string # The default language to use in the checkout page. (The different translations available are listed [here](https://github.com/btcpayserver/btcpayserver/tree/master/BTCPayServer/wwwroot/locales) (default: en)
  --htmlTitle: string # The HTML title of the checkout page (when you over the tab in your browser) (nullable)
  --networkFeeMode: string@networkFeeMode-completer # Check whether network fee should be added to the invoice if on-chain payment is used. ([More information](https://docs.btcpayserver.org/FAQ/Stores/#add-network-fee-to-invoice-vary-with-mining-fees))
  --payJoinEnabled: oneof<nothing, bool> # If true, payjoin will be proposed in the checkout page if possible. ([More information](https://docs.btcpayserver.org/Payjoin/)) (default: false)
  --autoDetectLanguage: oneof<nothing, bool> # If true, the language on the checkout page will adapt to the language defined by the user's browser settings (default: false)
  --showPayInWalletButton: oneof<nothing, bool> # If true, the "Pay in wallet" button will be shown on the checkout page (Checkout V2) (default: true)
  --showStoreHeader: oneof<nothing, bool> # If true, the store header will be shown on the checkout page (Checkout V2) (default: true)
  --celebratePayment: oneof<nothing, bool> # If true, payments on the checkout page will be celebrated with confetti (Checkout V2) (default: true)
  --playSoundOnPayment: oneof<nothing, bool> # If true, sounds on the checkout page will be enabled (Checkout V2) (default: false)
  --lazyPaymentMethods: oneof<nothing, bool> # If true, payment methods are enabled individually upon user interaction in the invoice (default: false)
  --defaultPaymentMethod: string # Payment method IDs. Available payment method IDs for Bitcoin are:   - `"BTC-CHAIN"`: Onchain    -`"BTC-LN"`: Lightning    - `"BTC-LNURL"`: LNURL (e.g. BTC-CHAIN)
  --paymentMethodCriteria: record # The criteria required to activate specific payment methods. (nullable)
  --id: string # The id of the store
]: any -> record<name: string, website: string, supportUrl: string, logoUrl: string, cssUrl: string, paymentSoundUrl: string, brandColor: string, applyBrandColorToBackend: bool, defaultCurrency: string, additionalTrackedRates: list<string>, invoiceExpiration: record, refundBOLT11Expiration: record, displayExpirationTimer: record, monitoringExpiration: record, speedPolicy: string, lightningDescriptionTemplate: string, paymentTolerance: float, archived: bool, anyoneCanCreateInvoice: bool, receipt: record, lightningAmountInSatoshi: bool, lightningPrivateRouteHints: bool, onChainWithLnInvoiceFallback: bool, redirectAutomatically: bool, showRecommendedFee: bool, recommendedFeeBlockTarget: int, defaultLang: string, htmlTitle: string, networkFeeMode: string, payJoinEnabled: bool, autoDetectLanguage: bool, showPayInWalletButton: bool, showStoreHeader: bool, celebratePayment: bool, playSoundOnPayment: bool, lazyPaymentMethods: bool, defaultPaymentMethod: string, paymentMethodCriteria: record, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)")
  let body = {name: $name, website: $website, supportUrl: $supportUrl, logoUrl: $logoUrl, cssUrl: $cssUrl, paymentSoundUrl: $paymentSoundUrl, brandColor: $brandColor, applyBrandColorToBackend: $applyBrandColorToBackend, defaultCurrency: $defaultCurrency, additionalTrackedRates: $additionalTrackedRates, invoiceExpiration: $invoiceExpiration, refundBOLT11Expiration: $refundBOLT11Expiration, displayExpirationTimer: $displayExpirationTimer, monitoringExpiration: $monitoringExpiration, speedPolicy: $speedPolicy, lightningDescriptionTemplate: $lightningDescriptionTemplate, paymentTolerance: $paymentTolerance, archived: $archived, anyoneCanCreateInvoice: $anyoneCanCreateInvoice, receipt: $receipt, lightningAmountInSatoshi: $lightningAmountInSatoshi, lightningPrivateRouteHints: $lightningPrivateRouteHints, onChainWithLnInvoiceFallback: $onChainWithLnInvoiceFallback, redirectAutomatically: $redirectAutomatically, showRecommendedFee: $showRecommendedFee, recommendedFeeBlockTarget: $recommendedFeeBlockTarget, defaultLang: $defaultLang, htmlTitle: $htmlTitle, networkFeeMode: $networkFeeMode, payJoinEnabled: $payJoinEnabled, autoDetectLanguage: $autoDetectLanguage, showPayInWalletButton: $showPayInWalletButton, showStoreHeader: $showStoreHeader, celebratePayment: $celebratePayment, playSoundOnPayment: $playSoundOnPayment, lazyPaymentMethods: $lazyPaymentMethods, defaultPaymentMethod: $defaultPaymentMethod, paymentMethodCriteria: $paymentMethodCriteria, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Store
#
# DELETE /api/v1/stores/{storeId}
# operationId: Stores_DeleteStore
export def "stores DeleteStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a logo for the store
#
# POST /api/v1/stores/{storeId}/logo
# operationId: Stores_UploadStoreLogo
export def "stores-logo UploadStoreLogo" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The logo (format: binary)
]: any -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/logo")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Deletes the store logo
#
# DELETE /api/v1/stores/{storeId}/logo
# operationId: Stores_DeleteStoreLogo
export def "stores-logo DeleteStoreLogo" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store's roles
#
# GET /api/v1/stores/{storeId}/roles
# operationId: Stores_GetStoreRoles
export def "stores-roles GetStoreRoles" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, role: string, permissions: list<string>, isServerRole: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an offering
#
# GET /api/v1/stores/{storeId}/offerings/{offeringId}
# operationId: GetOffering
export def "stores-offerings GetOffering" [
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appName: string, successRedirectUrl: string, metadata: record, features: table<id: string, description: string>, id: string, storeId: string, appId: string, plans: table<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an offering
#
# PUT /api/v1/stores/{storeId}/offerings/{offeringId}
# operationId: UpdateOffering
# --features item shape: {id: string, description: string}
export def "stores-offerings UpdateOffering" [
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appName: string # Display name of the related [application](#tag/Apps). (nullable, e.g. Example App)
  --successRedirectUrl: string # The default URL to redirect to after a plan checkout is successful. (nullable, e.g. https://example.com/success)
  --metadata: record # Custom metadata for the offering. (e.g. {category: saas, region: us})
  --features: list # List of features included in this offering. (nullable) — item shape: {id: string, description: string}
]: any -> record<appName: string, successRedirectUrl: string, metadata: record, features: table<id: string, description: string>, id: string, storeId: string, appId: string, plans: table<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)")
  let body = {appName: $appName, successRedirectUrl: $successRedirectUrl, metadata: $metadata, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List offerings for a store
#
# GET /api/v1/stores/{storeId}/offerings
# operationId: GetOfferings
export def "stores-offerings GetOfferings" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appName: string, successRedirectUrl: string, metadata: record, features: list<record>, id: string, storeId: string, appId: string, plans: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an offering
#
# POST /api/v1/stores/{storeId}/offerings
# operationId: CreateOffering
# --features item shape: {id: string, description: string}
export def "stores-offerings CreateOffering" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appName: string # Display name of the related [application](#tag/Apps). (nullable, e.g. Example App)
  --successRedirectUrl: string # The default URL to redirect to after a plan checkout is successful. (nullable, e.g. https://example.com/success)
  --metadata: record # Custom metadata for the offering. (e.g. {category: saas, region: us})
  --features: list # List of features included in this offering. (nullable) — item shape: {id: string, description: string}
]: any -> record<appName: string, successRedirectUrl: string, metadata: record, features: table<id: string, description: string>, id: string, storeId: string, appId: string, plans: table<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings")
  let body = {appName: $appName, successRedirectUrl: $successRedirectUrl, metadata: $metadata, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an offering plan
#
# POST /api/v1/stores/{storeId}/offerings/{offeringId}/plans
# operationId: CreateOfferingPlan
export def "stores-offerings-plans CreateOfferingPlan" [
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Display name of the plan. (e.g. Monthly Plan)
  --description: string # Short description of the plan. (e.g. Standard monthly subscription.)
  --currency: string # Currency code for the plan price. (e.g. USD)
  --gracePeriodDays: int # Number of grace period days after expiry. (nullable, e.g. 7)
  --optimisticActivation: oneof<nothing, bool> # Indicates if the plan is activated before payment confirmation. (nullable, e.g. true)
  --price: string # Price of the plan as a numeric string. (nullable, e.g. 19.99)
  --renewable: oneof<nothing, bool> # Indicates if the plan can be renewed. (nullable, e.g. true)
  --trialDays: int # Number of trial days before billing. (nullable, e.g. 14)
  --metadata: record # Custom metadata for the plan. (e.g. {tier: standard})
  --recurringType: string@recurringType-completer # Recurring interval for billing. (nullable, e.g. Monthly)
  --features: list # List of features from the offering included in this plan. (nullable, e.g. [feature-analytics])
]: any -> record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/plans")
  let body = {name: $name, description: $description, currency: $currency, gracePeriodDays: $gracePeriodDays, optimisticActivation: $optimisticActivation, price: $price, renewable: $renewable, trialDays: $trialDays, metadata: $metadata, recurringType: $recurringType, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an offering plan
#
# GET /api/v1/stores/{storeId}/offerings/{offeringId}/plans/{planId}
# operationId: GetOfferingPlan
export def "stores-offerings-plans GetOfferingPlan" [
  offeringId: string
  planId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/plans/($planId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an offering plan
#
# PUT /api/v1/stores/{storeId}/offerings/{offeringId}/plans/{planId}
# operationId: UpdateOfferingPlan
export def "stores-offerings-plans UpdateOfferingPlan" [
  offeringId: string
  planId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Display name of the plan. (e.g. Monthly Plan)
  --description: string # Short description of the plan. (e.g. Standard monthly subscription.)
  --currency: string # Currency code for the plan price. (e.g. USD)
  --gracePeriodDays: int # Number of grace period days after expiry. (nullable, e.g. 7)
  --optimisticActivation: oneof<nothing, bool> # Indicates if the plan is activated before payment confirmation. (nullable, e.g. true)
  --price: string # Price of the plan as a numeric string. (nullable, e.g. 19.99)
  --renewable: oneof<nothing, bool> # Indicates if the plan can be renewed. (nullable, e.g. true)
  --trialDays: int # Number of trial days before billing. (nullable, e.g. 14)
  --metadata: record # Custom metadata for the plan. (e.g. {tier: standard})
  --recurringType: string@recurringType-completer # Recurring interval for billing. (nullable, e.g. Monthly)
  --features: list # List of features from the offering included in this plan. (nullable, e.g. [feature-analytics])
]: any -> record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/plans/($planId)")
  let body = {name: $name, description: $description, currency: $currency, gracePeriodDays: $gracePeriodDays, optimisticActivation: $optimisticActivation, price: $price, renewable: $renewable, trialDays: $trialDays, metadata: $metadata, recurringType: $recurringType, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a subscriber
#
# GET /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}
# operationId: GetSubscriber
export def "stores-offerings-subscribers GetSubscriber" [
  customerSelector: string
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list<record>, id: string, storeId: string, appId: string, plans: list<record>>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a subscriber
#
# DELETE /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}
# operationId: DeleteSubscriber
export def "stores-offerings-subscribers DeleteSubscriber" [
  customerSelector: string
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subscriber credit balance
#
# GET /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}/credits/{currency}
# operationId: GetCredit
export def "stores-offerings-subscribers-credits GetCredit" [
  customerSelector: string
  offeringId: string
  storeId: string
  currency: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currency: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)/credits/($currency)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update subscriber credit balance
#
# POST /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}/credits/{currency}
# operationId: UpdateCredit
export def "stores-offerings-subscribers-credits UpdateCredit" [
  customerSelector: string
  offeringId: string
  storeId: string
  currency: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --credit: string # Amount of credit to add as a numeric string. (e.g. 25.00)
  --charge: string # Amount to deduct as a numeric string. (e.g. 10.00)
  --description: string # Short description explaining the credit change. (e.g. Monthly reward bonus)
  --allowOverdraft: oneof<nothing, bool> # Indicates if the credit balance is allowed to go negative. (e.g. false)
]: any -> record<currency: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)/credits/($currency)")
  let body = {credit: $credit, charge: $charge, description: $description, allowOverdraft: $allowOverdraft} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suspend a subscriber
#
# POST /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}/suspend
# operationId: SuspendSubscriber
export def "stores-offerings-subscribers-suspend SuspendSubscriber" [
  customerSelector: string
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for the suspension. (e.g. Suspicious behavior detected)
]: any -> record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list<record>, id: string, storeId: string, appId: string, plans: list<record>>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)/suspend")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsuspend a subscriber
#
# POST /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}/unsuspend
# operationId: UnsuspendSubscriber
export def "stores-offerings-subscribers-unsuspend UnsuspendSubscriber" [
  customerSelector: string
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list<record>, id: string, storeId: string, appId: string, plans: list<record>>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)/unsuspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update subscriber dates
#
# PUT /api/v1/stores/{storeId}/offerings/{offeringId}/subscribers/{customerSelector}/dates
# operationId: UpdateSubscriberDates
export def "stores-offerings-subscribers-dates UpdateSubscriberDates" [
  customerSelector: string
  offeringId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: int # New subscription start date as a Unix timestamp. Omit to leave the current start date unchanged. (nullable, format: unix-time, e.g. 1710000000)
  --expirationDate: int # New expiration date as a Unix timestamp. Updates `trialEnd` if the subscriber is in a trial, otherwise updates `periodEnd`. Grace period end and reminder date are recalculated automatically. Omit to leave the current expiration date unchanged. (nullable, format: unix-time, e.g. 1712678400)
]: any -> record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list<record>, id: string, storeId: string, appId: string, plans: list<record>>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/offerings/($offeringId)/subscribers/($customerSelector)/dates")
  let body = {startDate: $startDate, expirationDate: $expirationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a plan checkout
#
# GET /api/v1/plan-checkout/{checkoutId}
# operationId: GetPlanCheckout
export def "plan-checkout GetPlanCheckout" [
  checkoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<subscriber: record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list, id: string, storeId: string, appId: string, plans: list>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, baseUrl: string, id: string, invoiceId: string, successRedirectUrl: string, expiration: int, redirectUrl: string, invoiceMetadata: record, metadata: record, newSubscriber: bool, isTrial: bool, created: int, planStarted: bool, newSubscriberMetadata: record, refundAmount: string, creditedByInvoice: string, onPayBehavior: string, isExpired: bool, url: string, creditPurchase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plan-checkout/($checkoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Proceed with a plan checkout
#
# POST /api/v1/plan-checkout/{checkoutId}
# operationId: ProceedPlanCheckout
export def "plan-checkout ProceedPlanCheckout" [
  checkoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Optional customer email used when proceeding with the checkout. (e.g. user@example.com)
]: nothing -> record<subscriber: record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list, id: string, storeId: string, appId: string, plans: list>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, baseUrl: string, id: string, invoiceId: string, successRedirectUrl: string, expiration: int, redirectUrl: string, invoiceMetadata: record, metadata: record, newSubscriber: bool, isTrial: bool, created: int, planStarted: bool, newSubscriberMetadata: record, refundAmount: string, creditedByInvoice: string, onPayBehavior: string, isExpired: bool, url: string, creditPurchase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/plan-checkout/($checkoutId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a plan checkout session
#
# POST /api/v1/plan-checkout
# operationId: CreatePlanCheckout
export def "plan-checkout CreatePlanCheckout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # Store ID of the item (e.g. 9CiNzKoANXxmk5ayZngSXrHTiVvvgCrwrpFQd4m2K776)
  --offeringId: string # Offering's ID (e.g. offering_DKWhZGB6PZsgTcPwpf)
  --planId: string # Plan's ID (e.g. plan_KZMVyuQp3v2vFWnEUM)
  --customerSelector: string # Flexible identifier for selecting a customer. Supports: customer ID (e.g., `cust_abc123`), an email (e.g., `user@example.com`), or a key/value identity (e.g., `Email:user@example.com`). (e.g. cust_GUGnpx3311fkaqGk7f)
  --durationMinutes: int # How long the checkout session is valid, in minutes. (nullable, e.g. 30)
  --onPayBehavior: string@onPayBehavior-completer # Defines how the system should behave when payment is processed during a plan checkout or migration. * `SoftMigration`: Starts the plan only if payment is due. If no payment is due yet, the amount is added as credit instead of starting the plan. * `HardMigration`: Starts the plan immediately, even if payment is not due. If the user already paid for unused time, the unused portion is refunded before starting the plan. (e.g. SoftMigration)
  --newSubscriberMetadata: record # Metadata used when creating a new subscriber. (e.g. {locale: en-US})
  --invoiceMetadata: record # Metadata attached to the created invoice. (e.g. {campaign: winter-sale})
  --metadata: record # Custom metadata for the checkout session. (e.g. {flow: upgrade})
  --isTrial: oneof<nothing, bool> # Indicates if the checkout starts a trial. (nullable, e.g. false)
  --creditPurchase: string # Amount of credit to purchase. (nullable, e.g. 20.00)
  --successRedirectLink: string # URL to redirect the user after checkout success. (This default to offering's successRedirectLink, also, the `checkoutPlanId` query parameter will be added to the URL.) (e.g. https://example.com/thank-you)
  --newSubscriberEmail: string # Email address for creating a new subscriber. Keep `null` to let the user choose an email address in the checkout page. (nullable, e.g. user@example.com)
]: any -> record<subscriber: record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list, id: string, storeId: string, appId: string, plans: list>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list<string>, renewable: bool, metadata: record>, baseUrl: string, id: string, invoiceId: string, successRedirectUrl: string, expiration: int, redirectUrl: string, invoiceMetadata: record, metadata: record, newSubscriber: bool, isTrial: bool, created: int, planStarted: bool, newSubscriberMetadata: record, refundAmount: string, creditedByInvoice: string, onPayBehavior: string, isExpired: bool, url: string, creditPurchase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plan-checkout")
  let body = {storeId: $storeId, offeringId: $offeringId, planId: $planId, customerSelector: $customerSelector, durationMinutes: $durationMinutes, onPayBehavior: $onPayBehavior, newSubscriberMetadata: $newSubscriberMetadata, invoiceMetadata: $invoiceMetadata, metadata: $metadata, isTrial: $isTrial, creditPurchase: $creditPurchase, successRedirectLink: $successRedirectLink, newSubscriberEmail: $newSubscriberEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a subscriber portal session
#
# POST /api/v1/subscriber-portal
# operationId: CreatePortalSession
export def "subscriber-portal CreatePortalSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # Store ID of the item (e.g. 9CiNzKoANXxmk5ayZngSXrHTiVvvgCrwrpFQd4m2K776)
  --offeringId: string # Offering's ID (e.g. offering_DKWhZGB6PZsgTcPwpf)
  --customerSelector: string # Flexible identifier for selecting a customer. Supports: customer ID (e.g., `cust_abc123`), an email (e.g., `user@example.com`), or a key/value identity (e.g., `Email:user@example.com`). (e.g. cust_GUGnpx3311fkaqGk7f)
  --durationMinutes: int # Duration in minutes before the portal session expires. (nullable, e.g. 30)
]: any -> record<baseUrl: string, id: string, subscriber: record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list, id: string, storeId: string, appId: string, plans: list>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string>, expiration: int, isExpired: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/subscriber-portal")
  let body = {storeId: $storeId, offeringId: $offeringId, customerSelector: $customerSelector, durationMinutes: $durationMinutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a subscriber portal session
#
# GET /api/v1/subscriber-portal/{portalSessionId}
# operationId: GetPortalSession
export def "subscriber-portal GetPortalSession" [
  portalSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseUrl: string, id: string, subscriber: record<created: int, customer: record<storeId: string, id: string, externalId: string, identities: record, metadata: record>, offering: record<appName: string, successRedirectUrl: string, metadata: record, features: list, id: string, storeId: string, appId: string, plans: list>, plan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, periodEnd: int, trialEnd: int, gracePeriodEnd: int, isActive: bool, isSuspended: bool, suspensionReason: string, autoRenew: bool, metadata: record, processingInvoiceId: string, nextPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlan: record<id: string, name: string, status: string, price: string, currency: string, recurringType: string, gracePeriodDays: int, trialDays: int, description: string, memberCount: int, optimisticActivation: bool, features: list, renewable: bool, metadata: record>, scheduledPlanActivatesAt: int, phase: string>, expiration: int, isExpired: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriber-portal/($portalSessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user information
#
# GET /api/v1/users/me
# operationId: Users_GetCurrentUser
export def "users-me GetCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update current user information
#
# PUT /api/v1/users/me
# operationId: Users_UpdateCurrentUser
export def "users-me UpdateCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user (nullable)
  --name: string # The name of the user (nullable)
  --imageUrl: string # The profile picture URL of the user (nullable)
  --currentPassword: string # The current password of the user (nullable)
  --newPassword: string # The new password of the user (nullable)
]: any -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let body = {email: $email, name: $name, imageUrl: $imageUrl, currentPassword: $currentPassword, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes user profile
#
# DELETE /api/v1/users/me
# operationId: Users_DeleteCurrentUser
export def "users-me DeleteCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a profile picture for the current user
#
# POST /api/v1/users/me/picture
# operationId: Users_UploadCurrentUserProfilePicture
export def "users-me-picture UploadCurrentUserProfilePicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The profile picture (format: binary)
]: any -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/picture")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Deletes user profile picture
#
# DELETE /api/v1/users/me/picture
# operationId: Users_DeleteCurrentUserProfilePicture
export def "users-me-picture DeleteCurrentUserProfilePicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/picture")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users
#
# GET /api/v1/users
# operationId: Users_GetUsers
export def "users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user
#
# POST /api/v1/users
# operationId: Users_CreateUser
export def "users CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the new user
  --name: string # The name of the new user (nullable)
  --imageUrl: string # The profile picture URL of the new user (nullable)
  --password: string # The password of the new user (if no password is set, an email will be sent to the user requiring him to set the password) (nullable)
  --isAdministrator: oneof<nothing, bool> # Make this user administrator (only if you have the `unrestricted` permission of a server administrator) (nullable, default: false)
  --sendInvitationEmail: oneof<nothing, bool> # Flag to specify if an email invitation should be sent to the user (nullable, default: true)
]: any -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let body = {email: $email, name: $name, imageUrl: $imageUrl, password: $password, isAdministrator: $isAdministrator, sendInvitationEmail: $sendInvitationEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user by ID or Email
#
# GET /api/v1/users/{idOrEmail}
# operationId: Users_GetUser
export def "users GetUser" [
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, email: string, name: string, imageUrl: string, invitationUrl: string, emailConfirmed: bool, requiresEmailConfirmation: bool, approved: bool, requiresApproval: bool, created: float, disabled: bool, roles: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /api/v1/users/{idOrEmail}
# operationId: Users_DeleteUser
export def "users DeleteUser" [
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle user lock out
#
# POST /api/v1/users/{idOrEmail}/lock
# operationId: Users_ToggleUserLock
export def "users-lock ToggleUserLock" [
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locked: oneof<nothing, bool> # Whether to lock or unlock the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)/lock")
  let body = {locked: $locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle user approval
#
# POST /api/v1/users/{idOrEmail}/approve
# operationId: Users_ToggleUserApproval
export def "users-approve ToggleUserApproval" [
  idOrEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --approved: oneof<nothing, bool> # Whether to approve or unapprove the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($idOrEmail)/approve")
  let body = {approved: $approved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get webhooks of a store
#
# GET /api/v1/stores/{storeId}/webhooks
# operationId: Webhooks_GetWebhooks
export def "stores-webhooks GetWebhooks" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<enabled: bool, automaticRedelivery: bool, url: string, authorizedEvents: record<everything: bool, specificEvents: list>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new webhook
#
# POST /api/v1/stores/{storeId}/webhooks
# operationId: Webhooks_CreateWebhook
# --authorizedEvents shape: {everything?: bool, specificEvents?: list}
export def "stores-webhooks CreateWebhook" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether this webhook is enabled or not (default: true)
  --automaticRedelivery: oneof<nothing, bool> # If true, BTCPay Server will retry to redeliver any failed delivery after 10 seconds, 1 minutes and up to 6 times after 10 minutes. (default: true)
  --body-url: string # The endpoint where BTCPay Server will make the POST request with the webhook body
  --authorizedEvents: record # Which event should be received by this endpoint — shape: {everything?: bool, specificEvents?: list}
  --secret: string # Must be used by the callback receiver to ensure the delivery comes from BTCPay Server. BTCPay Server includes the `BTCPay-Sig` HTTP header, whose format is `sha256=HMAC256(UTF8(webhook's secret), body)`. The pattern to authenticate the webhook is similar to [how to secure webhooks in Github](https://docs.github.com/webhooks/securing/). If left out, null, or empty, the secret will be auto-generated. (nullable)
]: any -> record<secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks")
  let body = {enabled: $enabled, automaticRedelivery: $automaticRedelivery, url: $body_url, authorizedEvents: $authorizedEvents, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a webhook of a store
#
# GET /api/v1/stores/{storeId}/webhooks/{webhookId}
# operationId: Webhooks_GetWebhook
export def "stores-webhooks GetWebhook" [
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, automaticRedelivery: bool, url: string, authorizedEvents: record<everything: bool, specificEvents: list<string>>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /api/v1/stores/{storeId}/webhooks/{webhookId}
# operationId: Webhooks_UpdateWebhook
# --authorizedEvents shape: {everything?: bool, specificEvents?: list}
export def "stores-webhooks UpdateWebhook" [
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether this webhook is enabled or not (default: true)
  --automaticRedelivery: oneof<nothing, bool> # If true, BTCPay Server will retry to redeliver any failed delivery after 10 seconds, 1 minutes and up to 6 times after 10 minutes. (default: true)
  --body-url: string # The endpoint where BTCPay Server will make the POST request with the webhook body
  --authorizedEvents: record # Which event should be received by this endpoint — shape: {everything?: bool, specificEvents?: list}
  --secret: string # Must be used by the callback receiver to ensure the delivery comes from BTCPay Server. BTCPay Server includes the `BTCPay-Sig` HTTP header, whose format is `sha256=HMAC256(UTF8(webhook's secret), body)`. The pattern to authenticate the webhook is similar to [how to secure webhooks in Github](https://docs.github.com/webhooks/securing/). If left out, null, or empty, the secret will not be changed. (nullable)
]: any -> record<enabled: bool, automaticRedelivery: bool, url: string, authorizedEvents: record<everything: bool, specificEvents: list<string>>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)")
  let body = {enabled: $enabled, automaticRedelivery: $automaticRedelivery, url: $body_url, authorizedEvents: $authorizedEvents, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /api/v1/stores/{storeId}/webhooks/{webhookId}
# operationId: Webhooks_DeleteWebhook
export def "stores-webhooks DeleteWebhook" [
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get latest deliveries
#
# GET /api/v1/stores/{storeId}/webhooks/{webhookId}/deliveries
# operationId: Webhooks_GetWebhookDeliveries
export def "stores-webhooks-deliveries GetWebhookDeliveries" [
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # The number of latest deliveries to fetch
]: nothing -> table<id: string, timestamp: float, deliveryTime: float, httpCode: float, errorMessage: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)/deliveries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook delivery
#
# GET /api/v1/stores/{storeId}/webhooks/{webhookId}/deliveries/{deliveryId}
# operationId: Webhooks_GetWebhookDelivery
export def "stores-webhooks-deliveries GetWebhookDelivery" [
  deliveryId: string
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, timestamp: float, deliveryTime: float, httpCode: float, errorMessage: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)/deliveries/($deliveryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the delivery's request
#
# GET /api/v1/stores/{storeId}/webhooks/{webhookId}/deliveries/{deliveryId}/request
# operationId: Webhooks_GetWebhookDeliveryRequests
export def "stores-webhooks-deliveries-request GetWebhookDeliveryRequests" [
  deliveryId: string
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)/deliveries/($deliveryId)/request")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Redeliver the delivery
#
# POST /api/v1/stores/{storeId}/webhooks/{webhookId}/deliveries/{deliveryId}/redeliver
# operationId: Webhooks_RedeliverWebhookDelivery
export def "stores-webhooks-deliveries-redeliver RedeliverWebhookDelivery" [
  deliveryId: string
  storeId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stores/($storeId)/webhooks/($webhookId)/deliveries/($deliveryId)/redeliver")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
