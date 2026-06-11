# Auto-generated client for Criteo API v2023-10
# Source: https://api.criteo.com/2023-10/retailmedia/open-api-specifications.json
# Auth: --token flag or $env.CRITEO_API_TOKEN

const BASE_URL = "https://api.criteo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CRITEO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.criteo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def limitToType-completer [] { ["Auction" "Preferred" "Unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2023-10-retail-media-accounts GetAccounts" } } | get name | first)
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

# /2023-10/retail-media/accounts
#
# GET /2023-10/retail-media/accounts
# operationId: GetAccounts
export def "2023-10-retail-media-accounts GetAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/retail-media/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/accounts/{account-id}/campaigns
#
# GET /2023-10/retail-media/accounts/{account-id}/campaigns
# operationId: GetCampaignsByAccountId
export def "2023-10-retail-media-accounts-campaigns GetCampaignsByAccountId" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/accounts/{account-id}/campaigns
#
# POST /2023-10/retail-media/accounts/{account-id}/campaigns
# operationId: CreateCampaignsByAccountId
# --data shape: {attributes?: record, type: string}
export def "2023-10-retail-media-accounts-campaigns CreateCampaignsByAccountId" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A JSON:API wrapper class to format a <typeparamref name="TAttributes" /> with Type, and Attributes properties — shape: {attributes?: record, type: string}
]: any -> record<data: record<attributes: record<accountId: string, budget: float, budgetRemaining: float, budgetSpent: float, clickAttributionScope: string, clickAttributionWindow: string, companyName: string, createdAt: string, dailyPacing: float, drawableBalanceIds: list, endDate: string, isAutoDailyPacing: bool, monthlyPacing: float, name: string, onBehalfCompanyName: string, promotedBrandIds: list, retailerId: int, startDate: string, status: string, type: string, updatedAt: string, viewAttributionScope: string, viewAttributionWindow: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/campaigns")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/accounts/{account-id}/creatives
#
# GET /2023-10/retail-media/accounts/{account-id}/creatives
# operationId: GetAccountCreatives
export def "2023-10-retail-media-accounts-creatives GetAccountCreatives" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/creatives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/accounts/{account-id}/creatives
#
# POST /2023-10/retail-media/accounts/{account-id}/creatives
# operationId: CreateCreative
# --templateVariableValues item shape: {choiceVariableValue?: record, colorVariableValue?: record, filesVariableValue?: record, hyperlinkVariableValue?: record, id: string, textVariableValue?: record, videoVariableValue?: record}
export def "2023-10-retail-media-accounts-creatives CreateCreative" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brandId: int # The brand associated to the creative (nullable, format: int64)
  --id: string # nullable
  name: string # The name of the creative
  retailerId: int # The retailer associated to the creative (format: int32)
  templateId: int # The creative template used for this creative (format: int32)
  templateVariableValues: list # The template chosen values — item shape: {choiceVariableValue?: record, colorVariableValue?: record, filesVariableValue?: record, hyperlinkVariableValue?: record, id: string, textVariableValue?: record, videoVariableValue?: record}
]: any -> record<data: record<attributes: record<associatedLineItemIds: list, brandId: int, creativeFormatType: string, environments: list, formatId: int, id: string, name: string, retailerId: int, status: string, templateId: int, templateName: string, templateVariableValues: list, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/creatives")
  let body = {brandId: $brandId, id: $id, name: $name, retailerId: $retailerId, templateId: $templateId, templateVariableValues: $templateVariableValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/accounts/{account-id}/creatives/{creative-id}
#
# PUT /2023-10/retail-media/accounts/{account-id}/creatives/{creative-id}
# operationId: UpdateCreative
# --templateVariableValues item shape: {choiceVariableValue?: record, colorVariableValue?: record, filesVariableValue?: record, hyperlinkVariableValue?: record, id: string, textVariableValue?: record, videoVariableValue?: record}
export def "2023-10-retail-media-accounts-creatives UpdateCreative" [
  account_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brandId: int # The brand associated to the creative (format: int64)
  --id: string # nullable
  name: string # The name of the creative
  retailerId: int # The retailer associated to the creative (format: int32)
  templateId: int # The creative template used for this creative (format: int32)
  templateVariableValues: list # The template chosen values — item shape: {choiceVariableValue?: record, colorVariableValue?: record, filesVariableValue?: record, hyperlinkVariableValue?: record, id: string, textVariableValue?: record, videoVariableValue?: record}
]: any -> record<data: record<attributes: record<associatedLineItemIds: list, brandId: int, creativeFormatType: string, environments: list, formatId: int, id: string, name: string, retailerId: int, status: string, templateId: int, templateName: string, templateVariableValues: list, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/creatives/($creative_id)")
  let body = {brandId: $brandId, id: $id, name: $name, retailerId: $retailerId, templateId: $templateId, templateVariableValues: $templateVariableValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/accounts/{account-id}/line-items
#
# GET /2023-10/retail-media/accounts/{account-id}/line-items
# operationId: GetLineItemsByAccountId
export def "2023-10-retail-media-accounts-line-items GetLineItemsByAccountId" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToCampaignId: list # The campaign ids that you would like to limit your result set to
  --limitToId: list # The ids that you would like to limit your result set to
  --limitToType: string@limitToType-completer # The campaign types that you would like to limit your result set to (nullable)
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToCampaignId" $limitToCampaignId "multi") (serialize-qp "limitToId" $limitToId "multi") (serialize-qp "limitToType" $limitToType "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($account_id)/line-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/accounts/{accountId}/brands
#
# GET /2023-10/retail-media/accounts/{accountId}/brands
# operationId: GetBrandsByAccountId
export def "2023-10-retail-media-accounts-brands GetBrandsByAccountId" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($accountId)/brands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/accounts/{accountId}/catalogs
#
# POST /2023-10/retail-media/accounts/{accountId}/catalogs
# operationId: CatalogApi_PostApiV1ExternalAccountCatalogsByAccountId
# --data shape: {attributes?: record, type: string}
export def "2023-10-retail-media-accounts-catalogs PostApiV1ExternalAccountCatalogsByAccountId" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A JSON:API wrapper class to format a <typeparamref name="TAttributes" /> with Type, and Attributes properties — shape: {attributes?: record, type: string}
]: any -> record<data: record<attributes: record<createdAt: string, currency: string, fileSizeBytes: int, md5Checksum: string, message: string, rowCount: int, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($accountId)/catalogs")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/accounts/{accountId}/retailers
#
# GET /2023-10/retail-media/accounts/{accountId}/retailers
# operationId: GetRetailersByAccountId
export def "2023-10-retail-media-accounts-retailers GetRetailersByAccountId" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/accounts/($accountId)/retailers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/assets
#
# POST /2023-10/retail-media/assets
# operationId: CreateAsset
export def "2023-10-retail-media-assets CreateAsset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  AssetFile: string # The asset binary content (format: binary)
]: any -> record<data: record<attributes: record<fileExtension: string, fileLocation: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/retail-media/assets")
  let body = {AssetFile: $AssetFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# /2023-10/retail-media/auction-line-items/{line-item-id}
#
# GET /2023-10/retail-media/auction-line-items/{line-item-id}
# operationId: GetAuctionLineItemsByLineItemId
export def "2023-10-retail-media-auction-line-items GetAuctionLineItemsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<bidStrategy: string, budget: float, budgetRemaining: float, budgetSpent: float, campaignId: string, createdAt: string, dailyPacing: float, endDate: string, id: string, isAutoDailyPacing: bool, maxBid: float, monthlyPacing: float, name: string, startDate: string, status: string, targetBid: float, targetRetailerId: string, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/auction-line-items/($line_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/auction-line-items/{line-item-id}
#
# PUT /2023-10/retail-media/auction-line-items/{line-item-id}
# operationId: UpdateAuctionLineItemByLineItemId
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-retail-media-auction-line-items UpdateAuctionLineItemByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A class that represents a domain entity exposed by an API — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: record<attributes: record<bidStrategy: string, budget: float, budgetRemaining: float, budgetSpent: float, campaignId: string, createdAt: string, dailyPacing: float, endDate: string, id: string, isAutoDailyPacing: bool, maxBid: float, monthlyPacing: float, name: string, startDate: string, status: string, targetBid: float, targetRetailerId: string, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/auction-line-items/($line_item_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/balances/{balance-id}/campaigns
#
# GET /2023-10/retail-media/balances/{balance-id}/campaigns
# operationId: GetCampaignsByBalanceId
export def "2023-10-retail-media-balances-campaigns GetCampaignsByBalanceId" [
  balance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/balances/($balance_id)/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/balances/{balance-id}/campaigns/append
#
# POST /2023-10/retail-media/balances/{balance-id}/campaigns/append
# operationId: AppendCampaignsByBalanceId
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-retail-media-balances-campaigns-append AppendCampaignsByBalanceId" [
  balance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/balances/($balance_id)/campaigns/append")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/balances/{balance-id}/campaigns/delete
#
# POST /2023-10/retail-media/balances/{balance-id}/campaigns/delete
# operationId: DeleteCampaignsByBalanceId
# --data item shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-retail-media-balances-campaigns-delete DeleteCampaignsByBalanceId" [
  balance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: list # item shape: {attributes?: record, id?: string, type?: string}
]: any -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/balances/($balance_id)/campaigns/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/campaigns/{campaign-id}/auction-line-items
#
# GET /2023-10/retail-media/campaigns/{campaign-id}/auction-line-items
# operationId: GetAuctionLineItemsByCampaignId
export def "2023-10-retail-media-campaigns-auction-line-items GetAuctionLineItemsByCampaignId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limitToId: list # The ids that you would like to limit your result set to
  --pageIndex: int # The 0 indexed page index you would like to receive given the page size (format: int32, default: 0)
  --pageSize: int # The maximum number of items you would like to receive in this request (format: int32, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, metadata: record<currentPageIndex: int, currentPageSize: int, nextPage: string, previousPage: string, totalItemsAcrossAllPages: int, totalPages: int>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limitToId" $limitToId "multi") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2023-10/retail-media/campaigns/($campaign_id)/auction-line-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/campaigns/{campaign-id}/auction-line-items
#
# POST /2023-10/retail-media/campaigns/{campaign-id}/auction-line-items
# operationId: ModifyAuctionLineItemsByCampaignId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-campaigns-auction-line-items ModifyAuctionLineItemsByCampaignId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a Resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<bidStrategy: string, budget: float, budgetRemaining: float, budgetSpent: float, campaignId: string, createdAt: string, dailyPacing: float, endDate: string, id: string, isAutoDailyPacing: bool, maxBid: float, monthlyPacing: float, name: string, startDate: string, status: string, targetBid: float, targetRetailerId: string, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/campaigns/($campaign_id)/auction-line-items")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/campaigns/{campaignId}
#
# GET /2023-10/retail-media/campaigns/{campaignId}
# operationId: GetCampaignByCampaignId
export def "2023-10-retail-media-campaigns GetCampaignByCampaignId" [
  campaignId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<accountId: string, budget: float, budgetRemaining: float, budgetSpent: float, clickAttributionScope: string, clickAttributionWindow: string, companyName: string, createdAt: string, dailyPacing: float, drawableBalanceIds: list, endDate: string, isAutoDailyPacing: bool, monthlyPacing: float, name: string, onBehalfCompanyName: string, promotedBrandIds: list, retailerId: int, startDate: string, status: string, type: string, updatedAt: string, viewAttributionScope: string, viewAttributionWindow: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/campaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/campaigns/{campaignId}
#
# PUT /2023-10/retail-media/campaigns/{campaignId}
# operationId: UpdateCampaignByCampaignId
# --data shape: {attributes?: record, id: string, type: string}
export def "2023-10-retail-media-campaigns UpdateCampaignByCampaignId" [
  campaignId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A JSON:API wrapper class to format a <typeparamref name="TAttributes" /> with Id, Type, and Attributes properties — shape: {attributes?: record, id: string, type: string}
]: any -> record<data: record<attributes: record<accountId: string, budget: float, budgetRemaining: float, budgetSpent: float, clickAttributionScope: string, clickAttributionWindow: string, companyName: string, createdAt: string, dailyPacing: float, drawableBalanceIds: list, endDate: string, isAutoDailyPacing: bool, monthlyPacing: float, name: string, onBehalfCompanyName: string, promotedBrandIds: list, retailerId: int, startDate: string, status: string, type: string, updatedAt: string, viewAttributionScope: string, viewAttributionWindow: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/campaigns/($campaignId)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/catalogs/{catalogId}/output
#
# GET /2023-10/retail-media/catalogs/{catalogId}/output
# operationId: GetCatalogOutput
export def "2023-10-retail-media-catalogs-output GetCatalogOutput" [
  catalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/catalogs/($catalogId)/output")
  let accept_val = "application/x-json-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/catalogs/{catalogId}/status
#
# GET /2023-10/retail-media/catalogs/{catalogId}/status
# operationId: GetCatalogStatus
export def "2023-10-retail-media-catalogs-status GetCatalogStatus" [
  catalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<createdAt: string, currency: string, fileSizeBytes: int, md5Checksum: string, message: string, rowCount: int, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/catalogs/($catalogId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/categories
#
# GET /2023-10/retail-media/categories
# operationId: CategorySearch_GetApiExternalV1Categories
export def "2023-10-retail-media-categories GetApiExternalV1Categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageIndex: int # The start position in the overall list of matches. Must be zero or greater. (format: int32, default: 0)
  --pageSize: int # The maximum number of results to return with each call. Must be greater than zero. (format: int32, default: 100)
  --retailerId: int # The retailer id for which Categories fetched (format: int32)
  --textSubstring: string # Query string to search across Categories
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "retailerId" $retailerId "scalar") (serialize-qp "textSubstring" $textSubstring "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2023-10/retail-media/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/line-items/{id}/keywords
#
# GET /2023-10/retail-media/line-items/{id}/keywords
# operationId: FetchKeywords
export def "2023-10-retail-media-line-items-keywords FetchKeywords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<keywords: record, rank: list>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/line-items/($id)/keywords")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/line-items/{id}/keywords/add-remove
#
# POST /2023-10/retail-media/line-items/{id}/keywords/add-remove
# operationId: AddRemoveKeywords
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-retail-media-line-items-keywords-add-remove AddRemoveKeywords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Resource object containing keywords to be added or removed from a line item — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/line-items/($id)/keywords/add-remove")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/line-items/{id}/keywords/set-bid
#
# POST /2023-10/retail-media/line-items/{id}/keywords/set-bid
# operationId: SetKeywordBids
# --data shape: {attributes?: record, id?: string, type?: string}
export def "2023-10-retail-media-line-items-keywords-set-bid SetKeywordBids" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Resource object containing keywords and their associated bid overrides — shape: {attributes?: record, id?: string, type?: string}
]: any -> record<errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, status: int, title: string, traceId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/line-items/($id)/keywords/set-bid")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/line-items/{line-item-id}
#
# GET /2023-10/retail-media/line-items/{line-item-id}
# operationId: GetLineItemsByCampaignId
export def "2023-10-retail-media-line-items GetLineItemsByCampaignId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<budget: float, budgetRemaining: float, budgetSpent: float, campaignId: string, createdAt: string, endDate: string, id: string, name: string, startDate: string, status: string, targetRetailerId: string, type: string, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/line-items/($line_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/me
#
# GET /2023-10/retail-media/me
# operationId: GetCurrentApplication
export def "2023-10-retail-media-me GetCurrentApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<applicationId: int, criteoService: string, description: string, name: string, organizationId: int>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/retail-media/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket
#
# GET /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket
# operationId: GetAddToBasketTargetsByLineItemId
export def "2023-10-retail-media-preferred-line-items-targeting-add-to-basket GetAddToBasketTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<categoryIds: list, productIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/add-to-basket")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket
#
# PUT /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket
# operationId: PutAddToBasketTargetByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-add-to-basket PutAddToBasketTargetByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<categoryIds: list, productIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/add-to-basket")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket/append
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket/append
# operationId: AppendAddToBasketTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-add-to-basket-append AppendAddToBasketTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<categoryIds: list, productIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/add-to-basket/append")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket/delete
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/add-to-basket/delete
# operationId: DeleteAddToBasketTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-add-to-basket-delete DeleteAddToBasketTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<categoryIds: list, productIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/add-to-basket/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences
#
# GET /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences
# operationId: GetAudienceTargetsByLineItemId
export def "2023-10-retail-media-preferred-line-items-targeting-audiences GetAudienceTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<audienceIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/audiences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences
#
# PUT /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences
# operationId: PutAudienceTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-audiences PutAudienceTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<audienceIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/audiences")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences/append
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences/append
# operationId: AppendAudienceTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-audiences-append AppendAudienceTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<audienceIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/audiences/append")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences/delete
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/audiences/delete
# operationId: DeleteAudienceTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-audiences-delete DeleteAudienceTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<audienceIds: list, scope: string>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/audiences/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores
#
# GET /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores
# operationId: GetStoreTargetsByLineItemId
export def "2023-10-retail-media-preferred-line-items-targeting-stores GetStoreTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<scope: string, storeIds: list>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/stores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores
#
# PUT /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores
# operationId: PutStoreTargetByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-stores PutStoreTargetByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<scope: string, storeIds: list>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/stores")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores/append
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores/append
# operationId: AppendStoreTargetsByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-stores-append AppendStoreTargetsByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<scope: string, storeIds: list>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/stores/append")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores/delete
#
# POST /2023-10/retail-media/preferred-line-items/{line-item-id}/targeting/stores/delete
# operationId: DeleteStoreTargetByLineItemId
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-preferred-line-items-targeting-stores-delete DeleteStoreTargetByLineItemId" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Data model for a value type resource — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<scope: string, storeIds: list>, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/preferred-line-items/($line_item_id)/targeting/stores/delete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/reports/{reportId}/output
#
# GET /2023-10/retail-media/reports/{reportId}/output
# operationId: GetAsyncExportOutput
export def "2023-10-retail-media-reports-output GetAsyncExportOutput" [
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/reports/($reportId)/output")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/reports/{reportId}/status
#
# GET /2023-10/retail-media/reports/{reportId}/status
# operationId: GetAsyncExportStatus
export def "2023-10-retail-media-reports-status GetAsyncExportStatus" [
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<createdAt: string, expiresAt: string, fileSizeBytes: int, id: string, md5CheckSum: string, message: string, rowCount: int, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/reports/($reportId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/reports/revenue
#
# POST /2023-10/retail-media/reports/revenue
# operationId: GenerateAsyncRevenueReport
# --data shape: {attributes?: record, type?: string}
export def "2023-10-retail-media-reports-revenue GenerateAsyncRevenueReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A top-level object that encapsulates a Criteo API response for a single value — shape: {attributes?: record, type?: string}
]: any -> record<data: record<attributes: record<createdAt: string, expiresAt: string, fileSizeBytes: int, id: string, md5CheckSum: string, message: string, rowCount: int, status: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2023-10/retail-media/reports/revenue")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# /2023-10/retail-media/retailers/{retailer-id}/templates
#
# GET /2023-10/retail-media/retailers/{retailer-id}/templates
# operationId: GetRetailerCreativeTemplates
export def "2023-10-retail-media-retailers-templates GetRetailerCreativeTemplates" [
  retailer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<attributes: record, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/retailers/($retailer_id)/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/retailers/{retailer-id}/templates/{template-id}
#
# GET /2023-10/retail-media/retailers/{retailer-id}/templates/{template-id}
# operationId: GetCreativeTemplate
export def "2023-10-retail-media-retailers-templates GetCreativeTemplate" [
  retailer_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<allCollectionsMandatory: bool, createdAt: string, creativeFormat: string, displayableSkusMax: int, id: string, name: string, sections: list, skuCollectionMax: int, skuCollectionMin: int, skuPerCollectionMax: int, skuPerCollectionMin: int, updatedAt: string>, id: string, type: string>, errors: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>, warnings: table<code: string, detail: string, instance: string, source: record, stackTrace: string, title: string, traceId: string, traceIdentifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/retailers/($retailer_id)/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# /2023-10/retail-media/retailers/{retailerId}/pages
#
# GET /2023-10/retail-media/retailers/{retailerId}/pages
# operationId: RetailerApi_GetApi202110ExternalRetailerPagesByRetailerId
export def "2023-10-retail-media-retailers-pages GetApi202110ExternalRetailerPagesByRetailerId" [
  retailerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pageTypes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2023-10/retail-media/retailers/($retailerId)/pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
