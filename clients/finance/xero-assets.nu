# Auto-generated client for Xero Assets API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_assets/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_ASSETS_API_TOKEN

const BASE_URL = "https://api.xero.com/assets.xro/1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XERO_ASSETS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.xero.com/assets.xro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["DISPOSED" "DRAFT" "REGISTERED"] }
def orderBy-completer [] { ["AssetName" "AssetNumber" "AssetType" "DisposalDate" "DisposalPrice" "PurchaseDate" "PurchasePrice"] }
def sortDirection-completer [] { ["asc" "desc"] }
def assetStatus-completer [] { ["Disposed" "Draft" "Registered"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<accumulatedDepreciationAccountId: string, assetTypeId: string, assetTypeName: string, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, depreciationExpenseAccountId: string, fixedAssetAccountId: string, locks: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssetTypes")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# adds a fixed asset type
#
# POST /AssetTypes
# operationId: createAssetType
# --bookDepreciationSetting shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
export def "asset-types createAssetType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accumulatedDepreciationAccountId: string # The account for accumulated depreciation of fixed assets of this type (format: uuid, e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
  --assetTypeId: string # Xero generated unique identifier for asset types (format: uuid, e.g. 5da209c5-5e19-4a43-b925-71b776c49ced)
  assetTypeName: string # The name of the asset type (e.g. Computer Equipment)
  bookDepreciationSetting: any # shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
  --depreciationExpenseAccountId: string # The expense account for the depreciation of fixed assets of this type (format: uuid, e.g. b23fc79b-d66b-44b0-a240-e138e086fcbc)
  --fixedAssetAccountId: string # The asset account for fixed assets of this type (format: uuid, e.g. 24e260f1-bfc4-4766-ad7f-8a8ce01de879)
  --locks: int # All asset types that have accumulated depreciation for any assets that use them are deemed ‘locked’ and cannot be removed. (e.g. 33)
]: any -> record<accumulatedDepreciationAccountId: string, assetTypeId: string, assetTypeName: string, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, depreciationExpenseAccountId: string, fixedAssetAccountId: string, locks: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssetTypes")
  let body = {accumulatedDepreciationAccountId: $accumulatedDepreciationAccountId, assetTypeId: $assetTypeId, assetTypeName: $assetTypeName, bookDepreciationSetting: $bookDepreciationSetting, depreciationExpenseAccountId: $depreciationExpenseAccountId, fixedAssetAccountId: $fixedAssetAccountId, locks: $locks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --status: string@status-completer # Required when retrieving a collection of assets. See Asset Status Codes (e.g. DRAFT)
  --page: int # Results are paged. This specifies which page of the results to return. The default page is 1. (e.g. 1)
  --pageSize: int # The number of records returned per page. By default the number of records returned is 10. (e.g. 5)
  --orderBy: string@orderBy-completer # Requests can be ordered by AssetType, AssetName, AssetNumber, PurchaseDate and PurchasePrice. If the asset status is DISPOSED it also allows DisposalDate and DisposalPrice. (e.g. AssetName)
  --sortDirection: string@sortDirection-completer # ASC or DESC (e.g. ASC)
  --filterBy: string # A string that can be used to filter the list to only return assets containing the text. Checks it against the AssetName, AssetNumber, Description and AssetTypeName fields. (e.g. Company Car)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<items: table<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record, bookDepreciationSetting: record, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string>, pagination: record<itemCount: int, page: int, pageCount: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "filterBy" $filterBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Assets" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# adds a fixed asset
#
# POST /Assets
# operationId: createAsset
# --bookDepreciationDetail shape: {costLimit?: float, currentAccumDepreciationAmount?: float, currentCapitalGain?: float, currentGainLoss?: float, depreciationStartDate?: string, priorAccumDepreciationAmount?: float, residualValue?: float}
# --bookDepreciationSetting shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
export def "assets createAsset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accountingBookValue: float # The accounting value of the asset (format: double, e.g. 0)
  --assetId: string # The Xero-generated Id for the asset (format: uuid, e.g. 3b5b3a38-5649-495f-87a1-14a4e5918634)
  assetName: string # The name of the asset (e.g. Awesome Truck 3)
  --assetNumber: string # Must be unique. (e.g. FA-0013)
  --assetStatus: string@assetStatus-completer # See Asset Status Codes. (e.g. Draft)
  --assetTypeId: string # The Xero-generated Id for the asset type (format: uuid, e.g. 3b5b3a38-5649-495f-87a1-14a4e5918634)
  --bookDepreciationDetail: any # shape: {costLimit?: float, currentAccumDepreciationAmount?: float, currentCapitalGain?: float, currentGainLoss?: float, depreciationStartDate?: string, priorAccumDepreciationAmount?: float, residualValue?: float}
  --bookDepreciationSetting: any # shape: {averagingMethod?: "FullMonth"|"ActualDays", bookEffectiveDateOfChangeId?: string, depreciableObjectId?: string, depreciableObjectType?: string, depreciationCalculationMethod?: "Rate"|"Life"|"None", depreciationMethod?: "NoDepreciation"|"StraightLine"|"DiminishingValue100"|"DiminishingValue150"|"DiminishingValue200"|"FullDepreciation", depreciationRate?: float, effectiveLifeYears?: int}
  --canRollback: oneof<nothing, bool> # Boolean to indicate whether depreciation can be rolled back for this asset individually. This is true if it doesn't have 'legacy' journal entries and if there is no lock period that would prevent this asset from rolling back. (e.g. true)
  --disposalDate: string # The date the asset was disposed (format: date, e.g. 2020-07-01T00:00:00)
  --disposalPrice: float # The price the asset was disposed at (format: double, e.g. 1.0000)
  --isDeleteEnabledForDate: oneof<nothing, bool> # Boolean to indicate whether delete is enabled (e.g. true)
  --purchaseDate: string # The date the asset was purchased YYYY-MM-DD (format: date, e.g. 2015-07-01T00:00:00)
  --purchasePrice: float # The purchase price of the asset (format: double, e.g. 1000.0000)
  --serialNumber: string # The asset's serial number (e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
  --warrantyExpiryDate: string # The date the asset’s warranty expires (if needed) YYYY-MM-DD (e.g. ca4c6b39-4f4f-43e8-98da-5e1f350a6694)
]: any -> record<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record<costLimit: float, currentAccumDepreciationAmount: float, currentCapitalGain: float, currentGainLoss: float, depreciationStartDate: string, priorAccumDepreciationAmount: float, residualValue: float>, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Assets")
  let body = {accountingBookValue: $accountingBookValue, assetId: $assetId, assetName: $assetName, assetNumber: $assetNumber, assetStatus: $assetStatus, assetTypeId: $assetTypeId, bookDepreciationDetail: $bookDepreciationDetail, bookDepreciationSetting: $bookDepreciationSetting, canRollback: $canRollback, disposalDate: $disposalDate, disposalPrice: $disposalPrice, isDeleteEnabledForDate: $isDeleteEnabledForDate, purchaseDate: $purchaseDate, purchasePrice: $purchasePrice, serialNumber: $serialNumber, warrantyExpiryDate: $warrantyExpiryDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<accountingBookValue: float, assetId: string, assetName: string, assetNumber: string, assetStatus: string, assetTypeId: string, bookDepreciationDetail: record<costLimit: float, currentAccumDepreciationAmount: float, currentCapitalGain: float, currentGainLoss: float, depreciationStartDate: string, priorAccumDepreciationAmount: float, residualValue: float>, bookDepreciationSetting: record<averagingMethod: string, bookEffectiveDateOfChangeId: string, depreciableObjectId: string, depreciableObjectType: string, depreciationCalculationMethod: string, depreciationMethod: string, depreciationRate: float, effectiveLifeYears: int>, canRollback: bool, disposalDate: string, disposalPrice: float, isDeleteEnabledForDate: bool, purchaseDate: string, purchasePrice: float, serialNumber: string, warrantyExpiryDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Assets/($id)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# searches fixed asset settings
#
# GET /Settings
# operationId: getAssetSettings
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<assetNumberPrefix: string, assetNumberSequence: string, assetStartDate: string, defaultCapitalGainOnDisposalAccountId: string, defaultGainOnDisposalAccountId: string, defaultLossOnDisposalAccountId: string, lastDepreciationDate: string, optInForTax: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Settings")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
