# Auto-generated client for Google Sheets API vv4
# Source: https://api.apis.guru/v2/specs/googleapis.com/sheets/v4/openapi.json
# Auth: --token flag or $env.GOOGLE_SHEETS_API_TOKEN

const BASE_URL = "https://sheets.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_SHEETS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sheets.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def dateTimeRenderOption-completer [] { ["FORMATTED_STRING" "SERIAL_NUMBER"] }
def majorDimension-completer [] { ["COLUMNS" "DIMENSION_UNSPECIFIED" "ROWS"] }
def valueRenderOption-completer [] { ["FORMATTED_VALUE" "FORMULA" "UNFORMATTED_VALUE"] }
def responseDateTimeRenderOption-completer [] { ["FORMATTED_STRING" "SERIAL_NUMBER"] }
def responseValueRenderOption-completer [] { ["FORMATTED_VALUE" "FORMULA" "UNFORMATTED_VALUE"] }
def valueInputOption-completer [] { ["INPUT_VALUE_OPTION_UNSPECIFIED" "RAW" "USER_ENTERED"] }
def insertDataOption-completer [] { ["INSERT_ROWS" "OVERWRITE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "spreadsheets sheetsspreadsheetscreate" } } | get name | first)
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

# Creates a spreadsheet, returning the newly created spreadsheet.
#
# POST /v4/spreadsheets
# operationId: sheets.spreadsheets.create
# --dataSourceSchedules item shape: {dailySchedule?: record, enabled?: bool, monthlySchedule?: record, nextRun?: record, refreshScope?: "DATA_SOURCE_REFRESH_SCOPE_UNSPECIFIED"|"ALL_DATA_SOURCES", weeklySchedule?: record}
# --dataSources item shape: {calculatedColumns?: list, dataSourceId?: string, sheetId?: int, spec?: record}
# --developerMetadata item shape: {location?: record, metadataId?: int, metadataKey?: string, metadataValue?: string, visibility?: "DEVELOPER_METADATA_VISIBILITY_UNSPECIFIED"|"DOCUMENT"|"PROJECT"}
# --namedRanges item shape: {name?: string, namedRangeId?: string, range?: record}
# --properties shape: {autoRecalc?: "RECALCULATION_INTERVAL_UNSPECIFIED"|"ON_CHANGE"|"MINUTE"|"HOUR", defaultFormat?: record, iterativeCalculationSettings?: record, locale?: string, spreadsheetTheme?: record, timeZone?: string, title?: string}
# --sheets item shape: {bandedRanges?: list, basicFilter?: record, charts?: list, columnGroups?: list, conditionalFormats?: list, data?: list, developerMetadata?: list, filterViews?: list, merges?: list, properties?: record, protectedRanges?: list, rowGroups?: list, slicers?: list}
export def "spreadsheets sheetsspreadsheetscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataSources: list # A list of external data sources connected with the spreadsheet. — item shape: {calculatedColumns?: list, dataSourceId?: string, sheetId?: int, spec?: record}
  --developerMetadata: list # The developer metadata associated with a spreadsheet. — item shape: {location?: record, metadataId?: int, metadataKey?: string, metadataValue?: string, visibility?: "DEVELOPER_METADATA_VISIBILITY_UNSPECIFIED"|"DOCUMENT"|"PROJECT"}
  --namedRanges: list # The named ranges defined in a spreadsheet. — item shape: {name?: string, namedRangeId?: string, range?: record}
  --properties: record # Properties of a spreadsheet. — shape: {autoRecalc?: "RECALCULATION_INTERVAL_UNSPECIFIED"|"ON_CHANGE"|"MINUTE"|"HOUR", defaultFormat?: record, iterativeCalculationSettings?: record, locale?: string, spreadsheetTheme?: record, timeZone?: string, title?: string}
  --sheets: list # The sheets that are part of a spreadsheet. — item shape: {bandedRanges?: list, basicFilter?: record, charts?: list, columnGroups?: list, conditionalFormats?: list, data?: list, developerMetadata?: list, filterViews?: list, merges?: list, properties?: record, protectedRanges?: list, rowGroups?: list, slicers?: list}
  --spreadsheetId: string # The ID of the spreadsheet. This field is read-only.
  --spreadsheetUrl: string # The url of the spreadsheet. This field is read-only.
]: any -> record<dataSourceSchedules: table<dailySchedule: record, enabled: bool, monthlySchedule: record, nextRun: record, refreshScope: string, weeklySchedule: record>, dataSources: table<calculatedColumns: list, dataSourceId: string, sheetId: int, spec: record>, developerMetadata: table<location: record, metadataId: int, metadataKey: string, metadataValue: string, visibility: string>, namedRanges: table<name: string, namedRangeId: string, range: record>, properties: record<autoRecalc: string, defaultFormat: record<backgroundColor: record, backgroundColorStyle: record, borders: record, horizontalAlignment: string, hyperlinkDisplayType: string, numberFormat: record, padding: record, textDirection: string, textFormat: record, textRotation: record, verticalAlignment: string, wrapStrategy: string>, iterativeCalculationSettings: record<convergenceThreshold: float, maxIterations: int>, locale: string, spreadsheetTheme: record<primaryFontFamily: string, themeColors: list>, timeZone: string, title: string>, sheets: table<bandedRanges: list, basicFilter: record, charts: list, columnGroups: list, conditionalFormats: list, data: list, developerMetadata: list, filterViews: list, merges: list, properties: record, protectedRanges: list, rowGroups: list, slicers: list>, spreadsheetId: string, spreadsheetUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/spreadsheets" $qp)
  let body = {dataSources: $dataSources, developerMetadata: $developerMetadata, namedRanges: $namedRanges, properties: $properties, sheets: $sheets, spreadsheetId: $spreadsheetId, spreadsheetUrl: $spreadsheetUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the spreadsheet at the given ID. The caller must specify the spreadsheet ID. By default, data within grids is not returned. You can include grid data in one of 2 ways: * Specify a [field mask](https://developers.google.com/sheets/api/guides/field-masks) listing your desired fields using the `fields` URL parameter in HTTP * Set the includeGridData URL parameter to true. If a field mask is set, the `includeGridData` parameter is ignored For large spreadsheets, as a best practice, retrieve only the specific spreadsheet fields that you want. To retrieve only subsets of spreadsheet data, use the ranges URL parameter. Ranges are specified using [A1 notation](/sheets/api/guides/concepts#cell). You can define a single cell (for example, `A1`) or multiple cells (for example, `A1:D5`). You can also get cells from other sheets within the same spreadsheet (for example, `Sheet2!A1:C4`) or retrieve multiple ranges at once (for example, `?ranges=A1:D5&ranges=Sheet2!A1:C4`). Limiting the range returns only the portions of the spreadsheet that intersect the requested ranges.
#
# GET /v4/spreadsheets/{spreadsheetId}
# operationId: sheets.spreadsheets.get
export def "spreadsheets sheetsspreadsheetsget" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeGridData: oneof<nothing, bool> # True if grid data should be returned. This parameter is ignored if a field mask was set in the request.
  --ranges: list # The ranges to retrieve from the spreadsheet.
]: nothing -> record<dataSourceSchedules: table<dailySchedule: record, enabled: bool, monthlySchedule: record, nextRun: record, refreshScope: string, weeklySchedule: record>, dataSources: table<calculatedColumns: list, dataSourceId: string, sheetId: int, spec: record>, developerMetadata: table<location: record, metadataId: int, metadataKey: string, metadataValue: string, visibility: string>, namedRanges: table<name: string, namedRangeId: string, range: record>, properties: record<autoRecalc: string, defaultFormat: record<backgroundColor: record, backgroundColorStyle: record, borders: record, horizontalAlignment: string, hyperlinkDisplayType: string, numberFormat: record, padding: record, textDirection: string, textFormat: record, textRotation: record, verticalAlignment: string, wrapStrategy: string>, iterativeCalculationSettings: record<convergenceThreshold: float, maxIterations: int>, locale: string, spreadsheetTheme: record<primaryFontFamily: string, themeColors: list>, timeZone: string, title: string>, sheets: table<bandedRanges: list, basicFilter: record, charts: list, columnGroups: list, conditionalFormats: list, data: list, developerMetadata: list, filterViews: list, merges: list, properties: record, protectedRanges: list, rowGroups: list, slicers: list>, spreadsheetId: string, spreadsheetUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "includeGridData" $includeGridData "scalar") (serialize-qp "ranges" $ranges "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the developer metadata with the specified ID. The caller must specify the spreadsheet ID and the developer metadata's unique metadataId.
#
# GET /v4/spreadsheets/{spreadsheetId}/developerMetadata/{metadataId}
# operationId: sheets.spreadsheets.developerMetadata.get
export def "spreadsheets-developer-metadata sheetsspreadsheetsdeveloperMetadataget" [
  spreadsheetId: string
  metadataId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<location: record<dimensionRange: record<dimension: string, endIndex: int, sheetId: int, startIndex: int>, locationType: string, sheetId: int, spreadsheet: bool>, metadataId: int, metadataKey: string, metadataValue: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/developerMetadata/($metadataId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all developer metadata matching the specified DataFilter. If the provided DataFilter represents a DeveloperMetadataLookup object, this will return all DeveloperMetadata entries selected by it. If the DataFilter represents a location in a spreadsheet, this will return all developer metadata associated with locations intersecting that region.
#
# POST /v4/spreadsheets/{spreadsheetId}/developerMetadata:search
# operationId: sheets.spreadsheets.developerMetadata.search
# --dataFilters item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
export def "spreadsheets-developer-metadata-search sheetsspreadsheetsdeveloperMetadatasearch" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataFilters: list # The data filters describing the criteria used to determine which DeveloperMetadata entries to return. DeveloperMetadata matching any of the specified filters are included in the response. — item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
]: any -> record<matchedDeveloperMetadata: table<dataFilters: list, developerMetadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/developerMetadata:search" $qp)
  let body = {dataFilters: $dataFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copies a single sheet from a spreadsheet to another spreadsheet. Returns the properties of the newly created sheet.
#
# POST /v4/spreadsheets/{spreadsheetId}/sheets/{sheetId}:copyTo
# operationId: sheets.spreadsheets.sheets.copyTo
export def "spreadsheets-sheets sheetsspreadsheetssheetscopyTo" [
  spreadsheetId: string
  sheetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinationSpreadsheetId: string # The ID of the spreadsheet to copy the sheet to.
]: any -> record<dataSourceSheetProperties: record<columns: list<record>, dataExecutionStatus: record<errorCode: string, errorMessage: string, lastRefreshTime: string, state: string>, dataSourceId: string>, gridProperties: record<columnCount: int, columnGroupControlAfter: bool, frozenColumnCount: int, frozenRowCount: int, hideGridlines: bool, rowCount: int, rowGroupControlAfter: bool>, hidden: bool, index: int, rightToLeft: bool, sheetId: int, sheetType: string, tabColor: record<alpha: float, blue: float, green: float, red: float>, tabColorStyle: record<rgbColor: record<alpha: float, blue: float, green: float, red: float>, themeColor: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/sheets/($sheetId):copyTo" $qp)
  let body = {destinationSpreadsheetId: $destinationSpreadsheetId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a range of values from a spreadsheet. The caller must specify the spreadsheet ID and a range.
#
# GET /v4/spreadsheets/{spreadsheetId}/values/{range}
# operationId: sheets.spreadsheets.values.get
export def "spreadsheets-values sheetsspreadsheetsvaluesget" [
  spreadsheetId: string
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dateTimeRenderOption: string@dateTimeRenderOption-completer # How dates, times, and durations should be represented in the output. This is ignored if value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --majorDimension: string@majorDimension-completer # The major dimension that results should use. For example, if the spreadsheet data in Sheet1 is: `A1=1,B1=2,A2=3,B2=4`, then requesting `range=Sheet1!A1:B2?majorDimension=ROWS` returns `[[1,2],[3,4]]`, whereas requesting `range=Sheet1!A1:B2?majorDimension=COLUMNS` returns `[[1,3],[2,4]]`.
  --valueRenderOption: string@valueRenderOption-completer # How values should be represented in the output. The default render option is FORMATTED_VALUE.
]: nothing -> record<majorDimension: string, range: string, values: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dateTimeRenderOption" $dateTimeRenderOption "scalar") (serialize-qp "majorDimension" $majorDimension "scalar") (serialize-qp "valueRenderOption" $valueRenderOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values/($range)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets values in a range of a spreadsheet. The caller must specify the spreadsheet ID, range, and a valueInputOption.
#
# PUT /v4/spreadsheets/{spreadsheetId}/values/{range}
# operationId: sheets.spreadsheets.values.update
export def "spreadsheets-values sheetsspreadsheetsvaluesupdate" [
  spreadsheetId: string
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeValuesInResponse: oneof<nothing, bool> # Determines if the update response should include the values of the cells that were updated. By default, responses do not include the updated values. If the range to write was larger than the range actually written, the response includes all values in the requested range (excluding trailing empty rows and columns).
  --responseDateTimeRenderOption: string@responseDateTimeRenderOption-completer # Determines how dates, times, and durations in the response should be rendered. This is ignored if response_value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --responseValueRenderOption: string@responseValueRenderOption-completer # Determines how values in the response should be rendered. The default render option is FORMATTED_VALUE.
  --valueInputOption: string@valueInputOption-completer # How the input data should be interpreted.
  --majorDimension: string@majorDimension-completer # The major dimension of the values. For output, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then requesting `range=A1:B2,majorDimension=ROWS` will return `[[1,2],[3,4]]`, whereas requesting `range=A1:B2,majorDimension=COLUMNS` will return `[[1,3],[2,4]]`. For input, with `range=A1:B2,majorDimension=ROWS` then `[[1,2],[3,4]]` will set `A1=1,B1=2,A2=3,B2=4`. With `range=A1:B2,majorDimension=COLUMNS` then `[[1,2],[3,4]]` will set `A1=1,B1=3,A2=2,B2=4`. When writing, if this field is not set, it defaults to ROWS.
  --body-range: string # The range the values cover, in [A1 notation](/sheets/api/guides/concepts#cell). For output, this range indicates the entire requested range, even though the values will exclude trailing rows and columns. When appending values, this field represents the range to search for a table, after which values will be appended.
  --values: list # The data that was read or to be written. This is an array of arrays, the outer array representing all the data and each inner array representing a major dimension. Each item in the inner array corresponds with one cell. For output, empty trailing rows and columns will not be included. For input, supported value types are: bool, string, and double. Null values will be skipped. To set a cell to an empty value, set the string value to an empty string.
]: any -> record<spreadsheetId: string, updatedCells: int, updatedColumns: int, updatedData: record<majorDimension: string, range: string, values: list<list>>, updatedRange: string, updatedRows: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "includeValuesInResponse" $includeValuesInResponse "scalar") (serialize-qp "responseDateTimeRenderOption" $responseDateTimeRenderOption "scalar") (serialize-qp "responseValueRenderOption" $responseValueRenderOption "scalar") (serialize-qp "valueInputOption" $valueInputOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values/($range)" $qp)
  let body = {majorDimension: $majorDimension, range: $body_range, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Appends values to a spreadsheet. The input range is used to search for existing data and find a "table" within that range. Values will be appended to the next row of the table, starting with the first column of the table. See the [guide](/sheets/api/guides/values#appending_values) and [sample code](/sheets/api/samples/writing#append_values) for specific details of how tables are detected and data is appended. The caller must specify the spreadsheet ID, range, and a valueInputOption. The `valueInputOption` only controls how the input data will be added to the sheet (column-wise or row-wise), it does not influence what cell the data starts being written to.
#
# POST /v4/spreadsheets/{spreadsheetId}/values/{range}:append
# operationId: sheets.spreadsheets.values.append
export def "spreadsheets-values sheetsspreadsheetsvaluesappend" [
  spreadsheetId: string
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeValuesInResponse: oneof<nothing, bool> # Determines if the update response should include the values of the cells that were appended. By default, responses do not include the updated values.
  --insertDataOption: string@insertDataOption-completer # How the input data should be inserted.
  --responseDateTimeRenderOption: string@responseDateTimeRenderOption-completer # Determines how dates, times, and durations in the response should be rendered. This is ignored if response_value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --responseValueRenderOption: string@responseValueRenderOption-completer # Determines how values in the response should be rendered. The default render option is FORMATTED_VALUE.
  --valueInputOption: string@valueInputOption-completer # How the input data should be interpreted.
  --majorDimension: string@majorDimension-completer # The major dimension of the values. For output, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then requesting `range=A1:B2,majorDimension=ROWS` will return `[[1,2],[3,4]]`, whereas requesting `range=A1:B2,majorDimension=COLUMNS` will return `[[1,3],[2,4]]`. For input, with `range=A1:B2,majorDimension=ROWS` then `[[1,2],[3,4]]` will set `A1=1,B1=2,A2=3,B2=4`. With `range=A1:B2,majorDimension=COLUMNS` then `[[1,2],[3,4]]` will set `A1=1,B1=3,A2=2,B2=4`. When writing, if this field is not set, it defaults to ROWS.
  --body-range: string # The range the values cover, in [A1 notation](/sheets/api/guides/concepts#cell). For output, this range indicates the entire requested range, even though the values will exclude trailing rows and columns. When appending values, this field represents the range to search for a table, after which values will be appended.
  --values: list # The data that was read or to be written. This is an array of arrays, the outer array representing all the data and each inner array representing a major dimension. Each item in the inner array corresponds with one cell. For output, empty trailing rows and columns will not be included. For input, supported value types are: bool, string, and double. Null values will be skipped. To set a cell to an empty value, set the string value to an empty string.
]: any -> record<spreadsheetId: string, tableRange: string, updates: record<spreadsheetId: string, updatedCells: int, updatedColumns: int, updatedData: record<majorDimension: string, range: string, values: list>, updatedRange: string, updatedRows: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "includeValuesInResponse" $includeValuesInResponse "scalar") (serialize-qp "insertDataOption" $insertDataOption "scalar") (serialize-qp "responseDateTimeRenderOption" $responseDateTimeRenderOption "scalar") (serialize-qp "responseValueRenderOption" $responseValueRenderOption "scalar") (serialize-qp "valueInputOption" $valueInputOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values/($range):append" $qp)
  let body = {majorDimension: $majorDimension, range: $body_range, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clears values from a spreadsheet. The caller must specify the spreadsheet ID and range. Only values are cleared -- all other properties of the cell (such as formatting, data validation, etc..) are kept.
#
# POST /v4/spreadsheets/{spreadsheetId}/values/{range}:clear
# operationId: sheets.spreadsheets.values.clear
export def "spreadsheets-values sheetsspreadsheetsvaluesclear" [
  spreadsheetId: string
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<clearedRange: string, spreadsheetId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values/($range):clear" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clears one or more ranges of values from a spreadsheet. The caller must specify the spreadsheet ID and one or more ranges. Only values are cleared -- all other properties of the cell (such as formatting and data validation) are kept.
#
# POST /v4/spreadsheets/{spreadsheetId}/values:batchClear
# operationId: sheets.spreadsheets.values.batchClear
export def "spreadsheets-values-batch-clear sheetsspreadsheetsvaluesbatchClear" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --ranges: list # The ranges to clear, in [A1 notation or R1C1 notation](/sheets/api/guides/concepts#cell).
]: any -> record<clearedRanges: list<string>, spreadsheetId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchClear" $qp)
  let body = {ranges: $ranges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clears one or more ranges of values from a spreadsheet. The caller must specify the spreadsheet ID and one or more DataFilters. Ranges matching any of the specified data filters will be cleared. Only values are cleared -- all other properties of the cell (such as formatting, data validation, etc..) are kept.
#
# POST /v4/spreadsheets/{spreadsheetId}/values:batchClearByDataFilter
# operationId: sheets.spreadsheets.values.batchClearByDataFilter
# --dataFilters item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
export def "spreadsheets-values-batch-clear-by-data-filter sheetsspreadsheetsvaluesbatchClearByDataFilter" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataFilters: list # The DataFilters used to determine which ranges to clear. — item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
]: any -> record<clearedRanges: list<string>, spreadsheetId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchClearByDataFilter" $qp)
  let body = {dataFilters: $dataFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns one or more ranges of values from a spreadsheet. The caller must specify the spreadsheet ID and one or more ranges.
#
# GET /v4/spreadsheets/{spreadsheetId}/values:batchGet
# operationId: sheets.spreadsheets.values.batchGet
export def "spreadsheets-values-batch-get sheetsspreadsheetsvaluesbatchGet" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dateTimeRenderOption: string@dateTimeRenderOption-completer # How dates, times, and durations should be represented in the output. This is ignored if value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --majorDimension: string@majorDimension-completer # The major dimension that results should use. For example, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then requesting `ranges=["A1:B2"],majorDimension=ROWS` returns `[[1,2],[3,4]]`, whereas requesting `ranges=["A1:B2"],majorDimension=COLUMNS` returns `[[1,3],[2,4]]`.
  --ranges: list # The [A1 notation or R1C1 notation](/sheets/api/guides/concepts#cell) of the range to retrieve values from.
  --valueRenderOption: string@valueRenderOption-completer # How values should be represented in the output. The default render option is ValueRenderOption.FORMATTED_VALUE.
]: nothing -> record<spreadsheetId: string, valueRanges: table<majorDimension: string, range: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dateTimeRenderOption" $dateTimeRenderOption "scalar") (serialize-qp "majorDimension" $majorDimension "scalar") (serialize-qp "ranges" $ranges "multi") (serialize-qp "valueRenderOption" $valueRenderOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns one or more ranges of values that match the specified data filters. The caller must specify the spreadsheet ID and one or more DataFilters. Ranges that match any of the data filters in the request will be returned.
#
# POST /v4/spreadsheets/{spreadsheetId}/values:batchGetByDataFilter
# operationId: sheets.spreadsheets.values.batchGetByDataFilter
# --dataFilters item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
export def "spreadsheets-values-batch-get-by-data-filter sheetsspreadsheetsvaluesbatchGetByDataFilter" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataFilters: list # The data filters used to match the ranges of values to retrieve. Ranges that match any of the specified data filters are included in the response. — item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
  --dateTimeRenderOption: string@dateTimeRenderOption-completer # How dates, times, and durations should be represented in the output. This is ignored if value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --majorDimension: string@majorDimension-completer # The major dimension that results should use. For example, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then a request that selects that range and sets `majorDimension=ROWS` returns `[[1,2],[3,4]]`, whereas a request that sets `majorDimension=COLUMNS` returns `[[1,3],[2,4]]`.
  --valueRenderOption: string@valueRenderOption-completer # How values should be represented in the output. The default render option is FORMATTED_VALUE.
]: any -> record<spreadsheetId: string, valueRanges: table<dataFilters: list, valueRange: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchGetByDataFilter" $qp)
  let body = {dataFilters: $dataFilters, dateTimeRenderOption: $dateTimeRenderOption, majorDimension: $majorDimension, valueRenderOption: $valueRenderOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets values in one or more ranges of a spreadsheet. The caller must specify the spreadsheet ID, a valueInputOption, and one or more ValueRanges.
#
# POST /v4/spreadsheets/{spreadsheetId}/values:batchUpdate
# operationId: sheets.spreadsheets.values.batchUpdate
# --data item shape: {majorDimension?: "DIMENSION_UNSPECIFIED"|"ROWS"|"COLUMNS", range?: string, values?: list}
export def "spreadsheets-values-batch-update sheetsspreadsheetsvaluesbatchUpdate" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --data: list # The new values to apply to the spreadsheet. — item shape: {majorDimension?: "DIMENSION_UNSPECIFIED"|"ROWS"|"COLUMNS", range?: string, values?: list}
  --includeValuesInResponse: oneof<nothing, bool> # Determines if the update response should include the values of the cells that were updated. By default, responses do not include the updated values. The `updatedData` field within each of the BatchUpdateValuesResponse.responses contains the updated values. If the range to write was larger than the range actually written, the response includes all values in the requested range (excluding trailing empty rows and columns).
  --responseDateTimeRenderOption: string@responseDateTimeRenderOption-completer # Determines how dates, times, and durations in the response should be rendered. This is ignored if response_value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --responseValueRenderOption: string@responseValueRenderOption-completer # Determines how values in the response should be rendered. The default render option is FORMATTED_VALUE.
  --valueInputOption: string@valueInputOption-completer # How the input data should be interpreted.
]: any -> record<responses: table<spreadsheetId: string, updatedCells: int, updatedColumns: int, updatedData: record, updatedRange: string, updatedRows: int>, spreadsheetId: string, totalUpdatedCells: int, totalUpdatedColumns: int, totalUpdatedRows: int, totalUpdatedSheets: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchUpdate" $qp)
  let body = {data: $data, includeValuesInResponse: $includeValuesInResponse, responseDateTimeRenderOption: $responseDateTimeRenderOption, responseValueRenderOption: $responseValueRenderOption, valueInputOption: $valueInputOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets values in one or more ranges of a spreadsheet. The caller must specify the spreadsheet ID, a valueInputOption, and one or more DataFilterValueRanges.
#
# POST /v4/spreadsheets/{spreadsheetId}/values:batchUpdateByDataFilter
# operationId: sheets.spreadsheets.values.batchUpdateByDataFilter
# --data item shape: {dataFilter?: record, majorDimension?: "DIMENSION_UNSPECIFIED"|"ROWS"|"COLUMNS", values?: list}
export def "spreadsheets-values-batch-update-by-data-filter sheetsspreadsheetsvaluesbatchUpdateByDataFilter" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --data: list # The new values to apply to the spreadsheet. If more than one range is matched by the specified DataFilter the specified values are applied to all of those ranges. — item shape: {dataFilter?: record, majorDimension?: "DIMENSION_UNSPECIFIED"|"ROWS"|"COLUMNS", values?: list}
  --includeValuesInResponse: oneof<nothing, bool> # Determines if the update response should include the values of the cells that were updated. By default, responses do not include the updated values. The `updatedData` field within each of the BatchUpdateValuesResponse.responses contains the updated values. If the range to write was larger than the range actually written, the response includes all values in the requested range (excluding trailing empty rows and columns).
  --responseDateTimeRenderOption: string@responseDateTimeRenderOption-completer # Determines how dates, times, and durations in the response should be rendered. This is ignored if response_value_render_option is FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  --responseValueRenderOption: string@responseValueRenderOption-completer # Determines how values in the response should be rendered. The default render option is FORMATTED_VALUE.
  --valueInputOption: string@valueInputOption-completer # How the input data should be interpreted.
]: any -> record<responses: table<dataFilter: record, updatedCells: int, updatedColumns: int, updatedData: record, updatedRange: string, updatedRows: int>, spreadsheetId: string, totalUpdatedCells: int, totalUpdatedColumns: int, totalUpdatedRows: int, totalUpdatedSheets: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId)/values:batchUpdateByDataFilter" $qp)
  let body = {data: $data, includeValuesInResponse: $includeValuesInResponse, responseDateTimeRenderOption: $responseDateTimeRenderOption, responseValueRenderOption: $responseValueRenderOption, valueInputOption: $valueInputOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Applies one or more updates to the spreadsheet. Each request is validated before being applied. If any request is not valid then the entire request will fail and nothing will be applied. Some requests have replies to give you some information about how they are applied. The replies will mirror the requests. For example, if you applied 4 updates and the 3rd one had a reply, then the response will have 2 empty replies, the actual reply, and another empty reply, in that order. Due to the collaborative nature of spreadsheets, it is not guaranteed that the spreadsheet will reflect exactly your changes after this completes, however it is guaranteed that the updates in the request will be applied together atomically. Your changes may be altered with respect to collaborator changes. If there are no collaborators, the spreadsheet should reflect your changes.
#
# POST /v4/spreadsheets/{spreadsheetId}:batchUpdate
# operationId: sheets.spreadsheets.batchUpdate
# --requests item shape: {addBanding?: record, addChart?: record, addConditionalFormatRule?: record, addDataSource?: record, addDimensionGroup?: record, addFilterView?: record, addNamedRange?: record, addProtectedRange?: record, addSheet?: record, addSlicer?: record, appendCells?: record, appendDimension?: record, autoFill?: record, autoResizeDimensions?: record, clearBasicFilter?: record, copyPaste?: record, createDeveloperMetadata?: record, cutPaste?: record, deleteBanding?: record, deleteConditionalFormatRule?: record, deleteDataSource?: record, deleteDeveloperMetadata?: record, deleteDimension?: record, deleteDimensionGroup?: record, deleteDuplicates?: record, deleteEmbeddedObject?: record, deleteFilterView?: record, deleteNamedRange?: record, deleteProtectedRange?: record, deleteRange?: record, deleteSheet?: record, duplicateFilterView?: record, duplicateSheet?: record, findReplace?: record, insertDimension?: record, insertRange?: record, mergeCells?: record, moveDimension?: record, pasteData?: record, randomizeRange?: record, refreshDataSource?: record, repeatCell?: record, setBasicFilter?: record, setDataValidation?: record, sortRange?: record, textToColumns?: record, trimWhitespace?: record, unmergeCells?: record, updateBanding?: record, updateBorders?: record, updateCells?: record, updateChartSpec?: record, updateConditionalFormatRule?: record, updateDataSource?: record, updateDeveloperMetadata?: record, updateDimensionGroup?: record, updateDimensionProperties?: record, updateEmbeddedObjectBorder?: record, updateEmbeddedObjectPosition?: record, updateFilterView?: record, updateNamedRange?: record, updateProtectedRange?: record, updateSheetProperties?: record, updateSlicerSpec?: record, updateSpreadsheetProperties?: record}
export def "spreadsheets sheetsspreadsheetsbatchUpdate" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeSpreadsheetInResponse: oneof<nothing, bool> # Determines if the update response should include the spreadsheet resource.
  --requests: list # A list of updates to apply to the spreadsheet. Requests will be applied in the order they are specified. If any request is not valid, no requests will be applied. — item shape: {addBanding?: record, addChart?: record, addConditionalFormatRule?: record, addDataSource?: record, addDimensionGroup?: record, addFilterView?: record, addNamedRange?: record, addProtectedRange?: record, addSheet?: record, addSlicer?: record, appendCells?: record, appendDimension?: record, autoFill?: record, autoResizeDimensions?: record, clearBasicFilter?: record, copyPaste?: record, createDeveloperMetadata?: record, cutPaste?: record, deleteBanding?: record, deleteConditionalFormatRule?: record, deleteDataSource?: record, deleteDeveloperMetadata?: record, deleteDimension?: record, deleteDimensionGroup?: record, deleteDuplicates?: record, deleteEmbeddedObject?: record, deleteFilterView?: record, deleteNamedRange?: record, deleteProtectedRange?: record, deleteRange?: record, deleteSheet?: record, duplicateFilterView?: record, duplicateSheet?: record, findReplace?: record, insertDimension?: record, insertRange?: record, mergeCells?: record, moveDimension?: record, pasteData?: record, randomizeRange?: record, refreshDataSource?: record, repeatCell?: record, setBasicFilter?: record, setDataValidation?: record, sortRange?: record, textToColumns?: record, trimWhitespace?: record, unmergeCells?: record, updateBanding?: record, updateBorders?: record, updateCells?: record, updateChartSpec?: record, updateConditionalFormatRule?: record, updateDataSource?: record, updateDeveloperMetadata?: record, updateDimensionGroup?: record, updateDimensionProperties?: record, updateEmbeddedObjectBorder?: record, updateEmbeddedObjectPosition?: record, updateFilterView?: record, updateNamedRange?: record, updateProtectedRange?: record, updateSheetProperties?: record, updateSlicerSpec?: record, updateSpreadsheetProperties?: record}
  --responseIncludeGridData: oneof<nothing, bool> # True if grid data should be returned. Meaningful only if include_spreadsheet_in_response is 'true'. This parameter is ignored if a field mask was set in the request.
  --responseRanges: list # Limits the ranges included in the response spreadsheet. Meaningful only if include_spreadsheet_in_response is 'true'.
]: any -> record<replies: table<addBanding: record, addChart: record, addDataSource: record, addDimensionGroup: record, addFilterView: record, addNamedRange: record, addProtectedRange: record, addSheet: record, addSlicer: record, createDeveloperMetadata: record, deleteConditionalFormatRule: record, deleteDeveloperMetadata: record, deleteDimensionGroup: record, deleteDuplicates: record, duplicateFilterView: record, duplicateSheet: record, findReplace: record, refreshDataSource: record, trimWhitespace: record, updateConditionalFormatRule: record, updateDataSource: record, updateDeveloperMetadata: record, updateEmbeddedObjectPosition: record>, spreadsheetId: string, updatedSpreadsheet: record<dataSourceSchedules: list<record>, dataSources: list<record>, developerMetadata: list<record>, namedRanges: list<record>, properties: record<autoRecalc: string, defaultFormat: record, iterativeCalculationSettings: record, locale: string, spreadsheetTheme: record, timeZone: string, title: string>, sheets: list<record>, spreadsheetId: string, spreadsheetUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId):batchUpdate" $qp)
  let body = {includeSpreadsheetInResponse: $includeSpreadsheetInResponse, requests: $requests, responseIncludeGridData: $responseIncludeGridData, responseRanges: $responseRanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the spreadsheet at the given ID. The caller must specify the spreadsheet ID. This method differs from GetSpreadsheet in that it allows selecting which subsets of spreadsheet data to return by specifying a dataFilters parameter. Multiple DataFilters can be specified. Specifying one or more data filters returns the portions of the spreadsheet that intersect ranges matched by any of the filters. By default, data within grids is not returned. You can include grid data one of 2 ways: * Specify a [field mask](https://developers.google.com/sheets/api/guides/field-masks) listing your desired fields using the `fields` URL parameter in HTTP * Set the includeGridData parameter to true. If a field mask is set, the `includeGridData` parameter is ignored For large spreadsheets, as a best practice, retrieve only the specific spreadsheet fields that you want.
#
# POST /v4/spreadsheets/{spreadsheetId}:getByDataFilter
# operationId: sheets.spreadsheets.getByDataFilter
# --dataFilters item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
export def "spreadsheets sheetsspreadsheetsgetByDataFilter" [
  spreadsheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataFilters: list # The DataFilters used to select which ranges to retrieve from the spreadsheet. — item shape: {a1Range?: string, developerMetadataLookup?: record, gridRange?: record}
  --includeGridData: oneof<nothing, bool> # True if grid data should be returned. This parameter is ignored if a field mask was set in the request.
]: any -> record<dataSourceSchedules: table<dailySchedule: record, enabled: bool, monthlySchedule: record, nextRun: record, refreshScope: string, weeklySchedule: record>, dataSources: table<calculatedColumns: list, dataSourceId: string, sheetId: int, spec: record>, developerMetadata: table<location: record, metadataId: int, metadataKey: string, metadataValue: string, visibility: string>, namedRanges: table<name: string, namedRangeId: string, range: record>, properties: record<autoRecalc: string, defaultFormat: record<backgroundColor: record, backgroundColorStyle: record, borders: record, horizontalAlignment: string, hyperlinkDisplayType: string, numberFormat: record, padding: record, textDirection: string, textFormat: record, textRotation: record, verticalAlignment: string, wrapStrategy: string>, iterativeCalculationSettings: record<convergenceThreshold: float, maxIterations: int>, locale: string, spreadsheetTheme: record<primaryFontFamily: string, themeColors: list>, timeZone: string, title: string>, sheets: table<bandedRanges: list, basicFilter: record, charts: list, columnGroups: list, conditionalFormats: list, data: list, developerMetadata: list, filterViews: list, merges: list, properties: record, protectedRanges: list, rowGroups: list, slicers: list>, spreadsheetId: string, spreadsheetUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/spreadsheets/($spreadsheetId):getByDataFilter" $qp)
  let body = {dataFilters: $dataFilters, includeGridData: $includeGridData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
