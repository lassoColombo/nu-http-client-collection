# Auto-generated client for Xero Assets API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_assets/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_ASSETS_API_TOKEN

const BASE_URL = "https://api.xero.com/assets.xro/1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XERO_ASSETS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://api.xero.com/assets.xro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["DISPOSED" "DRAFT" "REGISTERED"] }
def order-by-completer [] { ["AssetName" "AssetNumber" "AssetType" "DisposalDate" "DisposalPrice" "PurchaseDate" "PurchasePrice"] }
def sort-direction-completer [] { ["asc" "desc"] }
def asset-status-completer [] { ["Disposed" "Draft" "Registered"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "asset-types get" } } | get name | first)
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

# searches fixed asset types
#
# GET /AssetTypes
# operationId: getAssetTypes
export def "asset-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<accumulatedDepreciationAccountId: string, assetTypeId: string, assetTypeName: string, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, depreciationExpenseAccountId: string, fixedAssetAccountId: string, locks: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssetTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# adds a fixed asset type
#
# POST /AssetTypes
# operationId: createAssetType
# --bookDepreciationSetting shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
export def "asset-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accumulated-depreciation-account-id: string # The account for accumulated depreciation of fixed assets of this type (format: uuid, e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
  --asset-type-id: string # Xero generated unique identifier for asset types (format: uuid, e.g. 5da209c5-5e19-4a43-b925-71b776c49ced)
  asset_type_name: string # The name of the asset type (e.g. Computer Equipment)
  book_depreciation_setting: any # shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
  --depreciation-expense-account-id: string # The expense account for the depreciation of fixed assets of this type (format: uuid, e.g. b23fc79b-d66b-44b0-a240-e138e086fcbc)
  --fixed-asset-account-id: string # The asset account for fixed assets of this type (format: uuid, e.g. 24e260f1-bfc4-4766-ad7f-8a8ce01de879)
  --locks: int # All asset types that have accumulated depreciation for any assets that use them are deemed ‘locked’ and cannot be removed. (e.g. 33)
]: any -> record<accumulatedDepreciationAccountId: string, assetTypeId: string, assetTypeName: string, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, depreciationExpenseAccountId: string, fixedAssetAccountId: string, locks: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssetTypes")
  let req_body = {"accumulatedDepreciationAccountId": $accumulated_depreciation_account_id, "assetTypeId": $asset_type_id, "assetTypeName": $asset_type_name, "bookDepreciationSetting": $book_depreciation_setting, "depreciationExpenseAccountId": $depreciation_expense_account_id, "fixedAssetAccountId": $fixed_asset_account_id, "locks": $locks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# searches fixed asset
#
# GET /Assets
# operationId: getAssets
export def "assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Required when retrieving a collection of assets. See Asset Status Codes (e.g. DRAFT)
  --page: int # Results are paged. This specifies which page of the results to return. The default page is 1. (e.g. 1)
  --page-size: int # The number of records returned per page. By default the number of records returned is 10. (e.g. 5)
  --order-by: string@order-by-completer # Requests can be ordered by AssetType, AssetName, AssetNumber, PurchaseDate and PurchasePrice. If the asset status is DISPOSED it also allows DisposalDate and DisposalPrice. (e.g. AssetName)
  --sort-direction: string@sort-direction-completer # ASC or DESC (e.g. ASC)
  --filter-by: string # A string that can be used to filter the list to only return assets containing the text. Checks it against the AssetName, AssetNumber, Description and AssetTypeName fields. (e.g. Company Car)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<items: table<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record, bookDepreciationSetting: record, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string>, pagination: record<itemCount: int, page: int, pageCount: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "filterBy" $filter_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "page": $page, "pageSize": $page_size, "orderBy": $order_by, "sortDirection": $sort_direction, "filterBy": $filter_by} | compact), body: null}
}

# adds a fixed asset
#
# POST /Assets
# operationId: createAsset
# --bookDepreciationDetail shape: {costLimit?: float, currentAccumDepreciationAmount?: float, currentCapitalGain?: float, currentGainLoss?: float, depreciationStartDate?: string, priorAccumDepreciationAmount?: float, residualValue?: float}
# --bookDepreciationSetting shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
export def "assets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accounting-book-value: float # The accounting value of the asset (format: double, e.g. 0)
  --asset-id: string # The Xero-generated Id for the asset (format: uuid, e.g. 3b5b3a38-5649-495f-87a1-14a4e5918634)
  asset_name: string # The name of the asset (e.g. Awesome Truck 3)
  --asset-number: string # Must be unique. (e.g. FA-0013)
  --asset-status: string@asset-status-completer # See Asset Status Codes. (e.g. Draft)
  --asset-type-id: string # The Xero-generated Id for the asset type (format: uuid, e.g. 3b5b3a38-5649-495f-87a1-14a4e5918634)
  --book-depreciation-detail: any # shape: {costLimit?: float, currentAccumDepreciationAmount?: float, currentCapitalGain?: float, currentGainLoss?: float, depreciationStartDate?: string, priorAccumDepreciationAmount?: float, residualValue?: float}
  --book-depreciation-setting: any # shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
  --can-rollback: oneof<nothing, bool> # Boolean to indicate whether depreciation can be rolled back for this asset individually. This is true if it doesn't have 'legacy' journal entries and if there is no lock period that would prevent this asset from rolling back. (e.g. true)
  --disposal-date: string # The date the asset was disposed (format: date, e.g. 2020-07-01T00:00:00)
  --disposal-price: float # The price the asset was disposed at (format: double, e.g. 1.0000)
  --is-delete-enabled-for-date: oneof<nothing, bool> # Boolean to indicate whether delete is enabled (e.g. true)
  --purchase-date: string # The date the asset was purchased YYYY-MM-DD (format: date, e.g. 2015-07-01T00:00:00)
  --purchase-price: float # The purchase price of the asset (format: double, e.g. 1000.0000)
  --serial-number: string # The asset's serial number (e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
  --warranty-expiry-date: string # The date the asset’s warranty expires (if needed) YYYY-MM-DD (e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
]: any -> record<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record<costLimit: float, currentAccumDepreciationAmount: float, currentCapitalGain: float, currentGainLoss: float, depreciationStartDate: string, priorAccumDepreciationAmount: float, residualValue: float>, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Assets")
  let req_body = {"accountingBookValue": $accounting_book_value, "assetId": $asset_id, "assetName": $asset_name, "assetNumber": $asset_number, "assetStatus": $asset_status, "assetTypeId": $asset_type_id, "bookDepreciationDetail": $book_depreciation_detail, "bookDepreciationSetting": $book_depreciation_setting, "canRollback": $can_rollback, "disposalDate": $disposal_date, "disposalPrice": $disposal_price, "isDeleteEnabledForDate": $is_delete_enabled_for_date, "purchaseDate": $purchase_date, "purchasePrice": $purchase_price, "serialNumber": $serial_number, "warrantyExpiryDate": $warranty_expiry_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves fixed asset by id
#
# GET /Assets/{id}
# operationId: getAssetById
export def "assets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record<costLimit: float, currentAccumDepreciationAmount: float, currentCapitalGain: float, currentGainLoss: float, depreciationStartDate: string, priorAccumDepreciationAmount: float, residualValue: float>, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Assets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# searches fixed asset settings
#
# GET /Settings
# operationId: getAssetSettings
export def "settings get-asset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<assetNumberPrefix: string, assetNumberSequence: string, assetStartDate: string, defaultCapitalGainOnDisposalAccountId: string, defaultGainOnDisposalAccountId: string, defaultLossOnDisposalAccountId: string, lastDepreciationDate: string, optInForTax: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
